-- ============================================================
-- PetBattleUI - Battle.lua
-- ============================================================


-- ============================================================
-- ICONOS SEGUN DAÑO
-- ============================================================

--Cura
local ATTACK_ICON_LOW =
    "Interface\\Icons\\Spell_nature_healingtouch"--Cura
local ATTACK_ICON_LOL =
    "Interface\\Icons\\Achievement_character_troll_male"
--Daño normal
local ATTACK_ICON_NORMAL =
    "Interface\\Icons\\ability_druid_catform"
--Daño brutal
local ATTACK_ICON_HIGH =
    "Interface\\Icons\\spell_holy_excorcism_02"


-- ============================================================
-- COLOR DORADO
-- ============================================================

local ATTACK_GOLD_R = 1.0
local ATTACK_GOLD_G = 1.0
local ATTACK_GOLD_B = 1.0


-- ============================================================
-- BOTONES / ICONOS
-- ============================================================

local ATTACK_ICONS = {
    PetBattleUI_AttackIcon1,
    PetBattleUI_AttackIcon2,
    PetBattleUI_AttackIcon3,
}


-- ============================================================
-- BARRE DE SORTS SYPHRENA_ACTIONBAR (masquee pendant le combat)
-- ============================================================
-- pUiMainBar est la barre principale creee par l'addon
-- Syphrena_actionbar (nom global attribue via CreateFrame). On la
-- cache a l'entree en combat de mascotte et on ne la reaffiche a
-- la sortie que si c'est nous qui l'avions cachee (on ne force
-- jamais un affichage si le joueur l'avait deja cachee lui-meme).

local actionBarWasHiddenByUs = false

local function PetBattleUI_HideActionBar()

    local bar = _G["pUiMainBar"]

    if bar and bar:IsShown() then

        bar:Hide()
        actionBarWasHiddenByUs = true

    end

end

local function PetBattleUI_RestoreActionBar()

    local bar = _G["pUiMainBar"]

    if bar and actionBarWasHiddenByUs then

        bar:Show()

    end

    actionBarWasHiddenByUs = false

end


-- ============================================================
-- MINIMAP SYPHRENA_MINIMAP (masquee pendant le combat)
-- ============================================================
-- Syphrena_minimap ne cree pas son propre cadre : il retexture le
-- cadre Blizzard standard "Minimap", qui vit lui-meme dans le
-- conteneur standard "MinimapCluster" (zone, mail, pistage, etc.
-- sont tous rattaches a ce conteneur). On cache donc MinimapCluster,
-- ce qui fonctionne que l'addon minimap soit installe ou non.

local minimapWasHiddenByUs = false

local function PetBattleUI_HideMinimap()

    local cluster = _G["MinimapCluster"]

    if cluster and cluster:IsShown() then

        cluster:Hide()
        minimapWasHiddenByUs = true

    end

end

local function PetBattleUI_RestoreMinimap()

    local cluster = _G["MinimapCluster"]

    if cluster and minimapWasHiddenByUs then

        cluster:Show()

    end

    minimapWasHiddenByUs = false

end


-- ============================================================
-- NOTIFICATION "DEBUT DE COMBAT" (icone + texte au centre de
-- l'ecran, affichee brievement au moment ou le combat commence)
-- ============================================================
-- Duree totale d'affichage, puis debut du fondu, en secondes.
-- Aucun C_Timer sur ce client (3.3.5a) : minuteur maison via
-- OnUpdate, meme pattern que le timer d'activation des attaques
-- plus bas dans ce fichier.

local FIGHT_NOTIF_TOTAL_DURATION = 1.8
local FIGHT_NOTIF_FADE_DURATION = 0.5

local fightNotifTimeLeft = 0

-- N'affiche la notification qu'une seule fois par combat : en duel
-- JcJ, PetBattleUI_Battle_Show() est appelee 2 fois (une fois a
-- BATTLEINIT, une fois de plus apres l'animation de la piece par
-- Coin.lua) -- sans ce garde-fou, le texte apparaitrait deux fois.
local fightNotifShownThisBattle = false

local function PetBattleUI_ShowFightStartNotif()

    local frame =
        PetBattleUI_FightStartNotif

    local text =
        PetBattleUI_FightStartText

    if not frame or not text then
        return
    end


    text:SetText(
        (PetBattleUI_Locale and PetBattleUI_Locale.FIGHT_START)
        or "Start Fight"
    )

    text:SetFont(
        "Fonts\\FRIZQT__.TTF",
        28,
        "THICKOUTLINE"
    )

    text:SetTextColor(1.0, 1.0, 1.0)


    frame:SetAlpha(1)
    frame:Show()

    fightNotifTimeLeft =
        FIGHT_NOTIF_TOTAL_DURATION

end


local function PetBattleUI_ShowFightStartNotifOnce()

    if fightNotifShownThisBattle then
        return
    end

    fightNotifShownThisBattle = true

    PetBattleUI_ShowFightStartNotif()

end


local fightNotifTimerFrame =
    CreateFrame("Frame")


fightNotifTimerFrame:SetScript(
    "OnUpdate",
    function(self, elapsed)

        if fightNotifTimeLeft <= 0 then
            return
        end

        fightNotifTimeLeft =
            fightNotifTimeLeft - elapsed

        if fightNotifTimeLeft <= 0 then

            fightNotifTimeLeft = 0

            if PetBattleUI_FightStartNotif then
                PetBattleUI_FightStartNotif:Hide()
            end

            return

        end


        -- Fondu de sortie durant les FIGHT_NOTIF_FADE_DURATION
        -- dernieres secondes.

        if fightNotifTimeLeft <= FIGHT_NOTIF_FADE_DURATION
            and PetBattleUI_FightStartNotif then

            PetBattleUI_FightStartNotif:SetAlpha(
                fightNotifTimeLeft / FIGHT_NOTIF_FADE_DURATION
            )

        end

    end
)


-- ============================================================
-- TEXTE DE DEGATS/SOIN FLOTTANT (au-dessus des barres de vie)
-- ============================================================
-- Meme technique de minuteur maison (OnUpdate) que la notification
-- "C'est parti !" ci-dessus, faute de C_Timer sur ce client 3.3.5a.
-- Chaque cote (mine/enemy) a son propre etat pour pouvoir s'animer
-- independamment l'un de l'autre.

local DMG_TEXT_DURATION =
    5

local DMG_TEXT_RISE_PIXELS =
    30

local dmgTextState = {

    mine = {
        timeLeft = 0,
        baseY = -41
    },

    enemy = {
        timeLeft = 0,
        baseY = -41
    }

}

local DMG_TEXT_COLORS = {

    hit = { 1.0, 0.15, 0.15 },
    crit = { 1.0, 0.65, 0.0 },
    heal = { 0.2, 1.0, 0.3 },
    miss = { 0.8, 0.8, 0.8 }

}


function PetBattleUI_Battle_ShowDamageText(
    side,
    amount,
    dmgType
)

    local fontString =
        (side == "mine")
        and PetBattleUI_MyDamageText
        or PetBattleUI_EnemyDamageText

    local state =
        dmgTextState[side]

    if not fontString or not state then
        return
    end


    -- ========================================================
    -- TEXTE
    -- ========================================================

    local text

    if dmgType == "miss" then

        text =
            (PetBattleUI_Locale and PetBattleUI_Locale.MISS_TEXT)
            or "Miss!"

    elseif dmgType == "heal" then

        text =
            "+" .. tostring(amount or 0)

    else

        text =
            "-" .. tostring(amount or 0)

    end


    -- ========================================================
    -- COULEUR
    -- ========================================================

    local color =
        DMG_TEXT_COLORS[dmgType]
        or DMG_TEXT_COLORS.hit

    fontString:SetTextColor(
        color[1],
        color[2],
        color[3]
    )


    -- ========================================================
    -- AFFICHAGE (position de depart)
    -- ========================================================

    fontString:SetText(text)
    fontString:SetAlpha(1)

    fontString:ClearAllPoints()

    fontString:SetPoint(
        "BOTTOM",
        (side == "mine")
            and PetBattleUI_MyHealthBar
            or PetBattleUI_EnemyHealthBar,
        "TOP",
        0,
        state.baseY
    )

    fontString:Show()

    state.timeLeft =
        DMG_TEXT_DURATION

end


local dmgTextTimerFrame =
    CreateFrame("Frame")


dmgTextTimerFrame:SetScript(
    "OnUpdate",
    function(self, elapsed)

        for side, state in pairs(dmgTextState) do

            if state.timeLeft > 0 then

                state.timeLeft =
                    state.timeLeft - elapsed

                local fontString =
                    (side == "mine")
                    and PetBattleUI_MyDamageText
                    or PetBattleUI_EnemyDamageText

                if fontString then

                    if state.timeLeft <= 0 then

                        state.timeLeft = 0
                        fontString:Hide()

                    else

                        local progress =
                            1 - (state.timeLeft / DMG_TEXT_DURATION)

                        fontString:SetAlpha(
                            state.timeLeft / DMG_TEXT_DURATION
                        )

                        fontString:ClearAllPoints()

                        fontString:SetPoint(
                            "BOTTOM",
                            (side == "mine")
                                and PetBattleUI_MyHealthBar
                                or PetBattleUI_EnemyHealthBar,
                            "TOP",
                            0,
                            state.baseY + (progress * DMG_TEXT_RISE_PIXELS)
                        )

                    end

                end

            end

        end

    end
)


-- ============================================================
-- TEXTURAS
-- ============================================================

local ATTACK_ICON_TEXTURES = {
    PetBattleUI_AttackIcon1Texture,
    PetBattleUI_AttackIcon2Texture,
    PetBattleUI_AttackIcon3Texture,
}


-- ============================================================
-- TEXTOS DE DAÑO
-- ============================================================

local ATTACK_DAMAGE_TEXTS = {
    PetBattleUI_AttackDamage1,
    PetBattleUI_AttackDamage2,
    PetBattleUI_AttackDamage3,
}


-- ============================================================
-- TEXTOS DE COOLDOWN
-- ============================================================

local ATTACK_CD_TEXTS = {
    PetBattleUI_AttackCD1,
    PetBattleUI_AttackCD2,
    PetBattleUI_AttackCD3,
}


-- ============================================================
-- ESTADO DE BATALLA
-- ============================================================

PetBattleUI_Battle =
    PetBattleUI_Battle or {}


PetBattleUI_Battle.isPlayerTurn =
    false


-- ============================================================
-- COOLDOWNS
-- ============================================================

PetBattleUI_Battle.cooldowns = {
    0,
    0,
    0
}


-- ============================================================
-- DAÑOS
-- ============================================================

PetBattleUI_Battle.damages = {
    0,
    0,
    0
}


-- ============================================================
-- TEMPORIZADOR DE ESPERA DEL TURNO
-- ============================================================

local playerTurnEnableTimer =
    0


-- ============================================================
-- TEMPORIZADORES INDIVIDUALES
-- ============================================================

local attackEnableTimers = {
    0,
    0,
    0
}


-- ============================================================
-- ESPERA DE ACTIVACION
-- ============================================================

local attackWaiting = {
    false,
    false,
    false
}


-- ============================================================
-- ATAQUES ACTIVOS
-- ============================================================

local attackActive = {
    false,
    false,
    false
}


-- ============================================================
-- OBTENER ICONO SEGUN DAÑO
-- ============================================================

local function GetAttackIcon(damage)

    damage =
        tonumber(damage) or 0


    -- ========================================================
    -- MENOR A 0 - CURA
    -- ========================================================

    if damage < 0 then

        return ATTACK_ICON_LOW

    end


    -- ========================================================
    -- DAÑO 0
    -- ========================================================

    if damage == 0 then

        return ATTACK_ICON_LOL

    end


    -- ========================================================
    -- 1 A 20
    -- ========================================================

    if damage <= 20 then

        return ATTACK_ICON_NORMAL

    end


    -- ========================================================
    -- MAS DE 20
    -- ========================================================

    return ATTACK_ICON_HIGH

end


-- ============================================================
-- ACTUALIZAR ICONO INDIVIDUAL
-- ============================================================

local function UpdateAttackIcon(index)

    local texture =
        ATTACK_ICON_TEXTURES[index]


    if not texture then
        return
    end


    local damage =
        PetBattleUI_Battle.damages[index] or 0


    texture:SetTexture(
        GetAttackIcon(damage)
    )


    -- ========================================================
    -- COLOR NORMAL DEL ICONO
    --
    -- El color dorado se aplica mediante SetVertexColor.
    -- No modifica la textura original.
    -- ========================================================

    texture:SetVertexColor(
        ATTACK_GOLD_R,
        ATTACK_GOLD_G,
        ATTACK_GOLD_B
    )


    texture:Show()

end


-- ============================================================
-- ACTUALIZAR TODOS LOS ICONOS
-- ============================================================

local function UpdateAllAttackIcons()

    for i = 1, 3 do

        UpdateAttackIcon(i)

    end

end


-- ============================================================
-- ACTUALIZAR DAÑO INDIVIDUAL
-- ============================================================

local function UpdateAttackDamage(index)

    local text =
        ATTACK_DAMAGE_TEXTS[index]


    if not text then
        return
    end


    local damage =
        PetBattleUI_Battle.damages[index] or 0


    -- ========================================================
    -- CURACION
    --
    -- Los valores negativos representan curacion.
    --
    -- Ejemplo:
    --     -10 -> mostrar 10 en verde
    --     -15 -> mostrar 15 en verde
    --
    -- math.abs() elimina el signo negativo visualmente.
    -- ========================================================

    if damage < 0 then

        text:SetText(
            tostring(
                math.abs(damage)
            )
        )


        text:SetTextColor(
            0.2,
            1.0,
            0.2
        )


    -- ========================================================
    -- DAÑO BAJO
    --
    -- 1 a 19 = amarillo
    -- ========================================================

    elseif damage >= 1 and damage < 20 then

        text:SetText(
            tostring(damage)
        )


        text:SetTextColor(
            1.0,
            1.0,
            0.0
        )


    -- ========================================================
    -- DAÑO ALTO
    --
    -- 20 o más = rojo
    -- ========================================================

    elseif damage >= 20 then

        text:SetText(
            tostring(damage)
        )


        text:SetTextColor(
            1.0,
            0.1,
            0.1
        )


    -- ========================================================
    -- CERO
    -- ========================================================

    else

        text:SetText(
            tostring(damage)
        )


        text:SetTextColor(
            1.0,
            1.0,
            1.0
        )

    end


    text:Show()

end


-- ============================================================
-- ACTUALIZAR TODOS LOS DAÑOS
-- ============================================================

local function UpdateAllAttackDamage()

    for i = 1, 3 do

        UpdateAttackDamage(i)

    end

end


-- ============================================================
-- ACTIVAR / DESACTIVAR ICONO
-- ============================================================

local function SetAttackIconEnabled(
    index,
    enabled
)

    local button =
        ATTACK_ICONS[index]


    local texture =
        ATTACK_ICON_TEXTURES[index]


    -- L'UI utilise desormais l'image custom BattlePetUI_Clean.tga comme
    -- fond unique (cadres des sorts deja peints dedans) : il n'y a plus
    -- de texture de cadre separee dans le XML. Cette variable reste nil
    -- et le bloc "if border then" ci-dessous ne s'execute simplement
    -- pas -- code laisse en place pour rester compatible si un cadre
    -- separe est reintroduit plus tard.
    local border =
        _G["PetBattleUI_AttackIcon" .. index .. "Border"]


    if not button then
        return
    end


    -- ========================================================
    -- ACTIVAR
    -- ========================================================

    if enabled then

        button:Enable()


        if texture then

            texture:SetAlpha(1)

            texture:SetVertexColor(
                ATTACK_GOLD_R,
                ATTACK_GOLD_G,
                ATTACK_GOLD_B
            )

        end


        if border then

            -- Teinte doree (le fichier stock reste le meme, on ne
            -- change jamais de texture -- zero risque de chargement).
            border:SetVertexColor(
                1.0, 0.85, 0.35
            )

            border:SetAlpha(1)

        end


        attackActive[index] =
            true


    -- ========================================================
    -- DESACTIVAR
    -- ========================================================

    else

        button:Disable()


        if texture then

            texture:SetAlpha(0.35)

            texture:SetVertexColor(
                ATTACK_GOLD_R,
                ATTACK_GOLD_G,
                ATTACK_GOLD_B
            )

        end


        if border then

            -- Teinte grise/terne pour l'etat indisponible -- meme
            -- fichier stock, meme raisonnement.
            border:SetVertexColor(
                0.55, 0.55, 0.58
            )

            border:SetAlpha(0.7)

        end


        attackActive[index] =
            false

    end

end


-- ============================================================
-- ACTIVAR/DESACTIVAR LE BOUTON "PASSER"
-- ============================================================
-- Contrairement aux 3 attaques, "Passer" n'a jamais de cooldown :
-- il est actif des que c'est notre tour (apres le meme delai de
-- 2s de securite) et desactive le reste du temps.

local function SetPassButtonEnabled(enabled)

    local button =
        PetBattleUI_PassButton

    if not button then
        return
    end

    if enabled then

        button:Enable()

    else

        button:Disable()

    end

end


-- ============================================================
-- ACTIVAR/DESACTIVAR LE BOUTON "CHANGER DE MASCOTTE"
-- ============================================================
-- Comme "Passer", changer de mascotte consomme le tour et n'a
-- pas de cooldown propre : meme regle d'activation.

local function SetSwitchPetButtonEnabled(enabled)

    local button =
        PetBattleUI_SwitchPetButton

    if not button then
        return
    end

    if enabled then

        button:Enable()

    else

        button:Disable()

    end

end


-- ============================================================
-- DESACTIVAR TODOS LOS ATAQUES
-- ============================================================

local function DisableAllAttackButtons()

    for i = 1, 3 do

        attackEnableTimers[i] =
            0


        attackWaiting[i] =
            false


        SetAttackIconEnabled(
            i,
            false
        )

    end


    SetPassButtonEnabled(
        false
    )


    SetSwitchPetButtonEnabled(
        false
    )

end


-- ============================================================
-- ACTUALIZAR COOLDOWN INDIVIDUAL
-- ============================================================

local function UpdateAttackCooldown(index)

    local text =
        ATTACK_CD_TEXTS[index]


    if not text then
        return
    end


    local cd =
        PetBattleUI_Battle.cooldowns[index] or 0


    -- ========================================================
    -- TIENE COOLDOWN
    -- ========================================================

    if cd > 0 then

        local palabra


        if cd == 1 then

            palabra =
                "tour"

        else

            palabra =
                "tours"

        end


        text:SetText(
            "CD: "
            .. cd
            .. " "
            .. palabra
        )


        text:Show()


    -- ========================================================
    -- SIN COOLDOWN
    -- ========================================================

    else

        text:SetText("")

        text:Hide()

    end

end


-- ============================================================
-- ACTUALIZAR TODOS LOS COOLDOWNS
-- ============================================================

local function UpdateAllAttackCooldowns()

    for i = 1, 3 do

        UpdateAttackCooldown(i)

    end

end


-- ============================================================
-- ACTIVAR ATAQUES DESPUES DE LOS 2 SEGUNDOS
-- ============================================================

local function EnableAvailableAttacks()

    -- ========================================================
    -- POR SEGURIDAD:
    -- SI YA NO ES NUESTRO TURNO, NO ACTIVAR NADA
    -- ========================================================

    if not PetBattleUI_Battle.isPlayerTurn then

        DisableAllAttackButtons()

        return

    end


    -- ========================================================
    -- EVALUAR CADA ATAQUE
    -- ========================================================

    for i = 1, 3 do

        local cd =
            PetBattleUI_Battle.cooldowns[i] or 0


        -- ====================================================
        -- TIENE COOLDOWN
        -- ====================================================

        if cd > 0 then

            SetAttackIconEnabled(
                i,
                false
            )


        -- ====================================================
        -- SIN COOLDOWN
        -- ====================================================

        else

            SetAttackIconEnabled(
                i,
                true
            )

        end

    end


    -- ========================================================
    -- "PASSER" N'A PAS DE COOLDOWN : TOUJOURS DISPONIBLE
    -- ========================================================

    SetPassButtonEnabled(
        true
    )


    SetSwitchPetButtonEnabled(
        true
    )

end


-- ============================================================
-- TIMER PRINCIPAL
-- ============================================================

local attackTimerFrame =
    CreateFrame("Frame")


attackTimerFrame:SetScript(
    "OnUpdate",
    function(self, elapsed)

        -- ====================================================
        -- NO HAY ESPERA
        -- ====================================================

        if playerTurnEnableTimer <= 0 then

            return

        end


        -- ====================================================
        -- RESTAR TIEMPO
        -- ====================================================

        playerTurnEnableTimer =
            playerTurnEnableTimer
            - elapsed


        -- ====================================================
        -- TODAVIA NO TERMINARON LOS 2 SEGUNDOS
        -- ====================================================

        if playerTurnEnableTimer > 0 then

            return

        end


        -- ====================================================
        -- TERMINO LA ESPERA
        -- ====================================================

        playerTurnEnableTimer =
            0


        -- ====================================================
        -- COMPROBAR QUE SIGA SIENDO NUESTRO TURNO
        -- ====================================================

        if not PetBattleUI_Battle.isPlayerTurn then

            DisableAllAttackButtons()

            return

        end


        -- ====================================================
        -- ACTIVAR SOLO LOS ATAQUES DISPONIBLES
        -- ====================================================

        EnableAvailableAttacks()

    end
)


-- ============================================================
-- ESTABLECER DAÑOS
-- ============================================================

function PetBattleUI_Battle_SetDamage(
    damage1,
    damage2,
    damage3
)

    -- ========================================================
    -- GUARDAR
    -- ========================================================

    PetBattleUI_Battle.damages[1] =
        tonumber(damage1) or 0


    PetBattleUI_Battle.damages[2] =
        tonumber(damage2) or 0


    PetBattleUI_Battle.damages[3] =
        tonumber(damage3) or 0


    -- ========================================================
    -- ACTUALIZAR TEXTOS
    -- ========================================================

    UpdateAttackDamage(1)

    UpdateAttackDamage(2)

    UpdateAttackDamage(3)


    -- ========================================================
    -- ACTUALIZAR ICONOS
    -- ========================================================

    UpdateAttackIcon(1)

    UpdateAttackIcon(2)

    UpdateAttackIcon(3)

end


-- ============================================================
-- ESTABLECER TURNO
-- ============================================================

function PetBattleUI_Battle_SetTurn(
    isPlayerTurn
)

    local newTurn =
        isPlayerTurn and true or false


    -- ========================================================
    -- GUARDAR TURNO
    -- ========================================================

    PetBattleUI_Battle.isPlayerTurn =
        newTurn


    -- ========================================================
    -- CANCELAR ESPERA ANTERIOR
    -- ========================================================

    playerTurnEnableTimer =
        0


    -- ========================================================
    -- DESACTIVAR TODO INMEDIATAMENTE
    -- ========================================================

    DisableAllAttackButtons()


    -- ========================================================
    -- SI NO ES NUESTRO TURNO
    -- ========================================================

    if not newTurn then

        return

    end


    -- ========================================================
    -- ES NUESTRO TURNO
    --
    -- LOS BOTONES QUEDAN OFF DURANTE 2 SEGUNDOS
    -- ========================================================

    playerTurnEnableTimer =
        2

end


-- ============================================================
-- ESTABLECER COOLDOWNS
-- ============================================================

function PetBattleUI_Battle_SetCooldowns(
    cd1,
    cd2,
    cd3
)

    -- ========================================================
    -- GUARDAR COOLDOWNS
    -- ========================================================

    PetBattleUI_Battle.cooldowns[1] =
        tonumber(cd1) or 0


    PetBattleUI_Battle.cooldowns[2] =
        tonumber(cd2) or 0


    PetBattleUI_Battle.cooldowns[3] =
        tonumber(cd3) or 0


    -- ========================================================
    -- ACTUALIZAR TEXTOS
    -- ========================================================

    UpdateAllAttackCooldowns()


    -- ========================================================
    -- IMPORTANTE
    --
    -- NO ACTIVAR BOTONES AQUI.
    --
    -- El temporizador de 2 segundos iniciado por SetTurn()
    -- es el unico responsable de activarlos.
    -- ========================================================

end


-- ============================================================
-- INICIALIZAR BATALLA
-- ============================================================

-- ============================================================
-- HP text to health bars (12300/12300)
-- ============================================================

local function PetBattleUI_Battle_SetHealthText(fontString, hp, hpMax)

    if not fontString then
        return
    end

    hp = math.floor(tonumber(hp) or 0)
    hpMax = math.floor(tonumber(hpMax) or 0)

    fontString:SetText(
        hp .. "/" .. hpMax
    )

end


function PetBattleUI_Battle_Init(
    enemyName,
    enemyType,
    enemyHP,
    enemyHPMax,
    myName,
    myType,
    myHP,
    myHPMax,
    isNewBattle
)

    -- ========================================================
    -- ENEMIGO
    -- ========================================================

    if PetBattleUI_EnemyName then

        PetBattleUI_EnemyName:SetText(
            enemyName or "?"
        )

    end


    if PetBattleUI_EnemyType then

        PetBattleUI_EnemyType:SetText(
            enemyType or ""
        )

    end


    if PetBattleUI_EnemyHealthBar then

        PetBattleUI_EnemyHealthBar:SetMinMaxValues(
            0,
            tonumber(enemyHPMax) or 100
        )


        PetBattleUI_EnemyHealthBar:SetValue(
            tonumber(enemyHP) or 100
        )

        PetBattleUI_EnemyHealthBar_UpdateFill(
            PetBattleUI_EnemyHealthBar
        )

        PetBattleUI_Battle_SetHealthText(
            PetBattleUI_EnemyHealthText,
            enemyHP,
            enemyHPMax
        )

    end


    -- ========================================================
    -- MASCOTA PROPIA
    -- ========================================================

    if PetBattleUI_MyName then

        PetBattleUI_MyName:SetText(
            myName or "?"
        )

    end


    if PetBattleUI_MyType then

        PetBattleUI_MyType:SetText(
            myType or ""
        )

    end


    if PetBattleUI_MyHealthBar then

        PetBattleUI_MyHealthBar:SetMinMaxValues(
            0,
            tonumber(myHPMax) or 100
        )


        PetBattleUI_MyHealthBar:SetValue(
            tonumber(myHP) or 100
        )

        PetBattleUI_Battle_SetHealthText(
            PetBattleUI_MyHealthText,
            myHP,
            myHPMax
        )

    end


    -- ========================================================
    -- CANCELAR TEMPORIZADORES
    -- ========================================================

    playerTurnEnableTimer =
        0


    -- ========================================================
    -- DESACTIVAR TODOS LOS BOTONES
    -- ========================================================

    DisableAllAttackButtons()


    -- ========================================================
    -- NUEVO COMBATE
    -- ========================================================

    if isNewBattle then

        PetBattleUI_Battle.isPlayerTurn =
            false


        PetBattleUI_Battle.cooldowns[1] =
            0

        PetBattleUI_Battle.cooldowns[2] =
            0

        PetBattleUI_Battle.cooldowns[3] =
            0

    end


    -- ========================================================
    -- SI YA ERA NUESTRO TURNO
    -- ========================================================

    if PetBattleUI_Battle.isPlayerTurn then

        playerTurnEnableTimer =
            2

    end


    -- ========================================================
    -- ACTUALIZAR DAÑOS
    -- ========================================================

    UpdateAllAttackDamage()


    -- ========================================================
    -- ACTUALIZAR ICONOS
    -- ========================================================

    UpdateAllAttackIcons()


    -- ========================================================
    -- ACTUALIZAR COOLDOWNS
    -- ========================================================

    UpdateAllAttackCooldowns()

end


-- ============================================================
-- MOSTRAR BATTLE FRAME
-- ============================================================

function PetBattleUI_Battle_Show()

    if PetBattleUI_CoinFrame then

        PetBattleUI_CoinFrame:Hide()

    end


    if PetBattleUI_BattleFrame then

        PetBattleUI_BattleFrame:Show()

    end


    PetBattleUI_HideActionBar()
    PetBattleUI_HideMinimap()
    PetBattleUI_ShowFightStartNotifOnce()

end


-- ============================================================
-- BARRE DE VIE ENNEMIE : remplissage colle a droite
-- ============================================================
-- Ni SetReverseFill, ni un repositionnement de la texture native
-- (bar:GetStatusBarTexture()) ne donnent le bon resultat visuel
-- sur ce client (le moteur reimpose sa propre position a chaque
-- rafraichissement). On utilise donc une texture de remplissage
-- totalement independante (PetBattleUI_EnemyHealthBarFill, dans
-- Battle.xml, rendu natif du StatusBar passe en alpha=0) que l'on
-- dimensionne nous-meme a 100% a la main : elle reste collee au
-- bord DROIT de la barre et se retrecit vers la droite, pour
-- qu'elle se vide en partant de la gauche (au lieu du remplis-
-- sage par defaut colle a gauche qui se vide vers la gauche).

