ReactionScale3D = {}

function ReactionScale3D:Create()
	self.connected = false
	self:InitDefault()
end

function ReactionScale3D:InitDefault()
	if not self.node then
		return
	end
	self.initialScale = self.node:GetScale()
	if not self.hoverScale then
		self.hoverScale = self.initialScale * 1.2
	end
	if not self.clickScale then
		self.clickScale = self.initialScale * 0.8
	end
end

function ReactionScale3D:Start()
	self:InitDefault()
	self:TryConnect()
end

function ReactionScale3D:Tick()
	if not self.connected then
		self:TryConnect()
	end
end

function ReactionScale3D:TryConnect()
	if self.connected then return end

	---@type InteractableWidget
	self.interactable = self:GetParent()

	-- Check if parent and signals exist
	if not self.interactable or not self.interactable.OnPressed then
		return
	end

	self.interactable.OnPressed:Connect(self, function(player, button)
		if button == Gamepad.A then
			self.node:SetScale(self.clickScale)
		end
	end)

	self.interactable.OnReleased:Connect(self, function(player, button)
		if button == Gamepad.A then
			self.node:SetScale(self.hoverScale)
		end
	end)

	self.interactable.OnHoverStart:Connect(self, function(player)
		self.node:SetScale(self.hoverScale)
	end)

	self.interactable.OnHoverEnd:Connect(self, function(player)
		self.node:SetScale(self.initialScale)
	end)

	self.connected = true
end

function ReactionScale3D:OnDestroy()
	if self.interactable and self.interactable.OnPressed then
		self.interactable.OnPressed:Disconnect(self)
		self.interactable.OnReleased:Disconnect(self)
		self.interactable.OnHoverStart:Disconnect(self)
		self.interactable.OnHoverEnd:Disconnect(self)
	end
end

function ReactionScale3D:GatherProperties()
	return {
		{ name = "node", type = DatumType.Node3D },
		{ name = "hoverScale", type = DatumType.Vector },
		{ name = "clickScale", type = DatumType.Vector },
	}
end
