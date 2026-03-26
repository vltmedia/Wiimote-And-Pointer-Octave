---@class ShootingGalleryEndGame
---@field resultsPanel Node
---@field playAgainButton Node
---@field gameManager ShootingGalleryGameManager|Node
---@field targetManager ShootingGalleryManager|Node
ShootingGalleryEndGame = {}

function ShootingGalleryEndGame:Create()
	self.OnPlayAgain = Signal:Create()
end

function ShootingGalleryEndGame:Start()
	-- Hide results panel initially
	if self.resultsPanel and self.resultsPanel.SetVisible then
		self.resultsPanel:SetVisible(false)
	end
	if self.resultsPanel and self.resultsPanel.SetActive then
		self.resultsPanel:SetActive(false)
	end
end

--- Called by ShootingGalleryGameManager when game ends
function ShootingGalleryEndGame:OnGameEnded()
	Log.Debug("ShootingGalleryEndGame: Game ended, showing results")

	-- Show results panel
	if self.resultsPanel then
		if self.resultsPanel.SetVisible then
			self.resultsPanel:SetVisible(true)
		end
		if self.resultsPanel.SetActive then
			self.resultsPanel:SetActive(true)
		end
	end

	-- Could display final scores, winner, etc. here
	self:DisplayResults()
end

function ShootingGalleryEndGame:DisplayResults()
	-- Override this or connect to targetManager to get scores
	if not self.targetManager or not self.targetManager.players then return end

	-- Find winner
	local winner = nil
	local highScore = -1

	for _, playerData in ipairs(self.targetManager.players) do
		if playerData.score > highScore then
			highScore = playerData.score
			winner = playerData
		end
	end

	if winner then
		Log.Debug("ShootingGalleryEndGame: Winner is " .. winner.name .. " with " .. winner.score .. " points")
	end
end

--- Call this to play again
function ShootingGalleryEndGame:PlayAgain()
	-- Hide results
	if self.resultsPanel then
		if self.resultsPanel.SetVisible then
			self.resultsPanel:SetVisible(false)
		end
		if self.resultsPanel.SetActive then
			self.resultsPanel:SetActive(false)
		end
	end

	-- Reset and run game manager
	if self.gameManager then
		if self.gameManager.Reset then
			self.gameManager:Reset()
		end
		if self.gameManager.Run then
			self.gameManager:Run()
		end
	end

	-- Reset target manager scores
	if self.targetManager and self.targetManager.players then
		for _, playerData in ipairs(self.targetManager.players) do
			playerData.score = 0
		end
	end

	self.OnPlayAgain:Emit()
	Log.Debug("ShootingGalleryEndGame: Playing again")
end

function ShootingGalleryEndGame:GatherProperties()
	return {
		{ name = "resultsPanel", type = DatumType.Node },
		{ name = "playAgainButton", type = DatumType.Node },
		{ name = "gameManager", type = DatumType.Node },
		{ name = "targetManager", type = DatumType.Node },
	}
end
