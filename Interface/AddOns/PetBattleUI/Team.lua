-- ============================================================
-- PetBattleUI - Team.lua
-- ============================================================


-- ============================================================
-- LOCALIZACION
-- ============================================================

local LOCALE = GetLocale()

local L = {}


-- ============================================================
-- ESPAÑOL
-- ============================================================

if LOCALE == "esES" or LOCALE == "esMX" then

    L.TEAM_TITLE =
        "Equipo de Mascotas"

    L.TEAM_SUBTITLE =
        "Arrastra tus compañeros para formar tu equipo"

    L.TEAM_SUBTITLE_2 =
        "(clic derecho para quitar)"

    L.TYPE =
        "Tipo: "

    L.DAMAGE =
        "Daño: "

    L.NONE_SELECTED =
        "Ninguna mascota seleccionada"

    L.DRAG_PET_HERE =
        "Arrastra una mascota aquí"

    L.PET =
        "Mascota"

    L.RELEASE =
        "Liberar"

    L.RELEASE_TOOLTIP =
        "Elimina la mascota seleccionada de tu colección. Esta acción no se puede deshacer."

    L.CAGE =
        "Enjaular"

    L.CAGE_TOOLTIP =
        "Convierte la mascota seleccionada en un objeto (jaula) y la quita de tu colección."

    L.PET_ALREADY_IN_TEAM =
        "|cffffff00 Esa mascota ya está en el equipo (casilla %d)."

    L.TEAM_FULL =
        "Tu equipo está lleno. Quita una mascota antes de agregar otra."

    L.GENERIC_ERROR =
        "No se pudo realizar la operación."

    L.GENERIC_SUCCESS =
        "Operación realizada correctamente."

    L.SELECT_OR_DRAG =
        "Primero selecciona o arrastra una mascota a la casilla inferior."

    L.ACTION_SLOT_EMPTY =
        "La casilla de gestión no contiene una mascota."

    L.RELEASE_CONFIRM =
        "¿Liberar a:\n\n%s\n\nEsta acción eliminará la mascota de tu colección y no se puede deshacer."

    L.CAGE_CONFIRM =
        "¿Enjaular a:\n\n%s\n\nLa mascota será convertida en su objeto y eliminada de tu colección."

    L.CANCEL =
        "Cancelar"


-- ============================================================
-- INGLÉS
-- ============================================================

elseif LOCALE == "enUS" or LOCALE == "enGB" then

    L.TEAM_TITLE =
        "Pet Team"

    L.TEAM_SUBTITLE =
        "Drag your companions to form your team"

    L.TEAM_SUBTITLE_2 =
        "(right-click to remove)"

    L.TYPE =
        "Type: "

    L.DAMAGE =
        "Damage: "

    L.NONE_SELECTED =
        "No pet selected"

    L.DRAG_PET_HERE =
        "Drag a pet here"

    L.PET =
        "Pet"

    L.RELEASE =
        "Release"

    L.RELEASE_TOOLTIP =
        "Removes the selected pet from your collection. This action cannot be undone."

    L.CAGE =
        "Cage"

    L.CAGE_TOOLTIP =
        "Converts the selected pet into an item (cage) and removes it from your collection."

    L.PET_ALREADY_IN_TEAM =
        "That pet is already in the team (slot %d)."

    L.TEAM_FULL =
        "Your team is full. Remove a pet before adding another."

    L.GENERIC_ERROR =
        "The operation could not be completed."

    L.GENERIC_SUCCESS =
        "Operation completed successfully."

    L.SELECT_OR_DRAG =
        "First select or drag a pet to the bottom slot."

    L.ACTION_SLOT_EMPTY =
        "The management slot does not contain a pet."

    L.RELEASE_CONFIRM =
        "Release:\n\n%s\n\nThis will remove the pet from your collection and cannot be undone."

    L.CAGE_CONFIRM =
        "Cage:\n\n%s\n\nThe pet will be converted into an item and removed from your collection."

    L.CANCEL =
        "Cancel"


-- ============================================================
-- FRANCÉS
-- ============================================================

elseif LOCALE == "frFR" then

    L.TEAM_TITLE =
        "Équipe de mascottes"

    L.TEAM_SUBTITLE =
        "Faites glisser vos mascottes pour former votre équipe"

    L.TEAM_SUBTITLE_2 =
        "(clic droit pour retirer)"

    L.TYPE =
        "Type : "

    L.DAMAGE =
        "Dégâts : "

    L.NONE_SELECTED =
        "Aucune mascotte sélectionnée"

    L.DRAG_PET_HERE =
        "Faites glisser une mascotte ici"

    L.PET =
        "Mascotte"

    L.RELEASE =
        "Libérer"

    L.RELEASE_TOOLTIP =
        "Supprime la mascotte sélectionnée de votre collection. Cette action est irréversible."

    L.CAGE =
        "Mettre en cage"

    L.CAGE_TOOLTIP =
        "Transforme la mascotte sélectionnée en objet (cage) et la retire de votre collection."

    L.PET_ALREADY_IN_TEAM =
        "Cette mascotte est déjà dans l’équipe (emplacement %d)."

    L.TEAM_FULL =
        "Votre équipe est complète. Retirez une mascotte avant d’en ajouter une autre."

    L.GENERIC_ERROR =
        "L’opération n’a pas pu être effectuée."

    L.GENERIC_SUCCESS =
        "Opération effectuée avec succès."

    L.SELECT_OR_DRAG =
        "Sélectionnez ou faites glisser une mascotte vers l’emplacement inférieur."

    L.ACTION_SLOT_EMPTY =
        "L’emplacement de gestion ne contient aucune mascotte."

    L.RELEASE_CONFIRM =
        "Libérer :\n\n%s\n\nCette action supprimera la mascotte de votre collection et est irréversible."

    L.CAGE_CONFIRM =
        "Mettre en cage :\n\n%s\n\nLa mascotte sera transformée en objet et retirée de votre collection."

    L.CANCEL =
        "Annuler"


-- ============================================================
-- ALEMÁN
-- ============================================================

