#ifndef MOD_PET_BATTLE_MGR_H
#define MOD_PET_BATTLE_MGR_H

#include "ObjectGuid.h"
#include "Position.h"
#include <map>
#include <unordered_map>
#include <array>
#include <string>
#include <initializer_list>

class Player;
class Creature;

// ================================================================
// Tipos elementales de las mascotas
// ================================================================
// Triangulo 1: Agua > Fuego > Tierra > Agua (x2 dano)
// Triangulo 2: Oscuridad > Basico > Luz > Oscuridad (x2 dano)
enum PetElementType : uint8
{
    PET_TIPO_AGUA = 0,
    PET_TIPO_TIERRA = 1,
    PET_TIPO_FUEGO = 2,
    PET_TIPO_LUZ = 3,
    PET_TIPO_OSCURIDAD = 4,
    PET_TIPO_BASICO = 5,

    PET_TIPO_MAX = 6
};

struct PetBattleStats
{
    uint32 mascotaID = 0;
    uint32 spellID = 0;
    uint32 itemEntry = 0;
    uint32 vidaMax = 0;
    uint32 vidaActual = 0;
    uint8  tipo = 0;
    uint32 daño1 = 0;
    uint32 daño2 = 0;
    uint32 daño3 = 0;

    // Cooldown restante de cada habilidad.
    //
    // 0 = disponible
    // 1 = falta un turno
    // 2 = falta dos turnos
    //
    // El cooldown solamente se aplica cuando el ataque conecta.
    uint8 cooldown1 = 0;
    uint8 cooldown2 = 0;
    uint8 cooldown3 = 0;

    uint8 GetCooldown(uint8 attackIndex) const
    {
        switch (attackIndex)
        {
        case 1:
            return cooldown1;

        case 2:
            return cooldown2;

        case 3:
            return cooldown3;

        default:
            return 0;
        }
    }

    void SetCooldown(uint8 attackIndex, uint8 turns)
    {
        switch (attackIndex)
        {
        case 1:
            cooldown1 = turns;
            break;

        case 2:
            cooldown2 = turns;
            break;

        case 3:
            cooldown3 = turns;
            break;

        default:
            break;
        }
    }

    void TickCooldowns()
    {
        if (cooldown1 > 0)
            --cooldown1;

        if (cooldown2 > 0)
            --cooldown2;

        if (cooldown3 > 0)
            --cooldown3;
    }
};

struct PetBattleTeamSlot
{
    uint32 creatureEntry = 0;
    std::string nombre;
};

struct ActivePetBattle
{
    ObjectGuid playerA;
    ObjectGuid playerB;
    uint32 turnTimeoutToken = 0;

    std::array<PetBattleStats, 3> teamA;
    std::array<PetBattleStats, 3> teamB;

    uint8 activeIndexA = 0;
    uint8 activeIndexB = 0;

    // GUID de la mascota actualmente invocada en el mundo para cada lado.
    ObjectGuid activeSummonA;
    ObjectGuid activeSummonB;

    // Jugador al que le corresponde el turno cuando el combate esta en
    // estado normal. Durante una secuencia de ataque el turno se resuelve
    // mediante los callbacks de movimiento/animacion.
    ObjectGuid turnPlayer;

    bool   diceRolled = false;
    uint32 diceA = 0;
    uint32 diceB = 0;

    bool finished = false;
    ObjectGuid winner;

    // ---- Datos de "duelo salvaje" ----
    bool   isWildBattle = false;
    uint32 wildCreatureEntry = 0;
    uint32 wildSummonSpellID = 0;
    ObjectGuid wildSourceGuid;
    Position   wildSpawnPos;
};