function PetBattleUI_EnemyHealthBar_UpdateFill(
    bar
)

    if not bar then
        return
    end


    local fillTex =
        PetBattleUI_EnemyHealthBarFill

    if not fillTex then
        return
    end


    local minVal, maxVal =
        bar:GetMinMaxValues()

    minVal =
        minVal or 0

    maxVal =
        maxVal or 100

    local val =
        bar:GetValue() or 0

    local pct =
        0

    if (maxVal - minVal) > 0 then

        pct =
            (val - minVal) / (maxVal - minVal)

        if pct < 0 then
            pct = 0
        elseif pct > 1 then
            pct = 1
        end

    end


    local barWidth =
        bar:GetWidth()


    -- SetWidth() refuse une valeur <= 0 sur ce client, donc on
    -- cache simplement la texture quand la mascotte est a 0 PV.

    if pct <= 0 then

        fillTex:Hide()

        return

    end


    fillTex:Show()

    fillTex:ClearAllPoints()

    fillTex:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
    fillTex:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    fillTex:SetWidth(barWidth * pct)

end


-- ============================================================
-- ACTUALIZAR VIDA
-- ============================================================

function PetBattleUI_Battle_UpdateHP(
    side,
    hp,
    hpMax
)

    local bar
    local text


    if side == "enemy" then

        bar =
            PetBattleUI_EnemyHealthBar

        text =
            PetBattleUI_EnemyHealthText

    else

        bar =
            PetBattleUI_MyHealthBar

        text =
            PetBattleUI_MyHealthText

    end


    if not bar then
        return
    end


    if hpMax then

        bar:SetMinMaxValues(
            0,
            tonumber(hpMax)
        )

    end


    bar:SetValue(
        tonumber(hp) or 0
    )


    if side == "enemy" then

        PetBattleUI_EnemyHealthBar_UpdateFill(
            bar
        )

    end

    PetBattleUI_Battle_SetHealthText(
        text,
        hp,
        hpMax or select(2, bar:GetMinMaxValues())
    )

