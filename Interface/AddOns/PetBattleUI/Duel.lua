-- ============================================================
-- PetBattleUI - Duel.lua
-- "jugador [NOMBRE] te desafia a un duelo" + Aceptar / Cancelar
-- ============================================================

function PetBattleUI_Duel_Show(challengerName)
    PetBattleUI_DuelFrameText:SetText(" " .. (challengerName or "?") .. " vous à défié en duel de mascotte")
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