elseif LOCALE == "deDE" then

    L.TEAM_TITLE =
        "Haustierteam"

    L.TEAM_SUBTITLE =
        "Ziehe deine Begleiter hierher, um dein Team zu bilden"

    L.TEAM_SUBTITLE_2 =
        "(Rechtsklick zum Entfernen)"

    L.TYPE =
        "Typ: "

    L.DAMAGE =
        "Schaden: "

    L.NONE_SELECTED =
        "Kein Haustier ausgewählt"

    L.DRAG_PET_HERE =
        "Ziehe ein Haustier hierher"

    L.PET =
        "Haustier"

    L.RELEASE =
        "Freigeben"

    L.RELEASE_TOOLTIP =
        "Entfernt das ausgewählte Haustier aus deiner Sammlung. Diese Aktion kann nicht rückgängig gemacht werden."

    L.CAGE =
        "Einsperren"

    L.CAGE_TOOLTIP =
        "Wandelt das ausgewählte Haustier in einen Gegenstand (Käfig) um und entfernt es aus deiner Sammlung."

    L.PET_ALREADY_IN_TEAM =
        "Dieses Haustier befindet sich bereits im Team (Platz %d)."

    L.TEAM_FULL =
        "Dein Team ist voll. Entferne ein Haustier, bevor du ein weiteres hinzufügst."

    L.GENERIC_ERROR =
        "Die Aktion konnte nicht ausgeführt werden."

    L.GENERIC_SUCCESS =
        "Aktion erfolgreich ausgeführt."

    L.SELECT_OR_DRAG =
        "Wähle zuerst ein Haustier aus oder ziehe es in den unteren Platz."

    L.ACTION_SLOT_EMPTY =
        "Der Verwaltungsplatz enthält kein Haustier."

    L.RELEASE_CONFIRM =
        "Freigeben:\n\n%s\n\nDadurch wird das Haustier aus deiner Sammlung entfernt. Diese Aktion kann nicht rückgängig gemacht werden."

    L.CAGE_CONFIRM =
        "Einsperren:\n\n%s\n\nDas Haustier wird in einen Gegenstand umgewandelt und aus deiner Sammlung entfernt."

    L.CANCEL =
        "Abbrechen"


-- ============================================================
-- IDIOMA POR DEFECTO
-- ============================================================

else

    L.TEAM_TITLE =
        "Pet Team"

    L.TEAM_SUBTITLE =
        "Drag your companions to form your team"

    L.TEAM_SUBTITLE_2 =
        "(right-click to remove)"

    L.TYPE =
        "Type: "

    L.DAMAGE =
        "Damage: "

    L.NONE_SELECTED =
        "No pet selected"

    L.DRAG_PET_HERE =
        "Drag a pet here"

    L.PET =
        "Pet"

    L.RELEASE =
        "Release"

    L.RELEASE_TOOLTIP =
        "Removes the selected pet from your collection. This action cannot be undone."

    L.CAGE =
        "Cage"

    L.CAGE_TOOLTIP =
        "Converts the selected pet into an item (cage) and removes it from your collection."

    L.PET_ALREADY_IN_TEAM =
        "That pet is already in the team (slot %d)."

    L.TEAM_FULL =
        "Your team is full. Remove a pet before adding another."

    L.GENERIC_ERROR =
        "The operation could not be completed."

    L.GENERIC_SUCCESS =
        "Operation completed successfully."

    L.SELECT_OR_DRAG =
        "First select or drag a pet to the bottom slot."

    L.ACTION_SLOT_EMPTY =
        "The management slot does not contain a pet."

    L.RELEASE_CONFIRM =
        "Release:\n\n%s\n\nThis will remove the pet from your collection and cannot be undone."

    L.CAGE_CONFIRM =
        "Cage:\n\n%s\n\nThe pet will be converted into an item and removed from your collection."

    L.CANCEL =
        "Cancel"

end


-- ============================================================
-- TIPOS DE MASCOTA
-- ============================================================

local PET_TYPE_TRANSLATIONS = {

    ["Bestia"] = {
        esES = "Bestia",
        esMX = "Bestia",
        enUS = "Beast",
        enGB = "Beast",
        frFR = "Bête",
        deDE = "Wildtier"
    },

    ["Acuático"] = {
        esES = "Acuático",
        esMX = "Acuático",
        enUS = "Aquatic",
        enGB = "Aquatic",
        frFR = "Aquatique",
        deDE = "Aquatisch"
    },

    ["Animal"] = {
        esES = "Animal",
        esMX = "Animal",
        enUS = "Critter",
        enGB = "Critter",
        frFR = "Bestiole",
        deDE = "Wildtier"
    },

    ["Elemental"] = {
        esES = "Elemental",
        esMX = "Elemental",
        enUS = "Elemental",
        enGB = "Elemental",
        frFR = "Élémentaire",
        deDE = "Elementar"
    },

    ["Mecánico"] = {
        esES = "Mecánico",
        esMX = "Mecánico",
        enUS = "Mechanical",
        enGB = "Mechanical",
        frFR = "Mécanique",
        deDE = "Mechanisch"
    },

    ["Magia"] = {
        esES = "Magia",
        esMX = "Magia",
        enUS = "Magic",
        enGB = "Magic",
        frFR = "Magie",
        deDE = "Magie"
    },

    ["Dragón"] = {
        esES = "Dragón",
        esMX = "Dragón",
        enUS = "Dragonkin",
        enGB = "Dragonkin",
        frFR = "Draconien",
        deDE = "Drachkin"
    },

    ["Volador"] = {
        esES = "Volador",
        esMX = "Volador",
        enUS = "Flying",
        enGB = "Flying",
        frFR = "Vol",
        deDE = "Fliegend"
    },

    ["No-muerto"] = {
        esES = "No-muerto",
        esMX = "No-muerto",
        enUS = "Undead",
        enGB = "Undead",
        frFR = "Mort-vivant",
        deDE = "Untot"
    },

    ["Humanoide"] = {
        esES = "Humanoide",
        esMX = "Humanoide",
        enUS = "Humanoid",
        enGB = "Humanoid",
        frFR = "Humanoïde",
        deDE = "Humanoid"
    }

}


local function TranslatePetType(tipo)

    if not tipo or tipo == "" then
        return tipo
    end

    local translation =
        PET_TYPE_TRANSLATIONS[tipo]

    if translation then

        return translation[LOCALE]
            or translation.enUS
            or tipo

    end

    return tipo

