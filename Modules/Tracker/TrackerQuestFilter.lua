---@class TrackerQuestFilter
local TrackerQuestFilter = QuestieLoader:CreateModule("TrackerQuestFilter")

local tinsert = table.insert
local strlower, strfind = string.lower, string.find

-- Lower case search text, empty when nothing is filtered. It is not saved, a reload clears the filter.
local searchText = ""

---@param text string|nil The text typed into the tracker filter box
function TrackerQuestFilter.SetText(text)
    searchText = strlower(string.match(text or "", "^%s*(.-)%s*$"))
end

---@return boolean active True when the tracker only shows the quests matching the filter
function TrackerQuestFilter.IsActive()
    return Questie.db.profile.trackerShowQuestFilter and searchText ~= ""
end

---Like the search of the quest log, a quest matches by its title or by the text of one of its objectives.
---@param quest TrackerQuest
---@return boolean
function TrackerQuestFilter.QuestMatches(quest)
    if quest.name and strfind(strlower(quest.name), searchText, 1, true) then
        return true
    end

    for _, objective in pairs(quest.Objectives or {}) do
        if objective.Description and strfind(strlower(objective.Description), searchText, 1, true) then
            return true
        end
    end

    return false
end

---@param sortedQuestIds QuestId[]
---@param questDetails table<QuestId, QuestSortDetails>
---@return QuestId[] questIds The quests matching the filter in sort order, sortedQuestIds itself when nothing is filtered
function TrackerQuestFilter.FilterQuestIds(sortedQuestIds, questDetails)
    if not TrackerQuestFilter.IsActive() then
        return sortedQuestIds
    end

    local questIds = {}
    for _, questId in ipairs(sortedQuestIds) do
        if TrackerQuestFilter.QuestMatches(questDetails[questId].quest) then
            tinsert(questIds, questId)
        end
    end

    return questIds
end
