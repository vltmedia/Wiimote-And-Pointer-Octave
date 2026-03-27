---@class ShootingGalleryGameManager
---@field sequences ShootingGallerySequence[]
---@field countdown Countdown
---@field endGameHandler Node
---@field state string
---@field timelinePlayer TimelinePlayer
---@field currentSequenceIndex number
---@field sortedSequences ShootingGallerySequence[]
ShootingGalleryGameManager = {}
ShootingGalleryGameManager.Instance = nil

function ShootingGalleryGameManager:Create()
	self.state = "idle"  -- idle, countdown, playing, ended
	self.currentSequenceIndex = 0
	self.sortedSequences = {}

	self.OnGameStarted = Signal:Create()
	self.OnGameEnded = Signal:Create()
	self.OnSequenceChanged = Signal:Create()
	self.OnCountdownStarted = Signal:Create()
	self.OnCountdownFinished = Signal:Create()
end

function ShootingGalleryGameManager:Start()
	ShootingGalleryGameManager.Instance = self

	-- Sort sequences by order
	self:SortSequences()

	-- Connect to countdown if available
	if self.countdown and self.countdown.OnFinished then
		self.countdown.OnFinished:Connect(self, function()
			self:OnCountdownComplete()
		end)
	end

	-- Connect to each sequence's finished signal
	for _, sequence in ipairs(self.sortedSequences) do
		if sequence.OnSequenceFinished then
			sequence.OnSequenceFinished:Connect(self, function()
				self:OnCurrentSequenceFinished()
			end)
		end
	end
end

function ShootingGalleryGameManager:SortSequences()
	self.sortedSequences = {}

	if not self.sequences then return end

	for _, seq in ipairs(self.sequences) do
		table.insert(self.sortedSequences, seq)
	end

	table.sort(self.sortedSequences, function(a, b)
		local orderA = a.order or 0
		local orderB = b.order or 0
		return orderA < orderB
	end)
end

function ShootingGalleryGameManager:Run()
	if self.state ~= "idle" then return end
	if #self.sortedSequences == 0 then return end

	self.OnGameStarted:Emit()

	if self.countdown and self.countdown.Start then
		self.state = "countdown"
		self.OnCountdownStarted:Emit()
		self.countdown:Start()
	else
		self:StartFirstSequence()
	end
end

function ShootingGalleryGameManager:PlayTimeline(timeline)
	if self.timelinePlayer then
		self.timelinePlayer:SetTimeline(timeline)
		self.timelinePlayer:Play()
	end
end

function ShootingGalleryGameManager:OnCountdownComplete()
	if self.state ~= "countdown" then return end

	self.OnCountdownFinished:Emit()
	self:StartFirstSequence()
end

function ShootingGalleryGameManager:StartFirstSequence()
	self.state = "playing"
	self.currentSequenceIndex = 1
	self:PlayCurrentSequence()
end

function ShootingGalleryGameManager:PlayCurrentSequence()
	local sequence = self.sortedSequences[self.currentSequenceIndex]
	if not sequence then return end

	self.OnSequenceChanged:Emit(self.currentSequenceIndex, sequence)

	if sequence.Play then
		sequence:Play()
	end
end

function ShootingGalleryGameManager:OnCurrentSequenceFinished()
	if self.state ~= "playing" then return end

	if self.currentSequenceIndex < #self.sortedSequences then
		self.currentSequenceIndex = self.currentSequenceIndex + 1
		self:PlayCurrentSequence()
	else
		self:EndGame()
	end
end

function ShootingGalleryGameManager:EndGame()
	self.state = "ended"
	self.OnGameEnded:Emit()

	if self.endGameHandler then
		if self.endGameHandler.OnGameEnded then
			self.endGameHandler:OnGameEnded()
		elseif self.endGameHandler.Run then
			self.endGameHandler:Run()
		end
	end
end

function ShootingGalleryGameManager:Reset()
	self.state = "idle"
	self.currentSequenceIndex = 0

	for _, sequence in ipairs(self.sortedSequences) do
		if sequence.ResetForGame then
			sequence:ResetForGame()
		end
	end

	if self.countdown and self.countdown.Reset then
		self.countdown:Reset()
	end
end

---@return ShootingGallerySequence|nil
function ShootingGalleryGameManager:GetCurrentSequence()
	if self.currentSequenceIndex > 0 and self.currentSequenceIndex <= #self.sortedSequences then
		return self.sortedSequences[self.currentSequenceIndex]
	end
	return nil
end

---@return number
function ShootingGalleryGameManager:GetSequenceCount()
	return #self.sortedSequences
end

---@return boolean
function ShootingGalleryGameManager:IsRunning()
	return self.state == "playing" or self.state == "countdown"
end

---@return boolean
function ShootingGalleryGameManager:HasEnded()
	return self.state == "ended"
end

function ShootingGalleryGameManager:GatherProperties()
	return {
		{ name = "sequences", type = DatumType.Node, array = true },
		{ name = "countdown", type = DatumType.Node },
		{ name = "endGameHandler", type = DatumType.Node },
		{ name = "timelinePlayer", type = DatumType.Node },
	}
end
