dofile("setupTests.lua")

describe("TrackerQuestFilter", function()
    ---@type TrackerQuestFilter
    local TrackerQuestFilter

    local sortedQuestIds
    local questDetails

    before_each(function()
        Questie.db.profile.trackerShowQuestFilter = true

        sortedQuestIds = {1, 2, 3}
        questDetails = {
            [1] = {quest = {name = "Call of Water", Objectives = {{Description = "Shard of Water"}}}},
            [2] = {quest = {name = "Deviate Eradication", Objectives = {{Description = "Deviate Ravager slain"}, {Description = "Deviate Dreadfang slain"}}}},
            [3] = {quest = {name = "Serpentbloom", Objectives = {}}},
        }

        dofile("Modules/Tracker/TrackerQuestFilter.lua")
        TrackerQuestFilter = QuestieLoader:ImportModule("TrackerQuestFilter")
    end)

    describe("IsActive", function()
        it("should not be active without text", function()
            TrackerQuestFilter.SetText("")

            assert.is_false(TrackerQuestFilter.IsActive())
        end)

        it("should not be active for whitespace only", function()
            TrackerQuestFilter.SetText("   ")

            assert.is_false(TrackerQuestFilter.IsActive())
        end)

        it("should be active with text", function()
            TrackerQuestFilter.SetText("water")

            assert.is_true(TrackerQuestFilter.IsActive())
        end)

        it("should not be active when the option is disabled", function()
            Questie.db.profile.trackerShowQuestFilter = false
            TrackerQuestFilter.SetText("water")

            assert.is_false(TrackerQuestFilter.IsActive())
        end)
    end)

    describe("QuestMatches", function()
        it("should match the title regardless of case", function()
            TrackerQuestFilter.SetText("CALL OF")

            assert.is_true(TrackerQuestFilter.QuestMatches(questDetails[1].quest))
        end)

        it("should match the text of an objective", function()
            TrackerQuestFilter.SetText("dreadfang")

            assert.is_true(TrackerQuestFilter.QuestMatches(questDetails[2].quest))
        end)

        it("should not match other quests", function()
            TrackerQuestFilter.SetText("dreadfang")

            assert.is_false(TrackerQuestFilter.QuestMatches(questDetails[1].quest))
        end)

        it("should search the text literally instead of as a pattern", function()
            TrackerQuestFilter.SetText("(")

            assert.is_false(TrackerQuestFilter.QuestMatches(questDetails[1].quest))
        end)

        it("should ignore spaces around the text", function()
            TrackerQuestFilter.SetText("  water  ")

            assert.is_true(TrackerQuestFilter.QuestMatches(questDetails[1].quest))
        end)

        it("should handle a quest without objectives", function()
            TrackerQuestFilter.SetText("water")

            assert.is_false(TrackerQuestFilter.QuestMatches({name = "Serpentbloom"}))
        end)
    end)

    describe("FilterQuestIds", function()
        it("should return the sorted quests unchanged without a filter", function()
            TrackerQuestFilter.SetText("")

            assert.are.equal(sortedQuestIds, TrackerQuestFilter.FilterQuestIds(sortedQuestIds, questDetails))
        end)

        it("should keep the matching quests in sort order", function()
            TrackerQuestFilter.SetText("e")

            assert.are_same({1, 2, 3}, TrackerQuestFilter.FilterQuestIds(sortedQuestIds, questDetails))
        end)

        it("should remove the quests that do not match", function()
            TrackerQuestFilter.SetText("deviate")

            assert.are_same({2}, TrackerQuestFilter.FilterQuestIds(sortedQuestIds, questDetails))
        end)

        it("should return no quest when nothing matches", function()
            TrackerQuestFilter.SetText("ashenvale")

            assert.are_same({}, TrackerQuestFilter.FilterQuestIds(sortedQuestIds, questDetails))
        end)

        it("should not filter when the option is disabled", function()
            Questie.db.profile.trackerShowQuestFilter = false
            TrackerQuestFilter.SetText("deviate")

            assert.are.equal(sortedQuestIds, TrackerQuestFilter.FilterQuestIds(sortedQuestIds, questDetails))
        end)
    end)
end)
