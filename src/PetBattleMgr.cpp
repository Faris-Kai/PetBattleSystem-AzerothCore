#include "PetBattleMgr.h"
#include "DatabaseEnv.h"
#include "ObjectMgr.h"
#include "ObjectAccessor.h"
#include "GossipDef.h"
#include "Chat.h"
#include "Player.h"
#include "Creature.h"
#include "Item.h"
#include "EventProcessor.h"
#include "TemporarySummon.h"
#include "SpellMgr.h"
#include "SpellInfo.h"
#include "Config.h"
#include "SharedDefines.h"
#include "Random.h"
#include "World.h"
#include "WorldPacket.h"
#include "Opcodes.h"
#include <random>
#include <cmath>
#include <algorithm>
#include <utility>

// Heal chance
// 50 = 50%
// 25 = 25%
// 75 = 75%
static uint32 const PET_HEAL_CHANCE = 50;

// Daño normal
static int32 const PET_DAMAGE_MIN = 10;
static int32 const PET_DAMAGE_MAX = 30;

// Curación: se almacena como valor negativo
// Ejemplo: -10 = cura 10 HP
//          -25 = cura 25 HP
static int32 const PET_HEAL_MIN = -25;
static int32 const PET_HEAL_MAX = -10;


// Texto generico de gossip ya existente por defecto en la tabla `npc_text`
static uint32 const GOSSIP_TEXT_GENERICO = 68;

// Identificadores de "sender" usados para diferenciar los distintos menus gossip
static uint32 const SENDER_TEAM_MENU = 9001;
static uint32 const SENDER_TEAM_PICK = 9002;
static uint32 const SENDER_DICE_MENU = 9010;
static uint32 const SENDER_ATTACK_MENU = 9020;
static uint32 const SENDER_DUEL_CHALLENGE = 9030;

// Duracion maxima de una mascota invocada como copia de combate.
static uint32 const PET_SUMMON_MAX_DURATION_MS = 10 * 60 * 1000;

// ================================================================
// Balance de combate
// ================================================================

static uint32 const PET_MISS_CHANCE_DEFAULT = 5;
static uint32 const PET_MISS_CHANCE_DISADVANTAGE = 25;

static int32 const PET_DAMAGE_VARIANCE = 5;

static uint32 const PET_XP_PERCENT_VS_WILD = 5;
static uint32 const PET_XP_PERCENT_VS_PVP = 15;

// Tiempo por defecto (en segundos) que tiene un jugador para atacar
// en su turno antes de perder el combate automaticamente.
static uint32 const PET_TURN_TIMEOUT_SECONDS_DEFAULT = 15;

// Tiempo maximo para que ambos jugadores realicen la tirada inicial.
// Es fijo y no depende de PetBattle.TurnTimeoutSeconds.
static uint32 const PET_COIN_ROLL_TIMEOUT_SECONDS = 15;

// Umbral de daño: por debajo de este valor se usa el visual "bajo",
// igual o por encima se usa el visual "alto". No aplica a curaciones.
static uint32 const PET_DAMAGE_VISUAL_THRESHOLD = 19;

// Prefijo utilizado por el addon cuando el debug esta activado.
static char const* PETDMG_CHAT_PREFIX = "[PETDMG]";

// ================================================================
// Animacion / movimiento de ataques
// ================================================================

// Distancia que mantiene la mascota respecto al rival al llegar para atacar.
static float const PET_ATTACK_DISTANCE = 1.5f;

// Distancia maxima permitida entre mascotas para iniciar un ataque.
static float const PET_MAX_ATTACK_DISTANCE = 10.0f;

// Distancia maxima (en yardas) para poder ENVIAR el reto de combate
// (.dp contra jugador o criatura). Si estan mas lejos, el reto ni
// siquiera se manda. Configurable via PetBattle.ChallengeMaxDistance.
static float const PET_CHALLENGE_MAX_DISTANCE_DEFAULT = 10.0f;

// Tiempo aproximado de la animacion de ataque.
static uint32 const PET_ATTACK_ANIMATION_MS = 900;

// Pequeña pausa una vez que la mascota vuelve a su posicion.
static uint32 const PET_ATTACK_RETURN_DELAY_MS = 150;

// ================================================================

PetBattleMgr* PetBattleMgr::instance()
{
    static PetBattleMgr instance;
    return &instance;
}

// ================================================================
// Localizacion del modulo
// ================================================================

void PetBattleMgr::EnsureLocaleTextsLoaded() const
{
    if (_localeTextsLoaded)
        return;

    QueryResult result = WorldDatabase.Query(
        "SELECT id, enUS, esES, frFR, deDE "
        "FROM bp_pet_locale");

    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 id = fields[0].Get<uint32>();

            LocaleTextRow row;
            row.enUS = fields[1].Get<std::string>();
            row.esES = fields[2].Get<std::string>();
            row.frFR = fields[3].Get<std::string>();
            row.deDE = fields[4].Get<std::string>();

            _localeTexts[id] = std::move(row);
        } while (result->NextRow());
    }

    _localeTextsLoaded = true;
}

std::string PetBattleMgr::GetDefaultText(uint32 textId) const
{
    switch (textId)
    {
    case PETTXT_SYSTEM_DISABLED: return "The pet battle system is disabled on this server.";
    case PETTXT_ALREADY_BATTLE: return "You are already in a pet battle.";
    case PETTXT_WILD_NEED_SLOT1: return "{0} is a wild companion! First configure slot 1 of your pet battle team (type /dp with no target selected).";
    case PETTXT_WILD_START: return "{0} is a capturable wild companion ({1})! The battle begins. If you defeat it, you can learn it.";
    case PETTXT_SLOT_LABEL: return "Slot {0}: {1}";
    case PETTXT_EMPTY: return "Empty";
    case PETTXT_CLEAR_TEAM: return "Pet team cleared.";
    case PETTXT_SAVE_TEAM: return "Pet team saved.";
    case PETTXT_PET_FALLBACK: return "Pet {0}";
    case PETTXT_NO_PETS: return "You have no pets available for battle.";
    case PETTXT_BACK: return "Back";
    case PETTXT_DUPLICATE_SLOT: return "That pet is already in another slot of your team.";
    case PETTXT_PET_ASSIGNED: return "Pet assigned to slot {0}.";
    case PETTXT_TEAMERR_INVALID: return "That companion is not a valid battle pet.";
    case PETTXT_REMOVE_EMPTY: return "There is no pet in that slot.";
    case PETTXT_REMOVE_CHAT: return "Pet '{0}' was removed from the team.";
    case PETTXT_FORGET_EMPTY: return "There is no pet in that slot.";
    case PETTXT_FORGET_CHAT: return "Pet '{0}' was forgotten.";
    case PETTXT_DETACH_NO_DATA: return "This pet has no registered source item.";
    case PETTXT_DETACH_NO_SOURCE: return "Pet '{0}' has no registered item that taught it.";
    case PETTXT_DETACH_ITEM_MISSING: return "The item configured for this pet does not exist.";
    case PETTXT_DETACH_BAGS: return "You do not have enough bag space.";
    case PETTXT_DETACH_BAG_CHAT: return "You do not have space to receive the pet item.";
    case PETTXT_DETACH_CREATE: return "The pet item could not be created.";
    case PETTXT_DETACH_CHAT: return "Pet '{0}' was detached and converted into item {1}.";
    case PETTXT_DUEL_ALREADY: return "You are already in a pet battle.";
    case PETTXT_TARGET_ALREADY: return "That player is already in a pet battle.";
    case PETTXT_CHALLENGER_NO_SLOT: return "You must configure slot 1 of your pet team before challenging (type /dp with no target selected).";
    case PETTXT_TARGET_NO_SLOT: return "{0} has not configured slot 1 of their pet team yet.";
    case PETTXT_CHALLENGE_SENT: return "You challenged {0} to a pet battle.";
    case PETTXT_CHALLENGE_RECEIVED: return "{0} challenged you to a pet battle. A window was opened on screen to respond (or type /dp accept // /dp decline).";
    case PETTXT_NO_PENDING: return "You have no pending pet challenge.";
    case PETTXT_CHALLENGER_GONE: return "The player who challenged you is no longer available.";
    case PETTXT_ALREADY_DUEL: return "One of the two players is already in another pet battle.";
    case PETTXT_DUEL_CANCEL: return "The battle was cancelled: one of the two players does not have slot 1 configured in their pet team.";
    case PETTXT_DUEL_STARTED: return "The pet battle has begun. Roll the dice to see who attacks first.";
    case PETTXT_CHALLENGE_REJECTED: return "{0} rejected your pet battle challenge.";
    case PETTXT_DUEL_REJECTED: return "You rejected the pet battle.";
    case PETTXT_FORFEIT_ADDON: return "You abandoned the pet battle.";
    case PETTXT_FORFEIT_CHAT: return "You abandoned the pet battle and lost.";
    case PETTXT_TEAM_MODIFIED: return "One of the duelists modified their pet team. The battle ends automatically.";
    case PETTXT_TEAM_MODIFIED_WILD_ADDON: return "You modified your team. You lost the pet battle.";
    case PETTXT_TEAM_MODIFIED_WILD_CHAT: return "You modified your pet team and lost the battle.";
    case PETTXT_TIMEOUT_WILD_ADDON: return "Time ran out to attack. You lost the pet battle.";
    case PETTXT_TIMEOUT_WILD_CHAT: return "Time ran out to attack and you lost the pet battle.";
    case PETTXT_TIMEOUT_PVP: return "The turn time expired. The player who failed to attack in time loses the battle.";
    case PETTXT_ROLL_MENU: return "Roll the dice";
    case PETTXT_ROLL_RESULT: return "You rolled {0} on the die.";
    case PETTXT_ROLL_DRAW: return "The dice are tied. Roll again.";
    case PETTXT_ROLL_WINNER: return "{0} won the roll and attacks first.";
    case PETTXT_ATTACK_INFO: return "Your pet: {0} | Opponent: {1}";
    case PETTXT_ATTACK_BUTTON: return "Attack {0} (Damage: {1})";
    case PETTXT_COOLDOWN: return "That ability is on cooldown for {0} turn(s).";
    case PETTXT_WILD_PET_NAME: return "The wild pet";
    case PETTXT_ATTACK_MISS: return "{0} attacks... but misses!";
    case PETTXT_EFFECTIVE: return " (Super effective! x2)";
    case PETTXT_ATTACK_HIT: return "{0} attacks for {1} damage{2}. Remaining health of the opposing pet: {3}";
    case PETTXT_PET_DEFEATED: return "A pet has been defeated. The next pet enters the battle.";
    case PETTXT_VICTORY: return "You won the pet battle!";
    case PETTXT_DEFEAT: return "You lost the pet battle.";
    case PETTXT_XP: return "You gain {0} experience ({1}% of your level bar).";
    case PETTXT_CAPTURE_NO_CREATURE: return "You captured the companion, but the wild creature could not be found in creature_template.";
    case PETTXT_CAPTURE_NO_MODEL: return "You captured the companion, but the wild creature has no valid model.";
    case PETTXT_CAPTURE_NO_ITEMS: return "You captured the companion, but no items with companion spells were found.";
    case PETTXT_CAPTURE_NO_MATCH: return "You captured the companion, but no item with a compatible model was found.";
    case PETTXT_CAPTURE_NO_SPACE: return "You captured the companion, but you have no inventory space for {0}! Make room and try again later.";
    case PETTXT_CAPTURE_SUCCESS: return "You captured the companion! You receive {0} — you can learn it, give it away, or sell it.";
    case PETTXT_TYPE_WATER: return "Water";
    case PETTXT_TYPE_EARTH: return "Earth";
    case PETTXT_TYPE_FIRE: return "Fire";
    case PETTXT_TYPE_LIGHT: return "Light";
    case PETTXT_TYPE_DARKNESS: return "Darkness";
    case PETTXT_TYPE_BASIC: return "Basic";
    case PETTXT_TYPE_UNKNOWN: return "Unknown";
    case PETTXT_WILD_NOT_CAPTUREABLE: return "That creature is not a capturable pet companion.";
    case PETTXT_TOO_FAR: return "You are too far from the opponent.";
    case PETTXT_ATTACK_HEAL: return "{0} has recovered {1} health points. Current HP: {2}";
    case PETTXT_AUTO_HEAL: return "{0} change opinion and has recovered {1} health points. Current HP: {2}";
    default: return "[PetBattleText:{0}]";
    }
}

std::string PetBattleMgr::GetText(Player* player, uint32 textId) const
{
    EnsureLocaleTextsLoaded();

    auto it = _localeTexts.find(textId);
    if (it == _localeTexts.end())
        return GetDefaultText(textId);

    LocaleConstant locale = LOCALE_enUS;
    if (player && player->GetSession())
        locale = player->GetSession()->GetSessionDbLocaleIndex();

    switch (locale)
    {
    case LOCALE_esES:
    case LOCALE_esMX:
        return it->second.esES;
    case LOCALE_frFR:
        return it->second.frFR;
    case LOCALE_deDE:
        return it->second.deDE;
    default:
        return it->second.enUS;
    }
}

std::string PetBattleMgr::GetTextFmt(
    Player* player,
    uint32 textId,
    std::initializer_list<std::string> args) const
{
    std::string text = GetText(player, textId);
    uint32 index = 0;

    for (std::string const& arg : args)
    {
        std::string token = "{" + std::to_string(index++) + "}";
        size_t pos = 0;

        while ((pos = text.find(token, pos)) != std::string::npos)
        {
            text.replace(pos, token.length(), arg);
            pos += arg.length();
        }
    }

    return text;
}

std::string PetBattleMgr::GetTipoName(Player* player, uint8 tipo) const
{
    switch (tipo)
    {
    case PET_TIPO_AGUA:       return GetText(player, PETTXT_TYPE_WATER);
    case PET_TIPO_TIERRA:     return GetText(player, PETTXT_TYPE_EARTH);
    case PET_TIPO_FUEGO:      return GetText(player, PETTXT_TYPE_FIRE);
    case PET_TIPO_LUZ:        return GetText(player, PETTXT_TYPE_LIGHT);
    case PET_TIPO_OSCURIDAD:  return GetText(player, PETTXT_TYPE_DARKNESS);
    case PET_TIPO_BASICO:     return GetText(player, PETTXT_TYPE_BASIC);
    default:                  return GetText(player, PETTXT_TYPE_UNKNOWN);
    }
}

std::string PetBattleMgr::GetCreatureName(Player* player, uint32 creatureEntry) const
{
    CreatureTemplate const* creature =
        sObjectMgr->GetCreatureTemplate(creatureEntry);

    if (!creature)
        return GetTextFmt(player, PETTXT_PET_FALLBACK,
            { std::to_string(creatureEntry) });

    std::string name = creature->Name;

    if (player && player->GetSession())
    {
        LocaleConstant locale =
            player->GetSession()->GetSessionDbLocaleIndex();

        if (locale != LOCALE_enUS)
        {
            if (CreatureLocale const* localeData =
                sObjectMgr->GetCreatureLocale(creatureEntry))
            {
                ObjectMgr::GetLocaleString(
                    localeData->Name,
                    locale,
                    name);
            }
        }
    }

    return name;
}


// ================================================================
// Persistencia de equipos
// ================================================================

uint8 PetBattleMgr::SelectAvailableAttack(
    PetBattleStats const& pet) const
{
    std::array<uint8, 3> available = {};
    uint8 count = 0;

    if (pet.cooldown1 == 0)
        available[count++] = 1;

    if (pet.cooldown2 == 0)
        available[count++] = 2;

    if (pet.cooldown3 == 0)
        available[count++] = 3;

    // Por seguridad: si las tres estuvieran en cooldown,
    // utilizamos ataque 1.
    if (count == 0)
        return 1;

    return available[
        urand(
            0,
            count - 1)];
}

