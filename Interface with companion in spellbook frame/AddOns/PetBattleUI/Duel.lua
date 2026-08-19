-- ============================================================
-- PetBattleUI - Duel.lua
-- "jugador [NOMBRE] te desafia a un duelo" + Aceptar / Cancelar
-- ============================================================

function PetBattleUI_Duel_Show(challengerName)
    PetBattleUI_DuelFrameText:SetText("Jugador " .. (challengerName or "?") .. " te desafia a un duelo")
    PetBattleUI_DuelFrame:Show()
end

function PetBattleUI_Duel_OnAccept()
    PetBattleUI_DuelFrame:Hide()
    PetBattleUI:Send("DUELACC")
end

function PetBattleUI_Duel_OnDecline()
    PetBattleUI_DuelFrame:Hide()
    PetBattleUI:Send("DUELDEC")
end