end


-- ============================================================
-- ATAQUE
-- ============================================================

function PetBattleUI_Battle_OnAttack(
    index
)

    -- ========================================================
    -- NO ES NUESTRO TURNO
    -- ========================================================

    if not PetBattleUI_Battle.isPlayerTurn then

        return

    end


    -- ========================================================
    -- INDEX INVALIDO
    -- ========================================================

    if
        not index
        or index < 1
        or index > 3
    then

        return

    end


    -- ========================================================
    -- COOLDOWN
    -- ========================================================

    if
        (PetBattleUI_Battle.cooldowns[index] or 0)
        > 0
    then

        return

    end


    -- ========================================================
    -- ATAQUE NO ACTIVO
    -- ========================================================

    if not attackActive[index] then

        return

    end


    -- ========================================================
    -- TERMINAR TURNO
    -- ========================================================

    PetBattleUI_Battle_SetTurn(
        false
    )


    -- ========================================================
    -- CANCELAR TODO
    -- ========================================================

    playerTurnEnableTimer =
        0


    DisableAllAttackButtons()


    -- ========================================================
    -- ENVIAR ATAQUE AL SERVIDOR
    -- ========================================================

    PetBattleUI:Send(
        "ATK:" .. index
    )

end


-- ============================================================
-- PASSER LE TOUR
-- ============================================================

