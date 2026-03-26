---@class ShootingTargetItem
---@field targetName string
---@field manager ShootingGalleryTargetManager|Node
---@field description string
---@field collected boolean
---@field world World
---@field animateIn Node
---@field animateOut Node
---@field dataAsset Asset
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

	-- Connect to animation finished signals
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
	return self.dataAsset:Get("score")
end

function ShootingTargetItem:GetTargetName()
	return self.dataAsset:Get("targetName")
end

function ShootingTargetItem:GetHealth()
	return self.dataAsset:Get("health")
end

function ShootingTargetItem:GetDescription()
	return self.dataAsset:Get("description")
end
function ShootingTargetItem:GetHitSound()
	return self.dataAsset:Get("hitSound")
end

function ShootingTargetItem:PlayAnimateIn()
	if self.state ~= "hidden" then return end

	self.state = "animatingIn"
	self.OnAnimateInStarted:Emit()

	if self.animateIn and self.animateIn.Play then
		self.animateIn:Play()
	else
		-- No animation, go straight to active
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

	if self.animateOut and self.animateOut.Play then
		self.animateOut:Play()
	else
		-- No animation, go straight to collected
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
		{name="dataAsset", type=DatumType.Asset },
		{name="animateIn", type=DatumType.Node },
		{name="animateOut", type=DatumType.Node },
	}
end

---@param player number
function ShootingTargetItem:Hit(player)
	-- Only allow hits when active
	if self.state ~= "active" then return end
	if self.collected then return end

	self.collected = true
	self.OnHit:Emit(player)

	-- Notify manager
	if self.manager and self.manager.Hit then
		self.manager:Hit(player, self)
	end

	-- Play out animation
	self:PlayAnimateOut()
end

