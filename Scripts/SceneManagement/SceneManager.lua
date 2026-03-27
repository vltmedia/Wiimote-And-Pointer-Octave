---@class SceneManager
SceneManager = {}
---@type SceneManager|nil
SceneManager.Instance = nil

function SceneManager:Create()
	-- Signals that other scripts can connect to
	self.OnSceneLoadRequested = Signal:Create()   -- (sceneName)
	self.OnSceneLoaded = Signal:Create()          -- (sceneName, sceneRoot)
	self.OnSceneUnloadRequested = Signal:Create() -- (sceneName)
	self.OnSceneUnloaded = Signal:Create()        -- (sceneName)
	self.OnAllScenesUnloaded = Signal:Create()    -- ()
	self.OnProgress = Signal:Create()             -- (progress)

	-- Track loaded scenes: sceneName -> { root = node, asset = scene, path = string }
	self.loadedScenes = {}
	self.mainScene = nil
	self.progress = 0
end

function SceneManager:Start()
	SceneManager.Instance = self
	Log.Debug("SceneManager: Started")
end

--- Set loading progress (0-1)
---@param progress number
function SceneManager:SetProgress(progress)
	self.progress = progress
	self.OnProgress:Emit(progress)
end

--- Load a scene additively using world:SpawnScene
---@param scenePath string Path to the scene asset
---@param sceneName string|nil Optional name to identify the scene (defaults to path)
---@param position table|nil Optional spawn position {x, y, z}
---@return boolean success
function SceneManager:LoadSceneAdditive(scenePath, sceneName, position)
	sceneName = sceneName or scenePath
	position = position or Vec(0, 0, 0)

	-- Check if already loaded
	if self.loadedScenes[sceneName] then
		return false
	end

	self.OnSceneLoadRequested:Emit(sceneName)

	-- Load the scene asset
	local sceneAsset = LoadAsset(scenePath)
	if not sceneAsset then
		Log.Error("SceneManager: Failed to load scene asset '" .. scenePath .. "'")
		return false
	end

	-- Spawn the scene using world:SpawnScene (additive)
	local sceneRoot = nil
	if self.world and self.world.SpawnScene then
		sceneRoot = self.world:SpawnScene(sceneAsset, position)
	end

	if sceneRoot then
		self.loadedScenes[sceneName] = {
			root = sceneRoot,
			asset = sceneAsset,
			path = scenePath
		}
		self.OnSceneLoaded:Emit(sceneName, sceneRoot)
		return true
	else
		Log.Error("SceneManager: Failed to spawn scene '" .. sceneName .. "'")
		return false
	end
end

--- Unload a previously loaded scene
---@param sceneName string Name of the scene to unload
---@return boolean success
function SceneManager:UnloadScene(sceneName)
	local sceneData = self.loadedScenes[sceneName]
	if not sceneData then
		Log.Warning("SceneManager: Scene '" .. sceneName .. "' is not loaded")
		return false
	end

	self.OnSceneUnloadRequested:Emit(sceneName)
	Log.Debug("SceneManager: Unloading scene '" .. sceneName .. "'")

	-- Destroy the scene root node (use Doom for deferred destruction)
	if sceneData.root then
		if sceneData.root.Doom then
			sceneData.root:Doom()
		elseif sceneData.root.DestroyDeferred then
			sceneData.root:DestroyDeferred()
		elseif sceneData.root.Destruct then
			sceneData.root:Destruct()
		end
	end

	self.loadedScenes[sceneName] = nil
	self.OnSceneUnloaded:Emit(sceneName)
	return true
end

--- Unload all additively loaded scenes
function SceneManager:UnloadAllScenes()
	local scenesToUnload = {}
	for sceneName, _ in pairs(self.loadedScenes) do
		table.insert(scenesToUnload, sceneName)
	end

	for _, sceneName in ipairs(scenesToUnload) do
		self:UnloadScene(sceneName)
	end

	self.OnAllScenesUnloaded:Emit()
end

--- Check if a scene is loaded
---@param sceneName string
---@return boolean
function SceneManager:IsSceneLoaded(sceneName)
	return self.loadedScenes[sceneName] ~= nil
end

--- Get the root node of a loaded scene
---@param sceneName string
---@return Node|nil
function SceneManager:GetSceneRoot(sceneName)
	local sceneData = self.loadedScenes[sceneName]
	if sceneData then
		return sceneData.root
	end
	return nil
end

--- Get list of all loaded scene names
---@return string[]
function SceneManager:GetLoadedSceneNames()
	local scenes = {}
	for sceneName, _ in pairs(self.loadedScenes) do
		table.insert(scenes, sceneName)
	end
	return scenes
end

--- Get count of loaded scenes
---@return number
function SceneManager:GetLoadedSceneCount()
	local count = 0
	for _, _ in pairs(self.loadedScenes) do
		count = count + 1
	end
	return count
end

--- Set the main scene name (for reference)
---@param sceneName string
function SceneManager:SetMainScene(sceneName)
	self.mainScene = sceneName
end

--- Get the main scene name
---@return string|nil
function SceneManager:GetMainScene()
	return self.mainScene
end

--- Switch to a new main scene (unloads all additive scenes, then loads new scene)
---@param scenePath string
---@param instant boolean|nil If true, load immediately without transition
function SceneManager:SwitchScene(scenePath, instant)
	instant = instant or false

	self:UnloadAllScenes()
	self.OnSceneLoadRequested:Emit(scenePath)

	-- Use world:LoadScene for non-additive scene loading
	if self.world and self.world.LoadScene then
		self.world:LoadScene(scenePath, instant)
	end
end

--- Reload a scene (unload then load again)
---@param sceneName string
---@return boolean success
function SceneManager:ReloadScene(sceneName)
	local sceneData = self.loadedScenes[sceneName]
	if not sceneData then
		Log.Warning("SceneManager: Scene '" .. sceneName .. "' is not loaded")
		return false
	end

	local scenePath = sceneData.path
	if not scenePath then
		Log.Warning("SceneManager: No path stored for scene '" .. sceneName .. "'")
		return false
	end

	self:UnloadScene(sceneName)
	return self:LoadSceneAdditive(scenePath, sceneName)
end

function SceneManager:GatherProperties()
	return {
		{ name = "mainScene", type = DatumType.String },
	}
end
