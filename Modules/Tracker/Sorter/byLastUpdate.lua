---@class Sorter
local Sorter = QuestieLoader:ImportModule("Sorter")

---@type QuestUpdateOrder
local QuestUpdateOrder = QuestieLoader:ImportModule("QuestUpdateOrder")

--- Sorts the given questIds in place by when they were last accepted or progressed, with the least recently updated quests first.
--- Quests without a recorded update count as updated first.
---@param questIds QuestId[]
---@param _questDetails table<QuestId, QuestSortDetails>
function Sorter.byLastUpdate(questIds, _questDetails)
    table.sort(questIds, function(questIdA, questIdB)
        local orderA = QuestUpdateOrder.Get(questIdA)
        local orderB = QuestUpdateOrder.Get(questIdB)
        if orderA == orderB then
            return questIdA < questIdB
        end
        return orderA < orderB
    end)
end

--- Sorts the given questIds in place by when they were last accepted or progressed, with the most recently updated quests first.
--- Quests without a recorded update count as updated first, so they are listed last ordered by quest ID.
---@param questIds QuestId[]
---@param _questDetails table<QuestId, QuestSortDetails>
function Sorter.byLastUpdateReverse(questIds, _questDetails)
    table.sort(questIds, function(questIdA, questIdB)
        local orderA = QuestUpdateOrder.Get(questIdA)
        local orderB = QuestUpdateOrder.Get(questIdB)
        if orderA == orderB then
            return questIdA < questIdB
        end
        return orderA > orderB
    end)
end