end


-- ============================================================
-- CONFIGURACION
-- ============================================================

local TEAM_MAX_SLOTS = 3

local selectedSlot = nil
local dragSourceSlot = nil

local lastCompanionType = nil
local lastCompanionIndex = nil


-- ============================================================
-- MOSTRAR / OCULTAR VENTANA
-- ============================================================

local function GetCompanionsWindow()

    if PetPaperDollFrameCompanionFrame then

        return PetPaperDollFrameCompanionFrame:GetParent()
            or PetPaperDollFrame

    end

    return PetPaperDollFrame

end


local function AnchorTeamFrameToCompanions()

    if not PetBattleUI_TeamFrame then
        return
    end

    local companionsWindow =
        GetCompanionsWindow()

    if not companionsWindow then
        return
    end

    PetBattleUI_TeamFrame:ClearAllPoints()

    PetBattleUI_TeamFrame:SetPoint(
        "TOPLEFT",
        companionsWindow,
        "TOPRIGHT",
        0,
        0
    )

    PetBattleUI_TeamFrame:SetPoint(
        "BOTTOMLEFT",
        companionsWindow,
        "BOTTOMRIGHT",
        0,
        0
    )

end


-- ============================================================
-- ACTUALIZAR TITULO Y SUBTITULOS
-- ============================================================

local function UpdateTeamHeader()

    if not PetBattleUI_TeamFrame then
        return
    end


    -- ========================================================
    -- OBTENER NOMBRE DEL FRAME
    -- ========================================================

    local frameName =
        PetBattleUI_TeamFrame:GetName()

    if not frameName then
        return
    end


    -- ========================================================
    -- TITULO
    -- ========================================================

    local title =
        _G[frameName .. "Title"]

    if title then

        title:SetText(
            L.TEAM_TITLE
            or "Pet Team"
        )

        title:Show()

    end


    -- ========================================================
    -- SUBTITULO
    -- ========================================================

    local subtitle =
        _G[frameName .. "Subtitle"]

    if subtitle then

        subtitle:SetText(
            L.TEAM_SUBTITLE
            or "Drag your companions to form your team"
        )

        subtitle:Show()

    end


    -- ========================================================
    -- SUBTITULO 2
    -- ========================================================

    local subtitle2 =
        _G[frameName .. "Subtitle2"]

    if subtitle2 then

        subtitle2:SetText(
            L.TEAM_SUBTITLE_2
            or "(right-click to remove)"
        )

        subtitle2:Show()

    end

end


-- ============================================================
-- MOSTRAR TEAM
-- ============================================================

function PetBattleUI_Team_Show()

    if not PetBattleUI_TeamFrame then
        return
    end

    AnchorTeamFrameToCompanions()

    -- IMPORTANTE:
    -- actualizar textos antes de mostrar el frame
    UpdateTeamHeader()

    PetBattleUI_TeamFrame:Show()

    if PetBattleUI and PetBattleUI.Send then
        PetBattleUI:Send("TEAMGET")
    end

end


-- ============================================================
-- OCULTAR TEAM
-- ============================================================

function PetBattleUI_Team_Hide()

    if PetBattleUI_TeamFrame then
        PetBattleUI_TeamFrame:Hide()
    end

    selectedSlot = nil
    dragSourceSlot = nil

    if PetBattleUI_Team_UpdateActionButtons then
        PetBattleUI_Team_UpdateActionButtons()
    end

end


-- ============================================================
-- OBTENER BOTON DE SLOT
-- ============================================================

local function GetTeamSlotButton(index)

    return _G[
        "PetBattleUI_TeamSlot" .. index
    ]

end


-- ============================================================
-- DUPLICADOS / SLOTS LIBRES
-- ============================================================

local function FindTeamSlotWithSpell(spellID)

    if not spellID then
        return nil
    end

    for i = 1, TEAM_MAX_SLOTS do

        local button =
            GetTeamSlotButton(i)

        if button
            and button.spellID == spellID then

            return i

        end

    end

    return nil

end


local function FindFreeTeamSlot()

    for i = 1, TEAM_MAX_SLOTS do

        local button =
            GetTeamSlotButton(i)

        if button
            and not button.spellID then

            return i

        end

    end

    return nil

end


local function AssignCompanionToSlot(
    slotIndex,
    spellID,
    icon,
    name
)

    PetBattleUI_Team_UpdateSlot(
        slotIndex,
        spellID,
        icon,
        name
    )

    PetBattleUI_Team_SelectSlot(
        slotIndex
    )

    if PetBattleUI and PetBattleUI.Send then

        PetBattleUI:Send(
            "TEAM:"
            .. slotIndex
            .. ":"
            .. spellID
        )

    end

end


-- ============================================================
-- TEXTO DEL SLOT
-- ============================================================

local function UpdateSlotName(
    button,
    name
)

    if not button
        or not button.Name then

        return

    end

    if name and name ~= "" then

        button.Name:SetText(name)

        button.Name:SetFont(
            "Fonts\\FRIZQT__.TTF",
            14,
            "OUTLINE"
        )

        button.Name:Show()

    else

        button.Name:SetText("")
        button.Name:Hide()

    end

end


local function UpdateSlotDetails(
    button,
    tipo,
    d1,
    d2,
    d3
)

    if not button then
        return
    end


    if button.Type then

        if tipo and tipo ~= "" then

            tipo =
                TranslatePetType(tipo)

            button.Type:SetText(
                L.TYPE .. tipo
            )

            button.Type:SetFont(
                "Fonts\\FRIZQT__.TTF",
                14
            )

            button.Type:Show()

        else

            button.Type:SetText("")
            button.Type:Hide()

        end

    end


    if button.Damage then

        if d1 or d2 or d3 then

            local function DamageColor(damage)

                if not damage then

                    return "|cff808080-|r"

                elseif damage < 0 then

                    return "|cff00ff00"
                        .. tostring(math.abs(damage))
                        .. "|r"

                elseif damage > 0 and damage <= 19 then

                    return "|cffffff00"
                        .. tostring(math.abs(damage))
                        .. "|r"
						
                elseif damage > 19 then

                    return "|cffff0000"
                        .. tostring(math.abs(damage))
                        .. "|r"
                else

                    return ""--agregar color
                        .. tostring(math.abs(damage))
                        .. "|r"

                end

            end


            button.Damage:SetText(
                L.DAMAGE
                .. "("
                .. DamageColor(d1)
                .. ") ("
                .. DamageColor(d2)
                .. ") ("
                .. DamageColor(d3)
                .. ")"
            )

            button.Damage:SetFont(
                "Fonts\\FRIZQT__.TTF",
                14
            )

            button.Damage:Show()

        else

            button.Damage:SetText("")
            button.Damage:Hide()

        end

    end

