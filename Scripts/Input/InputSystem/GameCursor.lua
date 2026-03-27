GameCursor = {}

function GameCursor:Create()
	-- Editor-configurable defaults and state
	self.player = self.player or 1
	self.playerPointer = nil
	self.visible = false
	self.pointerUp = false
end

function GameCursor:Start()
	-- Runtime-only: connection to other scripts
	self.connected = false
	self:TryConnect()
end

function GameCursor:TryConnect()
	if self.connected then return true end

	if not self.manager then
		self.manager = self.world:FindNode("InputManager")
	end

	-- if not self.manager then
	-- 	self.manager = InputManager.Instance
	-- end

	if self.manager then
		if self:ConnectPlayerPointer() then
			self.connected = true
			Log.Debug("GameCursor: Connected to InputManager")
			return true
		end
	end

	return false
end

function GameCursor:ConnectPlayerPointer()
	if not self.manager then
		Log.Warning("GameCursor: No manager available")
		return false
	end

	if not self.playerPointer and self.manager.GetPlayerPointer then
		self.playerPointer = self.manager:GetPlayerPointer(self.player)
	end
	-- if not self.playerPointer then
	-- 	self.playerPointer = self:GetParent()
	-- end
	if not self.playerPointer then
		Log.Warning("Cursor could not find player pointer for player " .. self.player)
		return false
	end

	-- Check if signals exist (playerPointer's Start() may not have run yet)
	if not self.playerPointer.OnPointingStarted or not self.playerPointer.OnPointingStopped then
		return false
	end

	Log.Debug("GameCursor: Connected to player pointer for player " .. self.player)

	if self.textName then
		self.textName:SetText(string.format("Player %d", self.player))
	end

	self.playerPointer.OnPointingStarted:Connect(self, function(player, pointerX, pointerY)
		if player == self.player then
			self.visible = true
			Log.Debug("GameCursor: Player " .. player .. " pointing started")
		end
	end)

	self.playerPointer.OnPointingStopped:Connect(self, function(player, pointerX, pointerY)
		if player == self.player then
			self.visible = false
			Log.Debug("GameCursor: Player " .. player .. " pointing stopped")
		end
	end)

	return true
end

function GameCursor:Tick()
	if not self.connected then
		if not self:TryConnect() then
			if self.textName then
				if not self.manager then
					self.textName:SetText("P" .. self.player .. ": No Manager")
				else
					self.textName:SetText("P" .. self.player .. ": No Pointer")
				end
			end
			return
		end
	end

	if self.playerPointer then
		local x, y = self.playerPointer:GetPointerPosition()
		local isPointing = self.playerPointer:GetIsPointing()

		-- Debug text
		
		
		if self.showDebug == true then Log.Debug(string.format("GameCursor Tick - Player %d: Position (%d, %d), Pointing: %s",
			self.player,
			x or 0,
			y or 0,
			isPointing and "ON" or "OFF")) end

		if isPointing then
			self.visible = true
		else
			self.visible = false
			return
		end

		if x and y and self.quad then
			-- Try different position methods depending on widget type
			if self.quad.SetOffset then
				self.quad:SetOffset(Vec(x, y, 0))
			elseif self.quad.SetPosition then
				self.quad:SetPosition(Vec(x, y, 0))
			elseif self.quad.SetAbsolutePosition then
				self.quad:SetAbsolutePosition(x, y)
			end
		end

		local orientation = self.playerPointer:GetPointerOrientation()
		if orientation and self.quad then
			if self.quad.SetRotation then
				self.quad:SetRotation(orientation.z)
			end
		end
	end
end

function GameCursor:GatherProperties()
	return {
		{ name = "player", type = DatumType.Integer },
		{ name = "manager", type = DatumType.Node },
		{ name = "quad", type = DatumType.Quad },
		{ name = "pointerTexture", type = DatumType.Asset },
		{ name = "moveTexture", type = DatumType.Asset },
		{ name = "grabTexture", type = DatumType.Asset },
		{ name = "loadingTexture", type = DatumType.Asset },
		{ name = "blockTexture", type = DatumType.Asset },
		{ name = "textName", type = DatumType.Text },
		{ name = "showDebug", type = DatumType.Bool },
	}
end
