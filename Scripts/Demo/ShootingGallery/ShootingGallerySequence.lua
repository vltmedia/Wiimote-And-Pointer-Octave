---@class ShootingGallerySequence
---@field targets Node[]
---@field animateIn Node
---@field animateOut Node
---@field maxTime number
---@field state string
---@field sequenceGameTime number
ShootingGallerySequence = {}

function ShootingGallerySequence:Create()
	if not self.maxTime or self.maxTime == 0 then
		self.maxTime = 20
	end
	self.sequenceGameTime = self.maxTime
	self.state = "idle"
	self.registeredTargets = {}
	self.currentTimeline = nil

	self.OnSequenceStarted = Signal:Create()
	self.OnSequenceFinished = Signal:Create()
	self.OnAnimateInStarted = Signal:Create()
	self.OnAnimateInFinished = Signal:Create()
	self.OnAnimateOutStarted = Signal:Create()
	self.OnAnimateOutFinished = Signal:Create()
end

function ShootingGallerySequence:GetTimelinePlayer()
	local mgr = ShootingGalleryGameManager.Instance
	return mgr and mgr.timelinePlayer or nil
end

function ShootingGallerySequence:Start()
	self.state = "idle"

	-- Connect to timeline player from GameManager if using timeline assets
	local timelinePlayer = self:GetTimelinePlayer()
	if timelinePlayer then
		timelinePlayer:ConnectSignal("OnFinished", self, function()
			if self.currentTimeline == "in" then
				self:OnAnimationInFinished()
			elseif self.currentTimeline == "out" then
				self:OnAnimationOutFinished()
			end
			self.currentTimeline = nil
		end)
	end

	-- Connect to animation node finished signals (Lua scripts use .OnFinished:Connect)
	if self.animateIn and self.animateIn.OnFinished then
		self.animateIn.OnFinished:Connect(self, function()
			self:OnAnimationInFinished()
		end)
	end
	if self.animateOut and self.animateOut.OnFinished then
		self.animateOut.OnFinished:Connect(self, function()
			self:OnAnimationOutFinished()
		end)
	end
end

function ShootingGallerySequence:RegisterTarget(targetScript)
	table.insert(self.registeredTargets, targetScript)
end

function ShootingGallerySequence:ResetForGame()
	self.state = "idle"
	self.sequenceGameTime = self.maxTime
end

function ShootingGallerySequence:Play()
	if self.state == "idle" then
		self.OnSequenceStarted:Emit()
		self:PlayAnimateIn()
	end
end

function ShootingGallerySequence:PlayAnimateIn()
	if self.state ~= "idle" then return end

	self.state = "animatingIn"
	self.OnAnimateInStarted:Emit()

	-- Priority: timelineIn asset > animateIn node > immediate finish
	local timelinePlayer = self:GetTimelinePlayer()
	if self.timelineIn and timelinePlayer then
		self.currentTimeline = "in"
		timelinePlayer:SetTimeline(self.timelineIn)
		timelinePlayer:SetTime(0)
		timelinePlayer:Play()
	elseif self.animateIn and self.animateIn.Play then
		self.animateIn:Play()
	else
		self:OnAnimationInFinished()
	end
end

function ShootingGallerySequence:PlayAnimateOut()
	if self.state ~= "waitingOut" then return end

	self.state = "animatingOut"
	self.OnAnimateOutStarted:Emit()

	-- Priority: timelineOut asset > animateOut node > immediate finish
	local timelinePlayer = self:GetTimelinePlayer()
	if self.timelineOut and timelinePlayer then
		self.currentTimeline = "out"
		timelinePlayer:SetTimeline(self.timelineOut)
		timelinePlayer:SetTime(0)
		timelinePlayer:Play()
	elseif self.animateOut and self.animateOut.Play then
		self.animateOut:Play()
	else
		self:OnAnimationOutFinished()
	end
end

function ShootingGallerySequence:Tick(deltaTime)
	if self.state == "playing" then
		-- Check if all targets collected
		if self:AreAllTargetsCollected() then
			self.state = "waitingOut"
			self:PlayAnimateOut()
			return
		end

		-- Otherwise count down timer
		self.sequenceGameTime = self.sequenceGameTime - deltaTime
		if self.sequenceGameTime <= 0 then
			self.sequenceGameTime = 0
			self.state = "waitingOut"
			self:PlayAnimateOut()
		end
	end
end

function ShootingGallerySequence:AreAllTargetsCollected()
	local targets = self.registeredTargets
	if not targets or #targets == 0 then
		return false
	end

	for _, target in ipairs(targets) do
		if target.IsCollected then
			if not target:IsCollected() then
				return false
			end
		elseif target.collected ~= true then
			return false
		end
	end

	return true
end

function ShootingGallerySequence:AnimateInTargets()
	local targets = self.registeredTargets
	if not targets or #targets == 0 then return end

	for _, target in ipairs(targets) do
		if target.ResetForGame then
			target:ResetForGame()
		end
		if target.PlayAnimateIn then
			target:PlayAnimateIn()
		end
	end
end

function ShootingGallerySequence:AnimateOutTargets()
	local targets = self.registeredTargets
	if not targets or #targets == 0 then return end

	for _, target in ipairs(targets) do
		if target.PlayAnimateOut then
			target:PlayAnimateOut()
		end
	end
end

function ShootingGallerySequence:OnAnimationInFinished()
	if self.state ~= "animatingIn" then return end
	self:AnimateInTargets()
	self.state = "playing"
	self.OnAnimateInFinished:Emit()
end

function ShootingGallerySequence:OnAnimationOutFinished()
	if self.state ~= "animatingOut" then return end
	self:AnimateOutTargets()
	self.state = "complete"
	self.OnAnimateOutFinished:Emit()
	self.OnSequenceFinished:Emit()
end

---@return number
function ShootingGallerySequence:GetTimeRemaining()
	return self.sequenceGameTime
end

---@return boolean
function ShootingGallerySequence:IsPlaying()
	return self.state == "playing"
end

function ShootingGallerySequence:GatherProperties()
	return {
		{ name = "targets", type = DatumType.Node, array = true },
		{ name = "animateIn", type = DatumType.Node },
		{ name = "animateOut", type = DatumType.Node },
		{ name = "maxTime", type = DatumType.Integer },
		{ name = "order", type = DatumType.Integer },
		{ name = "timelineIn", type = DatumType.Asset },
		{ name = "timelineOut", type = DatumType.Asset },
	}
end
