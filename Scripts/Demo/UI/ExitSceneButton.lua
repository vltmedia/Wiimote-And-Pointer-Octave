ExitSceneButton = {}

function ExitSceneButton:Start()
	self.connected = false
	self:TryConnect()
end

function ExitSceneButton:Tick()
	if not self.connected then
		self:TryConnect()
	end
end

function ExitSceneButton:TryConnect()
	if self.connected then return end

	---@type InteractableWidget
	self.interactable = self:GetParent()

	-- Check if signals exist (parent's Start() may not have run yet)
	if not self.interactable then
		Log.Debug("ExitSceneButton: No parent found")
		return
	end
	if not self.interactable.OnPressed then
		local parentName = self.interactable.GetName and self.interactable:GetName() or "unknown"
		return
	end

	self.interactable.OnPressed:Connect(self, function(player, button)
		if not self.exitScene or self.exitScene == "" then
			Log.Warning("ExitSceneButton: No exitScene set")
			return
		end
		self.world:LoadScene(self.exitScene, self.instant or false)
	end)
	


	self.connected = true
end


function ExitSceneButton:OnDestroy()
	if self.interactable then
		self.interactable.OnPressed:Disconnect(self)
	end
end

function ExitSceneButton:GatherProperties()
	return {
		{name="exitScene", type=DatumType.String	},
		{name="instant", type=DatumType.Bool	}
	}
end
