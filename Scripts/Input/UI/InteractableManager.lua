---@class InteractableManager
InteractableManager = {}
---@type InteractableManager|nil
InteractableManager.Instance = nil

function InteractableManager:Create()
	-- Tables that other scripts may access
	self.interactables = {}      -- 2D widgets
	self.interactables3D = {}    -- 3D objects
	self.selectedIndex = {}      -- per-player selected index
end

function InteractableManager:Start()
	-- Runtime-only: singleton assignment and signal connections
	self.signalsConnected = false
	InteractableManager.Instance = self
	self:TryConnectSignals()
end

function InteractableManager:TryConnectSignals()
	if self.signalsConnected then return end

	if not self.InputManager then
		self.InputManager = InputManager.Instance
	end
	if not self.InputManager then
		self.InputManager = self:FindAncestor("InputManager")
	end

	if self.InputManager and self.InputManager.OnGamepadPressed then
		self.InputManager.OnGamepadPressed:Connect(self, function(player, pointerPos, nunchukPos, isPointing, button)
			self:HandleGamepadPress(player, pointerPos, button)
		end)

		self.InputManager.OnGamepadReleased:Connect(self, function(player, pointerPos, nunchukPos, isPointing, button)
			self:HandleGamepadRelease(player, pointerPos, button)
		end)

		self.signalsConnected = true
		Log.Debug("InteractableManager: Connected to InputManager signals")
	end
end

-- 2D Widget registration
function InteractableManager:RegisterInteractable(interactable)
	table.insert(self.interactables, interactable)
end

function InteractableManager:UnregisterInteractable(interactable)
	for i, v in ipairs(self.interactables) do
		if v == interactable then
			table.remove(self.interactables, i)
			return
		end
	end
end

-- 3D Object registration
function InteractableManager:RegisterInteractable3D(interactable)
	table.insert(self.interactables3D, interactable)
end

function InteractableManager:UnregisterInteractable3D(interactable)
	for i, v in ipairs(self.interactables3D) do
		if v == interactable then
			table.remove(self.interactables3D, i)
			return
		end
	end
end

function InteractableManager:Tick()
	-- Retry signal connection if not connected yet
	if not self.signalsConnected then
		self:TryConnectSignals()
	end

	-- Get camera directly from world
	local camera = nil
	local world = Engine.GetWorld(0)
	if world and world.GetActiveCamera then
		camera = world:GetActiveCamera()
	end

	-- Poll direct input as fallback (mouse/keyboard in editor)
	self:PollDirectInput()

	-- Process each player's pointer
	for player = 1, 2 do
		local x, y = self:GetPointerPositionForPlayer(player)

		if x and y then
			-- Check 2D widgets
			for i, interactable in ipairs(self.interactables) do
				local isOver = interactable:CheckContainsPoint(x, y)
				interactable:SetHovered(player, isOver)
			end

			-- Check 3D objects via raycast
			if camera and #self.interactables3D > 0 then
				local worldPos, hitNode = camera:TraceScreenToWorld(x, y)
				for _, interactable in ipairs(self.interactables3D) do
					local node3d = interactable:GetNode3D()
					local isOver = (hitNode == node3d) or self:IsDescendantOf(hitNode, node3d)
					interactable:SetHovered(player, isOver)
				end
			end
		end
	end
end

function InteractableManager:GetPointerPositionForPlayer(player)
	-- Get position from InputManager's registered pointer (same as GameCursor)
	local inputMgr = InputManager.Instance
	if inputMgr then
		local pointers = inputMgr.InputPointers
		if pointers then
			for _, pointer in ipairs(pointers) do
				if pointer.player == player and pointer.GetPointerPosition then
					local x, y = pointer:GetPointerPosition()
					if x and y then
						return x, y
					end
				end
			end
		end
	end

	-- Fallback: use Input API directly
	if Input.GetPointerPosition then
		local x, y = Input.GetPointerPosition(player)
		if x and y and (x ~= 0 or y ~= 0) then
			return x, y
		end
	end

	return nil, nil
end

-- Direct input polling (fallback when no InputPointer is running)
function InteractableManager:PollDirectInput()
	-- Mouse clicks for player 1
	if Input.IsMouseButtonPressed and Input.IsMouseButtonPressed(Mouse.Left) then
		local x, y = self:GetPointerPositionForPlayer(1)
		if x and y then
			self:HandlePointerPress(1, {x, y})
		end
	end
	if Input.IsMouseButtonReleased and Input.IsMouseButtonReleased(Mouse.Left) then
		local x, y = self:GetPointerPositionForPlayer(1)
		if x and y then
			self:HandlePointerRelease(1, {x, y})
		end
	end

	-- Keyboard navigation for player 1
	if Input.IsKeyPressed then
		if Input.IsKeyPressed(Key.Up) then
			self:HandleUserSelectNextDirection(1, Gamepad.Up)
		elseif Input.IsKeyPressed(Key.Down) then
			self:HandleUserSelectNextDirection(1, Gamepad.Down)
		elseif Input.IsKeyPressed(Key.Left) then
			self:HandleUserSelectNextDirection(1, Gamepad.Left)
		elseif Input.IsKeyPressed(Key.Right) then
			self:HandleUserSelectNextDirection(1, Gamepad.Right)
		end
	end
end

function InteractableManager:IsDescendantOf(node, potentialAncestor)
	if not node or not potentialAncestor then return false end
	local parent = node:GetParent()
	while parent do
		if parent == potentialAncestor then return true end
		parent = parent:GetParent()
	end
	return false
end