end


-- ============================================================
-- ACTUALIZAR SLOT
-- ============================================================

function PetBattleUI_Team_UpdateSlot(
    slotIndex,
    spellID,
    icon,
    name,
    tipo,
    d1,
    d2,
    d3,
    creatureID
)

    local button =
        GetTeamSlotButton(slotIndex)

    if not button then
        return
    end

    button.spellID =
        spellID

    button.creatureName =
        name

    button.creatureID =
        creatureID
		
    button.tipo = tipo
    button.d1   = d1
    button.d2   = d2
    button.d3   = d3


    -- ========================================================
    -- MODELO 3D
    -- ========================================================

    if button.Model then

        if creatureID then

            button.Model:Show()

            button.Model:SetCreature(
                creatureID
            )

            if button.Model.SetCamDistanceScale then

                button.Model:SetCamDistanceScale(
                    5
                )

            end

            if button.Model.SetRotation then

                button.Model:SetRotation(
                    -70
                )

            end

        else

            button.Model:Hide()

        end

    end


    -- ========================================================
    -- ICONO
    -- ========================================================

    if button.Icon then

        if icon and icon ~= "" then

            button.Icon:SetTexture(icon)
            button.Icon:Show()

        else

            button.Icon:SetTexture(
                "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
            )

            button.Icon:Show()

        end

    end


    UpdateSlotName(
        button,
        name
    )

    UpdateSlotDetails(
        button,
        tipo,
        d1,
        d2,
        d3
    )


    button:Enable()

end


-- ============================================================
-- LIMPIAR SLOT
-- ============================================================

function PetBattleUI_Team_ClearSlot(slotIndex)

    local button =
        GetTeamSlotButton(slotIndex)

    if not button then
        return
    end

    button.spellID = nil
    button.creatureName = nil
    button.creatureID = nil
    -- AGREGÁ estas cuatro líneas:
    button.tipo         = nil
    button.d1           = nil
    button.d2           = nil
    button.d3           = nil

    if button.Model then
        button.Model:Hide()
    end


    if button.Icon then

        button.Icon:SetTexture(
            "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
        )

        button.Icon:Show()

    end


    UpdateSlotName(
        button,
        nil
    )

    UpdateSlotDetails(
        button,
        nil,
        nil,
        nil,
        nil
    )


    if button.Selection then
        button.Selection:Hide()
    end


    button:Enable()

    if PetBattleUI_Team_UpdateActionButtons then
        PetBattleUI_Team_UpdateActionButtons()
    end

end


-- ============================================================
-- QUITAR MASCOTA DEL EQUIPO
-- ============================================================

function PetBattleUI_Team_RemoveSlot(slotIndex)

    local button =
        GetTeamSlotButton(slotIndex)

    if not button
        or not button.spellID then

        return

    end

    if PetBattleUI and PetBattleUI.Send then

        PetBattleUI:Send(
            "PETREMOVE:"
            .. slotIndex
        )

    end

end


-- ============================================================
-- SELECCIONAR SLOT
-- ============================================================

function PetBattleUI_Team_SelectSlot(slotIndex)

    local button =
        GetTeamSlotButton(slotIndex)

    if not button then
        return
    end

    selectedSlot =
        slotIndex


    local selectedText =
        _G[
            "PetBattleUI_TeamSelectedName"
        ]


    if selectedText then

        if button.creatureName then

            selectedText:SetText(
                button.creatureName
            )

        else

            selectedText:SetText(
                L.NONE_SELECTED
            )

        end

    end


    for i = 1, TEAM_MAX_SLOTS do

        local slot =
            GetTeamSlotButton(i)

        if slot
            and slot.Selection then

            if i == slotIndex then

                slot.Selection:Show()

            else

                slot.Selection:Hide()

            end

        end

    end


    if PetBattleUI_Team_UpdateActionButtons then
        PetBattleUI_Team_UpdateActionButtons()
    end

end


-- ============================================================
-- CLICK EN SLOT
-- ============================================================

function PetBattleUI_Team_OnClick(
    slotButton,
    mouseButton
)

    if not slotButton then
        return
    end

    local slotIndex =
        slotButton.slotIndex

    if not slotIndex then
        return
    end


    if mouseButton == "RightButton" then

        PetBattleUI_Team_RemoveSlot(
            slotIndex
        )

        return

    end


    PetBattleUI_Team_SelectSlot(
        slotIndex
    )

end


-- ============================================================
-- DRAG DESDE LA VENTANA DE BLIZZARD
-- ============================================================

hooksecurefunc(
    "PickupCompanion",
    function(
        companionType,
        index
    )

        lastCompanionType =
            companionType

        lastCompanionIndex =
            index

        dragSourceSlot = nil

    end
)


-- ============================================================
-- RECIBIR COMPANERO
-- ============================================================

