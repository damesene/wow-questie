dofile("setupTests.lua")

describe("TrackerQuestFilterBox", function()
    ---@type TrackerQuestFilterBox
    local TrackerQuestFilterBox
    ---@type TrackerQuestFilter
    local TrackerQuestFilter
    ---@type QuestieTracker
    local QuestieTracker

    local originalCreateFrame, originalTimer
    local timers
    local filterBox

    ---@return table frame A fake frame that remembers its scripts, text and visibility
    local function _NewFrame()
        local frame = {shown = true, text = "", scripts = {}}
        local noop = function() end
        for _, method in ipairs({"SetPoint", "SetAutoFocus", "SetMaxLetters", "SetNormalTexture", "SetPushedTexture",
            "SetHighlightTexture", "SetFont", "SetHeight", "SetSize", "SetTextInsets"}) do
            frame[method] = noop
        end
        frame.SetScript = function(self, name, script) self.scripts[name] = script end
        frame.Show = function(self) self.shown = true end
        frame.Hide = function(self) self.shown = false end
        frame.SetShown = function(self, shown) self.shown = shown end
        frame.SetText = function(self, text)
            self.text = text
            if self.scripts.OnTextChanged then
                self.scripts.OnTextChanged(self)
            end
        end
        frame.GetText = function(self) return self.text end
        frame.ClearFocus = spy.new(function() end)
        frame.CreateFontString = function() return _NewFrame() end
        return frame
    end

    local function _RunTimers()
        local pending = timers
        timers = {}
        for _, callback in ipairs(pending) do
            callback()
        end
    end

    before_each(function()
        originalCreateFrame = _G.CreateFrame
        originalTimer = _G.C_Timer
        timers = {}
        _G.CreateFrame = function() return _NewFrame() end
        _G.C_Timer = {After = function(_, callback) table.insert(timers, callback) end}

        Questie.db.profile.trackerShowQuestFilter = true
        Questie.db.profile.trackerFontSizeQuest = 10
        Questie.db.profile.trackerFontQuest = "Friz Quadrata TT"

        QuestieTracker = QuestieLoader:ImportModule("QuestieTracker")
        QuestieTracker.Update = spy.new(function() end)
        QuestieLoader:ImportModule("QuestieCombatQueue").Queue = function(_, callback) callback() end

        dofile("Localization/l10n.lua")
        dofile("Modules/Tracker/TrackerQuestFilter.lua")
        TrackerQuestFilter = QuestieLoader:ImportModule("TrackerQuestFilter")
        dofile("Modules/Tracker/TrackerQuestFilterBox.lua")
        TrackerQuestFilterBox = QuestieLoader:ImportModule("TrackerQuestFilterBox")

        filterBox = TrackerQuestFilterBox.Initialize(_NewFrame())
    end)

    after_each(function()
        _G.CreateFrame = originalCreateFrame
        _G.C_Timer = originalTimer
    end)

    it("starts hidden and empty", function()
        assert.is_false(filterBox.shown)
        assert.is_false(filterBox.clearButton.shown)
    end)

    it("filters the tracked quests while typing", function()
        filterBox:SetText("water")

        assert.is_true(TrackerQuestFilter.IsActive())
        assert.is_true(filterBox.clearButton.shown)
        assert.is_false(filterBox.placeholder.shown)
    end)

    it("updates the tracker once typing pauses", function()
        filterBox:SetText("w")
        filterBox:SetText("wa")
        filterBox:SetText("wat")

        assert.spy(QuestieTracker.Update).was.not_called()
        _RunTimers()
        assert.spy(QuestieTracker.Update).was.called(1)
    end)

    it("removes the filter with the clear button", function()
        filterBox:SetText("water")

        filterBox.clearButton.scripts.OnClick()

        assert.are.equal("", filterBox:GetText())
        assert.is_false(TrackerQuestFilter.IsActive())
        assert.is_false(filterBox.clearButton.shown)
        assert.is_true(filterBox.placeholder.shown)
        assert.spy(filterBox.ClearFocus).was.called()
    end)

    describe("Update", function()
        it("shows the filter box and returns its height", function()
            local height = TrackerQuestFilterBox.Update(true)

            assert.is_true(filterBox.shown)
            assert.is_true(height > 0)
        end)

        it("hides the filter box but keeps the filter while there are no quests to filter", function()
            filterBox:SetText("water")

            local height = TrackerQuestFilterBox.Update(false)

            assert.are.equal(0, height)
            assert.is_false(filterBox.shown)
            assert.are.equal("water", filterBox:GetText())
        end)

        it("hides the filter box and removes the filter when the option is disabled", function()
            filterBox:SetText("water")
            Questie.db.profile.trackerShowQuestFilter = false

            local height = TrackerQuestFilterBox.Update(true)

            assert.are.equal(0, height)
            assert.is_false(filterBox.shown)
            assert.are.equal("", filterBox:GetText())
        end)
    end)
end)
