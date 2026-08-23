-- ============================================================
-- PetBattleUI - Duel.lua
-- "jugador [NOMBRE] te desafia a un duelo" + Aceptar / Cancelar
-- ============================================================

function PetBattleUI_Duel_Show(challengerName)

    local text =
        PetBattleUI_Locale.DUEL_CHALLENGE or
        "%s has challenged you to a pet duel!"

    PetBattleUI_DuelFrameText:SetText(
        string.format(
            text,
            challengerName or "?"
        )
    )

    PetBattleUI_Duel_UpdateLocale()

    PetBattleUI_DuelFrame:Show()
end

function PetBattleUI_Duel_UpdateLocale()

    PetBattleUI_DuelAcceptButton:SetText(
        PetBattleUI_Locale.DUEL_ACCEPT or "Accept"
    )

    PetBattleUI_DuelDeclineButton:SetText(
        PetBattleUI_Locale.DUEL_DECLINE or "Decline"
    )
end

function PetBattleUI_Duel_OnAccept()
    PetBattleUI_DuelFrame:Hide()
    PetBattleUI:Send("DUELACC")
end

function PetBattleUI_Duel_OnDecline()
    PetBattleUI_DuelFrame:Hide()
    PetBattleUI:Send("DUELDEC")
end
