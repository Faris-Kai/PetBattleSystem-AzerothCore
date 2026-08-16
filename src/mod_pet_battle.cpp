#include "PetBattleMgr.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Config.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "Unit.h"
#include "Creature.h"
#include <algorithm>
#include <cctype>

using namespace Acore::ChatCommands;

class mod_pet_battle_commandscript : public CommandScript
{
public:
    mod_pet_battle_commandscript() : CommandScript("mod_pet_battle_commandscript") {}

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "dp", HandleDpCommand, SEC_PLAYER, Console::No },
        };
        return commandTable;
    }

    static bool HandleDpCommand(ChatHandler* handler, Optional<std::string> arg)
    {
        Player* player = handler->GetSession()->GetPlayer();
        if (!player)
            return false;

        if (!sConfigMgr->GetOption<bool>("PetBattle.Enable", true))
        {
            handler->PSendSysMessage(
                "{}",
                sPetBattleMgr->GetText(player, PETTXT_SYSTEM_DISABLED));
            return true;
        }

        // /dp aceptar | /dp rechazar
        if (arg && !arg->empty())
        {
            std::string sub = *arg;
            std::transform(sub.begin(), sub.end(), sub.begin(), ::tolower);

            if (sub == "aceptar")
            {
                sPetBattleMgr->HandleDuelAccept(player);
                return true;
            }
            if (sub == "rechazar")
            {
                sPetBattleMgr->HandleDuelDecline(player);
                return true;
            }
        }

        // /dp con un jugador seleccionado -> desafiar
        Unit* target = player->GetSelectedUnit();
        if (target && target->GetTypeId() == TYPEID_PLAYER && target != player)
        {
            sPetBattleMgr->StartDuelRequest(player, target->ToPlayer());
            return true;
        }

        // /dp con una criatura del mundo seleccionada (npc "alimania" u otra
        // criatura normal): primero verificamos si esa criatura es un
        // companero capturable (existe un hechizo de mascota que invoca ese
        // mismo entry). De ser asi, el duelo contra ella arranca solo.
        if (target && target->GetTypeId() == TYPEID_UNIT && target->ToCreature())
        {
            if (sPetBattleMgr->TryStartWildBattle(player, target->ToCreature()))
                return true;

            handler->PSendSysMessage(
                "{}",
                sPetBattleMgr->GetText(player, PETTXT_WILD_NOT_CAPTUREABLE));
            return true;
        }

        // /dp sin objetivo valido -> abrir menu de configuracion de equipo
        sPetBattleMgr->ShowTeamMenu(player);
        return true;
    }
};

class mod_pet_battle_gossip : public PlayerScript
{
public:
    mod_pet_battle_gossip() : PlayerScript("mod_pet_battle_gossip") {}

    void OnPlayerGossipSelect(Player* player, uint32 /*menu_id*/, uint32 sender, uint32 action) override
    {
        // Menu de configuracion de equipo (principal y sub-menu de eleccion)
        if (sender == 9001 || sender == 9002)
        {
            sPetBattleMgr->HandleTeamGossipAction(player, sender, action);
            return;
        }

        // Menu de tirada de dados
        if (sender == 9010)
        {
            if (ActivePetBattle* battle = sPetBattleMgr->GetBattleByPlayer(player->GetGUID()))
                sPetBattleMgr->HandleDiceRoll(player, *battle);
            return;
        }

        // Menu de seleccion de ataque
        if (sender == 9020)
        {
            if (ActivePetBattle* battle = sPetBattleMgr->GetBattleByPlayer(player->GetGUID()))
                sPetBattleMgr->HandleAttack(player, *battle, static_cast<uint8>(action));
            return;
        }

        // Popup de aceptar/rechazar duelo (se abre solo, sin que el jugador
        // tenga que escribir /dp aceptar o /dp rechazar)
        if (sender == 9030)
        {
            if (action == 1)
                sPetBattleMgr->HandleDuelAccept(player);
            else if (action == 2)
                sPetBattleMgr->HandleDuelDecline(player);
            else
                player->PlayerTalkClass->SendCloseGossip();
            return;
        }
    }
};

class mod_pet_battle_playerscript : public PlayerScript
{
public:
    mod_pet_battle_playerscript() : PlayerScript("mod_pet_battle_playerscript") {}

    // NOTA: en algunos forks/versiones recientes de AzerothCore este hook de
    // ScriptMgr se llama "OnPlayerLearnSpell" en lugar de "OnLearnSpell". Si
    // el modulo no compila por este metodo (override no encontrado), revisa
    // la firma exacta en tu propio PlayerScript.h y renombralo.
    void OnPlayerLearnSpell(Player* player, uint32 spellID) override
    {
        if (!sConfigMgr->GetOption<bool>("PetBattle.Enable", true))
            return;

        sPetBattleMgr->RegisterPetIfSummonSpell(player, spellID);
    }
    // ============================================================
    // Puente de addon messages (reemplaza los gossip)
    // ============================================================
    //
    // PetBattleUI utiliza SendAddonMessage() mediante WHISPER hacia
    // el propio jugador:
    //
    // SendAddonMessage("PETBTL", mensaje, "WHISPER", UnitName("player"))
    //
    // En AzerothCore, los whispers utilizan este overload de
    // OnPlayerCanUseChat() con Player* receiver.
    //

    bool OnPlayerCanUseChat(
        Player* player,
        uint32 /*type*/,
        uint32 lang,
        std::string& msg,
        Player* /*receiver*/) override
    {
        if (!player)
            return true;

        // Solo nos interesan mensajes enviados por el addon.
        if (lang != LANG_ADDON)
            return true;

        // Buscar el separador:
        //
        // PETBTL<TAB>accion|datos
        //
        size_t tab = msg.find('\t');

        if (tab == std::string::npos)
            return true;

        // Comprobar prefijo.
        if (msg.substr(0, tab) != "PETBTL")
            return true;

        // Entregar el contenido a PetBattleMgr.
        sPetBattleMgr->HandleAddonMessage(
            player,
            msg.substr(tab + 1));

        // No bloquear el mensaje.
        return true;
    }
};

void AddSC_mod_pet_battle()
{
    new mod_pet_battle_commandscript();
    new mod_pet_battle_gossip();
    new mod_pet_battle_playerscript();
}
