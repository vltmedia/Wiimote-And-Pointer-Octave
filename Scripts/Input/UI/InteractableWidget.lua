InteractableWidget = {}

function InteractableWidget:Create()
	self.hoveredBy = {}   -- player -> bool
	self.pressedBy = {}   -- player -> button
	self.selectedBy = {}  -- player -> bool
	self.registered = false
	self.OnHoverStart = Signal:Create()
	self.OnHoverEnd = Signal:Create()
	self.OnPressed = Signal:Create()
	self.OnReleased = Signal:Create()
	self.OnClicked = Signal:Create()
	self.OnSelectStart = Signal:Create()
	self.OnSelectEnd = Signal:Create()
	-- Only editor-configurable defaults here - Create() runs in editor too
end

function InteractableWidget:Start()
	-- Runtime state initialization


	self:TryRegister()
end

function InteractableWidget:Tick()
	if not self.registered then
		self:TryRegister()
	end
end

function InteractableWidget:TryRegister()
	if self.registered then return end
	if InteractableManager.Instance and InteractableManager.Instance.RegisterInteractable then
		InteractableManager.Instance:RegisterInteractable(self)
		self.registered = true
		Log.Debug("Interactable Widget Registered")
	end
end

function InteractableWidget:TryGetManager()
	return InteractableManager.Instance
end

function InteractableWidget:IsHoveredBy(player)
	return self.hoveredBy[player] == true
end

function InteractableWidget:IsHovered()
	for _, hovered in pairs(self.hoveredBy) do
		if hovered then return true end
	end
	return false
end


function InteractableWidget:SetHovered(player, hovered)
	local wasHovered = self.hoveredBy[player] == true
	self.hoveredBy[player] = hovered
	if hovered and not wasHovered then
		self.OnHoverStart:Emit(player)
	elseif not hovered and wasHovered then
		self.OnHoverEnd:Emit(player)
		self.pressedBy[player] = nil  -- clear press if cursor leaves
	end
end

function InteractableWidget:IsSelectedBy(player)
	return self.selectedBy[player] == true
end

function InteractableWidget:IsSelected()
	for _, selected in pairs(self.selectedBy) do
		if selected then return true end
	end
	return false
end

function InteractableWidget:SetSelected(player, selected)
	local wasSelected = self.selectedBy[player] == true
	self.selectedBy[player] = selected
	if selected and not wasSelected then
		self.OnSelectStart:Emit(player)
	elseif not selected and wasSelected then
		self.OnSelectEnd:Emit(player)
	end
end

function InteractableWidget:HandlePress(player, button)
	if self.hoveredBy[player] then
		self.pressedBy[player] = button
		self.OnPressed:Emit(player, button)
		-- Log.Debug(string.format("InteractableWidget: Player %d pressed button %s", player, tostring(button)))
	end
end

function InteractableWidget:HandleRelease(player, button)
	if self.hoveredBy[player] and self.pressedBy[player] == button then
		self.OnReleased:Emit(player, button)
		self.OnClicked:Emit(player, button)
		self.pressedBy[player] = nil
		-- Log.Debug(string.format("InteractableWidget: Player %d released button %s", player, tostring(button)))
	end
end

function InteractableWidget:CheckContainsPoint(x, y)
	-- Use explicitly set widget property to call engine's ContainsPoint
	if self.widget then
		return self.widget:ContainsPoint(x, y)
	end
	return false
end

function InteractableWidget:GetTargetWidget()
	if self.widget then
		return self.widget
	end
	local parent = self:GetParent()
	if parent and parent ~= self then
		return parent
	end
	return nil
end

function InteractableWidget:GetWidget()
	return self:GetTargetWidget()
end

function InteractableWidget:GatherProperties()
	return {
		{ name = "widget", type = DatumType.Widget },
	}
end