function PetBattleUI_Battle_OnPass()

    -- ========================================================
    -- NO ES NUESTRO TURNO
    -- ========================================================

    if not PetBattleUI_Battle.isPlayerTurn then

        return

    end


    -- ========================================================
    -- TERMINAR TURNO
    -- ========================================================

    PetBattleUI_Battle_SetTurn(
        false
    )


    -- ========================================================
    -- CANCELAR TODO
    -- ========================================================

    playerTurnEnableTimer =
        0


    DisableAllAttackButtons()


    -- ========================================================
    -- ENVIAR AU SERVIDOR
    -- ========================================================

    PetBattleUI:Send(
        "PASS"
    )

end


-- ============================================================
-- CHANGER DE MASCOTTE
-- ============================================================

function PetBattleUI_Battle_OnSwitchPet()

    -- ========================================================
    -- NO ES NUESTRO TURNO
    -- ========================================================

    if not PetBattleUI_Battle.isPlayerTurn then

        return

    end


    -- ========================================================
    -- TERMINAR TURNO
    --
    -- Le serveur peut refuser (aucune autre mascotte vivante) et
    -- nous renverra alors directement TURN:mine + les cooldowns
    -- via ShowAttackMenu/SendCooldownsToClient sans avoir jamais
    -- change de mascotte -- le tour redevient donc utilisable
    -- normalement des la reponse du serveur dans ce cas.
    -- ========================================================

    PetBattleUI_Battle_SetTurn(
        false
    )


    -- ========================================================
    -- CANCELAR TODO
    -- ========================================================

    playerTurnEnableTimer =
        0


    DisableAllAttackButtons()


    -- ========================================================
    -- ENVIAR AU SERVIDOR
    -- ========================================================

    PetBattleUI:Send(
        "SWITCHPET"
    )

