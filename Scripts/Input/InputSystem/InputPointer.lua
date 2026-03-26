InputPointer = {}

function InputPointer:Create()
	-- Editor-configurable defaults
	self.player = self.player or 1
	self.inputMode = self.inputMode or "auto"  -- "auto", "mouse", "touch", "gamepad"

	-- Signals and tables that other scripts may connect to
	self.pointerX = 0
	self.pointerY = 0
	self.pointerXDelta = 0
	self.pointerYDelta = 0
	self.nunchukX = 0
	self.nunchukY = 0
	self.orientation = Vec(0, 0, 0)
	self.isPointing = false
	self.OnGamepadPressed = Signal:Create()
	self.OnGamepadReleased = Signal:Create()
	self.OnPointingStarted = Signal:Create()
	self.OnPointingStopped = Signal:Create()
	self.OnPointerPressed = Signal:Create()
	self.OnPointerReleased = Signal:Create()
end

function InputPointer:Start()
	-- Runtime-only: registration with manager
	self.registered = false
	Log.Debug("Pointer Started for player " .. self.player)
	self:TryRegister()
end

function InputPointer:TryRegister()
	if self.registered then return end

	if not self.manager then
		self.manager = self.world:FindNode("InputManager")
	end

	if self.manager and self.manager.RegisterInputPointer then
		self.manager:RegisterInputPointer(self)
		self.registered = true
		Log.Debug("Registered Pointer with Manager")
	end
end

function InputPointer:GetIsPointing()
	return self.isPointing
end

function InputPointer:Tick(deltaTime)
	if not self.registered then
		self:TryRegister()
	end

	local pointerXNow, pointerYNow = self:GetPointerPosition()
	self.pointerXDelta = pointerXNow - self.pointerX  -- new - old
	self.pointerYDelta = pointerYNow - self.pointerY  -- new - old
	self.pointerX, self.pointerY = pointerXNow, pointerYNow
	self.nunchukX, self.nunchukY = self:GetNunchukPosition()

	-- Check if pointer is active (Wiimote pointing at screen, mouse moved, or touch active)
	local pointing = Input.IsPointerDown(self.player)
	-- For player 1, also consider mouse as always "pointing" when position is valid
	if self.player == 1 and not pointing and (pointerXNow ~= 0 or pointerYNow ~= 0) then
		pointing = true
	end
	local pointingChanged = pointing ~= self.isPointing
	local pointingStarted = pointing and pointingChanged
	local pointingStopped = not pointing and pointingChanged
	self.isPointing = pointing
	if pointingStarted then
		self.OnPointingStarted:Emit(self.player, self.pointerX, self.pointerY)
	end
	if pointingStopped then
		self.OnPointingStopped:Emit(self.player, self.pointerX, self.pointerY)
	end

	-- Handle pointer/touch input (works for Wiimote IR, mouse, and touch)
	if Input.IsPointerJustDown and Input.IsPointerJustDown(self.player) then
		local pointerPos = {self.pointerX, self.pointerY}
		local nunchukPos = {self.nunchukX, self.nunchukY}
		self.OnPointerPressed:Emit(self.player, pointerPos, "pointer")
		self.OnGamepadPressed:Emit(self.player, pointerPos, nunchukPos, self.isPointing, Gamepad.A)
		if InteractableManager.Instance then
			InteractableManager.Instance:HandlePointerPress(self.player, pointerPos)
		end
	end
	if Input.IsPointerJustUp and Input.IsPointerJustUp(self.player) then
		local pointerPos = {self.pointerX, self.pointerY}
		self.OnPointerReleased:Emit(self.player, pointerPos, "pointer")
		if InteractableManager.Instance then
			InteractableManager.Instance:HandlePointerRelease(self.player, pointerPos)
		end
	end

	-- Handle mouse buttons (for player 1 only, or if using mouse mode)
	if self.player == 1 then
		self:CheckMouseButton(Mouse.Left, Gamepad.A)
		self:CheckMouseButton(Mouse.Right, Gamepad.B)
		self:CheckMouseButton(Mouse.Middle, Gamepad.X)
	end

	-- Handle keyboard navigation (for player 1)
	if self.player == 1 then
		self:CheckKey(Key.Up, Gamepad.Up)
		self:CheckKey(Key.Down, Gamepad.Down)
		self:CheckKey(Key.Left, Gamepad.Left)
		self:CheckKey(Key.Right, Gamepad.Right)
		self:CheckKey(Key.Enter, Gamepad.A)
		self:CheckKey(Key.Space, Gamepad.A)
		self:CheckKey(Key.Escape, Gamepad.B)
	end

	-- Check gamepad buttons
	self:CheckButton(Gamepad.A)
	self:CheckButton(Gamepad.B)
	self:CheckButton(Gamepad.C)
	self:CheckButton(Gamepad.Z)
	self:CheckButton(Gamepad.X)
	self:CheckButton(Gamepad.Y)
	self:CheckButton(Gamepad.Up)
	self:CheckButton(Gamepad.Down)
	self:CheckButton(Gamepad.Left)
	self:CheckButton(Gamepad.Right)
	self:CheckButton(Gamepad.Start)
	self:CheckButton(Gamepad.Select)
	self:CheckButton(Gamepad.Home)
