ReactionShot = {}

function ReactionShot:Create()
	self.connected = false
	self:InitDefault()
end

function ReactionShot:InitDefault()

end

function ReactionShot:Start()
	self:InitDefault()
	self:TryConnect()
end

function ReactionShot:Tick()
	if not self.connected then
		self:TryConnect()
	end
end

function ReactionShot:TryConnect()
	if self.connected then return end

	---@type InteractableWidget
	self.interactable = self:GetParent()

	-- Check if parent and signals exist
	if not self.interactable or not self.interactable.OnPressed then
		return
	end

	self.interactable.OnPressed:Connect(self, function(player, button)
		Log.Debug("HIT")
			self.shootingTargetScript:Hit(player)
	end)

	self.interactable.OnReleased:Connect(self, function(player, button)
	
	end)

	self.interactable.OnHoverStart:Connect(self, function(player)
		Log.Debug("HOVER")

	end)

	self.interactable.OnHoverEnd:Connect(self, function(player)
	end)

	self.connected = true
end

function ReactionShot:OnDestroy()
	if self.interactable and self.interactable.OnPressed then
		self.interactable.OnPressed:Disconnect(self)
		self.interactable.OnReleased:Disconnect(self)
		self.interactable.OnHoverStart:Disconnect(self)
		self.interactable.OnHoverEnd:Disconnect(self)
	end
end

function ReactionShot:GatherProperties()
	return {
		{ name = "shootingTargetScript", type = DatumType.Node }
	}
end