void PetBattleMgr::LoadPlayerTeam(
    ObjectGuid::LowType guidLow,
    std::array<PetBattleTeamSlot, 3>& outTeam)
{
    outTeam[0] = PetBattleTeamSlot();
    outTeam[1] = PetBattleTeamSlot();
    outTeam[2] = PetBattleTeamSlot();

    QueryResult result = WorldDatabase.Query(
        "SELECT slot1_creature_entry, slot2_creature_entry, slot3_creature_entry "
        "FROM bp_pet_team WHERE guid = {}",
        guidLow);

    if (!result)
        return;

    Field* fields = result->Fetch();

    uint32 entries[3] =
    {
        fields[0].Get<uint32>(),
        fields[1].Get<uint32>(),
        fields[2].Get<uint32>()
    };

    for (uint8 i = 0; i < 3; ++i)
    {
        outTeam[i].creatureEntry = entries[i];

        if (entries[i])
        {
            if (CreatureTemplate const* ci =
                sObjectMgr->GetCreatureTemplate(entries[i]))
            {
                outTeam[i].nombre = ci->Name;
            }
            else
            {
                outTeam[i].nombre =
                    "Desconocida (" +
                    std::to_string(entries[i]) +
                    ")";
            }
        }
    }
}

void PetBattleMgr::SavePlayerTeamSlot(
    ObjectGuid::LowType guidLow,
    uint8 slotIndex,
    uint32 creatureEntry)
{
    WorldDatabase.Execute(
        "INSERT INTO bp_pet_team "
        "(guid, slot1_creature_entry, slot2_creature_entry, slot3_creature_entry) "
        "VALUES ({}, 0, 0, 0) "
        "ON DUPLICATE KEY UPDATE guid = guid",
        guidLow);

    char const* column =
        "slot1_creature_entry";

    if (slotIndex == 1)
        column = "slot2_creature_entry";
    else if (slotIndex == 2)
        column = "slot3_creature_entry";

    WorldDatabase.Execute(
        "UPDATE bp_pet_team SET {} = {} WHERE guid = {}",
        column,
        creatureEntry,
        guidLow);
}

void PetBattleMgr::ClearPlayerTeam(
    ObjectGuid::LowType guidLow)
{
    WorldDatabase.Execute(
        "INSERT INTO bp_pet_team "
        "(guid, slot1_creature_entry, slot2_creature_entry, slot3_creature_entry) "
        "VALUES ({}, 0, 0, 0) "
        "ON DUPLICATE KEY UPDATE "
        "slot1_creature_entry = 0, "
        "slot2_creature_entry = 0, "
        "slot3_creature_entry = 0",
        guidLow);
}

// ================================================================
// Estadisticas de mascotas
// ================================================================

bool PetBattleMgr::GetPetStats(
    ObjectGuid::LowType guidLow,
    uint32 creatureEntry,
    PetBattleStats& out)
{
    QueryResult result = WorldDatabase.Query(
        "SELECT mascotaID, spell_id, item_entry, vida, tipo, "
        "cant_daño_1, cant_daño_2, cant_daño_3 "
        "FROM bp_pet_info "
        "WHERE guid_jugador = {} AND mascotaID = {}",
        guidLow,
        creatureEntry);

    if (!result)
        return false;

    Field* f = result->Fetch();

    out.mascotaID = f[0].Get<uint32>();
    out.spellID = f[1].Get<uint32>();
    out.itemEntry = f[2].Get<uint32>();
    out.vidaMax = f[3].Get<uint32>();
    out.vidaActual = out.vidaMax;
    out.tipo = f[4].Get<uint8>();
    out.daño1 = f[5].Get<int32>();
    out.daño2 = f[6].Get<int32>();
    out.daño3 = f[7].Get<int32>();

    return true;
}

void PetBattleMgr::CreatePetStats(
    ObjectGuid::LowType guidLow,
    uint32 spellID,
    uint32 creatureEntry)
{
    static std::mt19937 rng(std::random_device{}());

    std::uniform_int_distribution<int> vidaDist(90, 120);
    std::uniform_int_distribution<int> tipoDist(0, PET_TIPO_MAX - 1);

    std::uniform_int_distribution<int> dañoDist(
        PET_DAMAGE_MIN,
        PET_DAMAGE_MAX);

    std::uniform_int_distribution<int> healDist(
        PET_HEAL_MIN,
        PET_HEAL_MAX);

    std::uniform_int_distribution<int> chanceDist(1, 100);

    uint32 vida =
        static_cast<uint32>(vidaDist(rng));

    uint8 tipo =
        static_cast<uint8>(tipoDist(rng));

    auto GenerarDañoOHabilidad = [&]() -> int32
        {
            // 50% por defecto de probabilidad de curación
            if (chanceDist(rng) <= PET_HEAL_CHANCE)
                return static_cast<int32>(healDist(rng));

            return static_cast<int32>(dañoDist(rng));
        };

    int32 d1 = GenerarDañoOHabilidad();
    int32 d2 = GenerarDañoOHabilidad();
    int32 d3 = GenerarDañoOHabilidad();

    // Buscar el item que enseña este spell de companion.
    // Se guarda el entry para poder devolver exactamente ese item
    // cuando la mascota sea desligada.
    uint32 itemEntry = 0;

    QueryResult itemResult = WorldDatabase.Query(
        "SELECT entry "
        "FROM item_template "
        "WHERE spellid_1 = {} "
        "OR spellid_2 = {} "
        "OR spellid_3 = {} "
        "OR spellid_4 = {} "
        "OR spellid_5 = {} "
        "LIMIT 1",
        spellID,
        spellID,
        spellID,
        spellID,
        spellID);

    if (itemResult)
        itemEntry = itemResult->Fetch()[0].Get<uint32>();

    WorldDatabase.Execute(
        "INSERT INTO bp_pet_info "
        "(guid_jugador, spell_id, item_entry, mascotaID, vida, tipo, "
        "cant_daño_1, cant_daño_2, cant_daño_3) "
        "VALUES ({}, {}, {}, {}, {}, {}, {}, {}, {}) "
        "ON DUPLICATE KEY UPDATE "
        "spell_id = VALUES(spell_id), "
        "item_entry = IF(item_entry = 0, VALUES(item_entry), item_entry)",
        guidLow,
        spellID,
        itemEntry,
        creatureEntry,
        vida,
        tipo,
        d1,
        d2,
        d3);
}

void PetBattleMgr::RegisterPetIfSummonSpell(
    Player* player,
    uint32 spellID)
{
    if (!player)
        return;

    SpellInfo const* spellInfo =
        sSpellMgr->GetSpellInfo(spellID);

    if (!spellInfo)
        return;

    ObjectGuid::LowType guidLow =
        player->GetGUID().GetCounter();

    for (SpellEffectInfo const& eff :
        spellInfo->GetEffects())
    {
        if (eff.Effect != SPELL_EFFECT_SUMMON ||
            !eff.MiscValue)
        {
            continue;
        }

        uint32 creatureEntry =
            static_cast<uint32>(eff.MiscValue);

        if (!sObjectMgr->GetCreatureTemplate(creatureEntry))
            continue;

        PetBattleStats existing;

        if (GetPetStats(
            guidLow,
            creatureEntry,
            existing))
        {
            // Migraciones/filas antiguas pueden no tener el item asociado.
            // Si encontramos ahora el item que enseña el spell, lo guardamos.
            if (existing.itemEntry == 0)
            {
                QueryResult itemResult = WorldDatabase.Query(
                    "SELECT entry "
                    "FROM item_template "
                    "WHERE spellid_1 = {} "
                    "OR spellid_2 = {} "
                    "OR spellid_3 = {} "
                    "OR spellid_4 = {} "
                    "OR spellid_5 = {} "
                    "LIMIT 1",
                    spellID,
                    spellID,
                    spellID,
                    spellID,
                    spellID);

                if (itemResult)
                {
                    uint32 itemEntry =
                        itemResult->Fetch()[0].Get<uint32>();

                    WorldDatabase.Execute(
                        "UPDATE bp_pet_info "
                        "SET item_entry = {} "
                        "WHERE guid_jugador = {} AND mascotaID = {}",
                        itemEntry,
                        guidLow,
                        creatureEntry);
                }
            }

            continue;
        }

        CreatePetStats(
            guidLow,
            spellID,
            creatureEntry);
    }
}

// ================================================================
// Deteccion de companions por modelo
// ================================================================

void PetBattleMgr::EnsurePetSpellIndexBuilt()
{
    if (_petSpellIndexBuilt)
        return;

    // DisplayID -> SpellID
    //
    // La funcion ahora indexa por modelo y no por CreatureEntry.
    //
    // Ejemplo:
    //
    // Víbora       Entry 10001 -> DisplayID 500
    // Culebra      Entry 10002 -> DisplayID 500
    //
    // Ambas utilizan el mismo spell de mascota.

    uint32 maxId =
        sSpellMgr->GetSpellInfoStoreSize();

    for (uint32 id = 1;
        id < maxId;
        ++id)
    {
        SpellInfo const* spellInfo =
            sSpellMgr->GetSpellInfo(id);

        if (!spellInfo)
            continue;

        for (SpellEffectInfo const& eff :
            spellInfo->GetEffects())
        {
            if (eff.Effect != SPELL_EFFECT_SUMMON ||
                !eff.MiscValue)
            {
                continue;
            }

            uint32 creatureEntry =
                static_cast<uint32>(eff.MiscValue);

            CreatureTemplate const* creatureTemplate =
                sObjectMgr->GetCreatureTemplate(
                    creatureEntry);

            if (!creatureTemplate)
                continue;

            for (uint8 modelIndex = 0;
                modelIndex < 4;
                ++modelIndex)
            {
                CreatureModel const* model =
                    creatureTemplate->GetModelByIdx(
                        modelIndex);

                if (!model ||
                    !model->CreatureDisplayID)
                {
                    continue;
                }

                uint32 displayId =
                    model->CreatureDisplayID;

                _petSpellIndexByEntry.emplace(
                    displayId,
                    id);
            }
        }
    }

    _petSpellIndexBuilt = true;
}

uint32 PetBattleMgr::FindPetSummonSpellForCreatureEntry(
    uint32 creatureEntry)
{
    EnsurePetSpellIndexBuilt();

    CreatureTemplate const* creatureTemplate =
        sObjectMgr->GetCreatureTemplate(
            creatureEntry);

    if (!creatureTemplate)
        return 0;

    for (uint8 modelIndex = 0;
        modelIndex < 4;
        ++modelIndex)
    {
        CreatureModel const* model =
            creatureTemplate->GetModelByIdx(
                modelIndex);

        if (!model ||
            !model->CreatureDisplayID)
        {
            continue;
        }

        uint32 displayId =
            model->CreatureDisplayID;

        auto it =
            _petSpellIndexByEntry.find(
                displayId);

        if (it != _petSpellIndexByEntry.end())
            return it->second;
    }

    return 0;
}

// ================================================================
// Reto contra mascota salvaje
// ================================================================

bool PetBattleMgr::TryStartWildBattle(
    Player* player,
    Creature* creature)
{
    if (!player || !creature)
        return false;

    if (GetBattleByPlayer(
        player->GetGUID()))
    {
        ChatHandler(player->GetSession()).PSendSysMessage(
            "{}", GetText(player, PETTXT_ALREADY_BATTLE));

        return true;
    }

    // ------------------------------------------------------------
    // No permitir iniciar el reto si el jugador esta demasiado lejos
    // de la criatura salvaje.
    // ------------------------------------------------------------
    float maxChallengeDistance =
        sConfigMgr->GetOption<float>(
            "PetBattle.ChallengeMaxDistance",
            PET_CHALLENGE_MAX_DISTANCE_DEFAULT);

    if (player->GetDistance(creature) > maxChallengeDistance)
    {
        ChatHandler(player->GetSession()).PSendSysMessage(
            "{}", GetText(player, PETTXT_TOO_FAR));

        return true;
    }

    uint32 entry =
        creature->GetEntry();

    uint32 summonSpellID =
        FindPetSummonSpellForCreatureEntry(
            entry);

    if (!summonSpellID)
        return false;

    std::array<PetBattleTeamSlot, 3> team;

    LoadPlayerTeam(
        player->GetGUID().GetCounter(),
        team);

    // El jugador debe tener obligatoriamente la ranura 1 ocupada
    // para poder pelear (salvaje o PvP). Tener mascotas solo en la
    // ranura 2 y/o 3 no es suficiente.
    if (!team[0].creatureEntry)
    {
        ChatHandler(player->GetSession()).PSendSysMessage(
            "{}",
            GetTextFmt(player, PETTXT_WILD_NEED_SLOT1,
                { creature->GetName() }));

        return true;
    }

    ActivePetBattle battle;

    battle.playerA =
        player->GetGUID();

    battle.playerB.Clear();

    battle.isWildBattle = true;

    battle.wildCreatureEntry =
        entry;

    battle.wildSummonSpellID =
        summonSpellID;

    battle.wildSourceGuid =
        creature->GetGUID();

    battle.wildSpawnPos.Relocate(
        creature->GetPositionX(),
        creature->GetPositionY(),
        creature->GetPositionZ(),
        creature->GetOrientation());

    ObjectGuid::LowType guidLow =
        player->GetGUID().GetCounter();

    for (uint8 i = 0;
        i < 3;
        ++i)
    {
        if (team[i].creatureEntry)
        {
            GetPetStats(
                guidLow,
                team[i].creatureEntry,
                battle.teamA[i]);
        }
    }

    PetBattleStats& wild =
        battle.teamB[0];

    wild.mascotaID =
        entry;

    wild.spellID =
        summonSpellID;

    wild.vidaMax =
        static_cast<uint32>(
            urand(90, 120));

    wild.vidaActual =
        wild.vidaMax;

    wild.tipo =
        static_cast<uint8>(
            urand(0, PET_TIPO_MAX - 1));

    wild.daño1 =
        static_cast<uint32>(
            urand(10, 30));

    wild.daño2 =
        static_cast<uint32>(
            urand(10, 30));

    wild.daño3 =
        static_cast<uint32>(
            urand(10, 30));

    ObjectGuid key =
        battle.playerA;

    _activeBattles[key] =
        battle;

    ActivePetBattle& stored =
        _activeBattles[key];

    ChatHandler(player->GetSession()).PSendSysMessage(
        "{}",
        GetTextFmt(player, PETTXT_WILD_START,
            { creature->GetName(), GetTipoName(player, wild.tipo) }));

    // ------------------------------------------------------------
    // Invocar ambas mascotas.
    // ------------------------------------------------------------

    SummonActivePet(
        player,
        stored,
        true);

    SummonActivePet(
        player,
        stored,
        false);

    // ------------------------------------------------------------
    // Mostrar la interfaz de batalla del jugador (BATTLEINIT), igual
    // que se hace en el duelo PvP (HandleDuelAccept). Sin esto el
    // addon nunca se entera de que empezo un combate salvaje y la
    // ventana de PetBattleUI no se abre.
    // ------------------------------------------------------------

    SendBattleInit(
        player,
        stored,
        true);

    // ------------------------------------------------------------
    // En combate salvaje NO se abre el menu del jugador todavía.
    //
    // Primero ataca la criatura salvaje.
    // ------------------------------------------------------------

    stored.diceRolled = true;
    stored.turnPlayer.Clear();

    PetBattleStats const& wildAttacker =
        stored.teamB[
            stored.activeIndexB];

    uint8 wildAttackIndex =
        SelectAvailableAttack(
            wildAttacker);

    int32 wildDanoBase = 0;

    switch (wildAttackIndex)
    {
    case 1:
        wildDanoBase =
            wildAttacker.daño1;
        break;

    case 2:
        wildDanoBase =
            wildAttacker.daño2;
        break;

    case 3:
        wildDanoBase =
            wildAttacker.daño3;
        break;
    }

    StartPetAttack(
        stored,
        false,
        wildDanoBase,
        wildAttackIndex,
        nullptr,
        false);

    return true;
}

// ================================================================
// Resolucion del daño
// ================================================================

int32 PetBattleMgr::ResolveHitDamage(
    PetBattleStats const& attacker,
    PetBattleStats const& defender,
    int32 danoBase,
    bool& outMissed,
    bool& outSuperEfectivo)
{
    outMissed = false;
    outSuperEfectivo = false;

    // --------------------------------------------------------------
    // Las habilidades negativas son curaciones para la mascota
    // atacante.
    //
    // Las curaciones NO tienen miss chance ni variacion de daño.
    // Si danoBase = -10, cura exactamente 10.
    // Si danoBase = -15, cura exactamente 15.
    // --------------------------------------------------------------
    if (danoBase < 0)
        return danoBase;

    // --------------------------------------------------------------
    // Ataque normal: calculamos miss chance y variacion de daño.
    // --------------------------------------------------------------
    uint32 missChance =
        IsAttackerAtTypeDisadvantage(
            attacker.tipo,
            defender.tipo)
        ? PET_MISS_CHANCE_DISADVANTAGE
        : PET_MISS_CHANCE_DEFAULT;

    if (urand(1, 100) <= missChance)
    {
        outMissed = true;
        return 0;
    }

    int32 variado =
        danoBase +
        irand(
            -PET_DAMAGE_VARIANCE,
            PET_DAMAGE_VARIANCE);

    // Ataque normal: nunca permitimos daño 0 o negativo.
    if (variado < 1)
        variado = 1;

    float multiplier =
        GetTypeMultiplier(
            attacker.tipo,
            defender.tipo);

    outSuperEfectivo =
        multiplier > 1.0f;

    return static_cast<int32>(
        std::lround(
            variado * multiplier));
}

