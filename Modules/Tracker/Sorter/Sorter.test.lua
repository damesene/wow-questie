dofile("setupTests.lua")

describe("Sorter", function()
    ---@type Sorter
    local Sorter

    before_each(function()
        QuestieLoader:ImportModule("QuestieTracker").Update = spy.new(function() end)
        dofile("Localization/l10n.lua")
        dofile("Modules/Tracker/Sorter/Sorter.lua")
        Sorter = QuestieLoader:ImportModule("Sorter")
    end)

    describe("SetSorting", function()
        it("should store the sorting and update the tracker", function()
            local tracker = QuestieLoader:ImportModule("QuestieTracker")

            Sorter.SetSorting("byLevelReversed")

            assert.are.equal("byLevelReversed", Questie.db.profile.trackerSortObjectives)
            assert.spy(tracker.Update).was.called_with(tracker)
        end)
    end)

    describe("GetSortOptions", function()
        it("should offer every way of sorting the tracker supports", function()
            local keys = {}
            for _, sortOption in ipairs(Sorter.GetSortOptions()) do
                table.insert(keys, sortOption.key)
            end

            assert.are_same({
                "byComplete", "byCompleteReversed", "byLevel", "byLevelReversed", "byAccepted", "byAcceptedReversed",
                "byProximity", "byProximityReversed",
                "byZone", "byZonePlayerProximity", "byZonePlayerProximityReversed",
            }, keys)
        end)

        it("should show the percent sign in the labels", function()
            assert.are.equal("By % Complete", Sorter.GetSortOptions()[1].label)
        end)
    end)
end)
