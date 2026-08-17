-- ============================================================
-- PetBattleUI - Battle.lua
-- ============================================================


-- ============================================================
-- ICONOS SEGUN DAÑO
-- ============================================================

local ATTACK_ICON_LOW =
    "Interface\\Icons\\Spell_Nature_Rejuvenation"

local ATTACK_ICON_NORMAL =
    "Interface\\Icons\\Spell_Fire_Fireball"

local ATTACK_ICON_HIGH =
    "Interface\\Icons\\Spell_Fire_Incinerate"


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

        return ATTACK_ICON_LOW

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


        attackActive[index] =
            false

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
                "turno"

        else

            palabra =
                "turnos"

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


    if side == "enemy" then

        bar =
            PetBattleUI_EnemyHealthBar

    else

        bar =
            PetBattleUI_MyHealthBar

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
    -- OCULTAR
    -- ========================================================

    if PetBattleUI_BattleFrame then

        PetBattleUI_BattleFrame:Hide()

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