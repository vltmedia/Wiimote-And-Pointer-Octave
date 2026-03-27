---@class PlayerData
---@field name string
---@field score number
---@field playerIndex number

---@class ShootingGalleryTargetManager
---@field targets ShootingTargetItem[]
---@field running boolean
---@field players PlayerData[]
---@field OnHit Signal
---@field OnPlayerScore Signal
ShootingGalleryTargetManager = {}

function ShootingGalleryTargetManager:Create()
	self.targets = {}
	self.running = false
	self.players = {
		{name="P1", score=0, playerIndex=1},
		{name="P2", score=0, playerIndex=2},
		{name="P3", score=0, playerIndex=3},
		{name="P4", score=0, playerIndex=4},
	}
	self.OnHit = Signal:Create()
	self.OnPlayerScore = Signal:Create()
end

---@param shootingTarget ShootingTargetItem
function ShootingGalleryTargetManager:Register(shootingTarget)
	table.insert(self.targets, shootingTarget)
end

---@param player number
---@param shootingTarget ShootingTargetItem
function ShootingGalleryTargetManager:Hit(player, shootingTarget)
	local playerData = self.players[player]
	if not playerData then
		playerData = self.players[1]  -- Default to player 1
	end

	local points = shootingTarget:GetScore() or 0
	playerData.score = playerData.score + points

	self.OnHit:Emit(shootingTarget,points)
	self.OnPlayerScore:Emit(playerData, shootingTarget)
end

