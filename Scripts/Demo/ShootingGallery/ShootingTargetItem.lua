---@class ShootingTargetItem
---@field targetName string
---@field manager ShootingGalleryTargetManager|Node
---@field description string
---@field collected boolean
---@field world World
---@field animateIn Node
---@field animateOut Node
---@field score Integer
---@field health Integer
---@field state string
ShootingTargetItem = {}

function ShootingTargetItem:Create()
	self.manager = nil
	self.collected = false
	self.state = "hidden"  -- hidden, animatingIn, active, animatingOut, collected

	self.OnAnimateInStarted = Signal:Create()
	self.OnAnimateInFinished = Signal:Create()
	self.OnAnimateOutStarted = Signal:Create()
	self.OnAnimateOutFinished = Signal:Create()
	self.OnHit = Signal:Create()
end

function ShootingTargetItem:Start()
	if self.manager == nil then
		self.manager = self.world:FindNode("ShootingGalleryTargetManager")
	end
	if self.manager then
		self.manager:Register(self)
	end

	-- Find parent sequence by traversing up hierarchy
	local parent = self:GetParent()
	while parent do
		if parent.RegisterTarget then
			parent:RegisterTarget(self)
			Log.Debug("ShootingTargetItem: Registered with sequence " .. (parent.GetName and parent:GetName() or "unknown"))
			break
		end
		parent = parent:GetParent()
	end

	-- Connect to animation finished signals (Lua script signals use .OnFinished:Connect)
	local name = self.GetName and self:GetName() or "unknown"
	if self.animateIn and self.animateIn.OnFinished then
		self.animateIn.OnFinished:Connect(self, function()
			Log.Debug("TargetItem [" .. name .. "]: animateIn OnFinished")
			self:OnAnimateInComplete()
		end)
		Log.Debug("TargetItem [" .. name .. "]: Connected to animateIn OnFinished")
	else
		Log.Debug("TargetItem [" .. name .. "]: No animateIn node or signal")
	end
	if self.animateOut and self.animateOut.OnFinished then
		self.animateOut.OnFinished:Connect(self, function()
			Log.Debug("TargetItem [" .. name .. "]: animateOut OnFinished")
			self:OnAnimateOutComplete()
		end)
		Log.Debug("TargetItem [" .. name .. "]: Connected to animateOut OnFinished")
	else
		Log.Debug("TargetItem [" .. name .. "]: No animateOut node or signal")
	end
end
function ShootingTargetItem:GetScore()
	return self.score or 100
end

function ShootingTargetItem:GetTargetName()
	return self.targetName or "Target"
end

function ShootingTargetItem:GetHealth()
	return self.health or 1
end

function ShootingTargetItem:GetDescription()
	return self.description or ""
end

function ShootingTargetItem:PlayAnimateIn()
	local name = self.GetName and self:GetName() or "unknown"
	Log.Debug("TargetItem:PlayAnimateIn [" .. name .. "] state=" .. self.state)
	if self.state ~= "hidden" then
		Log.Debug("TargetItem:PlayAnimateIn [" .. name .. "] skipped - wrong state")
		return
	end

	self.state = "animatingIn"
	self.OnAnimateInStarted:Emit()

	if self.animateIn then
		Log.Debug("TargetItem:PlayAnimateIn [" .. name .. "] playing animateIn")
		self.animateIn:Play()
	else
		Log.Debug("TargetItem:PlayAnimateIn [" .. name .. "] no animateIn, completing immediately")
		self:OnAnimateInComplete()
	end
end

function ShootingTargetItem:OnAnimateInComplete()
	if self.state ~= "animatingIn" then return end

	self.state = "active"
	self.OnAnimateInFinished:Emit()
end

function ShootingTargetItem:PlayAnimateOut()
	local name = self.GetName and self:GetName() or "unknown"
	Log.Debug("TargetItem:PlayAnimateOut [" .. name .. "] state=" .. self.state)
	if self.state ~= "active" and self.state ~= "animatingIn" then
		Log.Debug("TargetItem:PlayAnimateOut [" .. name .. "] skipped - wrong state")
		return
	end

	self.state = "animatingOut"
	self.OnAnimateOutStarted:Emit()

	if self.animateOut then
		Log.Debug("TargetItem:PlayAnimateOut [" .. name .. "] playing animateOut")
		self.animateOut:Play()
	else
		Log.Debug("TargetItem:PlayAnimateOut [" .. name .. "] no animateOut, completing immediately")
		self:OnAnimateOutComplete()
	end
end

function ShootingTargetItem:OnAnimateOutComplete()
	local name = self.GetName and self:GetName() or "unknown"
	Log.Debug("TargetItem:OnAnimateOutComplete [" .. name .. "] state=" .. self.state)
	if self.state ~= "animatingOut" then
		Log.Debug("TargetItem:OnAnimateOutComplete [" .. name .. "] skipped - wrong state")
		return
	end

	self.state = "collected"
	Log.Debug("TargetItem:OnAnimateOutComplete [" .. name .. "] now collected")
	self.OnAnimateOutFinished:Emit()
end

function ShootingTargetItem:ResetForGame()
	self.collected = false
	self.state = "hidden"

	-- Reset animations if they have Reset
	if self.animateIn and self.animateIn.Reset then
		self.animateIn:Reset()
	end
	if self.animateOut and self.animateOut.Reset then
		self.animateOut:Reset()
	end
end

function ShootingTargetItem:IsActive()
	return self.state == "active"
end

function ShootingTargetItem:IsCollected()
	return self.collected or self.state == "collected"
end
function ShootingTargetItem:GatherProperties()
	return {
		{name="targetName", type=DatumType.String },
		{name="score", type=DatumType.Integer },
		{name="health", type=DatumType.Integer },
		{name="animateIn", type=DatumType.Node },
		{name="animateOut", type=DatumType.Node },
	}
end

---@param player number
function ShootingTargetItem:Hit(player)
	-- Only allow hits when active
	Log.Debug("TargetItem: State is: " .. self.state)
	if self.state ~= "active" then return end
	if self.collected then return end

	self.collected = true
	self.OnHit:Emit(player)

	-- Notify manager
	if self.manager and self.manager.Hit then
		self.manager:Hit(player, self)
	end
	Log.Debug("TargetItem: PlayAnimateOut ")

	-- Play out animation
	self:PlayAnimateOut()
end

