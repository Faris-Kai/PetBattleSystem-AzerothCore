-- ============================================================
-- PetBattleUI - Core.lua
-- ============================================================

PetBattleUI = {}

PetBattleUI.coinFlipped = false
PetBattleUI.inBattle = false

-- Vrai uniquement entre le moment ou le serveur annonce l'ouverture
-- imminente d'un menu gossip PetBattle (message addon "GOSSIPFLAG")
-- et le moment ou ce menu est effectivement masque. Sert a ne JAMAIS
-- toucher au gossip des autres PNJ/objets (quetes, guides, etc.).
PetBattleUI.expectingGossip = false

local ADDON_PREFIX = "PETBTL"


-- ============================================================
-- POSICIONES GUARDADAS
-- ============================================================

PetBattleUI_Settings =
    PetBattleUI_Settings or {}

PetBattleUI_Settings.framePos =
    PetBattleUI_Settings.framePos or {}


function PetBattleUI_SavePosition(frame)

    local point,
          _,
          relPoint,
          x,
          y =
        frame:GetPoint()

    PetBattleUI_Settings.framePos[
        frame:GetName()
    ] = {

        point = point,
        relPoint = relPoint,
        x = x,
        y = y

    }

end


function PetBattleUI_RestorePosition(frame)

    local data =
        PetBattleUI_Settings.framePos[
            frame:GetName()
        ]

    if data then

        frame:ClearAllPoints()

        frame:SetPoint(
            data.point,
            UIParent,
            data.relPoint,
            data.x,
            data.y
        )

    end

end


-- ============================================================
-- SPLIT
-- ============================================================

local function SplitMsg(msg)

    local parts = {}
    local pos = 1

    local sep =
        string.find(
            msg,
            ":",
            pos,
            true
        )

    while sep do

        table.insert(
            parts,
            string.sub(
                msg,
                pos,
                sep - 1
            )
        )

        pos =
            sep + 1

        sep =
            string.find(
                msg,
                ":",
                pos,
                true
            )

    end

    table.insert(
        parts,
        string.sub(msg, pos)
    )

    return parts

end


-- ============================================================
-- ENVIAR
-- ============================================================

function PetBattleUI:Send(msg)

    SendAddonMessage(
        ADDON_PREFIX,
        msg,
        "WHISPER",
        UnitName("player")
    )

end


-- ============================================================
-- BUSCAR CREATURE ID
-- ============================================================

local function GetCreatureIDFromSpellID(spellID)

    if not spellID then
        return nil
    end

    local numCompanions =
        GetNumCompanions("CRITTER")

    if not numCompanions then
        return nil
    end

    for index = 1, numCompanions do

        local creatureID,
              creatureName,
              creatureSpellID,
              icon =
            GetCompanionInfo(
                "CRITTER",
                index
            )

        if creatureSpellID
            and tonumber(creatureSpellID)
                == tonumber(spellID) then

            return creatureID

        end

    end

    return nil

end


-- ============================================================
-- MENSAJES DEL SERVIDOR
-- ============================================================

