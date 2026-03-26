ReactionToggleVisibility = {}

function ReactionToggleVisibility:Start()
	self.connected = false
	self:TryConnect()
end

function ReactionToggleVisibility:Tick()
	if not self.connected then
		self:TryConnect()
	end
end

function ReactionToggleVisibility:TryConnect()
	if self.connected then return end

	---@type InteractableWidget
	self.interactable = self:GetParent()

	-- Check if signals exist (parent's Start() may not have run yet)
	if not self.interactable then
		Log.Debug("ReactionToggleVisibility: No parent found")
		return
	end
	if not self.interactable.OnPressed then
		local parentName = self.interactable.GetName and self.interactable:GetName() or "unknown"
		return
	end

	self.interactable.OnPressed:Connect(self, function(player, button)
		if button == Gamepad.A then
			local newVisibility = not self.widget:GetVisible()
			self.widget:SetVisible(newVisibility)
		end
	end)
	self.interactable.OnHoverStart:Connect(self, function(player)
		self.widget:SetVisible(true)
	end)
	self.interactable.OnHoverEnd:Connect(self, function(player)
		self.widget:SetVisible(false)
	end)

	Log.Debug("ReactionToggleVisibility: Connected to interactable signals")

	self.connected = true
end

function ReactionToggleVisibility:OnToggleVisibility(player, visible)
	if self.widget then
		self.widget:SetVisible(visible)
	end
end

function ReactionToggleVisibility:OnDestroy()
	if self.interactable then
		self.interactable.OnPressed:Disconnect(self)
	end
end

function ReactionToggleVisibility:GatherProperties()
	return {
		{ name = "widget", type = DatumType.Node }
	}
end