// ================================================================
// Tipos
// ================================================================

float PetBattleMgr::GetTypeMultiplier(
    uint8 attackerType,
    uint8 defenderType)
{
    if ((attackerType == PET_TIPO_AGUA &&
        defenderType == PET_TIPO_FUEGO) ||

        (attackerType == PET_TIPO_FUEGO &&
            defenderType == PET_TIPO_TIERRA) ||

        (attackerType == PET_TIPO_TIERRA &&
            defenderType == PET_TIPO_AGUA))
    {
        return 2.0f;
    }

    if ((attackerType == PET_TIPO_OSCURIDAD &&
        defenderType == PET_TIPO_BASICO) ||

        (attackerType == PET_TIPO_BASICO &&
            defenderType == PET_TIPO_LUZ) ||

        (attackerType == PET_TIPO_LUZ &&
            defenderType == PET_TIPO_OSCURIDAD))
    {
        return 2.0f;
    }

    return 1.0f;
}

bool PetBattleMgr::IsAttackerAtTypeDisadvantage(
    uint8 attackerType,
    uint8 defenderType)
{
    return
        GetTypeMultiplier(
            defenderType,
            attackerType) > 1.0f;
}

// ================================================================
// Menu de equipo
// ================================================================

void PetBattleMgr::ShowTeamMenu(
    Player* player)
{
    player->PlayerTalkClass->ClearMenus();

    std::array<PetBattleTeamSlot, 3> team;

    LoadPlayerTeam(
        player->GetGUID().GetCounter(),
        team);

    for (uint8 i = 0;
        i < 3;
        ++i)
    {
        std::string label =
            GetTextFmt(player, PETTXT_SLOT_LABEL,
                { std::to_string(i + 1),
                  team[i].creatureEntry
                    ? GetCreatureName(player, team[i].creatureEntry)
                    : GetText(player, PETTXT_EMPTY) });

        player->PlayerTalkClass
            ->GetGossipMenu()
            .AddMenuItem(
                -1,
                GOSSIP_ICON_CHAT,
                label,
                SENDER_TEAM_MENU,
                1000 + i,
                "",
                0);
    }

    player->PlayerTalkClass
        ->GetGossipMenu()
        .AddMenuItem(
            -1,
            GOSSIP_ICON_TRAINER,
            GetText(player, PETTXT_CLEAR_TEAM),
            SENDER_TEAM_MENU,
            2000,
            "",
            0);

    player->PlayerTalkClass
        ->GetGossipMenu()
        .AddMenuItem(
            -1,
            GOSSIP_ICON_CHAT,
            GetText(player, PETTXT_SAVE_TEAM),
            SENDER_TEAM_MENU,
            3000,
            "",
            0);

    player->PlayerTalkClass->SendGossipMenu(
        GOSSIP_TEXT_GENERICO,
        player->GetGUID());
}

void PetBattleMgr::HandleTeamGossipAction(
    Player* player,
    uint32 sender,
    uint32 action)
{
    ObjectGuid::LowType guidLow =
        player->GetGUID().GetCounter();

    if (sender == SENDER_TEAM_MENU)
    {
        if (action == 2000)
        {
            ClearPlayerTeam(guidLow);

            ChatHandler(player->GetSession()).PSendSysMessage(
                GetText(player, PETTXT_CLEAR_TEAM));

            ShowTeamMenu(player);
            return;
        }

        if (action == 3000)
        {
            player->PlayerTalkClass->SendCloseGossip();

            ChatHandler(player->GetSession()).PSendSysMessage(
                GetText(player, PETTXT_SAVE_TEAM));

            return;
        }

        if (action >= 1000 &&
            action <= 1002)
        {
            uint8 slot =
                static_cast<uint8>(
                    action - 1000);

            player->PlayerTalkClass->ClearMenus();

            std::array<PetBattleTeamSlot, 3> currentTeam;

            LoadPlayerTeam(
                guidLow,
                currentTeam);

            bool any = false;

            for (auto const& spellPair :
                player->GetSpellMap())
            {
                SpellInfo const* spellInfo =
                    sSpellMgr->GetSpellInfo(
                        spellPair.first);

                if (!spellInfo)
                    continue;

                for (SpellEffectInfo const& eff :
                    spellInfo->GetEffects())
                {
                    if (eff.Effect != SPELL_EFFECT_SUMMON ||
                        !eff.MiscValue)
                    {
                        continue;
                    }

                    uint32 entry =
                        static_cast<uint32>(
                            eff.MiscValue);

                    if (!sObjectMgr->GetCreatureTemplate(entry))
                        continue;

                    bool yaEnOtraRanura = false;

                    for (uint8 i = 0;
                        i < 3;
                        ++i)
                    {
                        if (i != slot &&
                            currentTeam[i].creatureEntry ==
                            entry)
                        {
                            yaEnOtraRanura = true;
                            break;
                        }
                    }

                    if (yaEnOtraRanura)
                        continue;

                    PetBattleStats stats;

                    if (!GetPetStats(
                        guidLow,
                        entry,
                        stats))
                    {
                        CreatePetStats(
                            guidLow,
                            spellPair.first,
                            entry);

                        if (!GetPetStats(
                            guidLow,
                            entry,
                            stats))
                        {
                            continue;
                        }
                    }

                    std::string name =
                        GetCreatureName(player, entry);

                    name +=
                        " [" +
                        GetTipoName(player, stats.tipo) +
                        "]";

                    uint32 code =
                        6000000 +
                        (uint32(slot) * 1000000) +
                        entry;

                    player->PlayerTalkClass
                        ->GetGossipMenu()
                        .AddMenuItem(
                            -1,
                            GOSSIP_ICON_VENDOR,
                            name,
                            SENDER_TEAM_PICK,
                            code,
                            "",
                            0);

                    any = true;
                }
            }

            if (!any)
            {
                player->PlayerTalkClass
                    ->GetGossipMenu()
                    .AddMenuItem(
                        -1,
                        GOSSIP_ICON_CHAT,
                        GetText(player, PETTXT_NO_PETS),
                        SENDER_TEAM_PICK,
                        9999,
                        "",
                        0);
            }

            player->PlayerTalkClass
                ->GetGossipMenu()
                .AddMenuItem(
                    -1,
                    GOSSIP_ICON_TALK,
                    GetText(player, PETTXT_BACK),
                    SENDER_TEAM_PICK,
                    4000,
                    "",
                    0);

            player->PlayerTalkClass->SendGossipMenu(
                GOSSIP_TEXT_GENERICO,
                player->GetGUID());

            return;
        }

        player->PlayerTalkClass->SendCloseGossip();
        return;
    }

    if (sender == SENDER_TEAM_PICK)
    {
        if (action == 4000 ||
            action == 9999)
        {
            ShowTeamMenu(player);
            return;
        }

        if (action >= 6000000)
        {
            uint32 remainder =
                action - 6000000;

            uint8 slot =
                static_cast<uint8>(
                    remainder / 1000000);

            uint32 entry =
                remainder % 1000000;

            std::array<PetBattleTeamSlot, 3> currentTeam;

            LoadPlayerTeam(
                guidLow,
                currentTeam);

            for (uint8 i = 0;
                i < 3;
                ++i)
            {
                if (i != slot &&
                    currentTeam[i].creatureEntry ==
                    entry)
                {
                    ChatHandler(player->GetSession())
                        .PSendSysMessage(
                            GetText(player, PETTXT_DUPLICATE_SLOT));

                    ShowTeamMenu(player);
                    return;
                }
            }

            SavePlayerTeamSlot(
                guidLow,
                slot,
                entry);

            ChatHandler(player->GetSession())
                .PSendSysMessage(
                    "{}",
                    GetTextFmt(player, PETTXT_PET_ASSIGNED,
                        { std::to_string(slot + 1) }));

            ShowTeamMenu(player);
            return;
        }

        ShowTeamMenu(player);
        return;
    }

    player->PlayerTalkClass->SendCloseGossip();
}

// ================================================================
// Duelo PvP
// ================================================================

// ================================================================
// Puente de addon messages (reemplaza los gossip)
// ================================================================
//
// Formato del paquete: SMSG_MESSAGECHAT con lang = LANG_ADDON y el
// mensaje "PETBTL\t<contenido>". Snippet base tomado de la wiki de
// AzerothCore (how-to-use-warden-payload-mgr). El addon del cliente
// escucha esto via CHAT_MSG_ADDON con el prefijo PETBTL registrado.
void PetBattleMgr::SendAddonMsg(
    Player* player,
    std::string const& msg)
{
    if (!player)
        return;

    static char const* ADDON_PREFIX = "PETBTL";

    std::string full =
        std::string(ADDON_PREFIX) +
        "\t" +
        msg;

    size_t len = full.length();

    WorldPacket data;
    data.Initialize(
        SMSG_MESSAGECHAT,
        1 + 4 + 8 + 4 + 8 + 4 + 1 + len + 1);

    data << uint8(CHAT_MSG_WHISPER);
    data << uint32(LANG_ADDON);
    data << uint64(player->GetGUID().GetRawValue());
    data << uint32(0);
    data << uint64(player->GetGUID().GetRawValue());
    data << uint32(len + 1);
    data << full;
    data << uint8(0);

    player->SendDirectMessage(&data);
}

// Envia a "viewer" el estado inicial/actualizado de su mascota activa
// y la del rival, desde su propio punto de vista (asi cada cliente
// siempre pinta su barra de abajo como "mine" y la de arriba como
// "enemy", sin importar si es playerA o playerB).
void PetBattleMgr::SendBattleInit(
    Player* viewer,
    ActivePetBattle& battle,
    bool viewerIsA)
{
    if (!viewer)
        return;

    PetBattleStats const& mine =
        viewerIsA
        ? battle.teamA[battle.activeIndexA]
        : battle.teamB[battle.activeIndexB];

    PetBattleStats const& enemy =
        viewerIsA
        ? battle.teamB[battle.activeIndexB]
        : battle.teamA[battle.activeIndexA];


    CreatureTemplate const* mineCi =
        sObjectMgr->GetCreatureTemplate(
            mine.mascotaID
        );

    CreatureTemplate const* enemyCi =
        sObjectMgr->GetCreatureTemplate(
            enemy.mascotaID
        );


    // ========================================================
    // BATTLEINIT
    // ========================================================
    //
    // Formato:
    //
    // BATTLEINIT:
    // enemyName:
    // enemyType:
    // enemyHP:
    // enemyHPMax:
    // myName:
    // myType:
    // myHP:
    // myHPMax:
    // damage1:
    // damage2:
    // damage3:
    // isWild (1/0)
    //
    // ========================================================

    std::string msg =
        "BATTLEINIT:" +

        // ENEMIGO
        (enemyCi
            ? GetCreatureName(viewer, enemy.mascotaID)
            : std::string("?")) + ":" +

        GetTipoName(viewer, enemy.tipo) + ":" +

        std::to_string(
            enemy.vidaActual
        ) + ":" +

        std::to_string(
            enemy.vidaMax
        ) + ":" +


        // MASCOTA PROPIA
        (mineCi
            ? GetCreatureName(viewer, mine.mascotaID)
            : std::string("?")) + ":" +

        GetTipoName(viewer, mine.tipo) + ":" +

        std::to_string(
            mine.vidaActual
        ) + ":" +

        std::to_string(
            mine.vidaMax
        ) + ":" +


        // ====================================================
        // DAÑOS
        // ====================================================

        std::to_string(
            mine.daño1
        ) + ":" +

        std::to_string(
            mine.daño2
        ) + ":" +

        std::to_string(
            mine.daño3
        ) + ":" +


        // ====================================================
        // ES COMBATE SALVAJE
        //
        // El addon usa este flag para saltar la pantalla de la
        // moneda: contra una criatura salvaje no hay tirada de
        // dados, la mascota salvaje ataca primero directamente.
        // ====================================================

        std::string(
            battle.isWildBattle
            ? "1"
            : "0");


    SendAddonMsg(
        viewer,
        msg
    );
}

// Manda, para cada uno de los 3 slots del equipo guardado, un
// TEAMUPDATE con nombre/tipo/daños (el icono lo resuelve el addon
// a partir del spellID con GetSpellInfo), o un TEAMCLEAR si el slot
// esta vacio o apunta a una mascota sin ficha de combate.
void PetBattleMgr::SendFullTeamToClient(
    Player* player)
{
    if (!player)
        return;

    ObjectGuid::LowType guidLow =
        player->GetGUID().GetCounter();

    std::array<PetBattleTeamSlot, 3> team;
    LoadPlayerTeam(guidLow, team);

    for (uint8 i = 0; i < 3; ++i)
    {
        uint8 slot = i + 1;

        if (!team[i].creatureEntry)
        {
            SendAddonMsg(
                player,
                "TEAMCLEAR:" +
                std::to_string(slot));

            continue;
        }

        PetBattleStats stats;

        if (!GetPetStats(guidLow, team[i].creatureEntry, stats))
        {
            // El slot apunta a una mascota que ya no tiene ficha de
            // combate (datos huerfanos); lo tratamos como vacio.
            SendAddonMsg(
                player,
                "TEAMCLEAR:" +
                std::to_string(slot));

            continue;
        }

        SendAddonMsg(
            player,
            "TEAMUPDATE:" +
            std::to_string(slot) + ":" +
            std::to_string(stats.spellID) + ":" +
            GetCreatureName(player, team[i].creatureEntry) + ":" +
            std::string() + ":" +   // icono
            GetTipoName(player, stats.tipo) + ":" +
            std::to_string(stats.daño1) + ":" +
            std::to_string(stats.daño2) + ":" +
            std::to_string(stats.daño3) + ":" +
            std::to_string(team[i].creatureEntry));
    }
}

uint32 PetBattleMgr::FindCreatureEntryForSpell(
    uint32 spellID)
{
    SpellInfo const* spellInfo =
        sSpellMgr->GetSpellInfo(spellID);

    if (!spellInfo)
        return 0;

    for (SpellEffectInfo const& eff :
        spellInfo->GetEffects())
    {
        if (eff.Effect != SPELL_EFFECT_SUMMON ||
            !eff.MiscValue)
        {
            continue;
        }

        uint32 entry =
            static_cast<uint32>(eff.MiscValue);

        if (sObjectMgr->GetCreatureTemplate(entry))
            return entry;
    }

    return 0;
}