function PetBattleUI_Team_OnReceiveDrag(slotButton)

    if not slotButton then
        return
    end

    local destinationSlot =
        slotButton.slotIndex

    if not destinationSlot then
        return
    end


    if lastCompanionType
        and lastCompanionIndex then

        if lastCompanionType ~= "CRITTER" then

            lastCompanionType = nil
            lastCompanionIndex = nil

            ClearCursor()

            return

        end


        local creatureID,
              creatureName,
              creatureSpellID,
              icon =
            GetCompanionInfo(
                lastCompanionType,
                lastCompanionIndex
            )


        lastCompanionType = nil
        lastCompanionIndex = nil

        ClearCursor()


        if not creatureSpellID then
            return
        end


        local duplicateSlot =
            FindTeamSlotWithSpell(
                creatureSpellID
            )


        if duplicateSlot
            and duplicateSlot ~= destinationSlot then

            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                    L.PET_ALREADY_IN_TEAM,
                    duplicateSlot
                )
            )

            return

        end


        AssignCompanionToSlot(
            destinationSlot,
            creatureSpellID,
            icon,
            creatureName
        )

        return

    end


    if dragSourceSlot then

        local sourceSlot =
            dragSourceSlot

        dragSourceSlot = nil

        ClearCursor()


        if sourceSlot == destinationSlot then
            return
        end


        local sourceButton =
            GetTeamSlotButton(
                sourceSlot
            )

        local targetButton =
            GetTeamSlotButton(
                destinationSlot
            )


        if not sourceButton
            or not targetButton then

            return

        end


        local sourceSpellID =
            sourceButton.spellID

        local targetSpellID =
            targetButton.spellID

        local sourceName =
            sourceButton.creatureName

        local targetName =
            targetButton.creatureName

        local sourceCreatureID =
            sourceButton.creatureID

        local targetCreatureID =
            targetButton.creatureID


        local sourceIcon = nil
        local targetIcon = nil


        if sourceButton.Icon
            and sourceButton.Icon.GetTexture then

            sourceIcon =
                sourceButton.Icon:GetTexture()

        end


        if targetButton.Icon
            and targetButton.Icon.GetTexture then

            targetIcon =
                targetButton.Icon:GetTexture()

        end


        sourceButton.spellID =
            targetSpellID

        sourceButton.creatureName =
            targetName

        sourceButton.creatureID =
            targetCreatureID


        targetButton.spellID =
            sourceSpellID

        targetButton.creatureName =
            sourceName

        targetButton.creatureID =
            sourceCreatureID


        if sourceButton.Icon then

            sourceButton.Icon:SetTexture(
                targetIcon
                or "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
            )

            sourceButton.Icon:Show()

        end


        if targetButton.Icon then

            targetButton.Icon:SetTexture(
                sourceIcon
                or "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
            )

            targetButton.Icon:Show()

        end


        UpdateSlotName(
            sourceButton,
            sourceButton.creatureName
        )

        UpdateSlotName(
            targetButton,
            targetButton.creatureName
        )


        UpdateSlotDetails(
            sourceButton,
            nil,
            nil,
            nil,
            nil
        )

        UpdateSlotDetails(
            targetButton,
            nil,
            nil,
            nil,
            nil
        )


        if PetBattleUI and PetBattleUI.Send then

            PetBattleUI:Send(
                "SWAP:"
                .. sourceSlot
                .. ":"
                .. destinationSlot
            )

        end


        PetBattleUI_Team_SelectSlot(
            destinationSlot
        )

        return

    end

end


-- ============================================================
-- INICIAR DRAG
-- ============================================================

function PetBattleUI_Team_OnDragStart(slotButton)

    if not slotButton then
        return
    end

    if not slotButton.spellID then
        return
    end


    dragSourceSlot =
        slotButton.slotIndex


    PickupSpell(
        slotButton.spellID
    )

end


-- ============================================================
-- CASILLA DE GESTION
-- ============================================================

local function GetActionSlot()

    return _G[
        "PetBattleUI_TeamActionSlot"
    ]

end


-- ============================================================
-- BOTONES DE ACCION
-- ============================================================

local ACTION_BUTTON_ICON_RELEASE =
    "Interface\\Icons\\INV_Misc_MonsterClaw_03"

local ACTION_BUTTON_ICON_CAGE =
    "Interface\\Icons\\INV_Box_PetCarrier_01"


local function GetReleaseButton()

    return _G[
        "PetBattleUI_TeamReleaseButton"
    ]

end


local function GetConvertButton()

    return _G[
        "PetBattleUI_TeamConvertButton"
    ]

end


local function SetActionButtonState(
    button,
    enabled
)

    if not button then
        return
    end

    button.actionEnabled =
        enabled


    if enabled then

        button:Enable()
        button:EnableMouse(true)

        if button.Icon then

            button.Icon:SetDesaturated(false)
            button.Icon:SetAlpha(1)
            button.Icon:Show()

        end

    else

        button:Enable()
        button:EnableMouse(false)

        if button.Icon then

            button.Icon:SetDesaturated(true)
            button.Icon:SetAlpha(0.4)
            button.Icon:Show()

        end

    end

end


function PetBattleUI_Team_UpdateActionButtons()

    local actionSlot =
        GetActionSlot()

    local activeSlot =
        (actionSlot and actionSlot.sourceSlot)
        or selectedSlot

    local hasPet = false

    if activeSlot then

        local button =
            GetTeamSlotButton(
                activeSlot
            )

        hasPet =
            button ~= nil
            and button.spellID ~= nil

    end

    SetActionButtonState(
        GetReleaseButton(),
        hasPet
    )

    SetActionButtonState(
        GetConvertButton(),
        hasPet
    )

end


local function ClearActionSlot()

    local slot =
        GetActionSlot()

    if not slot then
        return
    end


    slot.sourceSlot = nil
    slot.spellID = nil
    slot.creatureName = nil


    slot:SetNormalTexture(
        "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
    )


    if slot.Name then

        slot.Name:SetText(
            L.DRAG_PET_HERE
        )

    end


    if slot.Icon then
        slot.Icon:Hide()
    end


    if PetBattleUI_Team_UpdateActionButtons then
        PetBattleUI_Team_UpdateActionButtons()
    end

end


local function SetActionSlot(sourceSlot)

    local source =
        GetTeamSlotButton(
            sourceSlot
        )

    local target =
        GetActionSlot()


    if not source
        or not target
        or not source.spellID then

        return

    end


    target.sourceSlot =
        sourceSlot

    target.spellID =
        source.spellID

    target.creatureName =
        source.creatureName


    local texture = nil

    if source.Icon
        and source.Icon.GetTexture then

        texture =
            source.Icon:GetTexture()

    end


    if texture then

        target:SetNormalTexture(
            texture
        )

    else

        target:SetNormalTexture(
            "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
        )

    end


    if target.Name then

        target.Name:SetText(
            source.creatureName
            or L.PET
        )

    end


    if target.Icon then
        target.Icon:Show()
    end


    PetBattleUI_Team_SelectSlot(
        sourceSlot
    )

