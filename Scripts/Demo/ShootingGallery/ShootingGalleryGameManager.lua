---@class ShootingGalleryGameManager
---@field sequences ShootingGallerySequence[]
---@field countdown Countdown
---@field endGameHandler Node
---@field state string
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
	self.OnSequenceChanged = Signal:Create()  -- (sequenceIndex, sequence)
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

	Log.Debug("ShootingGalleryGameManager: Started with " .. #self.sortedSequences .. " sequences")
end

function ShootingGalleryGameManager:SortSequences()
	self.sortedSequences = {}

	if not self.sequences then return end

	-- Copy sequences to sortable array
	for _, seq in ipairs(self.sequences) do
		table.insert(self.sortedSequences, seq)
	end

	-- Sort by order property
	table.sort(self.sortedSequences, function(a, b)
		local orderA = a.order or 0
		local orderB = b.order or 0
		return orderA < orderB
	end)
end

--- Start the game (with optional countdown)
function ShootingGalleryGameManager:Run()
	if self.state ~= "idle" then
		Log.Warning("ShootingGalleryGameManager: Cannot run, state is " .. self.state)
		return
	end

	if #self.sortedSequences == 0 then
		Log.Warning("ShootingGalleryGameManager: No sequences to play")
		return
	end

	self.OnGameStarted:Emit()

	-- Start countdown if available, otherwise go straight to playing
	if self.countdown and self.countdown.Start then
		self.state = "countdown"
		self.OnCountdownStarted:Emit()
		self.countdown:Start()
	else
		self:StartFirstSequence()
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
	if not sequence then
		Log.Error("ShootingGalleryGameManager: No sequence at index " .. self.currentSequenceIndex)
		return
	end

	self.OnSequenceChanged:Emit(self.currentSequenceIndex, sequence)
	Log.Debug("ShootingGalleryGameManager: Playing sequence " .. self.currentSequenceIndex)

	if sequence.Play then
		sequence:Play()
	end
end

function ShootingGalleryGameManager:OnCurrentSequenceFinished()
	if self.state ~= "playing" then return end

	Log.Debug("ShootingGalleryGameManager: Sequence " .. self.currentSequenceIndex .. " finished")

	-- Check if there are more sequences
	if self.currentSequenceIndex < #self.sortedSequences then
		self.currentSequenceIndex = self.currentSequenceIndex + 1
		self:PlayCurrentSequence()
	else
		-- All sequences complete
		self:EndGame()
	end
end

function ShootingGalleryGameManager:EndGame()
	self.state = "ended"
	self.OnGameEnded:Emit()

	Log.Debug("ShootingGalleryGameManager: Game ended")

	-- Call end game handler if available
	if self.endGameHandler then
		if self.endGameHandler.OnGameEnded then
			self.endGameHandler:OnGameEnded()
		elseif self.endGameHandler.Run then
			self.endGameHandler:Run()
		end
	end
end

--- Reset the game to play again
function ShootingGalleryGameManager:Reset()
	self.state = "idle"
	self.currentSequenceIndex = 0

	-- Reset all sequences
	for _, sequence in ipairs(self.sortedSequences) do
		if sequence.ResetForGame then
			sequence:ResetForGame()
		end
	end

	-- Reset countdown if available
	if self.countdown and self.countdown.Reset then
		self.countdown:Reset()
	end

	Log.Debug("ShootingGalleryGameManager: Reset")
end

--- Get current sequence
---@return ShootingGallerySequence|nil
function ShootingGalleryGameManager:GetCurrentSequence()
	if self.currentSequenceIndex > 0 and self.currentSequenceIndex <= #self.sortedSequences then
		return self.sortedSequences[self.currentSequenceIndex]
	end
	return nil
end

--- Get total sequence count
---@return number
function ShootingGalleryGameManager:GetSequenceCount()
	return #self.sortedSequences
end

--- Check if game is running
---@return boolean
function ShootingGalleryGameManager:IsRunning()
	return self.state == "playing" or self.state == "countdown"
end

--- Check if game has ended
---@return boolean
function ShootingGalleryGameManager:HasEnded()
	return self.state == "ended"
end

function ShootingGalleryGameManager:GatherProperties()
	return {
		{ name = "sequences", type = DatumType.Node, array = true },
		{ name = "countdown", type = DatumType.Node },
		{ name = "endGameHandler", type = DatumType.Node },
	}
end
