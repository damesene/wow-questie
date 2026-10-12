---@class TrackerQuestFrame
local TrackerQuestFrame = QuestieLoader:CreateModule("TrackerQuestFrame")
-------------------------
--Import QuestieTracker modules.
-------------------------
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieLoader:ImportModule("QuestieCombatQueue")
---@type TrackerBaseFrame
local TrackerBaseFrame = QuestieLoader:ImportModule("TrackerBaseFrame")
---@type TrackerFadeTicker
local TrackerFadeTicker = QuestieLoader:ImportModule("TrackerFadeTicker")
---@type TrackerUtils
local TrackerUtils = QuestieLoader:ImportModule("TrackerUtils")
---@type TrackerQuestFilterBox
local TrackerQuestFilterBox = QuestieLoader:ImportModule("TrackerQuestFilterBox")

local questFrame, trackerBaseFrame, trackerHeaderFrame
local filterBoxHeight = 0

function TrackerQuestFrame.Initialize(baseFrame, headerFrame)
    trackerBaseFrame = baseFrame
    trackerHeaderFrame = headerFrame

    -- TrackerQuestFrame
    questFrame = CreateFrame("Frame", "TrackedQuests", trackerBaseFrame)
    questFrame:SetWidth(25)
    questFrame:SetHeight(25)

    TrackerQuestFrame.PositionTrackedQuestsFrame()

    questFrame:EnableMouse(true)
    questFrame:SetMovable(true)
    questFrame:SetResizable(true)
    questFrame:RegisterForDrag("LeftButton")
    questFrame:SetScript("OnDragStart", TrackerBaseFrame.OnDragStart)
    questFrame:SetScript("OnDragStop", TrackerBaseFrame.OnDragStop)
    questFrame:SetScript("OnEnter", TrackerFadeTicker.Unfade)
    questFrame:SetScript("OnLeave", TrackerFadeTicker.Fade)

    questFrame.ScrollFrame = CreateFrame("ScrollFrame", "TrackedQuestsScrollFrame", questFrame, "ScrollFrameTemplate")
    questFrame.ScrollFrame:SetAllPoints(questFrame)
    questFrame.ScrollFrame.ScrollBar:Hide()

    questFrame.ScrollChildFrame = CreateFrame("Frame", "TrackedQuestsScrollChildFrame")
    questFrame.ScrollChildFrame:SetSize(questFrame.ScrollFrame:GetWidth(), (questFrame.ScrollFrame:GetHeight()))

    questFrame.ScrollFrame:SetScrollChild(questFrame.ScrollChildFrame)

    questFrame.FilterBox = TrackerQuestFilterBox.Initialize(questFrame)
    filterBoxHeight = 0

    questFrame:Hide()

    TrackerQuestFrame.questFrame = questFrame

    return questFrame
end

function TrackerQuestFrame:Update()
    if Questie.db.char.isTrackerExpanded then
        questFrame:ClearAllPoints()
        TrackerQuestFrame.PositionTrackedQuestsFrame()

        questFrame:Show()

        -- Enables Click-Through when the tracker is locked
        if IsControlKeyDown() or (not Questie.db.profile.trackerLocked) then
            QuestieCombatQueue:Queue(function()
                questFrame:EnableMouse(true)
                questFrame:SetMovable(true)
                questFrame:SetResizable(true)
            end)
        else
            QuestieCombatQueue:Queue(function()
                questFrame:EnableMouse(false)
                questFrame:SetMovable(false)
                questFrame:SetResizable(false)
            end)
        end
    else
        questFrame:Hide()
    end
end

---Shows or hides the quest filter box and places the scrolling quests below it.
---@param canShow boolean False while the tracker lists no quests to filter
function TrackerQuestFrame.UpdateFilterBox(canShow)
    local height = TrackerQuestFilterBox.Update(canShow)
    if height == filterBoxHeight then
        return
    end
    filterBoxHeight = height

    local scrollFrame = questFrame.ScrollFrame
    scrollFrame:ClearAllPoints()
    if height > 0 then
        scrollFrame:SetPoint("TOPLEFT", questFrame, "TOPLEFT", 0, -height)
        scrollFrame:SetPoint("BOTTOMRIGHT", questFrame, "BOTTOMRIGHT", 0, 0)
    else
        scrollFrame:SetAllPoints(questFrame)
    end
end

---@return number height The height the quest filter box takes at the top of the quest frame, 0 when it is hidden
function TrackerQuestFrame.GetFilterBoxHeight()
    return filterBoxHeight
end

function TrackerQuestFrame.PositionTrackedQuestsFrame()
    local QuestieTrackerLoc = Questie.db.profile.TrackerLocation
    if Questie.db.profile.trackerHeaderEnabled or (Questie.db.profile.alwaysShowTracker and not TrackerUtils.HasQuest()) then
        if Questie.db.profile.moveHeaderToBottom then
            -- Move the tracker header to the bottom
            questFrame:SetPoint("BOTTOMLEFT", trackerHeaderFrame, "TOPLEFT", 0, 4)
        else
            -- Move the tracker header to the top
            questFrame:SetPoint("TOPLEFT", trackerHeaderFrame, "BOTTOMLEFT", 0, 0)
        end
    elseif QuestieTrackerLoc and (QuestieTrackerLoc[1] == "BOTTOMLEFT" or QuestieTrackerLoc[1] == "BOTTOMRIGHT") then
        -- No header. TrackedQuestsFrame is attached to the bottom.
        questFrame:SetPoint("BOTTOMLEFT", trackerBaseFrame, "BOTTOMLEFT", 0, 10)
    else
        -- No header. TrackedQuestsFrame is attached to the top.
        questFrame:SetPoint("TOPLEFT", trackerBaseFrame, "TOPLEFT", 0, -10)
    end
end
