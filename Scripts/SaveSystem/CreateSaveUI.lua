-- CreateSaveUI.lua
-- Attach this script to any node. Set dialog and lineEdit properties in editor.
-- On Confirm: saves the game data and closes the dialog

CreateSaveUI = {}

function CreateSaveUI:Create()
    -- Default values
    self.slotIndex = 1
    self.gameData = {}
    self.onSavedCallback = Signal:Create()
    self.onCancelledCallback = Signal:Create()
end

function CreateSaveUI:Start()
    if self.dialog then
        self.dialog:ConnectSignal("Confirmed", self, self.OnConfirm)
        self.dialog:ConnectSignal("Rejected", self, self.OnReject)
    end
end

-- Call this to initialize save dialog with data
-- slotIndex: Which save slot (1-5)
-- gameData: { coins, level, stars, iconPath, playtimeSeconds, sceneName }
-- onSaved: Callback(slotIndex, data) after save
-- onCancelled: Callback() if cancelled
function CreateSaveUI:Init(slotIndex, gameData)
    self.slotIndex = slotIndex or 1
    self.gameData = gameData or {}


    -- Pre-fill with existing save name if slot has data
    if self.lineEdit then
        local existingData = SaveManager:GetSaveInfo(self.slotIndex)
        if existingData then
            self.lineEdit:SetText(existingData.name)
            self.lineEdit:SelectAll()
        else
            self.lineEdit:SetText("")
        end
        self.lineEdit:SetFocused(true)
    end
end

function CreateSaveUI:OnConfirm()
    if not self.lineEdit then return end

    local saveName = self.lineEdit:GetText()

    -- Validate name
    if saveName == nil or saveName == "" then
        Log.Warning("CreateSaveUI: Save name cannot be empty")
        return
    end

    -- Build save data
    local data = {
        name = saveName,
        coins = self.gameData.coins or 0,
        level = self.gameData.level or 1,
        stars = self.gameData.stars or 0,
        iconPath = self.gameData.iconPath or "",
        playtimeSeconds = self.gameData.playtimeSeconds or 0,
        sceneName = self.gameData.sceneName or ""
    }

    -- Write save
    SaveManager:WriteSave(self.slotIndex, data)

    Log.Debug("CreateSaveUI: Saved to slot " .. self.slotIndex .. " as '" .. saveName .. "'")

    -- Call success callback
    if self.onSavedCallback then
        self.onSavedCallback:Emit(self.slotIndex, data)
    end

    -- Close dialog
    if self.dialog then
        self.dialog:Hide()
    end
end

function CreateSaveUI:OnReject()
    -- Call cancel callback
    if self.onCancelledCallback then
        self.onCancelledCallback:Emit()
    end

    -- Close dialog
    if self.dialog then
        self.dialog:Hide()
    end
end

function CreateSaveUI:GatherProperties()
    return {
        {name="dialog", type=DatumType.Widget },
        {name="lineEdit", type=DatumType.Widget }
    }
end