function InteractableManager:HandleGamepadPress(player, pointerPos, button)
	if button == Gamepad.Up or button == Gamepad.Down or button == Gamepad.Left or button == Gamepad.Right then
		self:HandleUserSelectNextDirection(player, button)
	end

	if not pointerPos then return end
	local x, y = pointerPos[1], pointerPos[2]
	if not x or not y then return end
	-- 2D widgets
	if self.interactables then
		for i, interactable in ipairs(self.interactables) do
			if interactable and interactable.CheckContainsPoint and interactable:CheckContainsPoint(x, y) then
				interactable:HandlePress(player, button)
			end
		end
	end

	


	-- 3D objects
	local camera = nil
	local world = Engine.GetWorld(0)
	if world and world.GetActiveCamera then
		camera = world:GetActiveCamera()
	end

	if camera and #self.interactables3D > 0 then
		local worldPos, hitNode = camera:TraceScreenToWorld(x, y)
		for _, interactable in ipairs(self.interactables3D) do
			local node3d = interactable:GetNode3D()
			if (hitNode == node3d) or self:IsDescendantOf(hitNode, node3d) then
				interactable:HandlePress(player, button)
			end
		end
	end

end

function InteractableManager:HandleGamepadRelease(player, pointerPos, button)
	-- Release all (they track their own press state)
	for _, interactable in ipairs(self.interactables) do
		interactable:HandleRelease(player, button)
	end
	for _, interactable in ipairs(self.interactables3D) do
		interactable:HandleRelease(player, button)
	end
end

-- Generic pointer press (mouse/touch/Wiimote click)
function InteractableManager:HandlePointerPress(player, pointerPos)
	if not pointerPos then return end
	local x, y = pointerPos[1], pointerPos[2]
	if not x or not y then return end

	-- 2D widgets
	if self.interactables then
		for _, interactable in ipairs(self.interactables) do
			if interactable and interactable.CheckContainsPoint and interactable:CheckContainsPoint(x, y) then
				interactable:HandlePress(player, Gamepad.A)
			end
		end
	end

	-- 3D objects
	local camera = nil
	local world = Engine.GetWorld(0)
	if world and world.GetActiveCamera then
		camera = world:GetActiveCamera()
	end

	if camera and self.interactables3D and #self.interactables3D > 0 then
		local worldPos, hitNode = camera:TraceScreenToWorld(x, y)
		for _, interactable in ipairs(self.interactables3D) do
			local node3d = interactable:GetNode3D()
			if (hitNode == node3d) or self:IsDescendantOf(hitNode, node3d) then
				interactable:HandlePress(player, Gamepad.A)
			end
		end
	end
end

-- Generic pointer release
function InteractableManager:HandlePointerRelease(player, pointerPos)
	for _, interactable in ipairs(self.interactables) do
		interactable:HandleRelease(player, Gamepad.A)
	end
	for _, interactable in ipairs(self.interactables3D) do
		interactable:HandleRelease(player, Gamepad.A)
	end
end

function InteractableManager:HandleUserSelectNextDirection(player, button)
	if #self.interactables == 0 then return end

	-- Initialize selection if not set
	if not self.selectedIndex[player] then
		self.selectedIndex[player] = 1
	end

	local currentIndex = self.selectedIndex[player]
	local currentWidget = self.interactables[currentIndex]
	if not currentWidget then
		self.selectedIndex[player] = 1
		return
	end

	local currentPos = self:GetInteractableCenter(currentWidget)
	if not currentPos then return end

	local bestIndex = nil
	local bestScore = math.huge

	for i, interactable in ipairs(self.interactables) do
		if i ~= currentIndex then
			local pos = self:GetInteractableCenter(interactable)
			if pos then
				local dx = pos.x - currentPos.x
				local dy = pos.y - currentPos.y
				local isValid, score = self:CheckDirection(button, dx, dy)
				if isValid and score < bestScore then
					bestScore = score
					bestIndex = i
				end
			end
		end
	end

	if bestIndex then
		-- Deselect old
		self.interactables[currentIndex]:SetSelected(player, false)
		-- Select new
		self.selectedIndex[player] = bestIndex
		self.interactables[bestIndex]:SetSelected(player, true)
	end
end

function InteractableManager:GetInteractableCenter(interactable)
	local widget = interactable:GetWidget()
	if not widget then return nil end

	local rect = widget:GetRect()
	if rect and rect.X and rect.Y and rect.Width and rect.Height then
		return { x = rect.X + rect.Width / 2, y = rect.Y + rect.Height / 2 }
	end
	return nil
end

function InteractableManager:CheckDirection(button, dx, dy)
	-- Returns isValid, score (lower is better)
	-- Score combines distance with directional preference
	local dist = math.sqrt(dx * dx + dy * dy)
	if dist == 0 then return false, math.huge end

	if button == Gamepad.Up then
		-- dy should be negative (up is lower Y)
		if dy >= 0 then return false, math.huge end
		return true, dist + math.abs(dx) * 2  -- penalize horizontal offset
	elseif button == Gamepad.Down then
		-- dy should be positive
		if dy <= 0 then return false, math.huge end
		return true, dist + math.abs(dx) * 2
	elseif button == Gamepad.Left then
		-- dx should be negative
		if dx >= 0 then return false, math.huge end
		return true, dist + math.abs(dy) * 2
	elseif button == Gamepad.Right then
		-- dx should be positive
		if dx <= 0 then return false, math.huge end
		return true, dist + math.abs(dy) * 2
	end

	return false, math.huge
end

function InteractableManager:SelectInteractable(player, index)
	if index < 1 or index > #self.interactables then return end

	-- Deselect current
	local currentIndex = self.selectedIndex[player]
	if currentIndex and self.interactables[currentIndex] then
		self.interactables[currentIndex]:SetSelected(player, false)
	end

	-- Select new
	self.selectedIndex[player] = index
	self.interactables[index]:SetSelected(player, true)
end

function InteractableManager:GatherProperties()
	return {
	}
end
