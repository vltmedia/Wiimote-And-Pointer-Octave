ReactionButtonClick = {}

function ReactionButtonClick:Create()
	self.connected = false
end

function ReactionButtonClick:Start()
	self:TryConnect()
end

function ReactionButtonClick:Tick()
	if not self.connected then
		self:TryConnect()
	end
end

function ReactionButtonClick:TryConnect()
	if self.connected then return end

	---@type InteractableWidget
	self.interactable = self:GetParent()

	-- Check if parent and signals exist
	if not self.interactable or not self.interactable.OnClicked then
		return
	end

	self.interactable.OnClicked:Connect(self, function(player, button)
		if button == Gamepad.A then
			self:OnClick(player)
		end
	end)

	self.interactable.OnHoverStart:Connect(self, function(player)
		local parent = self:GetParent()
		if parent and parent.SetSelected then
			parent:SetSelected()
		end
	end)
	self.connected = true
end

function ReactionButtonClick:OnClick(player)
	local parent = self:GetParent()
	if parent and parent.Activate then
		parent:Activate()
	end
end

function ReactionButtonClick:OnDestroy()
	if self.interactable and self.interactable.OnClicked then
		self.interactable.OnClicked:Disconnect(self)
	end
end

function ReactionButtonClick:GatherProperties()
	return {}
end
