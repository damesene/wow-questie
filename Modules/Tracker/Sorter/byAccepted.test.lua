dofile("setupTests.lua")

describe("Sorter byAccepted", function()
    ---@type Sorter
    local Sorter

    ---@param questId QuestId
    ---@param timestamp number
    ---@return JourneyEntry
    local function _Accept(questId, timestamp)
        return {Event = "Quest", SubType = "Accept", Quest = questId, Timestamp = timestamp}
    end

    before_each(function()
        Questie.db.char.journey = {}

        dofile("Modules/Tracker/Sorter/Sorter.lua")
        dofile("Modules/Tracker/Sorter/byAccepted.lua")
        Sorter = QuestieLoader:ImportModule("Sorter")
    end)

    describe("byAccepted", function()
        it("should list the earliest accepted quest first", function()
            Questie.db.char.journey = {_Accept(3, 100), _Accept(1, 300), _Accept(2, 200)}
            local questIds = {1, 2, 3}

            Sorter.byAccepted(questIds, {})

            assert.are_same({3, 2, 1}, questIds)
        end)

        it("should use the latest accept of a quest accepted again", function()
            Questie.db.char.journey = {_Accept(1, 100), _Accept(2, 200), _Accept(1, 300)}
            local questIds = {1, 2}

            Sorter.byAccepted(questIds, {})

            assert.are_same({2, 1}, questIds)
        end)

        it("should list quests without accept time first, ordered by quest ID", function()
            Questie.db.char.journey = {_Accept(1, 100)}
            local questIds = {1, 5, 4}

            Sorter.byAccepted(questIds, {})

            assert.are_same({4, 5, 1}, questIds)
        end)

        it("should ignore journey entries that are not quest accepts", function()
            Questie.db.char.journey = {
                _Accept(1, 200),
                _Accept(2, 100),
                {Event = "Quest", SubType = "Complete", Quest = 2, Timestamp = 300},
                {Event = "Level", NewLevel = 10, Timestamp = 400},
            }
            local questIds = {1, 2}

            Sorter.byAccepted(questIds, {})

            assert.are_same({2, 1}, questIds)
        end)

        it("should use quests accepted after the last sort", function()
            Questie.db.char.journey = {_Accept(1, 100), _Accept(2, 200)}
            local questIds = {1, 2}
            Sorter.byAccepted(questIds, {})

            table.insert(Questie.db.char.journey, _Accept(1, 300))
            Sorter.byAccepted(questIds, {})

            assert.are_same({2, 1}, questIds)
        end)
    end)

    describe("accepts", function()
        it("should order quests accepted in the same second by their journey order", function()
            Questie.db.char.journey = {_Accept(500, 100), _Accept(200, 100)}
            local questIds = {200, 500}

            Sorter.byAccepted(questIds, {})
            assert.are_same({500, 200}, questIds)

            Sorter.byAcceptedReverse(questIds, {})
            assert.are_same({200, 500}, questIds)
        end)

        it("should notice a new accept after a journey entry was removed", function()
            Questie.db.char.journey = {_Accept(1, 100), {Event = "Note", Timestamp = 150}, _Accept(2, 200)}
            local questIds = {1, 2, 3}
            Sorter.byAccepted(questIds, {})

            table.remove(Questie.db.char.journey, 2)
            table.insert(Questie.db.char.journey, _Accept(3, 300))
            Sorter.byAccepted(questIds, {})

            assert.are_same({1, 2, 3}, questIds)
            Sorter.byAcceptedReverse(questIds, {})
            assert.are_same({3, 2, 1}, questIds)
        end)
    end)

    describe("byAcceptedReverse", function()
        it("should list the latest accepted quest first", function()
            Questie.db.char.journey = {_Accept(3, 100), _Accept(1, 300), _Accept(2, 200)}
            local questIds = {3, 2, 1}

            Sorter.byAcceptedReverse(questIds, {})

            assert.are_same({1, 2, 3}, questIds)
        end)

        it("should list quests without accept time last, in the reverse order of byAccepted", function()
            Questie.db.char.journey = {_Accept(1, 100)}
            local questIds = {5, 4, 1}

            Sorter.byAcceptedReverse(questIds, {})

            assert.are_same({1, 5, 4}, questIds)
        end)
    end)
end)