end


function PetBattleUI_Team_SetActionPet(slotIndex)

    if not slotIndex then
        return
    end

    SetActionSlot(
        slotIndex
    )

end


function PetBattleUI_Team_ActionSlotClick()

    local slot =
        GetActionSlot()

    if not slot
        or not slot.sourceSlot then

        return

    end


    PetBattleUI_Team_SelectSlot(
        slot.sourceSlot
    )

end


-- ============================================================
-- RECIBIR DRAG EN CASILLA DE GESTION
-- ============================================================

function PetBattleUI_Team_ActionSlotReceiveDrag()

    local slot =
        GetActionSlot()

    if not slot then
        return
    end


    if lastCompanionType
        and lastCompanionIndex then

        if lastCompanionType ~= "CRITTER" then

            lastCompanionType = nil
            lastCompanionIndex = nil

            ClearCursor()

            return

        end


        local creatureID,
              creatureName,
              creatureSpellID,
              icon =
            GetCompanionInfo(
                lastCompanionType,
                lastCompanionIndex
            )


        lastCompanionType = nil
        lastCompanionIndex = nil

        ClearCursor()


        if not creatureSpellID then
            return
        end


        local existingSlot =
            FindTeamSlotWithSpell(
                creatureSpellID
            )


        if existingSlot then

            SetActionSlot(
                existingSlot
            )

            return

        end


        local freeSlot =
            FindFreeTeamSlot()


        if not freeSlot then

            DEFAULT_CHAT_FRAME:AddMessage(
                "|cffff4040[PetBattle]|r "
                .. L.TEAM_FULL
            )

            return

        end


        AssignCompanionToSlot(
            freeSlot,
            creatureSpellID,
            icon,
            creatureName
        )


        SetActionSlot(
            freeSlot
        )

        return

    end


    if dragSourceSlot then

        local source =
            dragSourceSlot

        dragSourceSlot = nil

        ClearCursor()


        if source >= 1
            and source <= TEAM_MAX_SLOTS then

            SetActionSlot(
                source
            )

        end

    end

end


-- ============================================================
-- DRAG STOP
-- ============================================================

function PetBattleUI_Team_OnDragStop(slotButton)

    if not dragSourceSlot then
        return
    end

    local sourceSlot =
        dragSourceSlot

    dragSourceSlot = nil

    ClearCursor()

    local actionSlot = GetActionSlot()

    if actionSlot and MouseIsOver(actionSlot) then

        SetActionSlot(sourceSlot)
        return

    end

    -- Verificar si el drag termino sobre alguno de los slots del equipo
    for i = 1, TEAM_MAX_SLOTS do

        local targetButton = GetTeamSlotButton(i)

        if targetButton
            and i ~= sourceSlot
            and MouseIsOver(targetButton) then

            -- Intercambiar los dos slots
            local sourceButton = GetTeamSlotButton(sourceSlot)

            if not sourceButton then
                return
            end

            local sourceSpellID    = sourceButton.spellID
            local sourceName       = sourceButton.creatureName
            local sourceCreatureID = sourceButton.creatureID
            local sourceIcon       = sourceButton.Icon and sourceButton.Icon:GetTexture()
            local sourceTipo       = sourceButton.tipo
            local sourceD1         = sourceButton.d1
            local sourceD2         = sourceButton.d2
            local sourceD3         = sourceButton.d3

            local targetSpellID    = targetButton.spellID
            local targetName       = targetButton.creatureName
            local targetCreatureID = targetButton.creatureID
            local targetIcon       = targetButton.Icon and targetButton.Icon:GetTexture()
            local targetTipo       = targetButton.tipo
            local targetD1         = targetButton.d1
            local targetD2         = targetButton.d2
            local targetD3         = targetButton.d3

            -- Aplicar en ambos botones
            sourceButton.spellID      = targetSpellID
            sourceButton.creatureName = targetName
            sourceButton.creatureID   = targetCreatureID
            sourceButton.tipo         = targetTipo
            sourceButton.d1           = targetD1
            sourceButton.d2           = targetD2
            sourceButton.d3           = targetD3

            targetButton.spellID      = sourceSpellID
            targetButton.creatureName = sourceName
            targetButton.creatureID   = sourceCreatureID
            targetButton.tipo         = sourceTipo
            targetButton.d1           = sourceD1
            targetButton.d2           = sourceD2
            targetButton.d3           = sourceD3

            if sourceButton.Icon then
                sourceButton.Icon:SetTexture(
                    targetIcon or "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
                )
                sourceButton.Icon:Show()
            end

            if targetButton.Icon then
                targetButton.Icon:SetTexture(
                    sourceIcon or "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
                )
                targetButton.Icon:Show()
            end

            -- Actualizar modelos 3D
            if sourceButton.Model then
                if sourceButton.creatureID then
                    sourceButton.Model:SetCreature(sourceButton.creatureID)
                    if sourceButton.Model.SetCamDistanceScale then
                        sourceButton.Model:SetCamDistanceScale(5)
                    end
                    if sourceButton.Model.SetRotation then
                        sourceButton.Model:SetRotation(-70)
                    end
                    sourceButton.Model:Show()
                else
                    sourceButton.Model:Hide()
                end
            end

            if targetButton.Model then
                if targetButton.creatureID then
                    targetButton.Model:SetCreature(targetButton.creatureID)
                    if targetButton.Model.SetCamDistanceScale then
                        targetButton.Model:SetCamDistanceScale(5)
                    end
                    if targetButton.Model.SetRotation then
                        targetButton.Model:SetRotation(-70)
                    end
                    targetButton.Model:Show()
                else
                    targetButton.Model:Hide()
                end
            end

            UpdateSlotName(sourceButton, sourceButton.creatureName)
            UpdateSlotName(targetButton, targetButton.creatureName)

            UpdateSlotDetails(sourceButton, sourceButton.tipo, sourceButton.d1, sourceButton.d2, sourceButton.d3)
            UpdateSlotDetails(targetButton, targetButton.tipo, targetButton.d1, targetButton.d2, targetButton.d3)

            if PetBattleUI and PetBattleUI.Send then
                PetBattleUI:Send(
                    "SWAP:" .. sourceSlot .. ":" .. i
                )
            end

            PetBattleUI_Team_SelectSlot(i)

            return

        end

    end

