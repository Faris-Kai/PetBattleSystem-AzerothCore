-- ============================================================
-- PetBattleUI - DuelButton.lua
-- ============================================================
-- Bouton "Duel de Mascotte" : remplace le fait de devoir taper
-- .dp au clavier. Le joueur cible toujours son adversaire (un
-- autre joueur ou une creature capturable) normalement dans le
-- monde, puis clique sur ce bouton a la place d'ecrire .dp.
-- Le serveur regarde la cible actuelle au moment du clic (voir
-- PetBattleMgr::StartBattleAgainstTarget cote C++).
-- ============================================================

function PetBattleUI_DuelButton_OnClick()

    PetBattleUI:Send(
        "STARTBATTLE"
    )

end