function PetBattleUI:OnServerMessage(msg)

    local p =
        SplitMsg(msg)

    local cmd =
        p[1]


    -- ========================================================
    -- FLAG GOSSIP (marque le prochain GOSSIP_SHOW comme etant
    -- un menu PetBattle, envoye par le serveur juste avant
    -- chaque SendGossipMenu de PetBattleMgr)
    -- ========================================================

    if cmd == "GOSSIPFLAG" then

        PetBattleUI.expectingGossip = true


    -- ========================================================
    -- DUELO
    -- ========================================================

    elseif cmd == "DUELREQ" then

        PetBattleUI_Duel_Show(
            p[2]
        )


    -- ========================================================
    -- MONEDA
    -- ========================================================

    elseif cmd == "COINRESULT" then

        PetBattleUI.coinFlipped = true

        PetBattleUI_Coin_Reveal(
            p[2]
        )


    elseif cmd == "COINRETRY" then

        PetBattleUI_Coin_Show()


    -- ========================================================
    -- BATTLE INIT
    -- ========================================================

    elseif cmd == "BATTLEINIT" then

        local wasInBattle =
            PetBattleUI.inBattle

        -- El campo 13 indica si el combate es contra una criatura
        -- salvaje ("1") o un duelo PvP ("0"/ausente). Contra una
        -- mascota salvaje no hay tirada de dados: la mascota salvaje
        -- ataca primero automaticamente, asi que no se muestra la
        -- pantalla de la moneda.
        local isWildBattle =
            p[13] == "1"


        PetBattleUI_Battle_Init(

            p[2],
            p[3],
            p[4],
            p[5],
            p[6],
            p[7],
            p[8],
            p[9],
			not wasInBattle

        )

		PetBattleUI_Battle_SetDamage(
			tonumber(p[10]),
			tonumber(p[11]),
			tonumber(p[12])
		)

        PetBattleUI.inBattle = true


        -- ====================================================
        -- MOSTRAR SIEMPRE NUESTRA INTERFAZ
        -- ====================================================

		ClearTarget()
		ClearFocus()

        PetBattleUI_Battle_Show()


        -- ====================================================
        -- COMBATE NUEVO
        -- ====================================================

        if not wasInBattle and not isWildBattle then

            PetBattleUI_Coin_Show()

        end


    -- ========================================================
    -- HP
    -- ========================================================

    elseif cmd == "HPUPDATE" then

        PetBattleUI_Battle_UpdateHP(
            p[2],
            tonumber(p[3]),
            tonumber(p[4])
        )

        -- Compatibilidad con el flujo actual:
        -- si nuestra mascota recibio daño, significa que la
        -- criatura salvaje termino su accion y podemos preparar
        -- nuestro turno.
        --
        -- TURN:mine seguira siendo la señal oficial cuando el
        -- C++ este actualizado.


    -- ========================================================
    -- TEXTE DE DEGATS/SOIN FLOTTANT
    -- ========================================================

    elseif cmd == "DMGTEXT" then

        PetBattleUI_Battle_ShowDamageText(
            p[2],
            tonumber(p[3]),
            p[4]
        )


    -- ========================================================
    -- TURNO
    -- ========================================================

    elseif cmd == "TURN" then

        PetBattleUI_Battle_SetTurn(
            p[2] == "mine"
        )


    -- ========================================================
    -- COOLDOWNS
    -- ========================================================

    elseif cmd == "ATKCD" then

        PetBattleUI_Battle_SetCooldowns(

            tonumber(p[2]),
            tonumber(p[3]),
            tonumber(p[4])

        )


    -- ========================================================
    -- FIN BATALLA
    -- ========================================================

    elseif cmd == "BATTLEEND" then

        PetBattleUI.coinFlipped = false
        PetBattleUI.inBattle = false
		PetBattleUI_Coin_Hide()

        PetBattleUI_Battle_End(
            p[2]
        )


    -- ========================================================
    -- ACCIONES DE MASCOTA
    -- ========================================================

    elseif cmd == "PET_ACTION_OK" then

        local action =
            p[2]

        local slot =
            p[3]

        local itemEntry =
            p[4]


        local text =
            "Operación realizada correctamente."


        if action == "FORGET" then

            text =
                "La mascota fue liberada."


        elseif action == "DETACH" then

            text =
                "La mascota fue enjaulada y convertida en objeto."


            if itemEntry then

                text =
                    text ..
                    " Item: " ..
                    itemEntry

            end


        elseif action == "REMOVE" then

            text =
                "La mascota fue quitada del equipo."

        end


        if PetBattleUI_Team_OnActionResult then

            PetBattleUI_Team_OnActionResult(

                true,
                tonumber(slot),
                text

            )

        end


    elseif cmd == "PET_ACTION_ERR" then

        local action =
            p[2]

        local text =
            p[3]
            or
            "No se pudo realizar la operación."


        if #p > 3 then

            for i = 4, #p do

                text =
                    text ..
                    ":" ..
                    p[i]

            end

        end


        if PetBattleUI_Team_OnActionResult then

            PetBattleUI_Team_OnActionResult(

                false,
                action,
                text

            )

        else

            DEFAULT_CHAT_FRAME:AddMessage(
			
                "|cffff4040[PetBattle]|r " ..
                text
			
            )

        end


    -- ========================================================
    -- ERROR EQUIPO
    -- ========================================================

    elseif cmd == "TEAMERR" then

        DEFAULT_CHAT_FRAME:AddMessage(
		
            "|cffff4040[PetBattle]|r " ..
            (
                p[2]
                or
                "No se pudo realizar la operacion."
            )
		
        )


    -- ========================================================
    -- OK EQUIPO
    -- ========================================================

    elseif cmd == "TEAMOK" then

        --DEFAULT_CHAT_FRAME:AddMessage(
		--
        --    "|cff40ff40[PetBattle]|r " ..
        --    (
        --        p[2]
        --        or
        --        "Operacion realizada correctamente."
        --    )
		--
        --)


    -- ========================================================
    -- SLOT VACÍO
    -- ========================================================

    elseif cmd == "TEAMCLEAR" then

        local slot =
            tonumber(p[2])

        if slot then

            PetBattleUI_Team_ClearSlot(
                slot
            )

        end


    -- ========================================================
    -- ACTUALIZACIÓN EQUIPO
    -- ========================================================

    elseif cmd == "TEAMUPDATE" then

        local slot =
            tonumber(p[2])

        local spellID =
            tonumber(p[3])

        local name =
            p[4]

        local icon =
            p[5]

        local tipo =
            p[6]

        local d1 =
            tonumber(p[7])

        local d2 =
            tonumber(p[8])

        local d3 =
            tonumber(p[9])

        local creatureID =
            tonumber(p[10])


        if slot and spellID then

            PetBattleUI_Team_SetServerSlot(

                slot,
                spellID,
                name,
                icon,
                tipo,
                d1,
                d2,
                d3,
                creatureID

            )

        end


        -- Actualizar daños de batalla.

        PetBattleUI_Battle_SetDamage(
            d1,
            d2,
            d3
        )

    end