end


local function GetActionSourceSlot()

    local slot =
        GetActionSlot()


    if slot
        and slot.sourceSlot then

        return slot.sourceSlot

    end


    return selectedSlot

end


local function ShowPetActionError(text)

    --DEFAULT_CHAT_FRAME:AddMessage(
    --    "|cffff4040[PetBattle]|r "
    --    .. (
    --        text
    --        or
    --        L.GENERIC_ERROR
    --    )
    --)

end


local function ShowPetActionOK(text)

    --DEFAULT_CHAT_FRAME:AddMessage(
    --    "|cff40ff40[PetBattle]|r "
    --    .. (
    --        text
    --        or
    --        L.GENERIC_SUCCESS
    --    )
    --)

end


-- ============================================================
-- LIBERAR
-- ============================================================

function PetBattleUI_Team_ForgetSelected()

    local sourceSlot =
        GetActionSourceSlot()


    if not sourceSlot then

        ShowPetActionError(
            L.SELECT_OR_DRAG
        )

        return

    end


    local button =
        GetTeamSlotButton(
            sourceSlot
        )


    if not button
        or not button.spellID then

        ShowPetActionError(
            L.ACTION_SLOT_EMPTY
        )

        return

    end


    local name =
        button.creatureName
        or L.PET


    StaticPopupDialogs[
        "PETBATTLE_FORGET_CONFIRM"
    ] = {

        text =
            string.format(
                L.RELEASE_CONFIRM,
                name
            ),

        button1 =
            L.RELEASE,

        button2 =
            L.CANCEL,

        OnAccept = function()

            if PetBattleUI
                and PetBattleUI.Send then

                PetBattleUI:Send(
                    "PETFORGET:"
                    .. sourceSlot
                )

            end

        end,

        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3

    }


    StaticPopup_Show(
        "PETBATTLE_FORGET_CONFIRM"
    )

end


-- ============================================================
-- ENJAULAR
-- ============================================================

function PetBattleUI_Team_DetachSelected()

    local sourceSlot =
        GetActionSourceSlot()


    if not sourceSlot then

        ShowPetActionError(
            L.SELECT_OR_DRAG
        )

        return

    end


    local button =
        GetTeamSlotButton(
            sourceSlot
        )


    if not button
        or not button.spellID then

        ShowPetActionError(
            L.ACTION_SLOT_EMPTY
        )

        return

    end


    local name =
        button.creatureName
        or L.PET


    StaticPopupDialogs[
        "PETBATTLE_DETACH_CONFIRM"
    ] = {

        text =
            string.format(
                L.CAGE_CONFIRM,
                name
            ),

        button1 =
            L.CAGE,

        button2 =
            L.CANCEL,

        OnAccept = function()

            if PetBattleUI
                and PetBattleUI.Send then

                PetBattleUI:Send(
                    "PETDETACH:"
                    .. sourceSlot
                )

            end

        end,

        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3

    }


    StaticPopup_Show(
        "PETBATTLE_DETACH_CONFIRM"
    )

end


-- ============================================================
-- ALIASES
-- ============================================================

function PetBattleUI_Team_OnReleaseButtonClick()

    PetBattleUI_Team_ForgetSelected()

end


function PetBattleUI_Team_OnConvertButtonClick()

    PetBattleUI_Team_DetachSelected()

end


-- ============================================================
-- RESPUESTA DEL SERVIDOR
-- ============================================================

function PetBattleUI_Team_OnActionResult(
    success,
    action,
    data
)

    if not success then

        ShowPetActionError(
            data
        )

        return

    end


    ShowPetActionOK(
        data
    )


    local slotIndex =
        tonumber(action)


    if slotIndex
        and slotIndex >= 1
        and slotIndex <= TEAM_MAX_SLOTS then

        PetBattleUI_Team_ClearSlot(
            slotIndex
        )

    end


    local slot =
        GetActionSlot()


    if slot
        and slot.sourceSlot == slotIndex then

        ClearActionSlot()

    end


    if selectedSlot == slotIndex then

        selectedSlot = nil


        local selectedText =
            _G[
                "PetBattleUI_TeamSelectedName"
            ]


        if selectedText then

            selectedText:SetText(
                L.NONE_SELECTED
            )

        end

    end


    if PetBattleUI_Team_UpdateActionButtons then
        PetBattleUI_Team_UpdateActionButtons()
    end

end


-- ============================================================
-- ABRIR / CERRAR CON COMPANEROS
-- ============================================================

if PetPaperDollFrameCompanionFrame then

    PetPaperDollFrameCompanionFrame:HookScript(
        "OnShow",
        function()

            PetBattleUI_Team_Show()

        end
    )


    PetPaperDollFrameCompanionFrame:HookScript(
        "OnHide",
        function()

            PetBattleUI_Team_Hide()

        end
    )

end


-- ============================================================
-- CONFIGURACION DE SLOTS
-- ============================================================

local function SetupTeamSlots()

    for i = 1, TEAM_MAX_SLOTS do

        local button =
            GetTeamSlotButton(i)


        if button then

            button.slotIndex = i


            local buttonName =
                button:GetName()


            button.Icon =
                _G[buttonName .. "Icon"]

            button.Name =
                _G[buttonName .. "Name"]

            button.Type =
                _G[buttonName .. "Type"]

            button.Damage =
                _G[buttonName .. "Damage"]

            button.Model =
                _G[buttonName .. "Model"]

            button.Number =
                _G[buttonName .. "Number"]


            if button.Number then

                button.Number:SetFont(
                    "Fonts\\FRIZQT__.TTF",
                    25,
                    "OUTLINE"
                )

            end


            -- =================================================
            -- SELECCION DORADA
            -- =================================================

            button.Selection =
                button:CreateTexture(
                    nil,
                    "ARTWORK"
                )


            button.Selection:SetSize(
                360,
                84
            )


            button.Selection:SetPoint(
                "TOPLEFT",
                button,
                "TOPLEFT",
                0,
                0
            )


            button.Selection:SetTexture(
                1,
                0.65,
                0,
                0.10
            )


            button.Selection:Hide()


            button:RegisterForClicks(
                "LeftButtonUp",
                "RightButtonUp"
            )


            button:SetScript(
                "OnClick",
                function(
                    self,
                    mouseButton
                )

                    PetBattleUI_Team_OnClick(
                        self,
                        mouseButton
                    )

                end
            )


            button:SetScript(
                "OnDragStart",
                function(self)

                    PetBattleUI_Team_OnDragStart(
                        self
                    )

                end
            )


            button:SetScript(
                "OnDragStop",
                function(self)

                    PetBattleUI_Team_OnDragStop(
                        self
                    )

                end
            )


            button:SetScript(
                "OnReceiveDrag",
                function(self)

                    PetBattleUI_Team_OnReceiveDrag(
                        self
                    )

                end
            )


            PetBattleUI_Team_ClearSlot(i)

        end

    end

