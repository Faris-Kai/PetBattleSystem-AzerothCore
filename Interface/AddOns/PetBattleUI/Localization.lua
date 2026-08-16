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

end