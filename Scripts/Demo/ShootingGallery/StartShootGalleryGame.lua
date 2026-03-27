---@class StartShootGalleryGame
---@field window Node
StartShootGalleryGame = {}

function StartShootGalleryGame:Create()
	self.connected = false
end

function StartShootGalleryGame:Start()
	self:TryConnect()
end

function StartShootGalleryGame:Tick()
	if not self.connected then
		self:TryConnect()
	end
end

function StartShootGalleryGame:TryConnect()
	if self.connected then return end

	---@type InteractableWidget
	self.interactable = self:GetParent()

	if not self.interactable or not self.interactable.OnPressed then
		return
	end

	self.interactable.OnPressed:Connect(self, function(player, button)
		self:StartGame()
	end)
	self.interactable.OnHoverStart:Connect(self, function(player, button)
	end)

	self.connected = true
end

function StartShootGalleryGame:StartGame()
	-- Start the shooting gallery game
	if ShootingGalleryGameManager.Instance then
		ShootingGalleryGameManager.Instance:Run()
	else
		Log.Warning("StartShootGalleryGame: No ShootingGalleryGameManager found")
	end

	-- Close the window
	if self.window then
		self.window:SetActive(false)
		self.window:SetVisible(false)
	end
end

function StartShootGalleryGame:OnDestroy()
	if self.interactable and self.interactable.OnPressed then
		self.interactable.OnPressed:Disconnect(self)
	end
end

function StartShootGalleryGame:GatherProperties()
	return {
		{ name = "window", type = DatumType.Node },
	}
end