enum PetBattleLocaleTextId : uint32
{
    PETTXT_SYSTEM_DISABLED = 1,
    PETTXT_ALREADY_BATTLE,
    PETTXT_WILD_NEED_SLOT1,
    PETTXT_WILD_START,
    PETTXT_SLOT_LABEL,
    PETTXT_EMPTY,
    PETTXT_CLEAR_TEAM,
    PETTXT_SAVE_TEAM,
    PETTXT_PET_FALLBACK,
    PETTXT_NO_PETS,
    PETTXT_BACK,
    PETTXT_DUPLICATE_SLOT,
    PETTXT_PET_ASSIGNED,
    PETTXT_TEAMERR_INVALID,
    PETTXT_REMOVE_EMPTY,
    PETTXT_REMOVE_CHAT,
    PETTXT_FORGET_EMPTY,
    PETTXT_FORGET_CHAT,
    PETTXT_DETACH_NO_DATA,
    PETTXT_DETACH_NO_SOURCE,
    PETTXT_DETACH_ITEM_MISSING,
    PETTXT_DETACH_BAGS,
    PETTXT_DETACH_BAG_CHAT,
    PETTXT_DETACH_CREATE,
    PETTXT_DETACH_CHAT,
    PETTXT_DUEL_ALREADY,
    PETTXT_TARGET_ALREADY,
    PETTXT_CHALLENGER_NO_SLOT,
    PETTXT_TARGET_NO_SLOT,
    PETTXT_CHALLENGE_SENT,
    PETTXT_CHALLENGE_RECEIVED,
    PETTXT_NO_PENDING,
    PETTXT_CHALLENGER_GONE,
    PETTXT_ALREADY_DUEL,
    PETTXT_DUEL_CANCEL,
    PETTXT_DUEL_STARTED,
    PETTXT_CHALLENGE_REJECTED,
    PETTXT_DUEL_REJECTED,
    PETTXT_FORFEIT_ADDON,
    PETTXT_FORFEIT_CHAT,
    PETTXT_TEAM_MODIFIED,
    PETTXT_TEAM_MODIFIED_WILD_ADDON,
    PETTXT_TEAM_MODIFIED_WILD_CHAT,
    PETTXT_TIMEOUT_WILD_ADDON,
    PETTXT_TIMEOUT_WILD_CHAT,
    PETTXT_TIMEOUT_PVP,
    PETTXT_ROLL_MENU,
    PETTXT_ROLL_RESULT,
    PETTXT_ROLL_DRAW,
    PETTXT_ROLL_WINNER,
    PETTXT_ATTACK_INFO,
    PETTXT_ATTACK_BUTTON,
    PETTXT_COOLDOWN,
    PETTXT_WILD_PET_NAME,
    PETTXT_ATTACK_MISS,
    PETTXT_EFFECTIVE,
    PETTXT_ATTACK_HIT,
    PETTXT_PET_DEFEATED,
    PETTXT_VICTORY,
    PETTXT_DEFEAT,
    PETTXT_XP,
    PETTXT_CAPTURE_NO_CREATURE,
    PETTXT_CAPTURE_NO_MODEL,
    PETTXT_CAPTURE_NO_ITEMS,
    PETTXT_CAPTURE_NO_MATCH,
    PETTXT_CAPTURE_NO_SPACE,
    PETTXT_CAPTURE_SUCCESS,
    PETTXT_TYPE_WATER,
    PETTXT_TYPE_EARTH,
    PETTXT_TYPE_FIRE,
    PETTXT_TYPE_LIGHT,
    PETTXT_TYPE_DARKNESS,
    PETTXT_TYPE_BASIC,
    PETTXT_TYPE_UNKNOWN,
    PETTXT_WILD_NOT_CAPTUREABLE
};

class PetBattleMgr
{
public:
    static PetBattleMgr* instance();

    // Texto localizado para el idioma del cliente del jugador.
    std::string GetText(Player* player, uint32 textId) const;
    std::string GetTextFmt(Player* player, uint32 textId,
        std::initializer_list<std::string> args) const;
    std::string GetTipoName(Player* player, uint8 tipo) const;
    std::string GetCreatureName(Player* player, uint32 creatureEntry) const;
    //detectar modificación equipo
    void HandleForfeit(Player* player);
    void HandleTeamModifiedInBattle(Player* player, ActivePetBattle& battle); // <-- nuevo
    //tiempo limite turno
    void ScheduleTurnTimeout(ActivePetBattle& battle);
    void HandleTurnTimeout(ObjectGuid battleKey, ObjectGuid turnPlayerGuid, uint32 token);
    // ---- Persistencia de equipos ----
    void LoadPlayerTeam(ObjectGuid::LowType guidLow, std::array<PetBattleTeamSlot, 3>& outTeam);
    void SavePlayerTeamSlot(ObjectGuid::LowType guidLow, uint8 slotIndex /*0-2*/, uint32 creatureEntry);
    void ClearPlayerTeam(ObjectGuid::LowType guidLow);