// Punto de entrada unico para todo lo que manda el addon PetBattleUI.
// payload ya viene sin el prefijo "PETBTL" ni el tab (eso lo separa
// mod_pet_battle.cpp antes de llamar aca).
void PetBattleMgr::HandleAddonMessage(
    Player* player,
    std::string const& payload)
{
    if (!player)
        return;

    size_t colon =
        payload.find(':');

    std::string cmd =
        (colon == std::string::npos)
        ? payload
        : payload.substr(0, colon);

    std::string rest =
        (colon == std::string::npos)
        ? std::string()
        : payload.substr(colon + 1);

    // ------------------------------------------------------------
    // Si el jugador esta en combate, no puede tocar su equipo de
    // mascotas: cualquier intento termina el duelo y pierde.
    // ------------------------------------------------------------
    if (cmd == "TEAM" ||
        cmd == "SWAP" ||
        cmd == "PETREMOVE" ||
        cmd == "PETFORGET" ||
        cmd == "PETDETACH")
    {
        if (ActivePetBattle* battle =
            GetBattleByPlayer(player->GetGUID()))
        {
            if (!battle->finished)
            {
                HandleTeamModifiedInBattle(player, *battle);
                return;
            }
        }
    }

    if (cmd == "DUELACC")
    {
        HandleDuelAccept(player);
        return;
    }

    if (cmd == "DUELDEC")
    {
        HandleDuelDecline(player);
        return;
    }

    // Cerrar la ventana del combate significa abandonar la batalla.
    // El jugador que envia FORFEIT pierde inmediatamente.
    if (cmd == "FORFEIT")
    {
        HandleForfeit(player);
        return;
    }

    if (cmd == "COINCLICK")
    {
        if (ActivePetBattle* battle =
            GetBattleByPlayer(player->GetGUID()))
        {
            HandleDiceRoll(player, *battle);
        }
        return;
    }

    if (cmd == "ATK")
    {
        uint8 index =
            static_cast<uint8>(std::atoi(rest.c_str()));

        if (ActivePetBattle* battle =
            GetBattleByPlayer(player->GetGUID()))
        {
            HandleAttack(player, *battle, index);
        }
        return;
    }

    // El addon pide el equipo completo tal como esta guardado en el
    // servidor. Se envia al abrir la ventana de Companeros para que
    // los 3 slots siempre reflejen el equipo actual (nombre, tipo y
    // daños), en vez de arrancar vacios o con datos viejos.
    if (cmd == "TEAMGET")
    {
        SendFullTeamToClient(player);
        return;
    }

    // Intercambiar dos mascotas de nuestro propio equipo (arrastre
    // interno entre slots). El cliente ya actualiza la UI de forma
    // optimista; aca persistimos el intercambio en la base.
    if (cmd == "SWAP")
    {
        size_t colon2 =
            rest.find(':');

        if (colon2 == std::string::npos)
            return;

        uint8 slotA =
            static_cast<uint8>(
                std::atoi(rest.substr(0, colon2).c_str()));

        uint8 slotB =
            static_cast<uint8>(
                std::atoi(rest.substr(colon2 + 1).c_str()));

        if (slotA < 1 || slotA > 3 ||
            slotB < 1 || slotB > 3 ||
            slotA == slotB)
        {
            return;
        }

        ObjectGuid::LowType guidLow =
            player->GetGUID().GetCounter();

        std::array<PetBattleTeamSlot, 3> team;
        LoadPlayerTeam(guidLow, team);

        uint32 entryA = team[slotA - 1].creatureEntry;
        uint32 entryB = team[slotB - 1].creatureEntry;

        SavePlayerTeamSlot(guidLow, slotA - 1, entryB);
        SavePlayerTeamSlot(guidLow, slotB - 1, entryA);

        return;
    }

    if (cmd == "TEAM")
    {
        size_t colon2 =
            rest.find(':');

        if (colon2 == std::string::npos)
            return;

        uint8 slot =
            static_cast<uint8>(
                std::atoi(rest.substr(0, colon2).c_str()));

        uint32 spellID =
            static_cast<uint32>(
                std::atoi(rest.substr(colon2 + 1).c_str()));

        if (slot < 1 || slot > 3)
            return;

        uint32 entry =
            FindCreatureEntryForSpell(spellID);

        if (!entry)
        {
            SendAddonMsg(
                player,
                "TEAMERR:" + GetText(player, PETTXT_TEAMERR_INVALID));
            return;
        }

        ObjectGuid::LowType guidLow =
            player->GetGUID().GetCounter();

        PetBattleStats existing;

        if (!GetPetStats(guidLow, entry, existing))
        {
            CreatePetStats(guidLow, spellID, entry);
            GetPetStats(guidLow, entry, existing); // CreatePetStats no llena "existing"
        }

        SavePlayerTeamSlot(guidLow, slot - 1, entry);

        SendAddonMsg(
            player,
            "TEAMUPDATE:" +
            std::to_string(slot) + ":" +
            std::to_string(spellID) + ":" +
            std::string() + ":" +   // nombre
            std::string() + ":" +   // icono
            GetTipoName(player, existing.tipo) + ":" +
            std::to_string(existing.daño1) + ":" +
            std::to_string(existing.daño2) + ":" +
            std::to_string(existing.daño3) + ":" +
            std::to_string(entry));



    }

    // Quitar mascota del equipo, pero conservarla aprendida.
    if (cmd == "PETREMOVE")
    {
        uint8 slot =
            static_cast<uint8>(
                std::atoi(rest.c_str()));

        if (slot < 1 || slot > 3)
            return;

        RemovePetFromTeam(
            player,
            slot - 1);

        return;
    }

    // Olvidar la mascota: elimina sus datos de combate y el spell de
    // companion si ya no queda ninguna mascota usando ese spell.
    if (cmd == "PETFORGET")
    {
        uint8 slot =
            static_cast<uint8>(
                std::atoi(rest.c_str()));

        if (slot < 1 || slot > 3)
            return;

        ForgetPet(
            player,
            slot - 1);

        return;
    }

    // Desligar la mascota: la convierte en el item definido por
    // bp_pet_detach_items y luego la elimina de la colección.
    if (cmd == "PETDETACH")
    {
        uint8 slot =
            static_cast<uint8>(
                std::atoi(rest.c_str()));

        if (slot < 1 || slot > 3)
            return;

        ConvertPetToItem(
            player,
            slot - 1);

        return;
    }
}


// ================================================================
// Gestion de mascotas: quitar del equipo / olvidar / desligar
// ================================================================

uint32 PetBattleMgr::GetDetachItemEntry(uint32 creatureEntry) const
{
    QueryResult result = WorldDatabase.Query(
        "SELECT item_entry "
        "FROM bp_pet_detach_items "
        "WHERE creature_entry = {} "
        "LIMIT 1",
        creatureEntry);

    if (!result)
        return 0;

    return result->Fetch()[0].Get<uint32>();
}

void PetBattleMgr::RemovePetFromTeam(
    Player* player,
    uint8 slotIndex)
{
    if (!player || slotIndex >= 3)
        return;

    ObjectGuid::LowType guidLow =
        player->GetGUID().GetCounter();

    std::array<PetBattleTeamSlot, 3> team;
    LoadPlayerTeam(guidLow, team);

    if (!team[slotIndex].creatureEntry)
    {
        SendAddonMsg(
            player,
            "PET_ACTION_ERR:REMOVE:" + GetText(player, PETTXT_REMOVE_EMPTY));
        return;
    }

    uint32 entry = team[slotIndex].creatureEntry;

    SavePlayerTeamSlot(
        guidLow,
        slotIndex,
        0);

    SendAddonMsg(
        player,
        "PET_ACTION_OK:REMOVE:" +
        std::to_string(slotIndex + 1));

    ChatHandler(player->GetSession()).PSendSysMessage(
        "{}",
        GetTextFmt(player, PETTXT_REMOVE_CHAT,
            { GetCreatureName(player, team[slotIndex].creatureEntry) }));
}

void PetBattleMgr::ForgetPet(
    Player* player,
    uint8 slotIndex)
{
    if (!player || slotIndex >= 3)
        return;

    ObjectGuid::LowType guidLow =
        player->GetGUID().GetCounter();

    std::array<PetBattleTeamSlot, 3> team;
    LoadPlayerTeam(guidLow, team);

    uint32 creatureEntry =
        team[slotIndex].creatureEntry;

    if (!creatureEntry)
    {
        SendAddonMsg(
            player,
            "PET_ACTION_ERR:FORGET:" + GetText(player, PETTXT_FORGET_EMPTY));
        return;
    }

    PetBattleStats stats;

    if (!GetPetStats(guidLow, creatureEntry, stats))
    {
        // El equipo apunta a una mascota que ya no tiene datos.
        // Limpiamos igualmente las referencias del equipo.
        WorldDatabase.Execute(
            "UPDATE bp_pet_team "
            "SET slot1_creature_entry = IF(slot1_creature_entry = {}, 0, slot1_creature_entry), "
            "    slot2_creature_entry = IF(slot2_creature_entry = {}, 0, slot2_creature_entry), "
            "    slot3_creature_entry = IF(slot3_creature_entry = {}, 0, slot3_creature_entry) "
            "WHERE guid = {}",
            creatureEntry,
            creatureEntry,
            creatureEntry,
            guidLow);

        SendAddonMsg(
            player,
            "PET_ACTION_OK:FORGET:" +
            std::to_string(slotIndex + 1));

        return;
    }

    // Primero quitamos la mascota de cualquier ranura del equipo.
    WorldDatabase.Execute(
        "UPDATE bp_pet_team "
        "SET slot1_creature_entry = IF(slot1_creature_entry = {}, 0, slot1_creature_entry), "
        "    slot2_creature_entry = IF(slot2_creature_entry = {}, 0, slot2_creature_entry), "
        "    slot3_creature_entry = IF(slot3_creature_entry = {}, 0, slot3_creature_entry) "
        "WHERE guid = {}",
        creatureEntry,
        creatureEntry,
        creatureEntry,
        guidLow);

    // Eliminamos la ficha de combate de esta mascota.
    WorldDatabase.Execute(
        "DELETE FROM bp_pet_info "
        "WHERE guid_jugador = {} AND mascotaID = {}",
        guidLow,
        creatureEntry);

    // Un companion puede compartir spell con otra entrada.
    // Solo olvidamos el spell si ya no queda ninguna ficha usando ese spell.
    QueryResult remaining = WorldDatabase.Query(
        "SELECT COUNT(*) "
        "FROM bp_pet_info "
        "WHERE guid_jugador = {} AND spell_id = {}",
        guidLow,
        stats.spellID);

    if (remaining && remaining->Fetch()[0].Get<uint64>() == 0 &&
        player->HasSpell(stats.spellID))
    {
        player->removeSpell(
            stats.spellID,
            SPEC_MASK_ALL,
            false);
    }

    player->removeSpell(
        stats.spellID,
        SPEC_MASK_ALL,
        false);

    SendAddonMsg(
        player,
        "PET_ACTION_OK:FORGET:" +
        std::to_string(slotIndex + 1));

    ChatHandler(player->GetSession()).PSendSysMessage(
        "{}",
        GetTextFmt(player, PETTXT_FORGET_CHAT,
            { GetCreatureName(player, team[slotIndex].creatureEntry) }));
}

void PetBattleMgr::ConvertPetToItem(
    Player* player,
    uint8 slotIndex)
{
    if (!player || slotIndex >= 3)
        return;

    ObjectGuid::LowType guidLow =
        player->GetGUID().GetCounter();

    std::array<PetBattleTeamSlot, 3> team;
    LoadPlayerTeam(guidLow, team);

    uint32 creatureEntry =
        team[slotIndex].creatureEntry;

    if (!creatureEntry)
    {
        SendAddonMsg(
            player,
            "PET_ACTION_ERR:DETACH:No hay ninguna mascota en esa ranura.");
        return;
    }

    PetBattleStats stats;

    if (!GetPetStats(guidLow, creatureEntry, stats))
    {
        SendAddonMsg(
            player,
            "PET_ACTION_ERR:DETACH:No se encontraron los datos de esa mascota.");
        return;
    }

    // El item que se devuelve es exactamente el que enseñó el spell
    // con el que el jugador aprendió esta mascota.
    uint32 itemEntry = stats.itemEntry;

    if (!itemEntry)
    {
        SendAddonMsg(
            player,
            "PET_ACTION_ERR:DETACH:" + GetText(player, PETTXT_DETACH_NO_DATA));
        ChatHandler(player->GetSession()).PSendSysMessage(
            "{}",
            GetTextFmt(player, PETTXT_DETACH_NO_SOURCE,
                { GetCreatureName(player, team[slotIndex].creatureEntry) }));
        return;
    }

    if (!sObjectMgr->GetItemTemplate(itemEntry))
    {
        SendAddonMsg(
            player,
            "PET_ACTION_ERR:DETACH:" + GetText(player, PETTXT_DETACH_ITEM_MISSING));
        return;
    }

    // Verificamos espacio ANTES de tocar la mascota.
    ItemPosCountVec dest;
    InventoryResult inventoryResult =
        player->CanStoreNewItem(
            NULL_BAG,
            NULL_SLOT,
            dest,
            itemEntry,
            1);

    if (inventoryResult != EQUIP_ERR_OK)
    {
        SendAddonMsg(
            player,
            "PET_ACTION_ERR:DETACH:" + GetText(player, PETTXT_DETACH_BAGS));
        ChatHandler(player->GetSession()).PSendSysMessage(
            GetText(player, PETTXT_DETACH_BAG_CHAT));
        return;
    }

    // Creamos primero el item para evitar borrar la mascota si el inventario
    // finalmente no puede recibirlo.
    Item* item =
        player->StoreNewItem(
            dest,
            itemEntry,
            true);

    if (!item)
    {
        SendAddonMsg(
            player,
            "PET_ACTION_ERR:DETACH:" + GetText(player, PETTXT_DETACH_CREATE));
        return;
    }

    // El item ya fue entregado correctamente. Ahora quitamos la mascota
    // del equipo y de la coleccion de combate.
    WorldDatabase.Execute(
        "UPDATE bp_pet_team "
        "SET slot1_creature_entry = IF(slot1_creature_entry = {}, 0, slot1_creature_entry), "
        "    slot2_creature_entry = IF(slot2_creature_entry = {}, 0, slot2_creature_entry), "
        "    slot3_creature_entry = IF(slot3_creature_entry = {}, 0, slot3_creature_entry) "
        "WHERE guid = {}",
        creatureEntry,
        creatureEntry,
        creatureEntry,
        guidLow);

    WorldDatabase.Execute(
        "DELETE FROM bp_pet_info "
        "WHERE guid_jugador = {} AND mascotaID = {}",
        guidLow,
        creatureEntry);

    QueryResult remaining = WorldDatabase.Query(
        "SELECT COUNT(*) "
        "FROM bp_pet_info "
        "WHERE guid_jugador = {} AND spell_id = {}",
        guidLow,
        stats.spellID);

    if (remaining && remaining->Fetch()[0].Get<uint64>() == 0 &&
        player->HasSpell(stats.spellID))
    {
        player->removeSpell(
            stats.spellID,
            SPEC_MASK_ALL,
            false);
    }

    player->removeSpell(
        stats.spellID,
        SPEC_MASK_ALL,
        false);

    SendAddonMsg(
        player,
        "PET_ACTION_OK:DETACH:" +
        std::to_string(slotIndex + 1) + ":" +
        std::to_string(itemEntry));

    ChatHandler(player->GetSession()).PSendSysMessage(
        "{}",
        GetTextFmt(player, PETTXT_DETACH_CHAT,
            { GetCreatureName(player, team[slotIndex].creatureEntry), std::to_string(itemEntry) }));
}

bool PetBattleMgr::StartDuelRequest(
    Player* challenger,
    Player* target)
{
    if (!challenger ||
        !target ||
        challenger == target)
    {
        return false;
    }

    // ------------------------------------------------------------
    // No permitir enviar el reto si los jugadores estan demasiado
    // lejos entre si.
    // ------------------------------------------------------------
    float maxChallengeDistance =
        sConfigMgr->GetOption<float>(
            "PetBattle.ChallengeMaxDistance",
            PET_CHALLENGE_MAX_DISTANCE_DEFAULT);

    if (challenger->GetDistance(target) > maxChallengeDistance)
    {
        ChatHandler(challenger->GetSession()).PSendSysMessage(
            "{}", GetText(challenger, PETTXT_TOO_FAR));

        return false;
    }

    if (GetBattleByPlayer(
        challenger->GetGUID()))
    {
        ChatHandler(challenger->GetSession()).PSendSysMessage(
            GetText(challenger, PETTXT_DUEL_ALREADY));

        return false;
    }

    if (GetBattleByPlayer(
        target->GetGUID()))
    {
        ChatHandler(challenger->GetSession()).PSendSysMessage(
            GetText(challenger, PETTXT_TARGET_ALREADY));

        return false;
    }

    std::array<PetBattleTeamSlot, 3> teamChallenger;

    LoadPlayerTeam(
        challenger->GetGUID().GetCounter(),
        teamChallenger);

    // El desafiante necesita obligatoriamente la ranura 1 ocupada.
    if (!teamChallenger[0].creatureEntry)
    {
        ChatHandler(challenger->GetSession()).PSendSysMessage(
            GetText(challenger, PETTXT_CHALLENGER_NO_SLOT));

        return false;
    }

    std::array<PetBattleTeamSlot, 3> teamTarget;

    LoadPlayerTeam(
        target->GetGUID().GetCounter(),
        teamTarget);

    // El objetivo del reto tambien necesita la ranura 1 ocupada,
    // sino no podria pelear el duelo si lo aceptara.
    if (!teamTarget[0].creatureEntry)
    {
        ChatHandler(challenger->GetSession()).PSendSysMessage(
            "{}",
            GetTextFmt(challenger, PETTXT_TARGET_NO_SLOT,
                { target->GetName() }));

        return false;
    }

    _pendingChallenges[target->GetGUID()] =
        challenger->GetGUID();

    ChatHandler(challenger->GetSession()).PSendSysMessage(
        "{}",
        GetTextFmt(challenger, PETTXT_CHALLENGE_SENT,
            { target->GetName() }));

    ShowDuelChallengeMenu(
        target,
        challenger);

    ChatHandler(target->GetSession()).PSendSysMessage(
        "{}",
        GetTextFmt(target, PETTXT_CHALLENGE_RECEIVED,
            { challenger->GetName() }));

    return true;
}

