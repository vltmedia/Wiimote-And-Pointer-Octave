CustomWindowManager = {}
CustomWindowManager.Instance = nil

function CustomWindowManager:Create()
	self.OnWindowUnloadRequested = Signal:Create()
	self.OnWindowUnloaded = Signal:Create()
	self.OnWindowLoadRequested = Signal:Create()
	self.OnWindowLoaded = Signal:Create()
	self.OnWindowChanged = Signal:Create()  -- (oldWindow, newWindow)

	self.windowsByName = {}  -- name -> window
	self.windowStack = {}    -- stack of open windows
	self.activeWindow = nil
end

function CustomWindowManager:Start()
	CustomWindowManager.Instance = self

	-- Index pre-assigned windows by name
	if self.windows then
		for _, window in ipairs(self.windows) do
			self:RegisterWindow(window)
		end
	end

	-- Try to open the first window (may need to wait for WindowWidgets to register)
	self.firstWindowOpened = false
	if self.firstWindow and self.firstWindow ~= "" then
		self:TryOpenFirstWindow()
	else
		self.firstWindowOpened = true  -- No first window specified
	end

end

function CustomWindowManager:Tick()
	if not self.firstWindowOpened then
		self:TryOpenFirstWindow()
	end
end

function CustomWindowManager:TryOpenFirstWindow()
	if self.firstWindowOpened then return end
	if not self.firstWindow or self.firstWindow == "" then
		self.firstWindowOpened = true
		return
	end

	-- Check if the window is registered yet
	if self.windowsByName[self.firstWindow] then
		self:OpenWindow(self.firstWindow)
		self.firstWindowOpened = true
	end
end

--- Register a window with the manager
---@param window Widget The window widget to register
---@param windowName string|nil Optional name (defaults to node name)
function CustomWindowManager:RegisterWindow(window, windowName)
	if not window then return end

	windowName = windowName or (window.GetName and window:GetName()) or tostring(window)
	self.windowsByName[windowName] = window

	-- Start hidden and inactive (firstWindow will be opened properly after registration)
	if window.SetVisible then
		window:SetVisible(false)
	end
	if window.SetActive then
		window:SetActive(false)
	end

end

--- Open a window by name
---@param windowName string
---@param closeOthers boolean|nil If true, close all other windows first
---@return boolean success
function CustomWindowManager:OpenWindow(windowName, closeOthers)
	if not windowName or windowName == "" then
		Log.Warning("CustomWindowManager: OpenWindow called with nil or empty name")
		return false
	end

	local window = self.windowsByName[windowName]
	if not window then
		Log.Warning("CustomWindowManager: Window '" .. windowName .. "' not found")
		return false
	end

	if closeOthers then
		self:CloseAllWindows()
	end

	self.OnWindowLoadRequested:Emit(windowName, window)

	-- Show and activate the window
	if window.SetVisible then
		window:SetVisible(true)
	end
	if window.SetActive then
		window:SetActive(true)
	end

	-- Notify the window widget
	if window.OnWindowOpened then
		window:OnWindowOpened()
	end

	-- Track in stack
	self:PushWindowToStack(windowName)

	local oldWindow = self.activeWindow
	self.activeWindow = windowName

	self.OnWindowLoaded:Emit(windowName, window)
	self.OnWindowChanged:Emit(oldWindow, windowName)

	return true
end

