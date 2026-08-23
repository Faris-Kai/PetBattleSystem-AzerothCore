-- ============================================================
-- PetBattleUI - Localization.lua
-- ============================================================

PetBattleUI_Locale = {}

local locale = GetLocale()


-- ============================================================
-- ESPAÑOL
-- ============================================================

if locale == "esES" or locale == "esMX" then

    PetBattleUI_Locale.TEAM_TITLE =
        "Equipo de Mascotas"

    PetBattleUI_Locale.TEAM_SUBTITLE =
        "Arrastra tus compañeros para formar tu equipo"

    PetBattleUI_Locale.TEAM_SUBTITLE2 =
        "(clic derecho para quitar)"

    PetBattleUI_Locale.FIGHT_START =
        "Comienza el du-du-du-duelo"

    PetBattleUI_Locale.PASS_BUTTON =
        "Pasar"

    PetBattleUI_Locale.SWITCH_PET_BUTTON =
        "Cambiar de mascota"

    PetBattleUI_Locale.FORFEIT_BUTTON =
        "Rendirse"

    PetBattleUI_Locale.DUEL_BUTTON =
        "Duelo de mascota"

    PetBattleUI_Locale.MISS_TEXT =
        "Miss"
	
	PetBattleUI_Locale.DUEL_CHALLENGE =
        "¡%s te ha desafiado a un duelo de mascotas!"
		
	PetBattleUI_Locale.DUEL_ACCEPT =
		"Aceptar"
	
	PetBattleUI_Locale.DUEL_DECLINE =
		"Cancelar"
		
	PetBattleUI_Locale.COIN_FIRST =
		"¡Bien hecho! ¡Es tu turno!"

	PetBattleUI_Locale.COIN_SECOND =
		"¡Perdiste! Jugarás en el próximo turno."

-- ============================================================
-- INGLÉS
-- ============================================================

elseif locale == "enUS" or locale == "enGB" then

    PetBattleUI_Locale.TEAM_TITLE =
        "Pet Team"

    PetBattleUI_Locale.TEAM_SUBTITLE =
        "Drag your companions to form your team"

    PetBattleUI_Locale.TEAM_SUBTITLE2 =
        "(right-click to remove)"

    PetBattleUI_Locale.FIGHT_START =
        "Start Fight"

    PetBattleUI_Locale.PASS_BUTTON =
        "Pass"

    PetBattleUI_Locale.SWITCH_PET_BUTTON =
        "Switch Pet"

    PetBattleUI_Locale.FORFEIT_BUTTON =
        "Forfeit"

    PetBattleUI_Locale.DUEL_BUTTON =
        "Pet Duel"

    PetBattleUI_Locale.MISS_TEXT =
        "Miss!"

    PetBattleUI_Locale.DUEL_CHALLENGE =
        "%s has challenged you to a pet duel!"
	
	PetBattleUI_Locale.DUEL_ACCEPT =
		"Accept"
	
	PetBattleUI_Locale.DUEL_DECLINE =
		"Decline"
		
	PetBattleUI_Locale.COIN_FIRST =
		"Well done! It's your turn!"
	
	PetBattleUI_Locale.COIN_SECOND =
		"You lost! You'll play on the next turn."

-- ============================================================
-- FRANCÉS
-- ============================================================

elseif locale == "frFR" then

    PetBattleUI_Locale.TEAM_TITLE =
        "Équipe de mascottes"

    PetBattleUI_Locale.TEAM_SUBTITLE =
        "Faites glisser vos compagnons pour former votre équipe"

    PetBattleUI_Locale.TEAM_SUBTITLE2 =
        "(clic droit pour retirer)"

    PetBattleUI_Locale.FIGHT_START =
        "C'est parti !"

    PetBattleUI_Locale.PASS_BUTTON =
        "Passer"

    PetBattleUI_Locale.SWITCH_PET_BUTTON =
        "Changer de mascotte"

    PetBattleUI_Locale.FORFEIT_BUTTON =
        "Capituler"

    PetBattleUI_Locale.DUEL_BUTTON =
        "Duel de Mascotte"

    PetBattleUI_Locale.MISS_TEXT =
        "Raté !"

    PetBattleUI_Locale.DUEL_CHALLENGE =
        "%s vous a défié en duel de mascottes !"
	
	PetBattleUI_Locale.DUEL_ACCEPT =
		"Accepter"

	PetBattleUI_Locale.DUEL_DECLINE =
		"Annuler"
		
	PetBattleUI_Locale.COIN_FIRST =
		"Bien joué ! À vous de jouer !"
	
	PetBattleUI_Locale.COIN_SECOND =
		"Perdu ! Vous jouerez au prochain tour."