void PetBattleMgr::ShowDuelChallengeMenu(
    Player* target,
    Player* challenger)
{
    if (!target || !challenger)
        return;

    SendAddonMsg(
        target,
        "DUELREQ:" + std::string(challenger->GetName()));
}

void PetBattleMgr::HandleDuelAccept(
    Player* target)
{
    auto it =
        _pendingChallenges.find(
            target->GetGUID());

    if (it == _pendingChallenges.end())
    {
        ChatHandler(target->GetSession()).PSendSysMessage(
            GetText(target, PETTXT_NO_PENDING));

        return;
    }

    ObjectGuid challengerGuid =
        it->second;

    Player* challenger =
        ObjectAccessor::FindPlayer(
            challengerGuid);

    _pendingChallenges.erase(it);

    if (!challenger)
    {
        ChatHandler(target->GetSession()).PSendSysMessage(
            GetText(target, PETTXT_CHALLENGER_GONE));

        return;
    }

    if (GetBattleByPlayer(
        challenger->GetGUID()) ||
        GetBattleByPlayer(
            target->GetGUID()))
    {
        ChatHandler(target->GetSession()).PSendSysMessage(
            GetText(target, PETTXT_ALREADY_DUEL));

        return;
    }

    std::array<PetBattleTeamSlot, 3> teamA;
    std::array<PetBattleTeamSlot, 3> teamB;

    ObjectGuid::LowType guidLowA =
        challenger->GetGUID().GetCounter();

    ObjectGuid::LowType guidLowB =
        target->GetGUID().GetCounter();

    LoadPlayerTeam(
        guidLowA,
        teamA);

    LoadPlayerTeam(
        guidLowB,
        teamB);

    // Revalidamos la ranura 1 justo antes de empezar: el equipo pudo
    // haber cambiado (PETREMOVE/PETFORGET/PETDETACH) entre el reto y
    // el momento en que se acepta.
    if (!teamA[0].creatureEntry ||
        !teamB[0].creatureEntry)
    {
        ChatHandler(target->GetSession()).PSendSysMessage(
            GetText(target, PETTXT_DUEL_CANCEL));

        ChatHandler(challenger->GetSession()).PSendSysMessage(
            GetText(challenger, PETTXT_DUEL_CANCEL));

        return;
    }

    ActivePetBattle battle;

    battle.playerA =
        challenger->GetGUID();

    battle.playerB =
        target->GetGUID();

    for (uint8 i = 0;
        i < 3;
        ++i)
    {
        if (teamA[i].creatureEntry)
        {
            GetPetStats(
                guidLowA,
                teamA[i].creatureEntry,
                battle.teamA[i]);
        }

        if (teamB[i].creatureEntry)
        {
            GetPetStats(
                guidLowB,
                teamB[i].creatureEntry,
                battle.teamB[i]);
        }
    }

    ObjectGuid key =
        battle.playerA;

    _activeBattles[key] =
        battle;

    ActivePetBattle& stored =
        _activeBattles[key];

    SendPetChatFeedbackLocalized(
        challenger,
        target,
        PETTXT_DUEL_STARTED);

    SummonActivePet(
        challenger,
        stored,
        true);

    SummonActivePet(
        target,
        stored,
        false);

    SendBattleInit(
        challenger,
        stored,
        true);

    SendBattleInit(
        target,
        stored,
        false);

    // ------------------------------------------------------------
    // Timeout fijo de la tirada inicial.
    //
    // Este timeout es independiente de PetBattle.TurnTimeoutSeconds /
    // PET_TURN_TIMEOUT_SECONDS_DEFAULT. Si al cumplirse los 15 segundos
    // falta la tirada de al menos uno de los jugadores, se cancela el
    // duelo como si ese jugador hubiera rechazado el desafio.
    // ------------------------------------------------------------
    if (Creature* coinTimerPet =
        GetActiveSummonCreature(stored, true))
    {
        ObjectGuid battleKey = stored.playerA;

        coinTimerPet->m_Events.AddEventAtOffset(
            [this, battleKey]()
            {
                auto battleIt =
                    _activeBattles.find(battleKey);

                if (battleIt == _activeBattles.end())
                    return;

                ActivePetBattle& battle =
                    battleIt->second;

                if (battle.finished ||
                    battle.diceA != 0 && battle.diceB != 0)
                {
                    return;
                }

                Player* a =
                    ObjectAccessor::FindPlayer(
                        battle.playerA);

                Player* b =
                    ObjectAccessor::FindPlayer(
                        battle.playerB);

                bool missingA =
                    battle.diceA == 0;

                bool missingB =
                    battle.diceB == 0;

                // Si falta una sola tirada, ese jugador es tratado como
                // quien rechazo el duelo. Si faltan ambas, ambos reciben
                // la notificacion de rechazo.
                if (missingA && !missingB)
                {
                    if (a)
                    {
                        ChatHandler(a->GetSession()).PSendSysMessage(
                            GetText(a, PETTXT_DUEL_REJECTED));

                        SendAddonMsg(
                            a,
                            "BATTLEEND:" +
                            GetText(a, PETTXT_DUEL_REJECTED));
                    }

                    if (b)
                    {
                        ChatHandler(b->GetSession()).PSendSysMessage(
                            "{}",
                            GetTextFmt(
                                b,
                                PETTXT_CHALLENGE_REJECTED,
                                { a ? a->GetName() : std::string("the other player") }));

                        SendAddonMsg(
                            b,
                            "BATTLEEND:" +
                            GetTextFmt(
                                b,
                                PETTXT_CHALLENGE_REJECTED,
                                { a ? a->GetName() : std::string("the other player") }));
                    }
                }
                else if (!missingA && missingB)
                {
                    if (b)
                    {
                        ChatHandler(b->GetSession()).PSendSysMessage(
                            GetText(b, PETTXT_DUEL_REJECTED));

                        SendAddonMsg(
                            b,
                            "BATTLEEND:" +
                            GetText(b, PETTXT_DUEL_REJECTED));
                    }

                    if (a)
                    {
                        ChatHandler(a->GetSession()).PSendSysMessage(
                            "{}",
                            GetTextFmt(
                                a,
                                PETTXT_CHALLENGE_REJECTED,
                                { b ? b->GetName() : std::string("the other player") }));

                        SendAddonMsg(
                            a,
                            "BATTLEEND:" +
                            GetTextFmt(
                                a,
                                PETTXT_CHALLENGE_REJECTED,
                                { b ? b->GetName() : std::string("the other player") }));
                    }
                }
                else
                {
                    if (a)
                    {
                        ChatHandler(a->GetSession()).PSendSysMessage(
                            GetText(a, PETTXT_DUEL_REJECTED));

                        SendAddonMsg(
                            a,
                            "BATTLEEND:" +
                            GetText(a, PETTXT_DUEL_REJECTED));
                    }

                    if (b)
                    {
                        ChatHandler(b->GetSession()).PSendSysMessage(
                            GetText(b, PETTXT_DUEL_REJECTED));

                        SendAddonMsg(
                            b,
                            "BATTLEEND:" +
                            GetText(b, PETTXT_DUEL_REJECTED));
                    }
                }

                battle.finished = true;
                battle.winner.Clear();

                DespawnActivePet(battle, true);
                DespawnActivePet(battle, false);

                _activeBattles.erase(battleKey);
            },
            Seconds(PET_COIN_ROLL_TIMEOUT_SECONDS));
    }
}

void PetBattleMgr::HandleDuelDecline(
    Player* target)
{
    auto it =
        _pendingChallenges.find(
            target->GetGUID());

    if (it == _pendingChallenges.end())
    {
        ChatHandler(target->GetSession()).PSendSysMessage(
            GetText(target, PETTXT_NO_PENDING));

        return;
    }

    ObjectGuid challengerGuid =
        it->second;

    _pendingChallenges.erase(it);

    if (Player* challenger =
        ObjectAccessor::FindPlayer(
            challengerGuid))
    {
        ChatHandler(challenger->GetSession()).PSendSysMessage(
            "{}",
            GetTextFmt(challenger, PETTXT_CHALLENGE_REJECTED,
                { target->GetName() }));
    }

    ChatHandler(target->GetSession()).PSendSysMessage(
        GetText(target, PETTXT_DUEL_REJECTED));
}

// ================================================================
// Abandono de batalla
// ================================================================

void PetBattleMgr::HandleForfeit(Player* player)
{
    if (!player)
        return;

    ObjectGuid playerGuid = player->GetGUID();

    ActivePetBattle* battle =
        GetBattleByPlayer(playerGuid);

    if (!battle || battle->finished)
        return;

    // ------------------------------------------------------------
    // PvP
    // ------------------------------------------------------------
    // El jugador que cierra la ventana es el perdedor.
    // EndBattle() se encarga del ganador, perdedor, experiencia y
    // limpieza de la batalla.
    if (!battle->isWildBattle)
    {
        ObjectGuid winnerGuid =
            battle->playerA == playerGuid
            ? battle->playerB
            : battle->playerA;

        EndBattle(
            *battle,
            winnerGuid,
            playerGuid);

        return;
    }

    // ------------------------------------------------------------
    // Criatura salvaje
    // ------------------------------------------------------------
    // Aqui no usamos EndBattle(), porque esa funcion puede otorgar
    // XP y recompensa de captura al ganador. Al abandonar, el
    // jugador simplemente pierde el combate.
    battle->finished = true;
    battle->winner.Clear();

    SendAddonMsg(
        player,
        "BATTLEEND:" + GetText(player, PETTXT_FORFEIT_ADDON));

    ChatHandler(player->GetSession()).PSendSysMessage(
        GetText(player, PETTXT_FORFEIT_CHAT));

    player->HandleEmoteCommand(
        EMOTE_ONESHOT_CRY);

    // Desaparecer ambas copias de combate.
    DespawnActivePet(
        *battle,
        true);

    DespawnActivePet(
        *battle,
        false);

    // playerA es siempre la clave de las batallas salvajes.
    _activeBattles.erase(
        battle->playerA);
}

// ================================================================
// Modificar el equipo de mascotas durante un combate
// ================================================================
//
// Si el jugador intenta tocar su equipo de 3 mascotas (asignar,
// intercambiar, quitar, olvidar o desligar) mientras esta en un
// combate activo, el duelo termina de inmediato y ese jugador
// pierde. Misma logica de salida que HandleForfeit() y que
// HandleTurnTimeout() cuando se agotan los 15 segundos.
// ================================================================

void PetBattleMgr::HandleTeamModifiedInBattle(
    Player* player,
    ActivePetBattle& battle)
{
    if (!player || battle.finished)
        return;

    ObjectGuid playerGuid = player->GetGUID();

    SendAddonMsg(
        player,
        "PET_ACTION_ERR:TEAM:" + GetText(player, PETTXT_TEAM_MODIFIED));

    // ------------------------------------------------------------
    // PvP
    // ------------------------------------------------------------
    if (!battle.isWildBattle)
    {
        ObjectGuid winnerGuid =
            battle.playerA == playerGuid
            ? battle.playerB
            : battle.playerA;

        Player* winner =
            ObjectAccessor::FindPlayer(winnerGuid);

        SendPetChatFeedbackLocalized(
            player,
            winner,
            PETTXT_TEAM_MODIFIED);

        EndBattle(
            battle,
            winnerGuid,
            playerGuid);

        return;
    }

    // ------------------------------------------------------------
    // Criatura salvaje
    // ------------------------------------------------------------
    battle.finished = true;
    battle.winner.Clear();

    SendAddonMsg(
        player,
        "BATTLEEND:" + GetText(player, PETTXT_TEAM_MODIFIED_WILD_ADDON));

    ChatHandler(player->GetSession()).PSendSysMessage(
        GetText(player, PETTXT_TEAM_MODIFIED_WILD_CHAT));

    player->HandleEmoteCommand(
        EMOTE_ONESHOT_CRY);

    DespawnActivePet(battle, true);
    DespawnActivePet(battle, false);

    _activeBattles.erase(battle.playerA);
}

// ================================================================
// Timeout de turno
// ================================================================
//
// Cada vez que empieza el turno de un jugador (tras la tirada de
// dados en PvP, o tras el ataque de la criatura salvaje) se programa
// un evento retrasado que, si el jugador no responde a tiempo, hace
// que pierda el combate automaticamente.
//
// El evento se programa sobre los m_Events de la mascota invocada
// del jugador en turno, siguiendo el mismo patron que usa
// StartPetAttack() para encadenar la animacion de ataque.
//
// turnTimeoutToken sirve para invalidar timeouts obsoletos: se
// incrementa cada vez que el jugador ataca a tiempo (HandleAttack) y
// se programa un nuevo timeout (ScheduleTurnTimeout), de forma que
// un timeout viejo que dispare tarde no tenga ningun efecto si el
// turno ya avanzo.
// ================================================================

void PetBattleMgr::ScheduleTurnTimeout(
    ActivePetBattle& battle)
{
    if (battle.finished ||
        battle.turnPlayer.IsEmpty())
    {
        return;
    }

    uint32 timeoutSeconds =
        sConfigMgr->GetOption<uint32>(
            "PetBattle.TurnTimeoutSeconds",
            PET_TURN_TIMEOUT_SECONDS_DEFAULT);

    // Un valor 0 desactiva el timeout de turno.
    if (!timeoutSeconds)
        return;

    uint32 token =
        ++battle.turnTimeoutToken;

    ObjectGuid battleKey =
        battle.playerA;

    ObjectGuid turnPlayerGuid =
        battle.turnPlayer;

    bool turnIsA =
        turnPlayerGuid == battle.playerA;

    Creature* actingPet =
        GetActiveSummonCreature(
            battle,
            turnIsA);

    if (!actingPet)
        return;

    actingPet->m_Events.AddEventAtOffset(
        [this,
        battleKey,
        turnPlayerGuid,
        token]()
        {
            HandleTurnTimeout(
                battleKey,
                turnPlayerGuid,
                token);
        },
        Seconds(timeoutSeconds));
}

void PetBattleMgr::HandleTurnTimeout(
    ObjectGuid battleKey,
    ObjectGuid turnPlayerGuid,
    uint32 token)
{
    auto it =
        _activeBattles.find(
            battleKey);

    if (it == _activeBattles.end())
        return;

    ActivePetBattle& battle =
        it->second;

    if (battle.finished)
        return;

    // Si el jugador ya ataco, o el turno ya cambio desde que se
    // programo este timeout, el token ya no coincide: lo ignoramos.
    if (battle.turnTimeoutToken != token)
        return;

    if (battle.turnPlayer != turnPlayerGuid)
        return;

    Player* slowPlayer =
        ObjectAccessor::FindPlayer(
            turnPlayerGuid);

    // ------------------------------------------------------------
    // Combate contra criatura salvaje: el jugador pierde por no
    // responder a tiempo. No usamos EndBattle() porque esa funcion
    // otorga XP y recompensa de captura al ganador, y aca no hay
    // ganador (la criatura salvaje no es un Player).
    // ------------------------------------------------------------
    if (battle.isWildBattle)
    {
        battle.finished = true;
        battle.winner.Clear();

        if (slowPlayer)
        {
            SendAddonMsg(
                slowPlayer,
                "BATTLEEND:" + GetText(slowPlayer, PETTXT_TIMEOUT_WILD_ADDON));

            ChatHandler(slowPlayer->GetSession()).PSendSysMessage(
                GetText(slowPlayer, PETTXT_TIMEOUT_WILD_CHAT));

            slowPlayer->HandleEmoteCommand(
                EMOTE_ONESHOT_CRY);
        }

        DespawnActivePet(
            battle,
            true);

        DespawnActivePet(
            battle,
            false);

        _activeBattles.erase(
            battle.playerA);

        return;
    }

    // ------------------------------------------------------------
    // Duelo PvP: gana el rival del jugador que no respondio.
    // ------------------------------------------------------------
    ObjectGuid winnerGuid =
        battle.playerA == turnPlayerGuid
        ? battle.playerB
        : battle.playerA;

    Player* a =
        ObjectAccessor::FindPlayer(
            battle.playerA);

    Player* b =
        ObjectAccessor::FindPlayer(
            battle.playerB);

    SendPetChatFeedbackLocalized(
        a,
        b,
        PETTXT_TIMEOUT_PVP);

    EndBattle(
        battle,
        winnerGuid,
        turnPlayerGuid);
}

