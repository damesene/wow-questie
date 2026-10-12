---@class Sorter
local Sorter = QuestieLoader:CreateModule("Sorter")

---@type QuestieTracker
local QuestieTracker = QuestieLoader:ImportModule("QuestieTracker")
---@type l10n
local l10n = QuestieLoader:ImportModule("l10n")

---@class SortOption
---@field key string The value of Questie.db.profile.trackerSortObjectives
---@field label string

---Changes how the tracker sorts quests and shows the new order.
---@param sortKey string One of the keys of Sorter.GetSortOptions
function Sorter.SetSorting(sortKey)
    Questie.db.profile.trackerSortObjectives = sortKey
    QuestieTracker:Update()
end

---@return SortOption[] sortOptions Every way the tracker can sort quests, in the order they are offered
function Sorter.GetSortOptions()
    return {
        {key = "byComplete", label = l10n("By %% Complete")},
        {key = "byCompleteReversed", label = l10n("By %% Complete (Reversed)")},
        {key = "byLevel", label = l10n("By Level")},
        {key = "byLevelReversed", label = l10n("By Level (Reversed)")},
        {key = "byAccepted", label = l10n("By Accepted")},
        {key = "byAcceptedReversed", label = l10n("By Accepted (Reversed)")},
        {key = "byLastUpdate", label = l10n("By Last Update")},
        {key = "byLastUpdateReversed", label = l10n("By Last Update (Reversed)")},
        {key = "byProximity", label = l10n("By Proximity")},
        {key = "byProximityReversed", label = l10n("By Proximity (Reversed)")},
        {key = "byZone", label = l10n("By Zone")},
        {key = "byZonePlayerProximity", label = l10n("By Zone Prox")},
        {key = "byZonePlayerProximityReversed", label = l10n("By Zone Prox (Reversed)")},
    }
end

---@class QuestSortDetails
---@field questCompletePercent number
---@field quest Quest
---@field zoneName string