end


-- ============================================================
-- CONFIGURAR CASILLA DE GESTION
-- ============================================================

local function SetupActionSlot()

    local slot =
        GetActionSlot()


    if not slot then
        return
    end


    local slotName =
        slot:GetName()


    slot.Name =
        _G[slotName .. "Name"]

    slot.Icon =
        _G[slotName .. "Icon"]


    slot:RegisterForClicks(
        "LeftButtonUp",
        "RightButtonUp"
    )


    slot:RegisterForDrag(
        "LeftButton"
    )


    slot:SetScript(
        "OnClick",
        function(
            self,
            mouseButton
        )

            if mouseButton == "RightButton" then

                ClearActionSlot()

                return

            end


            PetBattleUI_Team_ActionSlotClick()

        end
    )


    slot:SetScript(
        "OnReceiveDrag",
        function()

            PetBattleUI_Team_ActionSlotReceiveDrag()

        end
    )


    slot:SetScript(
        "OnDragStart",
        function(self)

            if not self.sourceSlot then
                return
            end


            local source =
                GetTeamSlotButton(
                    self.sourceSlot
                )


            if source
                and source.spellID then

                dragSourceSlot =
                    self.sourceSlot

                PickupSpell(
                    source.spellID
                )

            end

        end
    )


    slot:SetScript(
        "OnDragStop",
        function()

            if dragSourceSlot then

                dragSourceSlot = nil

                ClearCursor()

            end

        end
    )


    ClearActionSlot()

end


-- ============================================================
-- CONFIGURAR BOTONES LIBERAR / ENJAULAR
-- ============================================================

local function SetupSingleActionButton(
    button,
    icon,
    tooltipTitle,
    tooltipText
)

    if not button then
        return
    end


    button:SetNormalTexture(icon)
    button:SetPushedTexture(icon)


    button.Icon =
        button:GetNormalTexture()


    if button.Icon then
        button.Icon:Show()
    end


    local highlight =
        button:GetHighlightTexture()


    if not highlight then

        button:SetHighlightTexture(
            "Interface\\Buttons\\ButtonHilight-Square",
            "ADD"
        )

    end


    button:SetScript(
        "OnEnter",
        function(self)

            GameTooltip:SetOwner(
                self,
                "ANCHOR_TOP"
            )

            GameTooltip:AddLine(
                tooltipTitle
            )

            GameTooltip:AddLine(
                tooltipText,
                1,
                1,
                1,
                true
            )

            GameTooltip:Show()

        end
    )


    button:SetScript(
        "OnLeave",
        function()

            GameTooltip:Hide()

        end
    )


    button.actionEnabled =
        false

    button:Enable()
    button:EnableMouse(false)


    if button.Icon then

        button.Icon:SetDesaturated(true)
        button.Icon:SetAlpha(0.4)
        button.Icon:Show()

    end

end


local function SetupActionButtons()

    SetupSingleActionButton(
        GetReleaseButton(),
        ACTION_BUTTON_ICON_RELEASE,
        L.RELEASE,
        L.RELEASE_TOOLTIP
    )


    SetupSingleActionButton(
        GetConvertButton(),
        ACTION_BUTTON_ICON_CAGE,
        L.CAGE,
        L.CAGE_TOOLTIP
    )

end


-- ============================================================
-- INICIALIZACION
-- ============================================================

local initFrame =
    CreateFrame("Frame")


initFrame:RegisterEvent(
    "PLAYER_LOGIN"
)


initFrame:SetScript(
    "OnEvent",
    function()

        SetupTeamSlots()
        SetupActionSlot()
        SetupActionButtons()

        -- ====================================================
        -- ACTUALIZAR ENCABEZADO
        -- ====================================================

        UpdateTeamHeader()

    end
)


-- ============================================================
-- SLOT RECIBIDO DEL SERVIDOR
-- ============================================================

function PetBattleUI_Team_SetServerSlot(
    slotIndex,
    spellID,
    creatureName,
    icon,
    tipo,
    d1,
    d2,
    d3,
    creatureID
)

    if not slotIndex then
        return
    end


    if slotIndex < 1
        or slotIndex > TEAM_MAX_SLOTS then

        return

    end


    local button =
        GetTeamSlotButton(
            slotIndex
        )


    local sameSpell =
        button
        and button.spellID == spellID


    -- ========================================================
    -- RESOLVER ICONO
    -- ========================================================

    if icon == "" then

        if sameSpell
            and button.Icon
            and button.Icon.GetTexture then

            icon =
                button.Icon:GetTexture()

        end


        if not icon or icon == "" then

            local _
            local _
            local resolvedIcon

            _, _, resolvedIcon =
                GetSpellInfo(
                    spellID
                )

            icon =
                resolvedIcon

        end

    end


    -- ========================================================
    -- RESOLVER NOMBRE
    -- ========================================================

    if creatureName == "" then

        if sameSpell
            and button.creatureName then

            creatureName =
                button.creatureName

        else

            creatureName =
                GetSpellInfo(
                    spellID
                )

        end

    end


    PetBattleUI_Team_UpdateSlot(
        slotIndex,
        spellID,
        icon,
        creatureName,
        tipo,
        d1,
        d2,
        d3,
        creatureID
    )

end
