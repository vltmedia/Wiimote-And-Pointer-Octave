DebugLogWindow = {}
DebugLogWindow.Instance = nil

local MAX_VISIBLE_ENTRIES = 20
local MAX_STORED_ENTRIES = 200
local ENTRY_HEIGHT = 14

local LogSeverity = {
	Debug = 0,
	Warning = 1,
	Error = 2
}

function DebugLogWindow:Create()
	self.entries = {}
	self.visibleEntries = {}

	self.showDebug = true
	self.showWarning = true
	self.showError = true

	self.visible = true
	self.scrollOffset = 0
	self.maxScrollOffset = 0

	self.OnVisibilityChanged = Signal:Create()
	self.OnLogAdded = Signal:Create()

	if not DebugLogWindow.Instance then
		DebugLogWindow.Instance = self
	end
end

function DebugLogWindow:Start()
	-- Get the UIDocument already loaded by the Canvas
	self.ui = self:GetUIDocument()
	if not self.ui then
		Log.Error("DebugLogWindow: No UIDocument on Canvas")
		return
	end

	self.logPanel = self.ui:FindById("log-panel")
	self.logEntriesContainer = self.ui:FindById("log-entries")
	self.statusText = self.ui:FindById("status-text")

	self.btnFilterDebug = self.ui:FindById("btn-filter-debug")
	self.btnFilterWarning = self.ui:FindById("btn-filter-warning")
	self.btnFilterError = self.ui:FindById("btn-filter-error")

	self.entryWidgets = {}
	for i = 0, MAX_VISIBLE_ENTRIES - 1 do
		local widget = self.ui:FindById("log-" .. i)
		self.entryWidgets[i] = widget
		-- Clear default "Text" content
		if widget then
			widget:SetText("")
		end
	end

	-- Register callback to capture all engine logs
	Log.SetCallback(function(severity, message)
		self:AddLog(severity, message)
	end)

	self.ui:SetCallback("btn-clear", "click", function()
		self:ClearLogs()
	end)

	self.ui:SetCallback("btn-close", "click", function()
		self:Hide()
	end)

	self.ui:SetCallback("btn-filter-debug", "click", function()
		self:ToggleFilter("debug")
	end)

	self.ui:SetCallback("btn-filter-warning", "click", function()
		self:ToggleFilter("warning")
	end)

	self.ui:SetCallback("btn-filter-error", "click", function()
		self:ToggleFilter("error")
	end)

	self:UpdateStatusText()

	

	self:LogDebug("Debug log window initialized")
end

function DebugLogWindow:Tick(deltaTime)
	if not self.ui then return end

	-- Canvas already calls ui:Tick(), no need to call it here

	if Input.IsGamepadButtonJustDown(Gamepad.A, 1) then
		self:ToggleVisibility()
	end

	if not self.visible then return end

	if Input.IsGamepadButtonDown(Gamepad.Up, 1) then
		self:Scroll(-1)
	end
	if Input.IsGamepadButtonDown(Gamepad.Down, 1) then
		self:Scroll(1)
	end
end

function DebugLogWindow:Stop()
	-- Unregister log callback
	Log.ClearCallback()

	-- Canvas owns and cleans up the UIDocument, just clear our reference
	self.ui = nil

	if DebugLogWindow.Instance == self then
		DebugLogWindow.Instance = nil
	end
end

function DebugLogWindow:ToggleVisibility()
	self:SetVisible(not self.visible)
end

function DebugLogWindow:Show()
	self:SetVisible(true)
end

function DebugLogWindow:Hide()
	self:SetVisible(false)
end

function DebugLogWindow:SetVisible(visible)
	self.visible = visible

	if self.logPanel then
		self.logPanel:SetVisible(visible)
	end

	self.OnVisibilityChanged:Emit(visible)
end

function DebugLogWindow:AddLog(severity, message)
	local entry = {
		severity = severity,
		message = message,
		timestamp = Engine.GetTime()
	}

	table.insert(self.entries, entry)

	while #self.entries > MAX_STORED_ENTRIES do
		table.remove(self.entries, 1)
	end

	self:FilterEntries()
	self:ScrollToBottom()
	self:RefreshVisibleEntries()
	self:UpdateStatusText()

	self.OnLogAdded:Emit(entry)
end

function DebugLogWindow:LogDebug(message)
	self:AddLog(LogSeverity.Debug, message)