// ================================================================
// Tirada de dados
// ================================================================

ActivePetBattle* PetBattleMgr::GetBattleByPlayer(
    ObjectGuid playerGuid)
{
    for (auto& pair :
        _activeBattles)
    {
        if (pair.second.playerA == playerGuid ||
            pair.second.playerB == playerGuid)
        {
            return &pair.second;
        }
    }

    return nullptr;
}

void PetBattleMgr::ShowDiceMenu(
    Player* player,
    ActivePetBattle& /*battle*/)
{
    player->PlayerTalkClass->ClearMenus();

    player->PlayerTalkClass
        ->GetGossipMenu()
        .AddMenuItem(
            -1,
            GOSSIP_ICON_CHAT,
            GetText(player, PETTXT_ROLL_MENU),
            SENDER_DICE_MENU,
            1,
            "",
            0);

    player->PlayerTalkClass->SendGossipMenu(
        GOSSIP_TEXT_GENERICO,
        player->GetGUID());
}

void PetBattleMgr::HandleDiceRoll(
    Player* player,
    ActivePetBattle& battle)
{
    bool isA =
        player->GetGUID() == battle.playerA;

    if (isA &&
        battle.diceA != 0)
    {
        return;
    }

    if (!isA &&
        battle.diceB != 0)
    {
        return;
    }

    static std::random_device rd;
    static std::mt19937 gen(rd());

    std::uniform_int_distribution<> dist(
        1,
        6);

    uint32 roll =
        static_cast<uint32>(
            dist(gen));

    if (isA)
        battle.diceA = roll;
    else
        battle.diceB = roll;

    ChatHandler(player->GetSession()).PSendSysMessage(
        "{}",
        GetTextFmt(player, PETTXT_ROLL_RESULT,
            { std::to_string(roll) }));

    player->PlayerTalkClass->SendCloseGossip();

    if (battle.diceA == 0 ||
        battle.diceB == 0)
    {
        return;
    }

    Player* a =
        ObjectAccessor::FindPlayer(
            battle.playerA);

    Player* b =
        ObjectAccessor::FindPlayer(
            battle.playerB);

    if (battle.diceA ==
        battle.diceB)
    {
        battle.diceA = 0;
        battle.diceB = 0;

        if (a && b)
        {
            SendPetChatFeedbackLocalized(
                a,
                b,
                PETTXT_ROLL_DRAW);
        }

        if (a)
            SendAddonMsg(a, "COINRETRY");

        if (b)
            SendAddonMsg(b, "COINRETRY");

        return;
    }

    battle.turnPlayer =
        (battle.diceA > battle.diceB)
        ? battle.playerA
        : battle.playerB;

    battle.diceRolled = true;

    Player* first =
        ObjectAccessor::FindPlayer(
            battle.turnPlayer);

    if (a && b && first)
    {
        SendPetChatFeedbackLocalized(
            a,
            b,
            PETTXT_ROLL_WINNER,
            { first->GetName() });
    }

    if (a)
    {
        SendAddonMsg(
            a,
            battle.turnPlayer == battle.playerA
            ? "COINRESULT:primero"
            : "COINRESULT:segundo");
    }

    if (b)
    {
        SendAddonMsg(
            b,
            battle.turnPlayer == battle.playerB
            ? "COINRESULT:primero"
            : "COINRESULT:segundo");
    }

    // Arranca el turno del jugador que gano la tirada: si no ataca a
    // tiempo, pierde automaticamente el duelo.
    ScheduleTurnTimeout(
        battle);
}

// ================================================================
// Menu de ataque
// ================================================================

void PetBattleMgr::ShowAttackMenu(
    Player* player,
    ActivePetBattle& battle)
{
    if (!player ||
        player->GetGUID() != battle.turnPlayer ||
        battle.finished)
    {
        return;
    }

    bool isA =
        player->GetGUID() == battle.playerA;

    PetBattleStats const& myPet =
        isA
        ? battle.teamA[battle.activeIndexA]
        : battle.teamB[battle.activeIndexB];

    PetBattleStats const& rival =
        isA
        ? battle.teamB[battle.activeIndexB]
        : battle.teamA[battle.activeIndexA];

    player->PlayerTalkClass->ClearMenus();

    // ============================================================
    // Información de tipos
    // ============================================================

    player->PlayerTalkClass
        ->GetGossipMenu()
        .AddMenuItem(
            -1,
            GOSSIP_ICON_CHAT,
            GetTextFmt(player, PETTXT_ATTACK_INFO,
                { GetTipoName(player, myPet.tipo),
                  GetTipoName(player, rival.tipo) }),
            SENDER_ATTACK_MENU,
            0,
            "",
            0);

    // ============================================================
    // ATAQUE 1
    // ============================================================

    std::string attack1Text =
        GetTextFmt(player, PETTXT_ATTACK_BUTTON,
            { "1", std::to_string(myPet.daño1) });

    if (myPet.cooldown1 > 0)
    {
        attack1Text +=
            " [CD: " +
            std::to_string(myPet.cooldown1) +
            " turnos]";
    }

    player->PlayerTalkClass
        ->GetGossipMenu()
        .AddMenuItem(
            -1,
            GOSSIP_ICON_CHAT,
            attack1Text,
            SENDER_ATTACK_MENU,
            1,
            "",
            0);

    // ============================================================
    // ATAQUE 2
    // ============================================================

    std::string attack2Text =
        GetTextFmt(player, PETTXT_ATTACK_BUTTON,
            { "2", std::to_string(myPet.daño2) });

    if (myPet.cooldown2 > 0)
    {
        attack2Text +=
            " [CD: " +
            std::to_string(myPet.cooldown2) +
            " turnos]";
    }

    player->PlayerTalkClass
        ->GetGossipMenu()
        .AddMenuItem(
            -1,
            GOSSIP_ICON_CHAT,
            attack2Text,
            SENDER_ATTACK_MENU,
            2,
            "",
            0);

    // ============================================================
    // ATAQUE 3
    // ============================================================

    std::string attack3Text =
        GetTextFmt(player, PETTXT_ATTACK_BUTTON,
            { "3", std::to_string(myPet.daño3) });

    if (myPet.cooldown3 > 0)
    {
        attack3Text +=
            " [CD: " +
            std::to_string(myPet.cooldown3) +
            " turnos]";
    }

    player->PlayerTalkClass
        ->GetGossipMenu()
        .AddMenuItem(
            -1,
            GOSSIP_ICON_CHAT,
            attack3Text,
            SENDER_ATTACK_MENU,
            3,
            "",
            0);

    // ============================================================
    // Mostrar menú
    // ============================================================

    player->PlayerTalkClass->SendGossipMenu(
        GOSSIP_TEXT_GENERICO,
        player->GetGUID());
}


// ================================================================
// NUEVO FLUJO DE ATAQUE
//
// Ataque:
//   1. guardar posicion original
//   2. avanzar
//   3. esperar llegada
//   4. animacion de ataque
//   5. esperar animacion
//   6. aplicar daño
//   7. regresar
//   8. esperar regreso
//   9. siguiente turno
//
// No usamos sleep ni bloqueamos el worldserver.
// ================================================================

void PetBattleMgr::HandleAttack(
    Player* player,
    ActivePetBattle& battle,
    uint8 attackIndex)
{
    if (!player ||
        player->GetGUID() != battle.turnPlayer ||
        battle.finished)
    {
        if (player)
            player->PlayerTalkClass->SendCloseGossip();

        return;
    }

    if (attackIndex == 0)
    {
        ShowAttackMenu(
            player,
            battle);

        return;
    }

    bool isA =
        player->GetGUID() == battle.playerA;

    int32 danoBase = 0;

    PetBattleStats const& attacker =
        isA
        ? battle.teamA[battle.activeIndexA]
        : battle.teamB[battle.activeIndexB];

    // ============================================================
    // Comprobar cooldown
    // ============================================================

    if (attacker.GetCooldown(attackIndex) > 0)
    {
        ChatHandler(player->GetSession()).PSendSysMessage(
            "{}",
            GetTextFmt(player, PETTXT_COOLDOWN,
                { std::to_string(attacker.GetCooldown(attackIndex)) }));

        ShowAttackMenu(
            player,
            battle);

        return;
    }
    switch (attackIndex)
    {
    case 1:
        danoBase = attacker.daño1;
        break;

    case 2:
        danoBase = attacker.daño2;
        break;

    case 3:
        danoBase = attacker.daño3;
        break;

    default:
        return;
    }

    // ============================================================
    // CURACION AUTOMATICA
    //
    // Si la mascota activa esta por debajo del porcentaje configurado,
    // existe una probabilidad configurable de reemplazar el ataque
    // seleccionado por una curacion.
    //
    // Esto solo se aplica cuando el atacante es un JUGADOR. La criatura
    // salvaje mantiene su comportamiento actual y selecciona ataques
    // normalmente mediante SelectAvailableAttack().
    // ============================================================

    uint32 healBelowPercent =
        sConfigMgr->GetOption<uint32>(
            "PetBattle.HealBelowPercent",
            25);

    uint32 healChance =
        sConfigMgr->GetOption<uint32>(
            "PetBattle.HealChance",
            50);

    uint32 healMin =
        sConfigMgr->GetOption<uint32>(
            "PetBattle.HealMin",
            10);

    uint32 healMax =
        sConfigMgr->GetOption<uint32>(
            "PetBattle.HealMax",
            15);

    // Evitar configuraciones invalidas.
    if (healMax < healMin)
        std::swap(healMin, healMax);

    // Limitar la probabilidad a 100%.
    if (healChance > 100)
        healChance = 100;

    // Limitar el porcentaje de HP a 100%.
    if (healBelowPercent > 100)
        healBelowPercent = 100;

    bool shouldHeal = false;
    bool autoHeal = false;

    if (attacker.vidaMax > 0 &&
        attacker.vidaActual < attacker.vidaMax)
    {
        uint32 hpPercent =
            static_cast<uint32>(
                (static_cast<uint64>(attacker.vidaActual) * 100) /
                attacker.vidaMax);

        // Importante: es MENOR que el porcentaje configurado.
        // Con HealBelowPercent = 25, 25% exacto no activa la IA.
        if (hpPercent < healBelowPercent &&
            healChance > 0 &&
            urand(1, 100) <= healChance)
        {
            shouldHeal = true;
        }
    }

    if (shouldHeal)
    {
        uint32 healAmount =
            urand(healMin, healMax);

        // Las curaciones se representan con valores negativos.
        // Ejemplo: -10 cura 10, -15 cura 15.
        danoBase =
            -static_cast<int32>(healAmount);
        autoHeal = true;
    }

    player->PlayerTalkClass->SendCloseGossip();

    // El jugador respondio a tiempo: invalidamos cualquier timeout de
    // turno pendiente (ver ScheduleTurnTimeout / HandleTurnTimeout).
    ++battle.turnTimeoutToken;

    StartPetAttack(
        battle,
        isA,
        danoBase,
        attackIndex,
        player,
        autoHeal);
}

// ================================================================
// Secuencia completa de un ataque
// ================================================================

