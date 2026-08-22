-- ============================================================
-- PetBattleUI - Coin.lua
-- El orden de turno lo decide el SERVIDOR (no el cliente), para
-- evitar trampas. Clic en la moneda -> pedimos el resultado ->
-- el servidor responde COINRESULT:primero|segundo -> se muestra
-- la imagen con el texto y se va transparentando hasta desaparecer.
-- ============================================================


function PetBattleUI_Coin_Show()
    PetBattleUI_CoinResultText:SetAlpha(0)
    PetBattleUI_CoinButton:Enable()

    PetBattleUI_BattleFrame:Hide()
    PetBattleUI_CoinFrame:Show()
end


function PetBattleUI_Coin_OnClick()
    PetBattleUI_CoinButton:Disable()
    PetBattleUI:Send("COINCLICK")
end


-- ============================================================
-- REVELAR RESULTADO DE LA MONEDA
-- ============================================================

function PetBattleUI_Coin_Reveal(order)
    PetBattleUI.coinFlipped = true

    local text = (order == "primero") and "Bien joué ! À vous de jouer !" or "Perdu ! Vous jouerez au prochain tour."

    PetBattleUI_CoinResultText:SetText(text)

    UIFrameFadeIn(
        PetBattleUI_CoinResultText,
        0.4,
        PetBattleUI_CoinResultText:GetAlpha(),
        1
    )

    PetBattleUI_CoinFrame.revealAt = GetTime()

    PetBattleUI_CoinFrame:SetScript("OnUpdate", function()
        local elapsed = GetTime() - this.revealAt

        if elapsed > 1.5 and elapsed <= 1.51 then

            UIFrameFadeOut(
                PetBattleUI_CoinResultText,
                1.2,
                1,
                0
            )

        elseif elapsed > 2.8 then

            this:SetScript("OnUpdate", nil)

            PetBattleUI_Battle_SetTurn(order == "primero")
            PetBattleUI_Battle_Show()
        end
    end)
end


-- ============================================================
-- OCULTAR MONEDA AL TERMINAR EL DUELO
-- ============================================================

function PetBattleUI_Coin_Hide()

    -- Detener cualquier OnUpdate pendiente
    if PetBattleUI_CoinFrame then
        PetBattleUI_CoinFrame:SetScript("OnUpdate", nil)
        PetBattleUI_CoinFrame:Hide()
    end

    -- Limpiar resultado
    if PetBattleUI_CoinResultText then
        PetBattleUI_CoinResultText:SetText("")
        PetBattleUI_CoinResultText:SetAlpha(0)
    end

    -- Restaurar estado para el próximo duelo
    if PetBattleUI_CoinButton then
        PetBattleUI_CoinButton:Enable()
    end

    PetBattleUI.coinFlipped = false
end