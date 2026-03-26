Interactable3D = {}

function Interactable3D:Create()
	-- Signals and state that other scripts may access
	self.hoveredBy = {}  -- player -> bool
	self.pressedBy = {}  -- player -> button
	self.OnHoverStart = Signal:Create()
	self.OnHoverEnd = Signal:Create()
	self.OnPressed = Signal:Create()
	self.OnReleased = Signal:Create()
	self.OnClicked = Signal:Create()
end

function Interactable3D:Start()
	self.registered = false
	self:TryRegister()
end

function Interactable3D:Tick()
	if not self.registered then
		self:TryRegister()
	end
end

function Interactable3D:TryRegister()
	if self.registered then return end
	if InteractableManager.Instance and InteractableManager.Instance.RegisterInteractable3D then
		InteractableManager.Instance:RegisterInteractable3D(self)
		self.registered = true
	end
end

function Interactable3D:IsHoveredBy(player)
	return self.hoveredBy[player] == true
end

function Interactable3D:IsHovered()
	for _, hovered in pairs(self.hoveredBy) do
		if hovered then return true end
	end
	return false
end

function Interactable3D:SetHovered(player, hovered)
	local wasHovered = self.hoveredBy[player] == true
	self.hoveredBy[player] = hovered

	if hovered and not wasHovered then
		self.OnHoverStart:Emit(player)
	elseif not hovered and wasHovered then
		self.OnHoverEnd:Emit(player)
		self.pressedBy[player] = nil
	end
end

function Interactable3D:HandlePress(player, button)
	if self.hoveredBy[player] then
		self.pressedBy[player] = button
		self.OnPressed:Emit(player, button)
	end
end

function Interactable3D:HandleRelease(player, button)
	if self.hoveredBy[player] and self.pressedBy[player] == button then
		self.OnReleased:Emit(player, button)
		self.OnClicked:Emit(player, button)
		self.pressedBy[player] = nil
	end
end

function Interactable3D:GetNode3D()
	return self.node3d or self:GetParent()
end

function Interactable3D:GatherProperties()
	return {
		{ name = "node3d", type = DatumType.Node },
	}
end
