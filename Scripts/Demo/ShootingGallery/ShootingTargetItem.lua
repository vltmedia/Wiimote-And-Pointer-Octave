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
			break
		end
		parent = parent:GetParent()
	end

	-- Connect to animation finished signals (Lua scripts use .OnFinished:Connect)
	if self.animateIn and self.animateIn.OnFinished then
		self.animateIn.OnFinished:Connect(self, function()
			self:OnAnimateInComplete()
		end)
	end
	if self.animateOut and self.animateOut.OnFinished then
		self.animateOut.OnFinished:Connect(self, function()
			self:OnAnimateOutComplete()
		end)
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
	if self.state ~= "hidden" then return end

	self.state = "animatingIn"
	self.OnAnimateInStarted:Emit()

	if self.animateIn then
		self.animateIn:Play()
	else
		self:OnAnimateInComplete()
	end
end

function ShootingTargetItem:OnAnimateInComplete()
	if self.state ~= "animatingIn" then return end

	self.state = "active"
	self.OnAnimateInFinished:Emit()
end

function ShootingTargetItem:PlayAnimateOut()
	if self.state ~= "active" and self.state ~= "animatingIn" then return end

	self.state = "animatingOut"
	self.OnAnimateOutStarted:Emit()

	if self.animateOut then
		self.animateOut:Play()
	else
		self:OnAnimateOutComplete()
	end
end

function ShootingTargetItem:OnAnimateOutComplete()
	if self.state ~= "animatingOut" then return end

	self.state = "collected"
	self.OnAnimateOutFinished:Emit()
end

function ShootingTargetItem:ResetForGame()
	self.collected = false
	self.state = "hidden"

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
		{ name = "targetName", type = DatumType.String },
		{ name = "score", type = DatumType.Integer },
		{ name = "health", type = DatumType.Integer },
		{ name = "animateIn", type = DatumType.Node },
		{ name = "animateOut", type = DatumType.Node },
	}
end

---@param player number
function ShootingTargetItem:Hit(player)
	if self.state ~= "active" then return end
	if self.collected then return end

	self.collected = true
	self.OnHit:Emit(player)

	if self.manager and self.manager.Hit then
		self.manager:Hit(player, self)
	end

	self:PlayAnimateOut()
end
