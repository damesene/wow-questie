---@class TrackerQuestFilterBox
local TrackerQuestFilterBox = QuestieLoader:CreateModule("TrackerQuestFilterBox")

---@type QuestieTracker
local QuestieTracker = QuestieLoader:ImportModule("QuestieTracker")
---@type TrackerQuestFilter
local TrackerQuestFilter = QuestieLoader:ImportModule("TrackerQuestFilter")
---@type TrackerFadeTicker
local TrackerFadeTicker = QuestieLoader:ImportModule("TrackerFadeTicker")
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieLoader:ImportModule("QuestieCombatQueue")
---@type l10n
local l10n = QuestieLoader:ImportModule("l10n")

local LSM30 = LibStub("LibSharedMedia-3.0")

local MARGIN_LEFT = 14
local MARGIN_RIGHT = 10
local SPACING_BELOW = 4
-- Longer than the 0.1s throttle of QuestieTracker:Update, so the last typed letter is never dropped
local UPDATE_DELAY = 0.2 -- seconds

---@type EditBox
local filterBox
local updateVersion = 0
-- The font settings the filter box uses, so it is only changed when they change
local appliedFont = {}

---Updates the tracker once typing pauses, so not every letter rebuilds the tracker.
local function _ScheduleTrackerUpdate()
    updateVersion = updateVersion + 1
    local version = updateVersion

    C_Timer.After(UPDATE_DELAY, function()
        if version ~= updateVersion then
            return
        end
        QuestieCombatQueue:Queue(function()
            QuestieTracker:Update()
        end)
    end)
end

---@param self EditBox
local function _OnTextChanged(self)
    local text = self:GetText()
    local isEmpty = text == ""

    self.clearButton:SetShown(not isEmpty)
    self.placeholder:SetShown(isEmpty)

    TrackerQuestFilter.SetText(text)
    _ScheduleTrackerUpdate()
end

---@param parent Frame The tracker quest frame, the filter box sits at its top
---@return EditBox filterBox
function TrackerQuestFilterBox.Initialize(parent)
    filterBox = CreateFrame("EditBox", "Questie_TrackerQuestFilter", parent, "InputBoxTemplate")
    filterBox:SetPoint("TOPLEFT", parent, "TOPLEFT", MARGIN_LEFT, 0)
    filterBox:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -MARGIN_RIGHT, 0)
    filterBox:SetAutoFocus(false)
    filterBox:SetMaxLetters(100)

    local placeholder = filterBox:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    placeholder:SetPoint("LEFT", filterBox, "LEFT", 0, 0)
    placeholder:SetText(l10n("Search"))
    filterBox.placeholder = placeholder

    local clearButton = CreateFrame("Button", nil, filterBox)
    clearButton:SetPoint("RIGHT", filterBox, "RIGHT", -2, 0)
    clearButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    clearButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    clearButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    clearButton:SetScript("OnClick", TrackerQuestFilterBox.Clear)
    clearButton:Hide()
    filterBox.clearButton = clearButton

    filterBox:SetScript("OnTextChanged", _OnTextChanged)
    filterBox:SetScript("OnEnterPressed", filterBox.ClearFocus)
    filterBox:SetScript("OnEscapePressed", filterBox.ClearFocus)
    filterBox:SetScript("OnEnter", TrackerFadeTicker.Unfade)
    filterBox:SetScript("OnLeave", TrackerFadeTicker.Fade)

    filterBox:Hide()
    appliedFont = {}

    return filterBox
end

---Removes the filter, the tracker shows all quests again.
function TrackerQuestFilterBox.Clear()
    filterBox:SetText("")
    filterBox:ClearFocus()
end

---Shows the filter box when it is enabled and adapts it to the quest font.
---@param canShow boolean False while the tracker lists no quests to filter
---@return number height The height the filter box takes at the top of the quest frame, 0 when it is hidden
function TrackerQuestFilterBox.Update(canShow)
    if not Questie.db.profile.trackerShowQuestFilter then
        if filterBox:GetText() ~= "" then
            -- A disabled filter must not keep hiding quests
            filterBox:SetText("")
        end
    end

    if not (Questie.db.profile.trackerShowQuestFilter and canShow) then
        filterBox:ClearFocus()
        filterBox:Hide()
        return 0
    end

    local fontSize = Questie.db.profile.trackerFontSizeQuest
    local fontName = Questie.db.profile.trackerFontQuest
    local fontOutline = Questie.db.profile.trackerFontOutline
    local height = fontSize + 10

    if fontSize ~= appliedFont.size or fontName ~= appliedFont.name or fontOutline ~= appliedFont.outline then
        local font = LSM30:Fetch("font", fontName)
        filterBox:SetFont(font, fontSize, fontOutline)
        filterBox.placeholder:SetFont(font, fontSize, fontOutline)
        filterBox:SetHeight(height)
        filterBox.clearButton:SetSize(height - 2, height - 2)
        filterBox:SetTextInsets(0, height, 0, 0)
        appliedFont = {size = fontSize, name = fontName, outline = fontOutline}
    end
    filterBox:Show()

    return height + SPACING_BELOW
end