    // ---- Estadisticas de mascotas ----
    bool GetPetStats(ObjectGuid::LowType guidLow, uint32 creatureEntry, PetBattleStats& out);

    void CreatePetStats(
        ObjectGuid::LowType guidLow,
        uint32 spellID,
        uint32 creatureEntry);

    void RegisterPetIfSummonSpell(
        Player* player,
        uint32 spellID);

    // ---- Utilidades de tipo elemental ----
    static float GetTypeMultiplier(
        uint8 attackerType,
        uint8 defenderType);

    static bool IsAttackerAtTypeDisadvantage(
        uint8 attackerType,
        uint8 defenderType);

    static uint32 ResolveHitDamage(
        PetBattleStats const& attacker,
        PetBattleStats const& defender,
        uint32 danoBase,
        bool& outMissed,
        bool& outSuperEfectivo);

    // ---- Menu de configuracion de equipo ----
    void ShowTeamMenu(Player* player);

    void HandleTeamGossipAction(
        Player* player,
        uint32 sender,
        uint32 action);

    // ---- Retos PvP ----
    bool StartDuelRequest(
        Player* challenger,
        Player* target);

    void HandleDuelAccept(Player* target);
    void HandleDuelDecline(Player* target);

    // ---- Reto contra criatura del mundo ----
    bool TryStartWildBattle(
        Player* player,
        Creature* creature);

    // Busca un hechizo de companion cuyo modelo coincida con el modelo
    // de la criatura del mundo.
    uint32 FindPetSummonSpellForCreatureEntry(
        uint32 creatureEntry);

    void ShowDuelChallengeMenu(
        Player* target,
        Player* challenger);

    // ---- Flujo de batalla ----
    void ShowDiceMenu(
        Player* player,
        ActivePetBattle& battle);

    void HandleDiceRoll(
        Player* player,
        ActivePetBattle& battle);

    void ShowAttackMenu(
        Player* player,
        ActivePetBattle& battle);

    void HandleAttack(
        Player* player,
        ActivePetBattle& battle,
        uint8 attackIndex);

    // Resuelve el daño de un ataque individual.
    bool ResolveAttackAndAdvance(
        ActivePetBattle& battle,
        bool attackerIsA,
        uint32 danoBase,
        uint8 attackIndex,
        Player* attackerPlayer);

    void EndBattle(
        ActivePetBattle& battle,
        ObjectGuid winnerGuid,
        ObjectGuid loserGuid);

    // Cerrar la ventana del combate equivale a abandonar la batalla.
    // El jugador que abandona pierde inmediatamente.

    // ---- Batallas activas ----
    ActivePetBattle* GetBattleByPlayer(
        ObjectGuid playerGuid);

    // ============================================================
    // Puente de addon messages (reemplaza los gossip)
    // ============================================================
    //
    // Punto de entrada unico para todo lo que llega del addon
    // PetBattleUI (prefijo "PETBTL"). payload ya viene sin el
    // prefijo ni el tab, tal como lo separa mod_pet_battle.cpp.
    void HandleAddonMessage(
        Player* player,
        std::string const& payload);

    void RemovePetFromTeam(
        Player* player,
        uint8 slotIndex);

    void ForgetPet(
        Player* player,
        uint8 slotIndex);

    void ConvertPetToItem(
        Player* player,
        uint8 slotIndex);

    // Busca el item que representa a una mascota al "desligarla".
    // La relacion se define en world.pet_battle_detach_items.
    uint32 GetDetachItemEntry(uint32 creatureEntry) const;
private:
    // Envia un mensaje al addon del cliente (prefijo PETBTL).
    void SendAddonMsg(
        Player* player,
        std::string const& msg);