--- Close a window by name
---@param windowName string
---@return boolean success
function CustomWindowManager:CloseWindow(windowName)
	if not windowName or windowName == "" then
		Log.Warning("CustomWindowManager: CloseWindow called with nil or empty name")
		return false
	end

	local window = self.windowsByName[windowName]
	if not window then
		Log.Warning("CustomWindowManager: Window '" .. windowName .. "' not found")
		return false
	end

	self.OnWindowUnloadRequested:Emit(windowName, window)

	-- Hide and deactivate the window
	if window.SetVisible then
		window:SetVisible(false)
	end
	if window.SetActive then
		window:SetActive(false)
	end

	-- Notify the window widget
	if window.OnWindowClosed then
		window:OnWindowClosed()
	end

	-- Remove from stack
	self:RemoveWindowFromStack(windowName)

	-- Update active window
	if self.activeWindow == windowName then
		local oldWindow = self.activeWindow
		self.activeWindow = self.windowStack[#self.windowStack]
		self.OnWindowChanged:Emit(oldWindow, self.activeWindow)
	end

	self.OnWindowUnloaded:Emit(windowName, window)

	return true
end

--- Open a window by index (1-based)
---@param windowIndex number
---@param closeOthers boolean|nil
---@return boolean success
function CustomWindowManager:OpenWindowByIndex(windowIndex, closeOthers)
	if not self.windows or windowIndex < 1 or windowIndex > #self.windows then
		Log.Warning("CustomWindowManager: Invalid window index " .. windowIndex)
		return false
	end

	local window = self.windows[windowIndex]
	local windowName = window.GetName and window:GetName() or tostring(window)

	return self:OpenWindow(windowName, closeOthers)
end

--- Close a window by index (1-based)
---@param windowIndex number
---@return boolean success
function CustomWindowManager:CloseWindowByIndex(windowIndex)
	if not self.windows or windowIndex < 1 or windowIndex > #self.windows then
		Log.Warning("CustomWindowManager: Invalid window index " .. windowIndex)
		return false
	end

	local window = self.windows[windowIndex]
	local windowName = window.GetName and window:GetName() or tostring(window)

	return self:CloseWindow(windowName)
end

--- Close all open windows
function CustomWindowManager:CloseAllWindows()
	-- Close in reverse order (top of stack first)
	for i = #self.windowStack, 1, -1 do
		local windowName = self.windowStack[i]
		local window = self.windowsByName[windowName]
		if window then
			if window.SetVisible then
				window:SetVisible(false)
			end
			if window.SetActive then
				window:SetActive(false)
			end
			if window.OnWindowClosed then
				window:OnWindowClosed()
			end
		end
		self.OnWindowUnloaded:Emit(windowName, window)
	end

	local oldWindow = self.activeWindow
	self.windowStack = {}
	self.activeWindow = nil

	if oldWindow then
		self.OnWindowChanged:Emit(oldWindow, nil)
	end

end

--- Toggle a window open/closed
---@param windowName string
---@return boolean isNowOpen
function CustomWindowManager:ToggleWindow(windowName)
	if self:IsWindowOpen(windowName) then
		self:CloseWindow(windowName)
		return false
	else
		self:OpenWindow(windowName)
		return true
	end
end

--- Check if a window is currently open
---@param windowName string
---@return boolean
function CustomWindowManager:IsWindowOpen(windowName)
	for _, name in ipairs(self.windowStack) do
		if name == windowName then
			return true
		end
	end
	return false
end

--- Get the currently active window name
---@return string|nil
function CustomWindowManager:GetActiveWindow()
	return self.activeWindow
end

--- Get a window by name
---@param windowName string
---@return Widget|nil
function CustomWindowManager:GetWindow(windowName)
	return self.windowsByName[windowName]
end

--- Get window count
---@return number
function CustomWindowManager:GetWindowCount()
	local count = 0
	for _ in pairs(self.windowsByName) do
		count = count + 1
	end
	return count
end

--- Internal: Push window to stack
function CustomWindowManager:PushWindowToStack(windowName)
	-- Remove if already in stack (will re-add at top)
	self:RemoveWindowFromStack(windowName)
	table.insert(self.windowStack, windowName)
end

--- Internal: Remove window from stack
function CustomWindowManager:RemoveWindowFromStack(windowName)
	for i, name in ipairs(self.windowStack) do
		if name == windowName then
			table.remove(self.windowStack, i)
			return
		end
	end
end

function CustomWindowManager:GatherProperties()
	return {
		{ name = "windows", type = DatumType.Widget, array = true },
		{ name = "firstWindow", type = DatumType.String	},
	}
end