---@class Sorter
local Sorter = QuestieLoader:ImportModule("Sorter")

-- When each quest was accepted, built from My Journey. The journey position orders accepts within the same second.
---@type table<QuestId, {time: number, position: number}>
local accepts = {}
local scannedLength = 0
local lastScannedEntry

---@param journey JourneyEntry[]
---@param firstPosition number
local function _ScanJourney(journey, firstPosition)
    for position = firstPosition, #journey do
        local entry = journey[position]
        if entry.Event == "Quest" and entry.SubType == "Accept" and entry.Quest and entry.Timestamp then
            -- A quest accepted again uses its latest accept
            accepts[entry.Quest] = {time = entry.Timestamp, position = position}
        end
    end
    scannedLength = #journey
    lastScannedEntry = journey[scannedLength]
end

---@return table<QuestId, {time: number, position: number}> accepts
local function _GetAccepts()
    local journey = Questie.db.char.journey or {}

    if #journey >= scannedLength and journey[scannedLength] == lastScannedEntry then
        -- The journey only grew, entries are appended
        if #journey > scannedLength then
            _ScanJourney(journey, scannedLength + 1)
        end
    else
        -- Entries were removed or replaced
        accepts = {}
        _ScanJourney(journey, 1)
    end

    return accepts
end

-- Quests My Journey has no accept for count as accepted first
local NO_ACCEPT = {time = 0, position = 0}

---@param acceptA {time: number, position: number}
---@param acceptB {time: number, position: number}
---@return boolean
local function _IsAcceptedEarlier(acceptA, acceptB, questIdA, questIdB)
    if acceptA.time ~= acceptB.time then
        return acceptA.time < acceptB.time
    end
    if acceptA.position ~= acceptB.position then
        return acceptA.position < acceptB.position
    end
    return questIdA < questIdB
end

--- Sorts the given questIds in place by when they were accepted, with the earliest accepted quests first.
--- Quests My Journey has no accept for count as accepted first.
---@param questIds QuestId[]
---@param _questDetails table<QuestId, QuestSortDetails>
function Sorter.byAccepted(questIds, _questDetails)
    local acceptsByQuest = _GetAccepts()
    table.sort(questIds, function(questIdA, questIdB)
        return _IsAcceptedEarlier(acceptsByQuest[questIdA] or NO_ACCEPT, acceptsByQuest[questIdB] or NO_ACCEPT, questIdA, questIdB)
    end)
end

--- Sorts the given questIds in place by when they were accepted, with the latest accepted quests first.
--- Quests My Journey has no accept for count as accepted first, so they are listed last.
---@param questIds QuestId[]
---@param _questDetails table<QuestId, QuestSortDetails>
function Sorter.byAcceptedReverse(questIds, _questDetails)
    local acceptsByQuest = _GetAccepts()
    table.sort(questIds, function(questIdA, questIdB)
        return _IsAcceptedEarlier(acceptsByQuest[questIdB] or NO_ACCEPT, acceptsByQuest[questIdA] or NO_ACCEPT, questIdB, questIdA)
    end)
end