end


-- ============================================================
-- SINCRONIZAR CD DESDE GOSSIP
-- ============================================================

local function PetBattleUI_SyncCooldownsFromGossip()

    if not GetGossipOptions then
        return
    end


    local cds = {
        0,
        0,
        0
    }


    local options = {
        GetGossipOptions()
    }


    for i = 1, #options, 2 do

        local text =
            options[i]


        if text then

            local index =
                tonumber(
                    string.match(
                        text,
                        "^Ataque (%d)"
                    )
                )


            if index
                and index >= 1
                and index <= 3 then

                local cd =
                    tonumber(
                        string.match(
                            text,
                            "%[CD:%s*(%d+)%s*tours?%]"
                        )
                    )


                cds[index] =
                    cd or 0

            end

        end

    end


    PetBattleUI_Battle_SetCooldowns(

        cds[1],
        cds[2],
        cds[3]

    )

end


-- ============================================================
-- OCULTAR GOSSIP
-- ============================================================

local function PetBattleUI_HideGossip()

    if GossipFrame then

        CloseGossip()

    end

end


-- ============================================================
-- EVENTOS
-- ============================================================

local eventFrame =
    CreateFrame("Frame")


eventFrame:RegisterEvent(
    "PLAYER_LOGIN"
)

eventFrame:RegisterEvent(
    "CHAT_MSG_ADDON"
)

eventFrame:RegisterEvent(
    "GOSSIP_SHOW"
)


eventFrame:SetScript(
    "OnEvent",
    function()

        -- ====================================================
        -- LOGIN
        -- ====================================================

        if event == "PLAYER_LOGIN" then

            if RegisterAddonMessagePrefix then
                RegisterAddonMessagePrefix(
                    ADDON_PREFIX
                )
            end

            PetBattleUI_RestorePosition(
                PetBattleUI_CoinFrame
            )


            PetBattleUI_RestorePosition(
                PetBattleUI_DuelButtonFrame
            )


            -- Habillage "grimoire" du Team frame (theme parchemin).
            -- Appele ici et pas depuis Team.xml : PLAYER_LOGIN est
            -- le premier point garanti d'etre execute APRES le
            -- chargement de tous les fichiers de l'addon (Team.xml
            -- se charge avant Team.lua dans le .toc, donc la fonction
            -- n'existerait pas encore si on l'appelait depuis son OnLoad).

            if PetBattleUI_Team_Skin then
                PetBattleUI_Team_Skin()
            end


        -- ====================================================
        -- CHAT ADDON
        -- ====================================================

        elseif event == "CHAT_MSG_ADDON" then

            local prefix =
                arg1

            local msg =
                arg2


            if prefix == ADDON_PREFIX then

                PetBattleUI:OnServerMessage(
                    msg
                )

            end


        -- ====================================================
        -- GOSSIP
        -- ====================================================

        elseif event == "GOSSIP_SHOW" then

            -- Solo actuamos si este gossip es de PetBattle.
            -- Si no, dejamos el GossipFrame normal (PNJ de quest,
            -- guias, objetos, etc.) intacto.

            if PetBattleUI.expectingGossip then

                -- Primero leemos los cooldowns.

                if PetBattleUI_BattleFrame:IsShown() then

                    PetBattleUI_SyncCooldownsFromGossip()

                end


                -- Luego ocultamos el Gossip.

                PetBattleUI_HideGossip()

            end

        end

    end
)


-- ============================================================
-- COMANDO DE EQUIPO
-- ============================================================

SLASH_PETBATTLETEAM1 =
    "/dpequipo"


SlashCmdList["PETBATTLETEAM"] =
    function()

        if PetBattleUI_TeamFrame:IsShown() then

            PetBattleUI_Team_Hide()

        else

            PetBattleUI_Team_Show()

        end

    end