-- ============================================================
-- ALEMÁN
-- ============================================================

elseif locale == "deDE" then

    PetBattleUI_Locale.TEAM_TITLE =
        "Haustierteam"

    PetBattleUI_Locale.TEAM_SUBTITLE =
        "Ziehe deine Begleiter, um dein Team zu bilden"

    PetBattleUI_Locale.TEAM_SUBTITLE2 =
        "(Rechtsklick zum Entfernen)"


-- ============================================================
-- RUSO
-- ============================================================

elseif locale == "ruRU" then

    PetBattleUI_Locale.TEAM_TITLE =
        "Команда питомцев"

    PetBattleUI_Locale.TEAM_SUBTITLE =
        "Перетащите питомцев, чтобы сформировать команду"

    PetBattleUI_Locale.TEAM_SUBTITLE2 =
        "(щелчок правой кнопкой — удалить)"


-- ============================================================
-- CHINO SIMPLIFICADO
-- ============================================================

elseif locale == "zhCN" then

    PetBattleUI_Locale.TEAM_TITLE =
        "宠物队伍"

    PetBattleUI_Locale.TEAM_SUBTITLE =
        "拖动你的宠物来组建队伍"

    PetBattleUI_Locale.TEAM_SUBTITLE2 =
        "（右键点击移除）"


-- ============================================================
-- CHINO TRADICIONAL
-- ============================================================

elseif locale == "zhTW" then

    PetBattleUI_Locale.TEAM_TITLE =
        "寵物隊伍"

    PetBattleUI_Locale.TEAM_SUBTITLE =
        "拖曳你的寵物來組成隊伍"

    PetBattleUI_Locale.TEAM_SUBTITLE2 =
        "（右鍵點擊移除）"


-- ============================================================
-- COREANO
-- ============================================================

elseif locale == "koKR" then

    PetBattleUI_Locale.TEAM_TITLE =
        "애완동물 팀"

    PetBattleUI_Locale.TEAM_SUBTITLE =
        "동료를 끌어다 놓아 팀을 구성하세요"

    PetBattleUI_Locale.TEAM_SUBTITLE2 =
        "(오른쪽 클릭하여 제거)"


-- ============================================================
-- IDIOMA POR DEFECTO
-- ============================================================

else

    PetBattleUI_Locale.TEAM_TITLE =
        "Pet Team"

    PetBattleUI_Locale.TEAM_SUBTITLE =
        "Drag your companions to form your team"

    PetBattleUI_Locale.TEAM_SUBTITLE2 =
        "(right-click to remove)"

    PetBattleUI_Locale.FIGHT_START =
        "Start Fight"

    PetBattleUI_Locale.PASS_BUTTON =
        "Pass"

    PetBattleUI_Locale.SWITCH_PET_BUTTON =
        "Switch Pet"

    PetBattleUI_Locale.FORFEIT_BUTTON =
        "Forfeit"

    PetBattleUI_Locale.DUEL_BUTTON =
        "Pet Duel"

    PetBattleUI_Locale.MISS_TEXT =
        "Miss!"
	PetBattleUI_Locale.DUEL_CHALLENGE =
		"%s has challenged you to a pet duel!"	
	
	PetBattleUI_Locale.DUEL_ACCEPT =
		"Accept"
	
	PetBattleUI_Locale.DUEL_DECLINE =
		"Decline"	
		
	PetBattleUI_Locale.COIN_FIRST =
		"Well done! It's your turn!"
	
	PetBattleUI_Locale.COIN_SECOND =
		"You lost! You'll play on the next turn."

end