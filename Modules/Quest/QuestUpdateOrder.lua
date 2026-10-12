-- Remembers in which order the quests in the quest log were last accepted or progressed.
-- A counter instead of a time keeps the order exact for changes in the same second and does not depend on the clock.
---@class QuestUpdateOrder
local QuestUpdateOrder = QuestieLoader:CreateModule("QuestUpdateOrder")

---Marks the quest as the most recently updated one.
---@param questId QuestId
function QuestUpdateOrder.Record(questId)
    local counter = Questie.db.char.questUpdateCounter + 1
    Questie.db.char.questUpdateCounter = counter
    Questie.db.char.questUpdateOrder[questId] = counter
end

---@param questId QuestId
function QuestUpdateOrder.Remove(questId)
    Questie.db.char.questUpdateOrder[questId] = nil
end

---Forgets quests that left the quest log while Questie could not notice, e.g. abandoned right before a logout.
---@param questIdsInLog table<QuestId, any> The quests in the quest log
function QuestUpdateOrder.Prune(questIdsInLog)
    for questId in pairs(Questie.db.char.questUpdateOrder) do
        if not questIdsInLog[questId] then
            Questie.db.char.questUpdateOrder[questId] = nil
        end
    end
end

---@param questId QuestId
---@return number order Higher means updated more recently, 0 for a quest without a recorded update
function QuestUpdateOrder.Get(questId)
    return Questie.db.char.questUpdateOrder[questId] or 0
end

---A quest progressed when an objective counts up or the quest becomes complete. Losing quest items is no progress.
---@param previous QuestLogCacheData The cached quest before the change
---@param current QuestLogCacheData The cached quest after the change
---@return boolean
function QuestUpdateOrder.HasProgressed(previous, current)
    if current.isComplete == 1 and previous.isComplete ~= 1 then
        return true
    end

    for index, objective in pairs(current.objectives or {}) do
        local previousObjective = previous.objectives and previous.objectives[index]
        if (not previousObjective) or (objective.numFulfilled or 0) > (previousObjective.numFulfilled or 0) then
            return true
        end
    end

    return false
end