end


-- ============================================================
-- CAPITULER
-- ============================================================

function PetBattleUI_Battle_OnForfeit()

    -- Contrairement a "Passer"/"Changer de mascotte", capituler
    -- ne necessite pas que ce soit notre tour : abandonner est
    -- toujours possible, comme fermer la fenetre de combat.

    DisableAllAttackButtons()

    PetBattleUI:Send(
        "FORFEIT"
    )

end


-- ============================================================
-- FINALIZAR BATALLA
-- ============================================================

function PetBattleUI_Battle_End(
    resultText
)

    -- ========================================================
    -- DETENER TEMPORIZADOR
    -- ========================================================

    playerTurnEnableTimer =
        0


    -- ========================================================
    -- DESACTIVAR TODO
    -- ========================================================

    DisableAllAttackButtons()


    -- ========================================================
    -- ESTADO
    -- ========================================================

    PetBattleUI_Battle.isPlayerTurn =
        false


    -- ========================================================
    -- TEXTE DE DEGATS FLOTTANT : NE PAS LAISSER TRAINER
    -- ========================================================

    dmgTextState.mine.timeLeft = 0
    dmgTextState.enemy.timeLeft = 0

    if PetBattleUI_MyDamageText then
        PetBattleUI_MyDamageText:Hide()
    end

    if PetBattleUI_EnemyDamageText then
        PetBattleUI_EnemyDamageText:Hide()
    end


    -- ========================================================
    -- OCULTAR
    -- ========================================================

    if PetBattleUI_BattleFrame then

        PetBattleUI_BattleFrame:Hide()

    end


    PetBattleUI_RestoreActionBar()
    PetBattleUI_RestoreMinimap()


    -- ========================================================
    -- SECURITE GOSSIP (bug corrige : apres le combat, parler a
    -- un PNJ de quete ou ouvrir un objet ne marchait plus)
    -- ========================================================
    -- Le serveur envoie un message addon "GOSSIPFLAG" juste avant
    -- CHAQUE menu gossip interne au combat (ex : synchronisation
    -- des cooldowns), ce qui met PetBattleUI.expectingGossip a
    -- true le temps que le client recoive et masque ce menu.
    -- Si le dernier de ces cycles ne se termine jamais proprement
    -- (fin de combat au mauvais moment, message perdu, etc.), le
    -- flag reste bloque a true -- et le PROCHAIN vrai gossip du
    -- joueur (PNJ de quete, objet) se fait alors fermer instantanement
    -- par erreur puisque le code le prend pour un menu interne.
    -- On force donc explicitement le flag a false ici, au moment ou
    -- le combat se termine reellement du point de vue du joueur :
    -- plus aucun gossip interne n'est attendu passe ce point.

    PetBattleUI.expectingGossip = false


    -- Autorise la notification "debut de combat" a se rafficher
    -- au prochain combat.

    fightNotifShownThisBattle = false

    if PetBattleUI_FightStartNotif then
        PetBattleUI_FightStartNotif:Hide()
    end


    -- ========================================================
    -- MENSAJE
    -- ========================================================

    --DEFAULT_CHAT_FRAME:AddMessage(
    --
    --    "|cff40ff40[PetBattle]|r "
    --    ..
    --    (
    --        resultText
    --        or
    --        "El combate ha terminado."
    --    )
    --
    --)

end