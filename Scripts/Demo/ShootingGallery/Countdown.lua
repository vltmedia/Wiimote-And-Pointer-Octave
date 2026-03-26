---@class Countdown
---@field duration number
---@field countdownText Text
---@field state string
---@field timeRemaining number
Countdown = {}

function Countdown:Create()
	if not self.duration or self.duration == 0 then
		self.duration = 3
	end
	self.state = "idle"
	self.timeRemaining = self.duration

	self.OnStarted = Signal:Create()
	self.OnTick = Signal:Create()      -- (timeRemaining, secondsLeft)
	self.OnSecond = Signal:Create()    -- (secondsLeft) fires each whole second
	self.OnFinished = Signal:Create()
end

function Countdown:Start()
	if self.state == "running" then return end

	self.state = "running"
	self.timeRemaining = self.duration
	self.lastSecond = math.ceil(self.duration)

	self.OnStarted:Emit()
	self:UpdateDisplay()

	Log.Debug("Countdown: Started (" .. self.duration .. " seconds)")
end

function Countdown:Stop()
	self.state = "idle"
end

function Countdown:Reset()
	self.state = "idle"
	self.timeRemaining = self.duration
	self:UpdateDisplay()
end

function Countdown:Tick(deltaTime)
	if self.state ~= "running" then return end

	self.timeRemaining = self.timeRemaining - deltaTime
	local secondsLeft = math.ceil(self.timeRemaining)

	self.OnTick:Emit(self.timeRemaining, secondsLeft)

	-- Fire OnSecond when we cross a whole second boundary
	if secondsLeft < self.lastSecond and secondsLeft >= 0 then
		self.lastSecond = secondsLeft
		self.OnSecond:Emit(secondsLeft)
		self:UpdateDisplay()
	end

	-- Check if finished
	if self.timeRemaining <= 0 then
		self.timeRemaining = 0
		self.state = "finished"
		self:UpdateDisplay()
		self.OnFinished:Emit()
		Log.Debug("Countdown: Finished")
	end
end

function Countdown:UpdateDisplay()
	if not self.countdownText or not self.countdownText.SetText then return end

	local secondsLeft = math.ceil(self.timeRemaining)

	if self.state == "finished" or secondsLeft <= 0 then
		self.countdownText:SetText("GO!")
	else
		self.countdownText:SetText(tostring(secondsLeft))
	end
end

--- Get time remaining
---@return number
function Countdown:GetTimeRemaining()
	return self.timeRemaining
end

--- Check if countdown is running
---@return boolean
function Countdown:IsRunning()
	return self.state == "running"
end

function Countdown:GatherProperties()
	return {
		{ name = "duration", type = DatumType.Float },
		{ name = "countdownText", type = DatumType.Text },
	}
end
