dofile("setupTests.lua")

describe("QuestUpdateOrder", function()
    ---@type QuestUpdateOrder
    local QuestUpdateOrder

    before_each(function()
        Questie.db.char.questUpdateOrder = {}
        Questie.db.char.questUpdateCounter = 0

        dofile("Modules/Quest/QuestUpdateOrder.lua")
        QuestUpdateOrder = QuestieLoader:ImportModule("QuestUpdateOrder")
    end)

    it("should return 0 for a quest without a recorded update", function()
        assert.are.equal(0, QuestUpdateOrder.Get(1))
    end)

    it("should order quests by their latest update", function()
        QuestUpdateOrder.Record(1)
        QuestUpdateOrder.Record(2)
        QuestUpdateOrder.Record(1)

        assert.is_true(QuestUpdateOrder.Get(1) > QuestUpdateOrder.Get(2))
        assert.is_true(QuestUpdateOrder.Get(2) > 0)
    end)

    it("should continue the counter saved for the character", function()
        Questie.db.char.questUpdateCounter = 41

        QuestUpdateOrder.Record(1)

        assert.are.equal(42, QuestUpdateOrder.Get(1))
        assert.are.equal(42, Questie.db.char.questUpdateCounter)
    end)

    it("should forget quests that are no longer in the quest log", function()
        QuestUpdateOrder.Record(1)
        QuestUpdateOrder.Record(2)

        QuestUpdateOrder.Prune({[2] = true})

        assert.are.equal(0, QuestUpdateOrder.Get(1))
        assert.is_true(QuestUpdateOrder.Get(2) > 0)
    end)

    describe("HasProgressed", function()
        ---@return QuestLogCacheData
        local function _Quest(isComplete, ...)
            local objectives = {}
            for index, numFulfilled in ipairs({...}) do
                objectives[index] = {numFulfilled = numFulfilled, numRequired = 10}
            end
            return {isComplete = isComplete, objectives = objectives}
        end

        it("should count an objective counting up as progress", function()
            assert.is_true(QuestUpdateOrder.HasProgressed(_Quest(0, 1, 5), _Quest(0, 1, 6)))
        end)

        it("should count completing the quest as progress", function()
            assert.is_true(QuestUpdateOrder.HasProgressed(_Quest(0, 9), _Quest(1, 9)))
        end)

        it("should count a new objective as progress", function()
            assert.is_true(QuestUpdateOrder.HasProgressed(_Quest(0, 10), _Quest(0, 10, 0)))
        end)

        it("should not count losing quest items as progress", function()
            assert.is_false(QuestUpdateOrder.HasProgressed(_Quest(1, 10), _Quest(0, 8)))
        end)

        it("should not count unchanged objectives as progress", function()
            assert.is_false(QuestUpdateOrder.HasProgressed(_Quest(0, 3), _Quest(0, 3)))
        end)
    end)

    it("should forget a removed quest", function()
        QuestUpdateOrder.Record(1)

        QuestUpdateOrder.Remove(1)

        assert.are.equal(0, QuestUpdateOrder.Get(1))
    end)
end)
