/*
 * This file is part of the AzerothCore Project.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include "PetBattleMgr.h"

#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "Creature.h"
#include "GossipDef.h"
#include "Player.h"
#include "RBAC.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "Unit.h"
#include "WorldSession.h"

#include <algorithm>
#include <cctype>
#include <string>

using namespace Acore::ChatCommands;

// ================================================================
// Comando .dp
// ================================================================

class mod_pet_battle_commandscript : public CommandScript
{
public:
    mod_pet_battle_commandscript()
        : CommandScript("mod_pet_battle_commandscript")
    {
    }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            {
                "dp",
                HandleDpCommand,
                rbac::RBAC_PERM_COMMAND_HELP,
                Console::No
            }
        };

        return commandTable;
    }

    static bool HandleDpCommand(
        ChatHandler* handler,
        Optional<std::string> arg)
    {
        if (!handler)
            return false;

        Player* player = handler->GetSession()
            ? handler->GetSession()->GetPlayer()
            : nullptr;

        if (!player)
            return false;

        if (!sConfigMgr->GetOption<bool>(
            "PetBattle.Enable",
            true))
        {
            handler->PSendSysMessage(
                "%s",
                sPetBattleMgr
                ->GetText(player, PETTXT_SYSTEM_DISABLED)
                .c_str());

            return true;
        }

        // ------------------------------------------------------------
        // .dp aceptar
        // .dp rechazar
        // ------------------------------------------------------------

        if (arg && !arg->empty())
        {
            std::string sub = *arg;

            std::transform(
                sub.begin(),
                sub.end(),
                sub.begin(),
                [](unsigned char c)
                {
                    return static_cast<char>(
                        std::tolower(c));
                });

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

        // ------------------------------------------------------------
        // .dp
        //
        // La lógica real está centralizada en PetBattleMgr.
        // ------------------------------------------------------------

        sPetBattleMgr->StartBattleAgainstTarget(player);

        return true;
    }
};

// ================================================================
// PlayerScript
//
// Los gossip callbacks NO pertenecen a PlayerScript en AzerothCore.
// El sistema de gossip debe utilizar un CreatureScript.
//
// Esta clase solamente se encarga de hooks relacionados con Player.
// ================================================================

class mod_pet_battle_playerscript : public PlayerScript
{
public:
    mod_pet_battle_playerscript()
        : PlayerScript("mod_pet_battle_playerscript")
    {
    }

    // ------------------------------------------------------------
    // Cuando el jugador aprende una nueva mascota.
    // ------------------------------------------------------------

    void OnPlayerLearnSpell(
        Player* player,
        uint32 spellID) override
    {
        if (!player)
            return;

        if (!sConfigMgr->GetOption<bool>(
            "PetBattle.Enable",
            true))
        {
            return;
        }

        sPetBattleMgr->RegisterPetIfSummonSpell(
            player,
            spellID);
    }

    void OnPlayerLogout(Player* player) // o OnLogout, según versión
    {
        if (!player)
            return;
        sPetBattleMgr->HandleForfeit(player);
    }
    void OnPlayerUpdateZone(Player* player, uint32 newZone, uint32 newArea)
    {
        if (!player)
            return;
        sPetBattleMgr->HandleForfeit(player);
    }

    // ------------------------------------------------------------
    // Mensajes enviados por el addon.
    //
    // El cliente utiliza:
    //
    // SendAddonMessage(
    //     "PETBTL",
    //     mensaje,
    //     "WHISPER",
    //     UnitName("player")
    // )
    //
    // En AzerothCore el hook apropiado es
    // OnPlayerBeforeSendChatMessage().
    // ------------------------------------------------------------

    void OnPlayerBeforeSendChatMessage(
        Player* player,
        uint32& /*type*/,
        uint32& lang,
        std::string& msg) override
    {
        if (!player)
            return;

        if (lang != LANG_ADDON)
            return;

        // --------------------------------------------------------
        // Formato:
        //
        // PETBTL<TAB>accion|datos
        // --------------------------------------------------------

        size_t tab = msg.find('\t');

        if (tab == std::string::npos)
            return;

        if (msg.compare(
            0,
            tab,
            "PETBTL") != 0)
        {
            return;
        }

        std::string payload =
            msg.substr(tab + 1);

        if (payload.empty())
            return;

        sPetBattleMgr->HandleAddonMessage(
            player,
            payload);
    }
};

// ================================================================
// Gossip
//
// IMPORTANTE:
// En AzerothCore OnGossipSelect() pertenece a CreatureScript,
// no a PlayerScript.
//
// Por eso la clase anterior:
//     mod_pet_battle_gossip : PlayerScript
//
// era incorrecta.
// ================================================================

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

// ================================================================
// Registro del módulo
// ================================================================

void AddSC_mod_pet_battle()
{
    new mod_pet_battle_commandscript();
    new mod_pet_battle_gossip();
    new mod_pet_battle_playerscript();
}