end

function DebugLogWindow:LogWarning(message)
	self:AddLog(LogSeverity.Warning, message)
end

function DebugLogWindow:LogError(message)
	self:AddLog(LogSeverity.Error, message)
end

function DebugLogWindow:ClearLogs()
	self.entries = {}
	self.visibleEntries = {}
	self.scrollOffset = 0
	self:RefreshVisibleEntries()
	self:UpdateStatusText()
end

function DebugLogWindow:ToggleFilter(filterType)
	if filterType == "debug" then
		self.showDebug = not self.showDebug
		self:UpdateFilterButtonVisual(self.btnFilterDebug, self.showDebug)
	elseif filterType == "warning" then
		self.showWarning = not self.showWarning
		self:UpdateFilterButtonVisual(self.btnFilterWarning, self.showWarning)
	elseif filterType == "error" then
		self.showError = not self.showError
		self:UpdateFilterButtonVisual(self.btnFilterError, self.showError)
	end

	self:FilterEntries()
	self:RefreshVisibleEntries()
	self:UpdateStatusText()
end

function DebugLogWindow:UpdateFilterButtonVisual(button, active)
	if not button then return end

	if active then
		button:SetOpacity(1.0)
	else
		button:SetOpacity(0.4)
	end
end

function DebugLogWindow:Scroll(delta)
	self.scrollOffset = self.scrollOffset + delta
	self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScrollOffset))
	self:RefreshVisibleEntries()
end

function DebugLogWindow:ScrollToBottom()
	self.scrollOffset = self.maxScrollOffset
end

function DebugLogWindow:FilterEntries()
	self.visibleEntries = {}

	for _, entry in ipairs(self.entries) do
		local show = false
		if entry.severity == LogSeverity.Debug and self.showDebug then show = true end
		if entry.severity == LogSeverity.Warning and self.showWarning then show = true end
		if entry.severity == LogSeverity.Error and self.showError then show = true end

		if show then
			table.insert(self.visibleEntries, entry)
		end
	end

	self.maxScrollOffset = math.max(0, #self.visibleEntries - MAX_VISIBLE_ENTRIES)
	self.scrollOffset = math.min(self.scrollOffset, self.maxScrollOffset)
end

function DebugLogWindow:RefreshVisibleEntries()
	for i = 0, MAX_VISIBLE_ENTRIES - 1 do
		local widget = self.entryWidgets[i]
		if widget then
			local entryIdx = self.scrollOffset + i + 1
			if entryIdx <= #self.visibleEntries then
				local entry = self.visibleEntries[entryIdx]
				widget:SetText(self:FormatEntry(entry))
				self:SetEntryColor(widget, entry.severity)
			else
				-- Clear unused entries
				widget:SetText("")
			end
		end
	end
end

function DebugLogWindow:FormatEntry(entry)
	local prefix = "[D]"
	if entry.severity == LogSeverity.Warning then prefix = "[W]" end
	if entry.severity == LogSeverity.Error then prefix = "[E]" end

	local totalSeconds = math.floor(entry.timestamp)
	local minutes = math.floor(totalSeconds / 60) % 60
	local seconds = totalSeconds % 60
	local time = string.format("[%02d:%02d]", minutes, seconds)

	return time .. " " .. prefix .. " " .. entry.message
end

function DebugLogWindow:SetEntryColor(widget, severity)
	if severity == LogSeverity.Debug then
		widget:SetColor(Vec(0.53, 0.8, 0.53, 1.0))
	elseif severity == LogSeverity.Warning then
		widget:SetColor(Vec(0.8, 0.8, 0.4, 1.0))
	elseif severity == LogSeverity.Error then
		widget:SetColor(Vec(0.8, 0.4, 0.4, 1.0))
	end
end

function DebugLogWindow:UpdateStatusText()
	if self.ui then
		local count = #self.entries
		local filtered = #self.visibleEntries
		if count == filtered then
			self.ui:SetData("logCount", tostring(count))
		else
			self.ui:SetData("logCount", string.format("%d/%d", filtered, count))
		end
	end
end

function DebugLogWindow:GatherProperties()
	return {
		{ name = "showDebug", type = DatumType.Bool },
		{ name = "showWarning", type = DatumType.Bool },
		{ name = "showError", type = DatumType.Bool },
		{ name = "regenerateUIOnStart", type = DatumType.Bool }
	}
end