    // Envia al addon el equipo completo tal como esta guardado en
    // equipo_mascotas/estatus_mascotas (los 3 slots, con nombre,
    // tipo y daños). Se usa para que la UI del addon siempre
    // refleje el equipo actual al abrir la ventana de Companeros,
    // en vez de depender solo de lo que el cliente pinto de forma
    // optimista durante la sesion.
    void SendFullTeamToClient(
        Player* player);

    // Envia BATTLEINIT a "viewer" con los datos de su propia mascota
    // activa y la del rival, desde su punto de vista.
    void SendBattleInit(
        Player* viewer,
        ActivePetBattle& battle,
        bool viewerIsA);

    // Busca el creatureEntry que invoca un hechizo de companero
    // (usado para traducir el spellID que manda el addon al
    // arrastrar y soltar, al mismo entry que usa equipo_mascotas).
    uint32 FindCreatureEntryForSpell(
        uint32 spellID);

    struct LocaleTextRow
    {
        std::string enUS;
        std::string esES;
        std::string frFR;
        std::string deDE;
    };

    void EnsureLocaleTextsLoaded() const;
    std::string GetDefaultText(uint32 textId) const;

    mutable bool _localeTextsLoaded = false;
    mutable std::unordered_map<uint32, LocaleTextRow> _localeTexts;

    // ============================================================
    // Almacenamiento de batallas
    // ============================================================

    std::map<ObjectGuid, ActivePetBattle> _activeBattles;

    std::map<ObjectGuid, ObjectGuid> _pendingChallenges;

    // DisplayID -> SpellID
    //
    // IMPORTANTE:
    // Aunque el nombre original era _petSpellIndexByEntry, ahora el
    // indice se basa en el MODELO de la criatura.
    std::unordered_map<uint32, uint32> _petSpellIndexByEntry;

    bool _petSpellIndexBuilt = false;

    void EnsurePetSpellIndexBuilt();

    // ============================================================
    // Secuencia visual de ataque
    // ============================================================
    //
    // Flujo:
    //
    //   posicion inicial
    //        ↓
    //   acercarse al rival
    //        ↓
    //   animacion de ataque
    //        ↓
    //   resolver daño
    //        ↓
    //   regresar a posicion inicial
    //        ↓
    //   siguiente turno / siguiente ataque
    //
    // Los retrasos se programan sobre m_Events de la criatura
    // atacante, evitando bloquear el worldserver.
    // ============================================================

    uint8 SelectAvailableAttack(PetBattleStats const& pet) const;

    void StartPetAttack(
        ActivePetBattle& battle,
        bool attackerIsA,
        uint32 danoBase,
        uint8 attackIndex,
        Player* attackerPlayer);

    void SendPetChatFeedback(
        Player* p1,
        Player* p2,
        std::string const& msg);

    void SendPetChatFeedbackLocalized(
        Player* p1,
        Player* p2,
        uint32 textId,
        std::initializer_list<std::string> args = {});

    // ============================================================
    // Recompensas
    // ============================================================

    void GrantBattleExperience(
        Player* winner,
        bool vsWild);

    void GrantWildCaptureReward(
        Player* winner,
        ActivePetBattle const& battle);

    // ============================================================
    // Feedback de daño
    // ============================================================

    void ShowFloatingDamageNumber(
        Creature* target,
        Player* attacker,
        Player* defenderOwner,
        uint32 damage,
        bool missed,
        bool critEffective);

    // ============================================================
    // Invocacion / desaparicion
    // ============================================================

    Creature* SummonActivePet(
        Player* player,
        ActivePetBattle& battle,
        bool isA);

    Creature* GetActiveSummonCreature(
        ActivePetBattle& battle,
        bool isA);

    void DespawnActivePet(
        ActivePetBattle& battle,
        bool isA);

    void DespawnActivePetDefeated(
        ActivePetBattle& battle,
        bool isA);
};

#define sPetBattleMgr PetBattleMgr::instance()

#endif // MOD_PET_BATTLE_MGR_H
