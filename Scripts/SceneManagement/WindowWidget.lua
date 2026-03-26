WindowWidget = {}

function WindowWidget:Create()
	self.OnOpened = Signal:Create()
	self.OnClosed = Signal:Create()
	self.isOpen = false
end

function WindowWidget:Start()
	self.registered = false
	self:TryRegister()
end

function WindowWidget:Tick()
	if not self.registered then
		self:TryRegister()
	end
end

function WindowWidget:TryRegister()
	if self.registered then return end

	-- Find manager
	local manager = self.windowManager or WindowManager.Instance
	if not manager or not manager.RegisterWindow then
		return
	end

	-- Get name (property or node name)
	local name = self.windowName
	if not name or name == "" then
		if self.GetName then
			name = self:GetName()
		else
			name = tostring(self)
		end
	end

	manager:RegisterWindow(self, name)
	self.registeredName = name
	self.registered = true

	Log.Debug("WindowWidget: '" .. name .. "' registered with WindowManager")
end

--- Called by WindowManager when this window is opened
function WindowWidget:OnWindowOpened()
	self.isOpen = true
	self.OnOpened:Emit()
end

--- Called by WindowManager when this window is closed
function WindowWidget:OnWindowClosed()
	self.isOpen = false
	self.OnClosed:Emit()
end

--- Check if this window is currently open
---@return boolean
function WindowWidget:IsOpen()
	return self.isOpen
end

--- Open this window via the manager
function WindowWidget:Open(closeOthers)
	local manager = self.windowManager or WindowManager.Instance
	if manager and manager.OpenWindow and self.registeredName then
		manager:OpenWindow(self.registeredName, closeOthers)
	end
end

--- Close this window via the manager
function WindowWidget:Close()
	local manager = self.windowManager or WindowManager.Instance
	if manager and manager.CloseWindow and self.registeredName then
		manager:CloseWindow(self.registeredName)
	end
end

--- Toggle this window via the manager
function WindowWidget:Toggle()
	local manager = self.windowManager or WindowManager.Instance
	if manager and manager.ToggleWindow and self.registeredName then
		manager:ToggleWindow(self.registeredName)
	end
end

function WindowWidget:GatherProperties()
	return {
		{ name = "windowName", type = DatumType.String },
		{ name = "windowManager", type = DatumType.Widget },
	}
end