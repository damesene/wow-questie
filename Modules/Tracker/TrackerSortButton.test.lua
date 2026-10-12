dofile("setupTests.lua")

describe("TrackerSortButton", function()
    ---@type TrackerSortButton
    local TrackerSortButton
    ---@type QuestieTracker
    local QuestieTracker

    local originals
    local libDropDown, aceConfigRegistry
    local sortButton

    ---@return table frame A fake frame that remembers its scripts, size, anchor and visibility
    local function _NewFrame()
        local frame = {shown = true, scripts = {}}
        local noop = function() end
        for _, method in ipairs({"SetNormalTexture", "SetPushedTexture", "SetHighlightTexture", "RegisterForClicks", "RegisterForDrag"}) do
            frame[method] = noop
        end
        frame.SetScript = function(self, name, script) self.scripts[name] = script end
        frame.Show = function(self) self.shown = true end
        frame.Hide = function(self) self.shown = false end
        frame.SetSize = function(self, width, height) self.size = {width, height} end
        frame.ClearAllPoints = function(self) self.anchor = nil end
        frame.SetPoint = function(self, point, relativeTo, relativePoint, x, y) self.anchor = {point, relativeTo, relativePoint, x, y} end
        return frame
    end

    before_each(function()
        originals = {
            CreateFrame = _G.CreateFrame,
            LibStub = _G.LibStub,
            GetInstanceInfo = _G.GetInstanceInfo,
        }
        _G.CreateFrame = function() return _NewFrame() end
        _G.GetInstanceInfo = function() return "Kalimdor", "none", 0, "" end

        libDropDown = {EasyMenu = spy.new(function() end), CloseDropDownMenus = spy.new(function() end)}
        aceConfigRegistry = {NotifyChange = spy.new(function() end)}
        _G.LibStub = setmetatable({GetLibrary = function() return libDropDown end}, {
            __call = function() return aceConfigRegistry end
        })

        Questie.db.profile.trackerShowSortButton = true
        Questie.db.profile.trackerHeaderEnabled = true
        Questie.db.profile.moveHeaderToBottom = false
        Questie.db.profile.trackerSortObjectives = "byZone"
        Questie.db.char.isTrackerExpanded = true

        QuestieTracker = QuestieLoader:ImportModule("QuestieTracker")
        QuestieTracker.Update = spy.new(function() end)
        QuestieLoader:ImportModule("QuestieCombatQueue").Queue = function(_, callback) callback() end
        QuestieLoader:ImportModule("TrackerMenu").menuFrame = {}

        dofile("Localization/l10n.lua")
        dofile("Modules/Tracker/Sorter/Sorter.lua")
        dofile("Modules/Tracker/TrackerSortButton.lua")
        TrackerSortButton = QuestieLoader:ImportModule("TrackerSortButton")

        sortButton = TrackerSortButton.Initialize(_NewFrame())
    end)

    after_each(function()
        for name, value in pairs(originals) do
            _G[name] = value
        end
    end)

    describe("IsShown", function()
        it("should be shown when enabled with the tracker header", function()
            assert.is_truthy(TrackerSortButton.IsShown())
        end)

        it("should not be shown when the option is disabled", function()
            Questie.db.profile.trackerShowSortButton = false

            assert.is_falsy(TrackerSortButton.IsShown())
        end)

        it("should not be shown without the tracker header", function()
            Questie.db.profile.trackerHeaderEnabled = false

            assert.is_falsy(TrackerSortButton.IsShown())
        end)

        it("should not be shown while the tracker is minimized", function()
            Questie.db.char.isTrackerExpanded = false

            assert.is_falsy(TrackerSortButton.IsShown())
        end)

        it("should not be shown while the tracker lists scenario criteria", function()
            local expansions = QuestieLoader:ImportModule("Expansions")
            local originalExpansion = expansions.Current
            expansions.Current = expansions.MoP
            _G.GetInstanceInfo = function() return "Scenario", "scenario", 0, "" end

            local shown = TrackerSortButton.IsShown()

            expansions.Current = originalExpansion
            assert.is_falsy(shown)
        end)
    end)

    describe("Update", function()
        it("places the button on the right of the header row at the top", function()
            local baseFrame = {}

            TrackerSortButton.Update(baseFrame, 12, true)

            assert.is_true(sortButton.shown)
            assert.are_same({12, 12}, sortButton.size)
            assert.are_same({"TOPRIGHT", baseFrame, "TOPRIGHT", -8, -10}, sortButton.anchor)
        end)

        it("places the button on the right of the header row at the bottom", function()
            Questie.db.profile.moveHeaderToBottom = true
            local baseFrame = {}

            TrackerSortButton.Update(baseFrame, 12, true)

            assert.are_same({"BOTTOMRIGHT", baseFrame, "BOTTOMRIGHT", -8, 5}, sortButton.anchor)
        end)

        it("hides the button when it is not shown", function()
            TrackerSortButton.Update({}, 12, false)

            assert.is_false(sortButton.shown)
        end)
    end)

    describe("sorting menu", function()
        it("opens the sorting menu at the button", function()
            sortButton.scripts.OnClick(sortButton)

            assert.spy(libDropDown.EasyMenu).was.called(1)
        end)

        it("offers every way of sorting and checks the current one", function()
            local menu = TrackerSortButton.GetMenu()

            assert.is_true(menu[1].isTitle)
            assert.are.equal(#QuestieLoader:ImportModule("Sorter").GetSortOptions() + 1, #menu)
            for i = 2, #menu do
                assert.are.equal(menu[i].text == "By Zone", menu[i].checked())
            end
        end)

        it("changes the sorting, updates the tracker and the options window", function()
            local menu = TrackerSortButton.GetMenu()
            local byLevel
            for _, entry in ipairs(menu) do
                if entry.text == "By Level" then
                    byLevel = entry
                end
            end

            byLevel.func()

            assert.are.equal("byLevel", Questie.db.profile.trackerSortObjectives)
            assert.spy(QuestieTracker.Update).was.called(1)
            assert.spy(aceConfigRegistry.NotifyChange).was.called_with(aceConfigRegistry, "Questie")
            assert.spy(libDropDown.CloseDropDownMenus).was.called(1)
        end)
    end)
end)