void PetBattleMgr::StartPetAttack(
    ActivePetBattle& battle,
    bool attackerIsA,
    int32 danoBase,
    uint8 attackIndex,
    Player* attackerPlayer,
    bool autoHeal)
{
    if (battle.finished)
        return;

    ObjectGuid battleKey = battle.playerA;
    ObjectGuid attackerPlayerGuid =
        attackerPlayer ? attackerPlayer->GetGUID() : ObjectGuid::Empty;

    Creature* attackerCreature =
        GetActiveSummonCreature(battle, attackerIsA);

    Creature* defenderCreature =
        GetActiveSummonCreature(battle, !attackerIsA);

    if (!attackerCreature || !defenderCreature)
        return;

    // ------------------------------------------------------------
    // Distancia maxima de ataque: 10 yardas.
    // ------------------------------------------------------------
    float currentDistance =
        attackerCreature->GetDistance(defenderCreature);


    Position startPosition = attackerCreature->GetPosition();

    float dx = defenderCreature->GetPositionX() - attackerCreature->GetPositionX();
    float dy = defenderCreature->GetPositionY() - attackerCreature->GetPositionY();
    float distance = std::sqrt((dx * dx) + (dy * dy));

    if (distance < 0.1f)
        distance = 0.1f;

    float dirX = dx / distance;
    float dirY = dy / distance;

    // Orientacion hacia el rival.
    float attackOrientation =
        std::atan2(dy, dx);

    // Al regresar a su posicion inicial, la mascota quedara
    // mirando exactamente en sentido contrario al rival.
    float returnOrientation = attackOrientation;

    Position attackPosition;
    attackPosition.Relocate(
        defenderCreature->GetPositionX() - dirX * PET_ATTACK_DISTANCE,
        defenderCreature->GetPositionY() - dirY * PET_ATTACK_DISTANCE,
        defenderCreature->GetPositionZ(),
        attackOrientation);

    attackerCreature->SetFacingTo(attackOrientation);

    float speed = attackerCreature->GetSpeed(MOVE_RUN);
    if (speed <= 0.0f)
        speed = 7.0f;

    float moveDistance = attackerCreature->GetDistance(
        attackPosition.GetPositionX(),
        attackPosition.GetPositionY(),
        attackPosition.GetPositionZ());

    uint32 movementTime = static_cast<uint32>((moveDistance / speed) * 1000.0f);
    movementTime += 100;

    attackerCreature->GetMotionMaster()->MovePoint(
        100,
        attackPosition,
        FORCED_MOVEMENT_RUN,
        speed);

    // ------------------------------------------------------------
    // 1) Esperar a que termine el avance.
    // ------------------------------------------------------------
    attackerCreature->m_Events.AddEventAtOffset(
        [this,
        battleKey,
        attackerIsA,
        danoBase,
        attackIndex,
        attackerPlayerGuid,
        startPosition,
        returnOrientation,
        autoHeal]()
        {
            auto it = _activeBattles.find(battleKey);
            if (it == _activeBattles.end())
                return;

            ActivePetBattle& currentBattle = it->second;
            if (currentBattle.finished)
                return;

            Creature* attacker =
                GetActiveSummonCreature(currentBattle, attackerIsA);
            Creature* defender =
                GetActiveSummonCreature(currentBattle, !attackerIsA);

            if (!attacker || !defender)
                return;

            attacker->SetFacingToObject(defender);
            attacker->HandleEmoteCommand(EMOTE_ONESHOT_ATTACK_UNARMED);

            // --------------------------------------------------------
            // 2) Esperar a que termine la animacion del ataque.
            // --------------------------------------------------------
            attacker->m_Events.AddEventAtOffset(
                [this,
                battleKey,
                attackerIsA,
                danoBase,
                attackIndex,
                attackerPlayerGuid,
                startPosition,
                returnOrientation,
                autoHeal]()
                {
                    auto it = _activeBattles.find(battleKey);
                    if (it == _activeBattles.end())
                        return;

                    ActivePetBattle& currentBattle = it->second;
                    if (currentBattle.finished)
                        return;

                    Creature* attacker =
                        GetActiveSummonCreature(currentBattle, attackerIsA);
                    if (!attacker)
                        return;

                    Player* attackerPlayer =
                        attackerPlayerGuid.IsEmpty()
                        ? nullptr
                        : ObjectAccessor::FindPlayer(attackerPlayerGuid);

                    // ------------------------------------------------
                    // 3) Resolver el golpe.
                    // ------------------------------------------------
                    if (!ResolveAttackAndAdvance(
                        currentBattle,
                        attackerIsA,
                        danoBase,
                        attackIndex,
                        attackerPlayer,
                        autoHeal))
                    {
                        return;
                    }

                    auto battleIt = _activeBattles.find(battleKey);
                    if (battleIt == _activeBattles.end())
                        return;

                    ActivePetBattle& battleAfterHit = battleIt->second;
                    if (battleAfterHit.finished)
                        return;

                    Creature* currentAttacker =
                        GetActiveSummonCreature(battleAfterHit, attackerIsA);
                    if (!currentAttacker)
                        return;

                    float returnSpeed = currentAttacker->GetSpeed(MOVE_RUN);
                    if (returnSpeed <= 0.0f)
                        returnSpeed = 7.0f;

                    float returnDistance = currentAttacker->GetDistance(
                        startPosition.GetPositionX(),
                        startPosition.GetPositionY(),
                        startPosition.GetPositionZ());

                    uint32 returnTime =
                        static_cast<uint32>((returnDistance / returnSpeed) * 1000.0f);
                    returnTime += 100;

                    // ------------------------------------------------
                    // 4) Regresar a la posicion inicial.
                    // ------------------------------------------------
                    currentAttacker->GetMotionMaster()->MovePoint(
                        101,
                        startPosition,
                        FORCED_MOVEMENT_RUN,
                        returnSpeed);

                    currentAttacker->m_Events.AddEventAtOffset(
                        [this,
                        battleKey,
                        attackerIsA,
                        startPosition,
                        returnOrientation]()
                        {
                            auto it = _activeBattles.find(battleKey);
                            if (it == _activeBattles.end())
                                return;

                            ActivePetBattle& battle = it->second;
                            if (battle.finished)
                                return;

                            Creature* attacker =
                                GetActiveSummonCreature(battle, attackerIsA);
                            if (!attacker)
                                return;

                            // La mascota ya regreso a su posicion inicial.
                            // Ahora queda mirando en sentido contrario al rival.
                            if (Creature* defender =
                                GetActiveSummonCreature(battle, !attackerIsA))
                            {
                                attacker->SetFacingToObject(defender);
                            }
                            else
                            {
                                attacker->SetFacingTo(returnOrientation);
                            }

                            attacker->m_Events.AddEventAtOffset(
                                [this,
                                battleKey,
                                attackerIsA]()
                                {
                                    auto it = _activeBattles.find(battleKey);
                                    if (it == _activeBattles.end())
                                        return;

                                    ActivePetBattle& battle = it->second;
                                    if (battle.finished)
                                        return;

                                    // =================================================
                                    // COMBATE SALVAJE
                                    // =================================================
                                    if (battle.isWildBattle)
                                    {
                                        // Termino la criatura salvaje: ahora juega A.
                                        if (!attackerIsA)
                                        {
                                            battle.teamA[battle.activeIndexA].TickCooldowns();
                                            battle.turnPlayer = battle.playerA;

                                            if (Player* player =
                                                ObjectAccessor::FindPlayer(battle.playerA))
                                            {
                                                // El turno se comunica de forma independiente
                                                // del HPUPDATE. Esto permite que una habilidad de
                                                // curacion (HPUPDATE:enemy) termine correctamente
                                                // devolviendo el turno al jugador.
                                                SendAddonMsg(
                                                    player,
                                                    "TURN:mine");

                                                ShowAttackMenu(player, battle);
                                            }

                                            // Empieza el turno del jugador: si no ataca a
                                            // tiempo, pierde el combate salvaje.
                                            ScheduleTurnTimeout(battle);

                                            return;
                                        }

                                        // Termino A: ahora contraataca B.
                                        if (attackerIsA)
                                        {
                                            ActivePetBattle* current =
                                                GetBattleByPlayer(battleKey);

                                            if (!current || current->finished)
                                                return;

                                            current->teamB[current->activeIndexB].TickCooldowns();

                                            PetBattleStats const& wildAttacker =
                                                current->teamB[current->activeIndexB];

                                            uint8 wildAttackIndex =
                                                SelectAvailableAttack(wildAttacker);

                                            int32 wildDanoBase = 0;

                                            switch (wildAttackIndex)
                                            {
                                            case 1:
                                                wildDanoBase = wildAttacker.daño1;
                                                break;
                                            case 2:
                                                wildDanoBase = wildAttacker.daño2;
                                                break;
                                            case 3:
                                                wildDanoBase = wildAttacker.daño3;
                                                break;
                                            default:
                                                return;
                                            }

                                            StartPetAttack(
                                                *current,
                                                false,
                                                wildDanoBase,
                                                wildAttackIndex,
                                                nullptr);

                                            return;
                                        }
                                    }

                                    // =================================================
                                    // COMBATE PvP
                                    // =================================================
                                    if (!battle.isWildBattle)
                                    {
                                        PetBattleStats& nextPet =
                                            attackerIsA
                                            ? battle.teamB[battle.activeIndexB]
                                            : battle.teamA[battle.activeIndexA];

                                        nextPet.TickCooldowns();

                                        battle.turnPlayer =
                                            attackerIsA
                                            ? battle.playerB
                                            : battle.playerA;

                                        if (Player* nextPlayer =
                                            ObjectAccessor::FindPlayer(battle.turnPlayer))
                                        {
                                            // =========================================================
                                            // AVISAR AL ADDON QUE ESTE JUGADOR TIENE EL TURNO
                                            // =========================================================

                                            SendAddonMsg(
                                                nextPlayer,
                                                "TURN:mine");

                                            // =========================================================
                                            // AVISAR AL OTRO JUGADOR QUE YA NO TIENE EL TURNO
                                            // =========================================================

                                            Player* otherPlayer =
                                                ObjectAccessor::FindPlayer(
                                                    attackerIsA
                                                    ? battle.playerA
                                                    : battle.playerB);

                                            if (otherPlayer)
                                            {
                                                SendAddonMsg(
                                                    otherPlayer,
                                                    "TURN:enemy");
                                            }

                                            // =========================================================
                                            // ACTUALIZAR MENU / COOLDOWNS DEL SERVIDOR
                                            // =========================================================

                                            ShowAttackMenu(
                                                nextPlayer,
                                                battle);
                                        }

                                        // =============================================================
                                        // EMPIEZA EL TURNO DEL SIGUIENTE JUGADOR
                                        // =============================================================

                                        ScheduleTurnTimeout(
                                            battle);
                                    }
                                },
                                Milliseconds(PET_ATTACK_RETURN_DELAY_MS));
                        },
                        Milliseconds(returnTime));
                },
                Milliseconds(PET_ATTACK_ANIMATION_MS));
        },
        Milliseconds(movementTime));
}

// ================================================================
// Resolver UN golpe
// ================================================================

bool PetBattleMgr::ResolveAttackAndAdvance(
    ActivePetBattle& battle,
    bool attackerIsA,
    int32 danoBase,
    uint8 attackIndex,
    Player* attackerPlayer,
    bool autoHeal)
{
    PetBattleStats& attacker =
        attackerIsA
        ? battle.teamA[battle.activeIndexA]
        : battle.teamB[battle.activeIndexB];

    PetBattleStats& defender =
        attackerIsA
        ? battle.teamB[battle.activeIndexB]
        : battle.teamA[battle.activeIndexA];

    bool missed = false;
    bool superEfectivo = false;

    int32 daño =
        ResolveHitDamage(
            attacker,
            defender,
            danoBase,
            missed,
            superEfectivo);

    // Un valor negativo representa recuperacion de vida para la propia
    // mascota (la atacante), no daño a la mascota rival.
    bool const curacionPropia = daño < 0;

    // La mascota realmente afectada por este golpe: la rival si es daño,
    // o la propia si es curacion.
    PetBattleStats& afectada =
        curacionPropia
        ? attacker
        : defender;

    if (!missed)
    {
        attacker.SetCooldown(
            attackIndex,
            3);

        if (curacionPropia)
        {
            int32 curado =
                static_cast<int32>(attacker.vidaActual) -
                daño; // daño es negativo, por lo que esto suma vida

            int32 vidaMax =
                static_cast<int32>(attacker.vidaMax);

            if (curado > vidaMax)
                curado = vidaMax;

            attacker.vidaActual =
                static_cast<uint32>(curado);
        }
        else
        {
            uint32 danoAplicado =
                static_cast<uint32>(daño);

            if (danoAplicado >= defender.vidaActual)
                defender.vidaActual = 0;
            else
                defender.vidaActual -= danoAplicado;
        }
    }

    Player* a =
        ObjectAccessor::FindPlayer(
            battle.playerA);

    Player* b =
        ObjectAccessor::FindPlayer(
            battle.playerB);

    // "afectadaEsA" indica si la mascota que cambio de vida (por daño o
    // por curacion propia) pertenece al equipo A. La mascota rival
    // (daño) es !attackerIsA; la propia (curacion) es attackerIsA.
    bool const afectadaEsA =
        curacionPropia
        ? attackerIsA
        : !attackerIsA;

    // side es relativo a cada cliente: "mine" si la mascota afectada es
    // la suya, "enemy" si es la del rival.
    if (a)
    {
        SendAddonMsg(
            a,
            "HPUPDATE:" +
            std::string(afectadaEsA ? "mine" : "enemy") +
            ":" +
            std::to_string(afectada.vidaActual));
    }

    if (b)
    {
        SendAddonMsg(
            b,
            "HPUPDATE:" +
            std::string(afectadaEsA ? "enemy" : "mine") +
            ":" +
            std::to_string(afectada.vidaActual));
    }

    // ============================================================
    // Animacion del atacante.
    //
    // - Si fallo el golpe: se mantiene el emote de ataque normal.
    // - Si fue una curacion propia (habilidad o auto-heal por HP
    //   bajo): se reproduce PetBattle.HealVisualSpellId, si esta
    //   configurado.
    // - Si fue daño real: se reproduce PetBattle.DamageVisualSpellIdLow
    //   o PetBattle.DamageVisualSpellIdHigh, segun el daño quede por
    //   debajo o por encima/igual de PET_DAMAGE_VISUAL_THRESHOLD.
    //
    // En cualquier caso, si el spell visual configurado es 0 (no
    // configurado), se usa el emote de ataque de siempre como
    // fallback, exactamente igual que PetBattle.SummonVisualSpellId.
    // ============================================================
    if (Creature* attackerCreature =
        GetActiveSummonCreature(
            battle,
            attackerIsA))
    {
        uint32 visualSpellId = 0;

        if (!missed)
        {
            if (curacionPropia)
            {
                visualSpellId =
                    sConfigMgr->GetOption<uint32>(
                        "PetBattle.HealVisualSpellId",
                        0);
            }
            else
            {
                visualSpellId =
                    daño < static_cast<int32>(PET_DAMAGE_VISUAL_THRESHOLD)
                    ? sConfigMgr->GetOption<uint32>(
                        "PetBattle.DamageVisualSpellIdLow",
                        0)
                    : sConfigMgr->GetOption<uint32>(
                        "PetBattle.DamageVisualSpellIdHigh",
                        0);
            }
        }

        if (visualSpellId)
        {
            attackerCreature->CastSpell(
                attackerCreature,
                visualSpellId,
                true);
        }
        else
        {
            attackerCreature->HandleEmoteCommand(
                EMOTE_ONESHOT_ATTACK_UNARMED);
        }
    }

    // Animacion de la defensa. Si el golpe se convirtio en curacion
    // propia, no corresponde animar herida en la mascota rival.
    Creature* defenderCreature =
        GetActiveSummonCreature(
            battle,
            !attackerIsA);

    if (defenderCreature)
    {
        if (missed)
        {
            defenderCreature->HandleEmoteCommand(
                EMOTE_ONESHOT_PARRY_UNARMED);
        }
        else if (!curacionPropia)
        {
            defenderCreature->HandleEmoteCommand(
                defender.vidaActual == 0
                ? EMOTE_ONESHOT_WOUND_CRITICAL
                : EMOTE_ONESHOT_WOUND);
        }
    }

    std::string atacanteNombre =
        attackerPlayer
        ? std::string(
            attackerPlayer->GetName())
        : (
            sObjectMgr->GetCreatureTemplate(
                attacker.mascotaID)
            ? GetCreatureName(a, attacker.mascotaID)
            : GetText(a, PETTXT_WILD_PET_NAME));

    if (a && b)
    {
        if (missed)
        {
            ChatHandler(a->GetSession()).PSendSysMessage(
                "{}",
                GetTextFmt(a, PETTXT_ATTACK_MISS,
                    { atacanteNombre }));

            ChatHandler(b->GetSession()).PSendSysMessage(
                "{}",
                GetTextFmt(b, PETTXT_ATTACK_MISS,
                    { atacanteNombre }));
        }
        else if (curacionPropia)
        {
            std::string curado =
                std::to_string(-daño);

            uint32 healTextId =
                autoHeal
                ? PETTXT_AUTO_HEAL
                : PETTXT_ATTACK_HEAL;

            ChatHandler(a->GetSession()).PSendSysMessage(
                "{}",
                GetTextFmt(a, healTextId,
                    { atacanteNombre, curado,
                      std::to_string(afectada.vidaActual) }));

            ChatHandler(b->GetSession()).PSendSysMessage(
                "{}",
                GetTextFmt(b, healTextId,
                    { atacanteNombre, curado,
                      std::to_string(afectada.vidaActual) }));
        }
        else
        {
            std::string bonusA =
                superEfectivo ? GetText(a, PETTXT_EFFECTIVE) : "";
            std::string bonusB =
                superEfectivo ? GetText(b, PETTXT_EFFECTIVE) : "";

            ChatHandler(a->GetSession()).PSendSysMessage(
                "{}",
                GetTextFmt(a, PETTXT_ATTACK_HIT,
                    { atacanteNombre, std::to_string(daño), bonusA,
                      std::to_string(afectada.vidaActual) }));

            ChatHandler(b->GetSession()).PSendSysMessage(
                "{}",
                GetTextFmt(b, PETTXT_ATTACK_HIT,
                    { atacanteNombre, std::to_string(daño), bonusB,
                      std::to_string(afectada.vidaActual) }));
        }
    }
    else if (a)
    {
        std::string msg;

        if (missed)
        {
            msg = GetTextFmt(a, PETTXT_ATTACK_MISS, { atacanteNombre });
        }
        else if (curacionPropia)
        {
            uint32 healTextId =
                autoHeal
                ? PETTXT_AUTO_HEAL
                : PETTXT_ATTACK_HEAL;

            msg = GetTextFmt(a, healTextId,
                { atacanteNombre, std::to_string(-daño),
                  std::to_string(afectada.vidaActual) });
        }
        else
        {
            msg = GetTextFmt(a, PETTXT_ATTACK_HIT,
                { atacanteNombre, std::to_string(daño),
                  superEfectivo ? GetText(a, PETTXT_EFFECTIVE) : "",
                  std::to_string(afectada.vidaActual) });
        }

        ChatHandler(a->GetSession()).PSendSysMessage(
            "{}",
            msg);
    }

    ShowFloatingDamageNumber(
        curacionPropia
        ? GetActiveSummonCreature(battle, attackerIsA)
        : defenderCreature,
        attackerPlayer,
        a,
        daño,
        missed,
        superEfectivo);

    if (defender.vidaActual == 0 &&
        !missed &&
        !curacionPropia)
    {
        if (attackerIsA)
        {
            // Muere mascota B.
            DespawnActivePetDefeated(
                battle,
                false);

            ++battle.activeIndexB;

            bool sinMascotas =
                battle.activeIndexB >= 3 ||
                battle.teamB[
                    battle.activeIndexB].mascotaID == 0;

            if (sinMascotas)
            {
                EndBattle(
                    battle,
                    battle.playerA,
                    battle.playerB);

                return false;
            }

            if (b)
            {
                SummonActivePet(
                    b,
                    battle,
                    false);
            }
            else if (battle.isWildBattle)
            {
                SummonActivePet(
                    a,
                    battle,
                    false);
            }
        }
        else
        {
            // Muere mascota A.
            DespawnActivePetDefeated(
                battle,
                true);

            ++battle.activeIndexA;

            bool sinMascotas =
                battle.activeIndexA >= 3 ||
                battle.teamA[
                    battle.activeIndexA].mascotaID == 0;

            if (sinMascotas)
            {
                EndBattle(
                    battle,
                    battle.playerB,
                    battle.playerA);

                return false;
            }

            if (a)
            {
                SummonActivePet(
                    a,
                    battle,
                    true);
            }
        }

        if (a && b)
        {
            SendPetChatFeedbackLocalized(
                a,
                b,
                PETTXT_PET_DEFEATED);
        }
        else if (a)
        {
            ChatHandler(a->GetSession()).PSendSysMessage(
                GetText(a, PETTXT_PET_DEFEATED));
        }

        // La mascota nueva tiene otro nombre/tipo/vida maxima: se
        // manda un BATTLEINIT fresco en vez de un simple HPUPDATE.
        SendBattleInit(a, battle, true);
        SendBattleInit(b, battle, false);
    }

    return true;
}