end

function InputPointer:CheckButton(button)
	local pointerPos = {self.pointerX, self.pointerY}
	local nunchukPos = {self.nunchukX, self.nunchukY}

	if Input.IsGamepadPressed(button, self.player) then
		self.OnGamepadPressed:Emit(self.player, pointerPos, nunchukPos, self.isPointing, button)
		if InteractableManager.Instance then
			InteractableManager.Instance:HandleGamepadPress(self.player, pointerPos, button)
		end
	end
	if Input.IsGamepadReleased(button, self.player) then
		self.OnGamepadReleased:Emit(self.player, pointerPos, nunchukPos, self.isPointing, button)
	end
end

function InputPointer:CheckMouseButton(mouseButton, mappedButton)
	if not Input.IsMouseButtonPressed or not Input.IsMouseButtonReleased then return end

	local pointerPos = {self.pointerX, self.pointerY}
	local nunchukPos = {self.nunchukX, self.nunchukY}

	if Input.IsMouseButtonPressed(mouseButton) then
		self.OnPointerPressed:Emit(self.player, pointerPos, "mouse")
		self.OnGamepadPressed:Emit(self.player, pointerPos, nunchukPos, true, mappedButton)
		if InteractableManager.Instance then
			InteractableManager.Instance:HandleGamepadPress(self.player, pointerPos, mappedButton)
		end
	end
	if Input.IsMouseButtonReleased(mouseButton) then
		self.OnPointerReleased:Emit(self.player, pointerPos, "mouse")
		self.OnGamepadReleased:Emit(self.player, pointerPos, nunchukPos, true, mappedButton)
		if InteractableManager.Instance then
			InteractableManager.Instance:HandleGamepadRelease(self.player, pointerPos, mappedButton)
		end
	end
end

function InputPointer:CheckKey(key, mappedButton)
	if not Input.IsKeyPressed or not Input.IsKeyReleased then return end

	local pointerPos = {self.pointerX, self.pointerY}
	local nunchukPos = {self.nunchukX, self.nunchukY}

	if Input.IsKeyPressed(key) then
		self.OnGamepadPressed:Emit(self.player, pointerPos, nunchukPos, self.isPointing, mappedButton)
		if InteractableManager.Instance then
			InteractableManager.Instance:HandleGamepadPress(self.player, pointerPos, mappedButton)
		end
	end
	if Input.IsKeyReleased(key) then
		self.OnGamepadReleased:Emit(self.player, pointerPos, nunchukPos, self.isPointing, mappedButton)
	end
end

function InputPointer:GetNunchukPosition()
	self.nunchukX = Input.GetGamepadAxis(Gamepad.AxisLX, self.player)
	self.nunchukY = Input.GetGamepadAxis(Gamepad.AxisLY, self.player)
	return self.nunchukX, self.nunchukY
end

function InputPointer:GetPointerPosition()
	-- Try pointer position first (Wiimote IR, touch)
	local x, y = Input.GetPointerPosition(self.player)

	-- Fall back to mouse position for player 1
	if (not x or not y or (x == 0 and y == 0)) and self.player == 1 then
		if Input.GetMousePosition then
			x, y = Input.GetMousePosition()
		end
	end

	return x or 0, y or 0
end

function InputPointer:GetPointerOrientation()
	return Input.GetGamepadOrientation(self.player)
end

function InputPointer:GetPointerPositionNormalized()
	return Input.GetPointerPositionNormalized(self.player)
end

function InputPointer:IsPointing()
	return self.isPointing
end

function InputPointer:GatherProperties()
	return {
		{ name = "player", type = DatumType.Integer },
		{ name = "manager", type = DatumType.Node },
		{ name = "inputMode", type = DatumType.String },  -- "auto", "mouse", "touch", "gamepad"
	}
end
