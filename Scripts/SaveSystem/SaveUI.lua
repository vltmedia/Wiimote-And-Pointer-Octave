-- SaveUI.lua
-- Attach this script to a widget that contains a ListViewWidget named "SaveListView"
--
-- Required Scene Setup:
-- 1. Create a Scene asset for the item template (e.g., "UI/SaveSlotTemplate")
--    with this widget hierarchy:
--      ArrayWidget "Root" (Horizontal)
--      ├── Quad "Icon" (64x64)
--      └── ArrayWidget "InfoColumn" (Vertical)
--          ├── Text "NameText"
--          ├── ArrayWidget "StatsRow" (Horizontal)
--          │   ├── Text "CoinsText"
--          │   ├── Text "LevelText"
--          │   └── Text "StarsText"
--          └── ArrayWidget "MetaRow" (Horizontal)
--              ├── Text "PlaytimeText"
--              ├── Text "DateText"
--              └── Text "LocationText"
--
-- 2. Your main UI scene should have:
--    - ListViewWidget "SaveListView"
--    - Button "SaveButton" (optional)
--    - Button "LoadButton" (optional)
--    - Button "DeleteButton" (optional)


SaveUI = {}


function SaveUI:Create()
    -- Find the ListView

    -- Initial population
    -- Track selected slot
    self.selectedSlot = nil
end
function SaveUI:Start()
    self.newButton:ConnectSignal("Activated", self, SaveUI.OnNewButtonClicked)
    self.saveButton:ConnectSignal("Activated", self, SaveUI.OnSaveButtonClicked)
    self.loadButton:ConnectSignal("Activated", self, SaveUI.OnLoadButtonClicked)
    self.deleteButton:ConnectSignal("Activated", self, SaveUI.OnDeleteButtonClicked)
    self:RefreshSaveList()

end

function SaveUI:OnNewButtonClicked()
    WindowManager.ShowWindow("save.create.new")
    -- local slotIndex = self.saveManager:CreateNewSave()
    -- if slotIndex then
    --     self:RefreshSaveList()
    --     Log.Debug("SaveUI: Created new save at slot " .. slotIndex)
    -- end
end

function SaveUI:OnSaveButtonClicked()
    self:Save()
end

function SaveUI:OnLoadButtonClicked()
    self:Load()
end

function SaveUI:OnDeleteButtonClicked()
    self:Delete()
end

function SaveUI:GatherProperties()
    return {
        {name="saveManager", type=DatumType.Widget },
        {name="createSaveUI", type=DatumType.Widget },
        {name="listView", type=DatumType.Widget },
        {name="saveButton", type=DatumType.Widget },
        {name="loadButton", type=DatumType.Widget },
        {name="deleteButton", type=DatumType.Widget },
        {name="newButton", type=DatumType.Widget },
    }
end


-- Refresh the save list display
function SaveUI:RefreshSaveList()
    local slots =self.saveManager:GetAllSaveSlots()
    self.listView:SetData(slots)
end

-- Called by ListView when an item is created
-- Populate the item's child widgets with save data
function SaveUI:OnItemGenerate(index, data, item)
    -- Get references to child widgets
    local content = item:GetContentWidget()
    if content == nil then
        return
    end
    -- Find and set the title text
    content:GenerateItem(data)
end

-- Called when selection changes
function SaveUI:OnSelectionChanged(index, data)
    self.selectedSlot = data

    -- Update button states based on selection

    local hasSelection = self.selectedSlot ~= nil
    local canLoad = hasSelection and not self.selectedSlot.isEmpty

    -- Enable/disable buttons (if they exist)
    -- Note: Adjust based on your Button widget API
end

-- Called when an item is clicked
function SaveUI:OnItemClicked(index, data)
    -- Selection is handled automatically by ListView
    -- Add custom click behavior here if needed
end

-- Save current game state to selected slot
-- Call this from a Save button or external script
function SaveUI:Save()
    if not self.selectedSlot then
        Log.Warning("SaveUI: No slot selected")
        return false
    end

    -- Gather current game data
    -- Replace these with your actual game state getters
    local data = {
        name = "Player",  -- Game.GetPlayerName()
        coins = 0,        -- Game.GetCoins()
        level = 1,        -- Game.GetLevel()
        stars = 0,        -- Game.GetStars()
        iconPath = "",    -- Game.GetPlayerIcon()
        playtimeSeconds = 0,  -- Game.GetPlaytime()
        sceneName = ""    -- World.GetCurrentSceneName()
    }

    self.saveManager:WriteSave(self.selectedSlot.slotIndex, data)
    self:RefreshSaveList()

    Log.Debug("SaveUI: Saved to slot " .. self.selectedSlot.slotIndex)
    return true
end

-- Load game state from selected slot
-- Call this from a Load button or external script
function SaveUI:Load()
    if not self.selectedSlot then
        Log.Warning("SaveUI: No slot selected")
        return false
    end

    if self.selectedSlot.isEmpty then
        Log.Warning("SaveUI: Cannot load from empty slot")
        return false
    end

    local data = self.saveManager:GetSaveInfo(self.selectedSlot.slotIndex)
    if not data then
        Log.Warning("SaveUI: Failed to read save data")
        return false
    end

    -- Apply loaded data to game state
    -- Replace these with your actual game state setters
    -- Game.SetPlayerName(data.name)
    -- Game.SetCoins(data.coins)
    -- Game.SetLevel(data.level)
    -- Game.SetStars(data.stars)
    -- World.LoadScene(data.sceneName)

    Log.Debug("SaveUI: Loaded from slot " .. self.selectedSlot.slotIndex)
    return true
end

-- Delete the selected save slot
-- Call this from a Delete button or external script
function SaveUI:Delete()
    if not self.selectedSlot then
        Log.Warning("SaveUI: No slot selected")
        return false
    end

    if self.selectedSlot.isEmpty then
        return false
    end

    self.saveManager:DeleteSave(self.selectedSlot.slotIndex)
    self:RefreshSaveList()

    Log.Debug("SaveUI: Deleted slot " .. self.selectedSlot.slotIndex)
    return true
end

-- Get the currently selected slot data
function SaveUI:GetSelectedSlot()
    return self.selectedSlot
end

-- Get the selected slot index (1-based)
function SaveUI:GetSelectedIndex()
    if self.selectedSlot then
        return self.selectedSlot.slotIndex
    end
    return nil
end

