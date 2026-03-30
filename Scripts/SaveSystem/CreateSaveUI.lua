-- CreateSaveUI.lua
-- Attach this script to any node. Set dialog and lineEdit properties in editor.
-- On Confirm: saves the game data and closes the dialog

CreateSaveUI = {}

function CreateSaveUI:Create()
    -- Default values
    self.slotIndex = 1
    self.selected = -1
    self.selectedAsset = ""
    self.playerName = ""
    self.gameData = {}
    self.onSavedCallback = Signal:Create()
    self.onCancelledCallback = Signal:Create()
end

function CreateSaveUI:Start()
    if self.dialog then
        self.dialog:ConnectSignal("Confirm", self, self.OnConfirm)
        self.dialog:ConnectSignal("Reject", self, self.OnReject)
    end
    self.iconSelectDialog:ConnectSignal("Confirm", self, function ()
        Log.Debug(self.nameGenDialog:GetWindowId())
        self.nameAdjectiveDropdown:SetRandom()
        self.nameNounDropdown:SetRandom()
        WindowManager.ShowWindow(tostring(self.nameGenDialog:GetWindowId()))
        WindowManager.HideWindow(self.iconSelectDialog:GetWindowId())
    end)
    self.nameGenDialog:ConnectSignal("Confirm", self, function ()
        self.playerName = self.nameAdjectiveDropdown:GetSelectedOption() .. " " .. self.nameNounDropdown:GetSelectedOption()
        self.nameLive:SetText(self.playerName)
        WindowManager.ShowWindow(self.namePreviewDialog:GetWindowId())
        WindowManager.HideWindow(self.nameGenDialog:GetWindowId())
    end)
    self.namePreviewDialog:ConnectSignal("Confirm", self, function ()
        WindowManager.HideWindow(self.nameGenDialog:GetWindowId())
        self:CreateSave()
    end)
    self.iconSelectDialog:ConnectSignal("Reject", self, function ()
        WindowManager.ShowWindow("save.Window")
        WindowManager.HideWindow("save.create.new")
    end)
    self.nameGenDialog:ConnectSignal("Reject", self, function ()
        WindowManager.ShowWindow(self.iconSelectDialog:GetWindowId())
        WindowManager.HideWindow(self.nameGenDialog:GetWindowId())
    end)
    self.namePreviewDialog:ConnectSignal("Reject", self, function ()
        
        WindowManager.ShowWindow(self.nameGenDialog:GetWindowId())
        WindowManager.HideWindow(self.namePreviewDialog:GetWindowId())
    end)
    self.randomizeNameButton:ConnectSignal("Activated", self, function ()
        self.nameAdjectiveDropdown:SetRandom()
        self.nameNounDropdown:SetRandom()
    end)
    self.icon1:ConnectSignal("Activated", self, function ()
        self.selected = 0
        self.iconLive:SetTexture(SavePlayerAssets.instance:GetAsset(self.icon1AssetName).asset)
    end)
    self.icon2:ConnectSignal("Activated", self, function ()
        self.selected = 1
        self.iconLive:SetTexture(SavePlayerAssets.instance:GetAsset(self.icon2AssetName).asset)
    end)
    self.icon3:ConnectSignal("Activated", self, function ()
        self.selected = 2
        self.iconLive:SetTexture(SavePlayerAssets.instance:GetAsset(self.icon3AssetName).asset)
    end)
end

function CreateSaveUI:CreateSave()
    Log.Debug("Create Save Called")
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

function CreateSaveUI:UpdateIcons()
    local icon1Asset = SavePlayerAssets.instance:GetAsset(self.icon1AssetName)
    self.icon1:SetStateTextures(icon1Asset.asset, icon1Asset.asset, icon1Asset.asset, icon1Asset.asset)
    local icon2Asset = SavePlayerAssets.instance:GetAsset(self.icon2AssetName)
    self.icon2:SetStateTextures(icon2Asset.asset,icon2Asset.asset, icon2Asset.asset, icon2Asset.asset)
    local icon3Asset = SavePlayerAssets.instance:GetAsset(self.icon3AssetName)
    self.icon3:SetStateTextures(icon3Asset.asset,icon3Asset.asset, icon3Asset.asset, icon3Asset.asset)
    -- local icon3Asset = SavePlayerAssets.instance:GetAsset(self.icon3AssetName)
    -- self.icon3:SetStateTextures(icon3Asset.asset,icon3Asset.asset,icon3Asset.asset,icon3Asset.asset)
end


function CreateSaveUI:GatherProperties()
    return {
        {name="dialog", type=DatumType.Widget },
        {name="iconLive", type=DatumType.Widget },
        {name="nameLive", type=DatumType.Widget },
        {name="icon1", type=DatumType.Widget },
        {name="icon1AssetName", type=DatumType.String },
        {name="icon2", type=DatumType.Widget },
        {name="icon2AssetName", type=DatumType.String },
        {name="icon3", type=DatumType.Widget },
        {name="icon3AssetName", type=DatumType.String },
        {name="nameAdjectiveDropdown", type=DatumType.Widget },
        {name="nameNounDropdown", type=DatumType.Widget },
        {name="iconSelectDialog", type=DatumType.Widget },
        {name="nameGenDialog", type=DatumType.Widget },
        {name="namePreviewDialog", type=DatumType.Widget },
        {name="randomizeNameButton", type=DatumType.Widget },
        {name="lineEdit", type=DatumType.Widget }
    }
end

