---@class ShootingGalleryUI
---@field manager ShootingGalleryTargetManager|Node
---@field scoreText1 Text
---@field scoreText2 Text
---@field scoreText3 Text
---@field scoreText4 Text
---@field hitFeedback Text
---@field world World
ShootingGalleryUI = {}

function ShootingGalleryUI:Create()
	self.connected = false
	self.manager = nil
end

function ShootingGalleryUI:Start()
	self:TryConnect()
end

function ShootingGalleryUI:TryConnect()
	if self.connected then return end

	-- Find manager if not assigned
	if not self.manager then
		self.manager = self.world:FindNode("ShootingGalleryTargetManager")
	end

	if not self.manager then return end

	-- Check if signals exist
	if not self.manager.OnPlayerScore or not self.manager.OnHit then
		return
	end

	-- Subscribe to score updates
	self.manager.OnPlayerScore:Connect(self, function(self, playerData, target)
		self:UpdatePlayerScore(playerData)
	end)

	-- Subscribe to hit events for feedback
	self.manager.OnHit:Connect(self, function(self, target, points)
		self:ShowHitFeedback(target, points)
	end)

	self.connected = true

	-- Initialize scores
	self:RefreshAllScores()
end

---@param playerData PlayerData
function ShootingGalleryUI:UpdatePlayerScore(playerData)
	local scoreText = self:GetScoreTextForPlayer(playerData.playerIndex)

	if scoreText and scoreText.SetText then

			scoreText:SetText(playerData.name .. ": " .. tostring(playerData.score))
		else
			scoreText:SetText(playerData.name .. ": -")
		end
end

---@param playerIndex number
---@return boolean
function ShootingGalleryUI:IsPlayerConnected(playerIndex)
	if Input.IsGamepadConnected then
		return Input.IsGamepadConnected(playerIndex)
	end
	-- Fallback: player 1 is always considered connected (mouse/keyboard)
	return playerIndex == 1
end

---@param playerIndex number
---@return Text|nil
function ShootingGalleryUI:GetScoreTextForPlayer(playerIndex)
	if playerIndex == 1 then return self.scoreText1
	elseif playerIndex == 2 then return self.scoreText2
	elseif playerIndex == 3 then return self.scoreText3
	elseif playerIndex == 4 then return self.scoreText4
	end
	return nil
end

function ShootingGalleryUI:RefreshAllScores()
	if not self.manager or not self.manager.players then return end

	for _, playerData in ipairs(self.manager.players) do
		self:UpdatePlayerScore(playerData)
	end
end

function ShootingGalleryUI:Tick()
	if not self.connected then
		self:TryConnect()
	end

	-- Periodically refresh to detect controller connect/disconnect
	-- self.refreshTimer = (self.refreshTimer or 0) + 1
	-- if self.refreshTimer >= 60 then  -- Every ~1 second at 60fps
	-- 	self.refreshTimer = 0
	-- 	self:RefreshAllScores()
	-- end
end

---@param target ShootingTargetItem
function ShootingGalleryUI:ShowHitFeedback(target, points)
	if self.hitFeedback and self.hitFeedback.SetText then
		local pointsNum = tonumber(points)
		local sign = pointsNum >= 0 and "+" or ""
		self.hitFeedback:SetText(sign .. tostring(pointsNum))
	end
end

function ShootingGalleryUI:GatherProperties()
	return {
		{ name = "scoreText1", type = DatumType.Text },
		{ name = "scoreText2", type = DatumType.Text },
		{ name = "scoreText3", type = DatumType.Text },
		{ name = "scoreText4", type = DatumType.Text },
		{ name = "hitFeedback", type = DatumType.Text },
	}
end
