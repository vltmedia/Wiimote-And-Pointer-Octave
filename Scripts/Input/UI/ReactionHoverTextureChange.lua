ReactionHoverTextureChange = {}

function ReactionHoverTextureChange:Start()
	self.connected = false
	self:TryConnect()
end

function ReactionHoverTextureChange:Tick()
	if not self.connected then
		self:TryConnect()
	end
end

function ReactionHoverTextureChange:TryConnect()
	if self.connected then return end

	---@type InteractableWidget
	self.interactable = self:GetParent()

	-- Check if signals exist (parent's Start() may not have run yet)
	if not self.interactable then
		Log.Debug("ReactionHoverTextureChange: No parent found")
		return
	end
	if not self.interactable.OnPressed then
		local parentName = self.interactable.GetName and self.interactable:GetName() or "unknown"
		return
	end

	self.isHovered = false
	self.isPressed = false

	-- Set initial normal state
	self:ApplyState(self.normalTexture, self.normalColor)

	self.interactable.OnPressed:Connect(self, function(player, button)
		if button == Gamepad.A then
			self.isPressed = true
			self:ApplyState(self.pressedTexture, self.pressedColor)
		end
	end)

	self.interactable.OnReleased:Connect(self, function(player, button)
		if button == Gamepad.A then
			self.isPressed = false
			if self.isHovered then
				self:ApplyState(self.highlightTexture, self.highlightColor)
			else
				self:ApplyState(self.normalTexture, self.normalColor)
			end
		end
	end)

	self.interactable.OnHoverStart:Connect(self, function(player)
		self.isHovered = true
		if not self.isPressed then
			self:ApplyState(self.highlightTexture, self.highlightColor)
		end
	end)

	self.interactable.OnHoverEnd:Connect(self, function(player)
		self.isHovered = false
		if not self.isPressed then
			self:ApplyState(self.normalTexture, self.normalColor)
		end
	end)

	self.connected = true
end

function ReactionHoverTextureChange:ApplyState(texture, color)
	if self.widget then
		if texture then
			self.widget:SetTexture(texture)
		end
		if color then
			self.widget:SetColor(color)
		end
	end
end

function ReactionHoverTextureChange:OnDestroy()
	if self.interactable then
		self.interactable.OnPressed:Disconnect(self)
		self.interactable.OnReleased:Disconnect(self)
		self.interactable.OnHoverStart:Disconnect(self)
		self.interactable.OnHoverEnd:Disconnect(self)
	end
end

function ReactionHoverTextureChange:GatherProperties()
	return {
		{ name = "widget", type = DatumType.Node },
		{ name = "normalTexture", type = DatumType.Asset },
		{ name = "highlightTexture", type = DatumType.Asset },
		{ name = "pressedTexture", type = DatumType.Asset },
		{ name = "normalColor", type = DatumType.Color },
		{ name = "highlightColor", type = DatumType.Color },
		{ name = "pressedColor", type = DatumType.Color },
	}
end