// ================================================================
// Finalizar batalla
// ================================================================

void PetBattleMgr::EndBattle(
    ActivePetBattle& battle,
    ObjectGuid winnerGuid,
    ObjectGuid loserGuid)
{
    battle.finished = true;
    battle.winner = winnerGuid;

    bool winnerIsA =
        winnerGuid == battle.playerA;

    Player* winner =
        ObjectAccessor::FindPlayer(
            winnerGuid);

    Player* loser =
        ObjectAccessor::FindPlayer(
            loserGuid);

    if (winner)
    {
        ChatHandler(winner->GetSession()).PSendSysMessage(
            GetText(winner, PETTXT_VICTORY));

        SendAddonMsg(
            winner,
            "BATTLEEND:" + GetText(winner, PETTXT_VICTORY));

        winner->HandleEmoteCommand(
            EMOTE_ONESHOT_CHEER);

        GrantBattleExperience(
            winner,
            battle.isWildBattle);

        if (battle.isWildBattle &&
            winnerIsA)
        {
            GrantWildCaptureReward(
                winner,
                battle);
        }
    }

    if (loser)
    {
        ChatHandler(loser->GetSession()).PSendSysMessage(
            GetText(loser, PETTXT_DEFEAT));

        SendAddonMsg(
            loser,
            "BATTLEEND:" + GetText(loser, PETTXT_DEFEAT));

        loser->HandleEmoteCommand(
            EMOTE_ONESHOT_CRY);
    }

    if (Creature* winnerPet =
        GetActiveSummonCreature(
            battle,
            winnerIsA))
    {
        winnerPet->HandleEmoteCommand(
            EMOTE_ONESHOT_ROAR);

        winnerPet->DespawnOrUnsummon(
            300ms);
    }

    // La mascota perdedora tambien debe desaparecer.
    // Esto es especialmente importante cuando la batalla termina por
    // FORFEIT, porque no debe quedar ninguna copia de combate en el mundo.
    bool loserIsA = !winnerIsA;

    if (Creature* loserPet =
        GetActiveSummonCreature(
            battle,
            loserIsA))
    {
        loserPet->DespawnOrUnsummon();
    }

    if (winnerIsA)
    {
        battle.activeSummonA.Clear();
        battle.activeSummonB.Clear();
    }
    else
    {
        battle.activeSummonA.Clear();
        battle.activeSummonB.Clear();
    }

    // A partir de aca la referencia battle deja de ser segura.
    _activeBattles.erase(
        battle.playerA);
}

// ================================================================
// Chat
// ================================================================

void PetBattleMgr::SendPetChatFeedbackLocalized(
    Player* p1,
    Player* p2,
    uint32 textId,
    std::initializer_list<std::string> args)
{
    if (p1)
    {
        ChatHandler(p1->GetSession()).PSendSysMessage(
            "{}",
            GetTextFmt(p1, textId, args));
    }

    if (p2)
    {
        ChatHandler(p2->GetSession()).PSendSysMessage(
            "{}",
            GetTextFmt(p2, textId, args));
    }
}

void PetBattleMgr::SendPetChatFeedback(
    Player* p1,
    Player* p2,
    std::string const& msg)
{
    if (p1)
    {
        ChatHandler(p1->GetSession()).PSendSysMessage(
            "{}",
            msg);
    }

    if (p2)
    {
        ChatHandler(p2->GetSession()).PSendSysMessage(
            "{}",
            msg);
    }
}

// ================================================================
// Experiencia
// ================================================================

void PetBattleMgr::GrantBattleExperience(
    Player* winner,
    bool vsWild)
{
    if (!winner)
        return;

    if (winner->GetLevel() >=
        sWorld->getIntConfig(
            CONFIG_MAX_PLAYER_LEVEL))
    {
        return;
    }

    uint32 xpParaSiguienteNivel =
        sObjectMgr->GetXPForLevel(
            winner->GetLevel());

    if (!xpParaSiguienteNivel)
        return;

    uint32 porcentaje =
        vsWild
        ? sConfigMgr->GetOption<uint32>(
            "PetBattle.XpPercentVsWild",
            PET_XP_PERCENT_VS_WILD)
        : sConfigMgr->GetOption<uint32>(
            "PetBattle.XpPercentVsPvp",
            PET_XP_PERCENT_VS_PVP);

    uint32 xpGanada =
        static_cast<uint32>(
            (static_cast<uint64>(
                xpParaSiguienteNivel) *
                porcentaje) /
            100);

    if (!xpGanada)
        return;

    winner->GiveXP(
        xpGanada,
        nullptr);

    ChatHandler(winner->GetSession()).PSendSysMessage(
        "{}",
        GetTextFmt(winner, PETTXT_XP,
            { std::to_string(xpGanada), std::to_string(porcentaje) }));
}

// ================================================================
// Recompensa de captura
// ================================================================

void PetBattleMgr::GrantWildCaptureReward(
    Player* winner,
    ActivePetBattle const& battle)
{
    if (!winner ||
        !battle.wildCreatureEntry)
    {
        return;
    }

    CreatureTemplate const* wildTemplate =
        sObjectMgr->GetCreatureTemplate(
            battle.wildCreatureEntry);

    if (!wildTemplate)
    {
        ChatHandler(winner->GetSession()).PSendSysMessage(
            GetText(winner, PETTXT_CAPTURE_NO_CREATURE));

        return;
    }

    std::array<uint32, 4> wildDisplayIds =
    {
        0,
        0,
        0,
        0
    };

    bool hasWildModel = false;

    for (uint8 modelIndex = 0;
        modelIndex < 4;
        ++modelIndex)
    {
        CreatureModel const* model =
            wildTemplate->GetModelByIdx(
                modelIndex);

        if (!model ||
            !model->CreatureDisplayID)
        {
            continue;
        }

        wildDisplayIds[modelIndex] =
            model->CreatureDisplayID;

        hasWildModel = true;
    }

    if (!hasWildModel)
    {
        ChatHandler(winner->GetSession()).PSendSysMessage(
            GetText(winner, PETTXT_CAPTURE_NO_MODEL));

        return;
    }

    QueryResult result = WorldDatabase.Query(
        "SELECT entry, spellid_1, spellid_2, spellid_3, spellid_4, spellid_5 "
        "FROM item_template "
        "WHERE spellid_1 > 0 "
        "OR spellid_2 > 0 "
        "OR spellid_3 > 0 "
        "OR spellid_4 > 0 "
        "OR spellid_5 > 0");

    if (!result)
    {
        ChatHandler(winner->GetSession()).PSendSysMessage(
            GetText(winner, PETTXT_CAPTURE_NO_ITEMS));

        return;
    }

    uint32 matchedItemEntry = 0;

    do
    {
        Field* fields =
            result->Fetch();

        uint32 currentItemEntry =
            fields[0].Get<uint32>();

        for (uint8 spellIndex = 0;
            spellIndex < 5;
            ++spellIndex)
        {
            // Leemos como signed para ignorar valores -1.
            int64 rawSpellId =
                fields[1 + spellIndex].Get<int64>();

            if (rawSpellId <= 0)
                continue;

            uint32 itemSpellId =
                static_cast<uint32>(
                    rawSpellId);

            SpellInfo const* itemSpell =
                sSpellMgr->GetSpellInfo(
                    itemSpellId);

            if (!itemSpell)
                continue;

            uint32 itemCreatureEntry = 0;

            for (SpellEffectInfo const& effect :
                itemSpell->GetEffects())
            {
                if (effect.Effect !=
                    SPELL_EFFECT_SUMMON)
                {
                    continue;
                }

                if (!effect.MiscValue)
                    continue;

                uint32 candidateEntry =
                    static_cast<uint32>(
                        effect.MiscValue);

                if (!sObjectMgr->GetCreatureTemplate(
                    candidateEntry))
                {
                    continue;
                }

                itemCreatureEntry =
                    candidateEntry;

                break;
            }

            if (!itemCreatureEntry)
                continue;

            CreatureTemplate const* itemCreatureTemplate =
                sObjectMgr->GetCreatureTemplate(
                    itemCreatureEntry);

            if (!itemCreatureTemplate)
                continue;

            bool modelMatches = false;

            for (uint8 itemModelIndex = 0;
                itemModelIndex < 4 &&
                !modelMatches;
                ++itemModelIndex)
            {
                CreatureModel const* itemModel =
                    itemCreatureTemplate->GetModelByIdx(
                        itemModelIndex);

                if (!itemModel ||
                    !itemModel->CreatureDisplayID)
                {
                    continue;
                }

                uint32 itemDisplayId =
                    itemModel->CreatureDisplayID;

                for (uint8 wildModelIndex = 0;
                    wildModelIndex < 4;
                    ++wildModelIndex)
                {
                    uint32 wildDisplayId =
                        wildDisplayIds[
                            wildModelIndex];

                    if (!wildDisplayId)
                        continue;

                    if (itemDisplayId ==
                        wildDisplayId)
                    {
                        modelMatches = true;
                        break;
                    }
                }
            }

            if (modelMatches)
            {
                matchedItemEntry =
                    currentItemEntry;

                break;
            }
        }

        if (matchedItemEntry)
            break;

    } while (result->NextRow());

    if (!matchedItemEntry)
    {
        ChatHandler(winner->GetSession()).PSendSysMessage(
            GetText(winner, PETTXT_CAPTURE_NO_MATCH));

        return;
    }

    ItemTemplate const* itemTemplate =
        sObjectMgr->GetItemTemplate(
            matchedItemEntry);

    if (!itemTemplate)
        return;

    if (!winner->StoreNewItemInBestSlots(
        matchedItemEntry,
        1))
    {
        ChatHandler(winner->GetSession()).PSendSysMessage(
            "{}",
            GetTextFmt(winner, PETTXT_CAPTURE_NO_SPACE,
                { itemTemplate->Name1 }));

        return;
    }

    ChatHandler(winner->GetSession()).PSendSysMessage(
        "{}",
        GetTextFmt(winner, PETTXT_CAPTURE_SUCCESS,
            { itemTemplate->Name1 }));
}

// ================================================================
// Daño para addon/debug
// ================================================================

void PetBattleMgr::ShowFloatingDamageNumber(
    Creature* target,
    Player* attacker,
    Player* defenderOwner,
    int32 damage,
    bool missed,
    bool /*critEffective*/)
{
    bool debugDamageMessages =
        sConfigMgr->GetOption<bool>(
            "PetBattle.DebugDamageMessages",
            false);

    if (!debugDamageMessages)
        return;

    if (!target)
        return;

    std::string linea =
        std::string(
            PETDMG_CHAT_PREFIX) +
        " " +
        target->GetGUID().ToString() +
        ";" +
        std::to_string(damage) +
        ";" +
        (missed ? "1" : "0");

    if (attacker)
    {
        ChatHandler(attacker->GetSession()).PSendSysMessage(
            "{}",
            linea);
    }

    if (defenderOwner &&
        defenderOwner != attacker)
    {
        ChatHandler(defenderOwner->GetSession()).PSendSysMessage(
            "{}",
            linea);
    }
}

// ================================================================
// Invocar mascota
// ================================================================

Creature* PetBattleMgr::SummonActivePet(
    Player* player,
    ActivePetBattle& battle,
    bool isA)
{
    if (!player)
        return nullptr;

    PetBattleStats const& stats =
        isA
        ? battle.teamA[battle.activeIndexA]
        : battle.teamB[battle.activeIndexB];

    if (!stats.mascotaID)
        return nullptr;

    Position pos;

    // ============================================================
    // Posicion
    // ============================================================

    if (!isA &&
        battle.isWildBattle)
    {
        pos =
            battle.wildSpawnPos;
    }
    else
    {
        float playerOrientation =
            player->GetOrientation();

        float dist =
            isA
            ? 2.0f
            : 4.0f;

        float x =
            player->GetPositionX() +
            dist *
            std::cos(playerOrientation);

        float y =
            player->GetPositionY() +
            dist *
            std::sin(playerOrientation);

        float z =
            player->GetPositionZ();

        pos =
            Position(
                x,
                y,
                z,
                playerOrientation);
    }

    // ============================================================
    // Buscar rival
    // ============================================================

    Creature* otherPet = nullptr;

    if (isA)
        otherPet =
        GetActiveSummonCreature(
            battle,
            false);
    else
        otherPet =
        GetActiveSummonCreature(
            battle,
            true);

    if (otherPet)
    {
        float dx =
            otherPet->GetPositionX() -
            pos.GetPositionX();

        float dy =
            otherPet->GetPositionY() -
            pos.GetPositionY();

        pos.SetOrientation(
            std::atan2(
                dy,
                dx));
    }

    // ============================================================
    // Invocar
    // ============================================================

    Creature* summon =
        player->SummonCreature(
            stats.mascotaID,
            pos,
            TEMPSUMMON_TIMED_DESPAWN,
            PET_SUMMON_MAX_DURATION_MS);

    if (!summon)
        return nullptr;

    // ============================================================
    // Las mascotas del Pet Battle son pasivas.
    // El movimiento y combate los controla PetBattleMgr.
    // ============================================================

    summon->SetReactState(
        REACT_PASSIVE);

    summon->CombatStop(
        true);

    summon->StopMoving();

    // ============================================================
    // Guardar GUID
    // ============================================================

    if (isA)
        battle.activeSummonA =
        summon->GetGUID();
    else
        battle.activeSummonB =
        summon->GetGUID();

    // ============================================================
    // Hacer que ambos se miren
    // ============================================================

    if (otherPet)
    {
        float dxToOther =
            otherPet->GetPositionX() -
            summon->GetPositionX();

        float dyToOther =
            otherPet->GetPositionY() -
            summon->GetPositionY();

        summon->SetOrientation(
            std::atan2(
                dyToOther,
                dxToOther));

        float dxToSummon =
            summon->GetPositionX() -
            otherPet->GetPositionX();

        float dyToSummon =
            summon->GetPositionY() -
            otherPet->GetPositionY();

        otherPet->SetOrientation(
            std::atan2(
                dyToSummon,
                dxToSummon));
    }

    // ============================================================
    // Animacion de aparicion
    // ============================================================

    uint32 visualSpellId =
        sConfigMgr->GetOption<uint32>(
            "PetBattle.SummonVisualSpellId",
            0);

    if (visualSpellId)
    {
        summon->CastSpell(
            summon,
            visualSpellId,
            true);
    }
    else
    {
        summon->HandleEmoteCommand(
            EMOTE_ONESHOT_EXCLAMATION);
    }

    return summon;
}

// ================================================================
// Obtener mascota activa
// ================================================================

Creature* PetBattleMgr::GetActiveSummonCreature(
    ActivePetBattle& battle,
    bool isA)
{
    ObjectGuid guid =
        isA
        ? battle.activeSummonA
        : battle.activeSummonB;

    if (guid.IsEmpty())
        return nullptr;

    Player* anchor =
        ObjectAccessor::FindPlayer(
            battle.playerA);

    if (!anchor)
    {
        anchor =
            ObjectAccessor::FindPlayer(
                battle.playerB);
    }

    if (!anchor)
        return nullptr;

    return ObjectAccessor::GetCreature(
        *anchor,
        guid);
}

// ================================================================
// Desaparecer mascota derrotada
// ================================================================

void PetBattleMgr::DespawnActivePetDefeated(
    ActivePetBattle& battle,
    bool isA)
{
    if (Creature* creature =
        GetActiveSummonCreature(
            battle,
            isA))
    {
        creature->HandleEmoteCommand(
            EMOTE_ONESHOT_WOUND_CRITICAL);

        creature->DespawnOrUnsummon(
            300ms);
    }

    if (isA)
        battle.activeSummonA.Clear();
    else
        battle.activeSummonB.Clear();
}

// ================================================================
// Desaparecer mascota
// ================================================================

void PetBattleMgr::DespawnActivePet(
    ActivePetBattle& battle,
    bool isA)
{
    if (Creature* creature =
        GetActiveSummonCreature(
            battle,
            isA))
    {
        creature->DespawnOrUnsummon();
    }

    if (isA)
        battle.activeSummonA.Clear();
    else
        battle.activeSummonB.Clear();
}
