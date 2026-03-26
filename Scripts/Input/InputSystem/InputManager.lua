InputManager = {}
InputManager.Instance = nil

function InputManager:Create()
	self.InputPointers = {}
	self.OnGamepadPressed = Signal:Create()
	self.OnGamepadReleased = Signal:Create()
	self.OnPointingStarted = Signal:Create()
	self.OnPointingStopped = Signal:Create()
	--- Cursormode can be free, or locked 
	self.cursorMode = "free"

end

function InputManager:GetCamera()
	return self:GetWorldCamera()
end

function InputManager:GetWorldCamera()
	-- Get active camera from main world
	self.camera = self.world:GetActiveCamera()
	return self.camera
end

function InputManager:RegisterInputPointer(InputPointer)
	table.insert(self.InputPointers, InputPointer)

	InputPointer.OnGamepadPressed:Connect(self, function(player, pointerPos, nunchukPos, isPointing, button)
		self.OnGamepadPressed:Emit(player, pointerPos, nunchukPos, isPointing, button)
	end)

	InputPointer.OnGamepadReleased:Connect(self, function(player, pointerPos, nunchukPos, isPointing, button)
		self.OnGamepadReleased:Emit(player, pointerPos, nunchukPos, isPointing, button)
	end)

	InputPointer.OnPointingStarted:Connect(self, function(player, pointerX, pointerY)
		self.OnPointingStarted:Emit(player, pointerX, pointerY)
	end)

	InputPointer.OnPointingStopped:Connect(self, function(player, pointerX, pointerY)
		self.OnPointingStopped:Emit(player, pointerX, pointerY)
	end)
end


function InputManager:Start()
	if not InputManager.Instance then
		InputManager.Instance = self
	end
	Renderer.EnableConsole(true)
	Log.Debug("Inputmote Manager Started")
end

function InputManager:Tick()
	if not self.camera then
		self:GetWorldCamera()
	end
end

function InputManager:GetPointerPositionNormalized()
	return Input.GetPointerPositionNormalized(self.player)
end

function InputManager:GetPlayerPointer(player)
	-- Find the InputPointer for the given player
	for _, InputPointer in ipairs(self.InputPointers) do
		if InputPointer.player == player then
			return InputPointer
		end
	end
end

function InputManager:GetPlayerPosition(player)
	local InputPointer = self:GetPlayerPointer(player)
	if InputPointer then
		return InputPointer:GetPointerPosition()
	end
end

function InputManager:GetNunchukPosition(player)
	local InputPointer = self:GetPlayerPointer(player)
	if InputPointer then
		return InputPointer.nunchukX, InputPointer.nunchukY
	end
end

function InputManager:IsPointing(player)
	local InputPointer = self:GetPlayerPointer(player)
	if InputPointer then
		return InputPointer.isPointing
	end
end

function InputManager:GatherProperties()
	return {}
end
