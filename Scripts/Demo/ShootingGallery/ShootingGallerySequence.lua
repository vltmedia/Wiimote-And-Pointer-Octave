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

	self.OnSequenceStarted = Signal:Create()
	self.OnSequenceFinished = Signal:Create()
	self.OnAnimateInStarted = Signal:Create()
	self.OnAnimateInFinished = Signal:Create()
	self.OnAnimateOutStarted = Signal:Create()
	self.OnAnimateOutFinished = Signal:Create()
end

function ShootingGallerySequence:Start()
	self.state = "idle"
	local targetCount = self.targets and #self.targets or 0
	Log.Debug("Sequence:Start - targets=" .. targetCount .. " maxTime=" .. (self.maxTime or 0))
end

function ShootingGallerySequence:RegisterTarget(targetScript)
	table.insert(self.registeredTargets, targetScript)
	Log.Debug("Sequence:RegisterTarget - now have " .. #self.registeredTargets .. " registered targets")
end

function ShootingGallerySequence:ResetForGame()
	self.state = "idle"
	self.sequenceGameTime = self.maxTime
end

--- Start the sequence
function ShootingGallerySequence:Play()
	Log.Debug("Sequence:Play called - state=" .. self.state)
	if self.state == "idle" then
		self.OnSequenceStarted:Emit()
		self:PlayAnimateIn()
	else
		Log.Debug("Sequence:Play skipped - not idle")
	end
end

function ShootingGallerySequence:PlayAnimateIn()
	Log.Debug("Sequence:PlayAnimateIn called - state=" .. self.state)
	if self.state ~= "idle" then
		Log.Debug("Sequence:PlayAnimateIn skipped - not idle")
		return
	end

	self.state = "animatingIn"
	self.OnAnimateInStarted:Emit()

	-- Animate targets in
	Log.Debug("Sequence:PlayAnimateIn calling AnimateInTargets")
	self:AnimateInTargets()

	if self.animateIn and self.animateIn.Play then
		Log.Debug("Sequence:PlayAnimateIn playing animateIn timeline")
		self.animateIn:Play()
	else
		Log.Debug("Sequence:PlayAnimateIn no timeline, calling OnAnimationInFinished")
		self:OnAnimationInFinished()
	end
end

function ShootingGallerySequence:PlayAnimateOut()
	if self.state ~= "waitingOut" then return end

	self.state = "animatingOut"
	self.OnAnimateOutStarted:Emit()

	if self.animateOut and self.animateOut.Play then
		self.animateOut:Play()
	else
		self:OnAnimationOutFinished()
	end
end

function ShootingGallerySequence:Tick(deltaTime)
	if self.state == "playing" then
		self.sequenceGameTime = self.sequenceGameTime - deltaTime
		if self.sequenceGameTime <= 0 then
			self.sequenceGameTime = 0
			self.state = "waitingOut"
			self:PlayAnimateOut()
		end
	end
end

function ShootingGallerySequence:AnimateInTargets()
	Log.Debug("Sequence:AnimateInTargets called")

	-- Use registered targets (scripts that registered themselves)
	local targets = self.registeredTargets
	if not targets or #targets == 0 then
		Log.Debug("Sequence:AnimateInTargets - no registered targets!")
		return
	end

	Log.Debug("Sequence:AnimateInTargets - " .. #targets .. " registered targets")
	for i, target in ipairs(targets) do
		local name = target.GetName and target:GetName() or "unknown"
		Log.Debug("Sequence:AnimateInTargets - target " .. i .. ": " .. name)

		if target.ResetForGame then
			target:ResetForGame()
		end
		if target.PlayAnimateIn then
			Log.Debug("Sequence:AnimateInTargets - calling PlayAnimateIn on " .. name)
			target:PlayAnimateIn()
		end
	end
end

--- Call this when animateIn timeline finishes (connect to timeline's OnFinished)
function ShootingGallerySequence:OnAnimationInFinished()
	Log.Debug("Sequence:OnAnimationInFinished called - state=" .. self.state)
	if self.state ~= "animatingIn" then return end

	self.state = "playing"
	Log.Debug("Sequence:OnAnimationInFinished - now playing")
	self.OnAnimateInFinished:Emit()
end

--- Call this when animateOut timeline finishes
function ShootingGallerySequence:OnAnimationOutFinished()
	if self.state ~= "animatingOut" then return end

	self.state = "complete"
	self.OnAnimateOutFinished:Emit()
	self.OnSequenceFinished:Emit()
end

--- Get remaining time
---@return number
function ShootingGallerySequence:GetTimeRemaining()
	return self.sequenceGameTime
end

--- Check if sequence is currently playing
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
	}
end