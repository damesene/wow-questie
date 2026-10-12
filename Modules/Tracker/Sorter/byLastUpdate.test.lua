dofile("setupTests.lua")

describe("Sorter byLastUpdate", function()
    ---@type Sorter
    local Sorter
    ---@type QuestUpdateOrder
    local QuestUpdateOrder

    before_each(function()
        Questie.db.char.questUpdateOrder = {}
        Questie.db.char.questUpdateCounter = 0

        dofile("Modules/Quest/QuestUpdateOrder.lua")
        QuestUpdateOrder = QuestieLoader:ImportModule("QuestUpdateOrder")
        dofile("Modules/Tracker/Sorter/Sorter.lua")
        dofile("Modules/Tracker/Sorter/byLastUpdate.lua")
        Sorter = QuestieLoader:ImportModule("Sorter")
    end)

    describe("byLastUpdate", function()
        it("should list the least recently updated quest first", function()
            QuestUpdateOrder.Record(3)
            QuestUpdateOrder.Record(1)
            QuestUpdateOrder.Record(2)
            local questIds = {1, 2, 3}

            Sorter.byLastUpdate(questIds, {})

            assert.are_same({3, 1, 2}, questIds)
        end)

        it("should move a quest that progresses to the end", function()
            QuestUpdateOrder.Record(1)
            QuestUpdateOrder.Record(2)
            local questIds = {1, 2}
            Sorter.byLastUpdate(questIds, {})

            QuestUpdateOrder.Record(1)
            Sorter.byLastUpdate(questIds, {})

            assert.are_same({2, 1}, questIds)
        end)

        it("should list quests without a recorded update first, ordered by quest ID", function()
            QuestUpdateOrder.Record(1)
            local questIds = {1, 5, 4}

            Sorter.byLastUpdate(questIds, {})

            assert.are_same({4, 5, 1}, questIds)
        end)
    end)

    describe("byLastUpdateReverse", function()
        it("should list the most recently updated quest first", function()
            QuestUpdateOrder.Record(3)
            QuestUpdateOrder.Record(1)
            QuestUpdateOrder.Record(2)
            local questIds = {1, 2, 3}

            Sorter.byLastUpdateReverse(questIds, {})

            assert.are_same({2, 1, 3}, questIds)
        end)

        it("should list quests without a recorded update last, ordered by quest ID", function()
            QuestUpdateOrder.Record(1)
            local questIds = {5, 4, 1}

            Sorter.byLastUpdateReverse(questIds, {})

            assert.are_same({1, 4, 5}, questIds)
        end)
    end)
end)
