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
	self.currentTimeline = nil  -- tracks which timeline is playing ("in" or "out")

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
	local targetCount = self.targets and #self.targets or 0

	-- Connect to timeline player from GameManager if using timeline assets
	local timelinePlayer = self:GetTimelinePlayer()
	if timelinePlayer then
		timelinePlayer:ConnectSignal("OnFinished", self, function()
			Log.Debug("Sequence: TimelinePlayer finished, currentTimeline=" .. (self.currentTimeline or "nil"))
			if self.currentTimeline == "in" then
				self:OnAnimationInFinished()
			elseif self.currentTimeline == "out" then
				self:OnAnimationOutFinished()
			end
			self.currentTimeline = nil
		end)
	end

	-- Connect to animation node finished signals (fallback - Lua scripts use .OnFinished:Connect)
	local name = self.GetName and self:GetName() or "unknown"
	if self.animateIn and self.animateIn.OnFinished then
		self.animateIn.OnFinished:Connect(self, function()
			Log.Debug("Sequence [" .. name .. "]: animateIn OnFinished fired")
			self:OnAnimationInFinished()
		end)
		Log.Debug("Sequence [" .. name .. "]: Connected to animateIn OnFinished")
	else
		Log.Debug("Sequence [" .. name .. "]: No animateIn node or signal")
	end
	if self.animateOut and self.animateOut.OnFinished then
		self.animateOut.OnFinished:Connect(self, function()
			Log.Debug("Sequence [" .. name .. "]: animateOut OnFinished fired")
			self:OnAnimationOutFinished()
		end)
		Log.Debug("Sequence [" .. name .. "]: Connected to animateOut OnFinished")
	else
		Log.Debug("Sequence [" .. name .. "]: No animateOut node or signal")
	end
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
	local name = self.GetName and self:GetName() or "unknown"
	Log.Debug("Sequence:Play [" .. name .. "] called - state=" .. self.state)
	if self.state == "idle" then
		self.OnSequenceStarted:Emit()
		self:PlayAnimateIn()
	else
		Log.Debug("Sequence:Play [" .. name .. "] skipped - not idle")
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

	-- Priority: timelineIn asset > animateIn node > immediate finish
	local timelinePlayer = self:GetTimelinePlayer()
	if self.timelineIn and timelinePlayer then
		Log.Debug("Sequence:PlayAnimateIn playing timelineIn asset")
		self.currentTimeline = "in"
		timelinePlayer:SetTimeline(self.timelineIn)
		timelinePlayer:Play()
	elseif self.animateIn and self.animateIn.Play then
		Log.Debug("Sequence:PlayAnimateIn playing animateIn node")
		self.animateIn:Play()
	else
		Log.Debug("Sequence:PlayAnimateIn no timeline, calling OnAnimationInFinished")
		self:OnAnimationInFinished()
	end
end

function ShootingGallerySequence:PlayAnimateOut()
	Log.Debug("Sequence:PlayAnimateOut called - state=" .. self.state)
	if self.state ~= "waitingOut" then
		Log.Debug("Sequence:PlayAnimateOut skipped - not waitingOut")
		return
	end

	self.state = "animatingOut"
	self.OnAnimateOutStarted:Emit()

	-- Priority: timelineOut asset > animateOut node > immediate finish
	local timelinePlayer = self:GetTimelinePlayer()
	if self.timelineOut and timelinePlayer then
		Log.Debug("Sequence:PlayAnimateOut playing timelineOut asset")
		self.currentTimeline = "out"
		timelinePlayer:SetTimeline(self.timelineOut)
		timelinePlayer:Play()
	elseif self.animateOut and self.animateOut.Play then
		Log.Debug("Sequence:PlayAnimateOut playing animateOut node")
		self.animateOut:Play()
	else
		Log.Debug("Sequence:PlayAnimateOut no timeline, calling OnAnimationOutFinished")
		self:OnAnimationOutFinished()
	end
end

function ShootingGallerySequence:Tick(deltaTime)
	if self.state == "playing" then
		-- Check if all targets collected
		if self:AreAllTargetsCollected() then
			Log.Debug("Sequence: All targets collected!")
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

	-- Use registered targets (scripts that registered themselves)
	local targets = self.registeredTargets
	if not targets or #targets == 0 then
		Log.Debug("Sequence:AnimateInTargets - no registered targets!")
		return
	end

	for i, target in ipairs(targets) do
		local name = target.GetName and target:GetName() or "unknown"

		if target.ResetForGame then
			target:ResetForGame()
		end
		if target.PlayAnimateIn then
			target:PlayAnimateIn()
		end
	end
end

function ShootingGallerySequence:AnimateOutTargets()

	-- Use registered targets (scripts that registered themselves)
	local targets = self.registeredTargets
	if not targets or #targets == 0 then
		Log.Debug("Sequence:AnimateOutTargets - no registered targets!")
		return
	end

	for i, target in ipairs(targets) do
		local name = target.GetName and target:GetName() or "unknown"

		if target.PlayAnimateOut then
			target:PlayAnimateOut()
		end
	end
end

--- Call this when animateIn timeline finishes (connect to timeline's OnFinished)
function ShootingGallerySequence:OnAnimationInFinished()
	Log.Debug("Sequence:OnAnimationInFinished called - state=" .. self.state)
	if self.state ~= "animatingIn" then return end
	-- Animate targets in
	self:AnimateInTargets()

	self.state = "playing"
	Log.Debug("Sequence:OnAnimationInFinished - now playing")
	self.OnAnimateInFinished:Emit()
end

--- Call this when animateOut timeline finishes
function ShootingGallerySequence:OnAnimationOutFinished()
	Log.Debug("Sequence:OnAnimationOutFinished called - state=" .. self.state)
	if self.state ~= "animatingOut" then
		Log.Debug("Sequence:OnAnimationOutFinished skipped - not animatingOut")
		return
	end
	self:AnimateOutTargets()
	self.state = "complete"
	Log.Debug("Sequence:OnAnimationOutFinished - emitting OnSequenceFinished")
	self.OnAnimateOutFinished:Emit()
	self.OnSequenceFinished:Emit()
	Log.Debug("Sequence:OnAnimationOutFinished - done, state=" .. self.state)
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
		{ name = "timelineIn", type = DatumType.Asset },
		{ name = "timelineOut", type = DatumType.Asset },
	}
end