---@class TrackerSortButton
local TrackerSortButton = QuestieLoader:CreateModule("TrackerSortButton")

---@type TrackerMenu
local TrackerMenu = QuestieLoader:ImportModule("TrackerMenu")
---@type TrackerBaseFrame
local TrackerBaseFrame = QuestieLoader:ImportModule("TrackerBaseFrame")
---@type TrackerFadeTicker
local TrackerFadeTicker = QuestieLoader:ImportModule("TrackerFadeTicker")
---@type Sorter
local Sorter = QuestieLoader:ImportModule("Sorter")
---@type Expansions
local Expansions = QuestieLoader:ImportModule("Expansions")
---@type l10n
local l10n = QuestieLoader:ImportModule("l10n")

local LibDropDown = LibStub:GetLibrary("LibUIDropDownMenuQuestie-4.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local MARGIN_RIGHT = 8
-- Keeps the button clear of the header text
TrackerSortButton.SPACING = 4

---@type Button
local sortButton

---@param sortKey string
local function _SetSorting(sortKey)
    Sorter.SetSorting(sortKey)
    -- The options window shows the sorting as well
    AceConfigRegistry:NotifyChange("Questie")
end

---@return table menu The sorting dropdown entries
function TrackerSortButton.GetMenu()
    local menu = {
        {text = l10n("Objective Sorting"), isTitle = true, notCheckable = true},
    }

    for _, sortOption in ipairs(Sorter.GetSortOptions()) do
        table.insert(menu, {
            text = sortOption.label,
            checked = function() return Questie.db.profile.trackerSortObjectives == sortOption.key end,
            func = function()
                LibDropDown:CloseDropDownMenus()
                _SetSorting(sortOption.key)
            end,
        })
    end

    return menu
end

---@param self Button
local function _OnClick(self)
    LibDropDown:EasyMenu(TrackerSortButton.GetMenu(), TrackerMenu.menuFrame, self, 0, 0, "MENU")
end

---@param self Button
local function _OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    GameTooltip:AddLine(l10n("Objective Sorting"))
    for _, sortOption in ipairs(Sorter.GetSortOptions()) do
        if sortOption.key == Questie.db.profile.trackerSortObjectives then
            GameTooltip:AddLine(sortOption.label, 1, 1, 1)
        end
    end
    GameTooltip:Show()

    TrackerFadeTicker.Unfade(self)
end

---@param self Button
local function _OnLeave(self)
    GameTooltip:Hide()

    TrackerFadeTicker.Fade(self)
end

---@param headerFrame Frame The tracker header, the button is part of it and hides with it
---@return Button sortButton
function TrackerSortButton.Initialize(headerFrame)
    sortButton = CreateFrame("Button", "Questie_TrackerSortButton", headerFrame)
    sortButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    sortButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    sortButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    sortButton:RegisterForClicks("LeftButtonUp")
    sortButton:RegisterForDrag("LeftButton")
    sortButton:SetScript("OnClick", _OnClick)
    sortButton:SetScript("OnEnter", _OnEnter)
    sortButton:SetScript("OnLeave", _OnLeave)
    -- Like the rest of the header, dragging the button moves the tracker
    sortButton:SetScript("OnDragStart", TrackerBaseFrame.OnDragStart)
    sortButton:SetScript("OnDragStop", TrackerBaseFrame.OnDragStop)
    sortButton:Hide()

    return sortButton
end

---@return boolean listsCriteria True while the tracker lists Challenge Mode or Scenario criteria instead of quests
local function _ListsCriteria()
    if Expansions.Current < Expansions.MoP then
        return false
    end

    local _, instanceType, _, difficultyName = GetInstanceInfo()
    return (instanceType ~= "none" and difficultyName == "Challenge Mode") or instanceType == "scenario"
end

---@return boolean shown True when the tracker header shows the sorting button
function TrackerSortButton.IsShown()
    return Questie.db.profile.trackerShowSortButton and Questie.db.profile.trackerHeaderEnabled and Questie.db.char.isTrackerExpanded
        and (not _ListsCriteria())
end

---Places the button on the right side of the tracker header row.
---@param trackerBaseFrame Frame
---@param size number The height of the header text
---@param isShown boolean The result of TrackerSortButton.IsShown
function TrackerSortButton.Update(trackerBaseFrame, size, isShown)
    if not isShown then
        sortButton:Hide()
        return
    end

    sortButton:SetSize(size, size)
    sortButton:ClearAllPoints()
    -- Same rows as TrackerHeaderFrame.PositionTrackerHeaderFrame for an expanded tracker
    if Questie.db.profile.moveHeaderToBottom then
        sortButton:SetPoint("BOTTOMRIGHT", trackerBaseFrame, "BOTTOMRIGHT", -MARGIN_RIGHT, 5)
    else
        sortButton:SetPoint("TOPRIGHT", trackerBaseFrame, "TOPRIGHT", -MARGIN_RIGHT, -10)
    end
    sortButton:Show()
end
