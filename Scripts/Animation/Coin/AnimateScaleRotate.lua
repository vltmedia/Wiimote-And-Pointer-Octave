---@class AnimateScaleRotate
---@field objectToAnimate Node3D
---@field startRotation Vector
---@field endRotation Vector
---@field startScale Vector
---@field endScale Vector
---@field animationTime number
---@field lerpStyle string
---@field setStartTransform boolean
---@field OnFinished Signal
AnimateScaleRotate = {}

function AnimateScaleRotate:Create()
	self.lerpValue = 0
	self.runtimeValue = 0
	self.animating = false

	-- Defaults
	if not self.animationTime or self.animationTime == 0 then
		self.animationTime = 1
	end
	if not self.lerpStyle or self.lerpStyle == "" then
		self.lerpStyle = "cubic"
	end

	self.OnFinished = Signal:Create()
end

function AnimateScaleRotate:Start()
	if self.setStartTransform == true and self.objectToAnimate then
		self.objectToAnimate:SetScale(self.startScale)
		self.objectToAnimate:SetRotation(self.startRotation)
	end
end
function AnimateScaleRotate:Play()
	if not self.animating then
		self.animating = true
		self.lerpValue = 0
		self.runtimeValue = 0
		-- Apply start transform immediately to prevent flash
		self:ApplyTransform(0)
	end
end

function AnimateScaleRotate:Stop()
	self.animating = false
end

function AnimateScaleRotate:Reset()
	self.animating = false
	self.lerpValue = 0
	self.runtimeValue = 0
	self:ApplyTransform(0)
end

function AnimateScaleRotate:Tick(deltaTime)
	if not self.animating then return end

	local newRuntimeValue = self.runtimeValue + deltaTime
	if newRuntimeValue >= self.animationTime then
		newRuntimeValue = self.animationTime
		self.animating = false
	end

	self.runtimeValue = newRuntimeValue
	self.lerpValue = newRuntimeValue / self.animationTime

	-- Apply easing and transform
	local easedValue = self:GetEasedValue(self.lerpValue)
	self:ApplyTransform(easedValue)

	-- Fire finished after applying final transform
	if not self.animating then
		self.OnFinished:Emit()
	end
end

---@param t number Linear 0-1 value
---@return number Eased 0-1 value
function AnimateScaleRotate:GetEasedValue(t)
	local style = self.lerpStyle or "cubic"

	if style == "linear" then
		return t
	elseif style == "cubic" then
		return self:inOutCubic(t, 0, 1, 1)
	elseif style == "quart" then
		return self:inOutQuart(t, 0, 1, 1)
	elseif style == "quint" then
		return self:inOutQuint(t, 0, 1, 1)
	elseif style == "expo" then
		return self:inOutExpo(t, 0, 1, 1)
	elseif style == "circ" then
		return self:inOutCirc(t, 0, 1, 1)
	elseif style == "sine" then
		return self:inOutSine(t, 0, 1, 1)
	else
		return self:inOutCubic(t, 0, 1, 1)
	end
end

---@param t number Eased 0-1 value
function AnimateScaleRotate:ApplyTransform(t)
	if not self.objectToAnimate then return end

	-- Lerp rotation
	if self.startRotation and self.endRotation then
		local rotX = self:Lerp(self.startRotation.x, self.endRotation.x, t)
		local rotY = self:Lerp(self.startRotation.y, self.endRotation.y, t)
		local rotZ = self:Lerp(self.startRotation.z, self.endRotation.z, t)

		if self.objectToAnimate.SetRotation then
			self.objectToAnimate:SetRotation(Vec(rotX, rotY, rotZ))
		end
	end

	-- Lerp scale
	if self.startScale and self.endScale then
		local scaleX = self:Lerp(self.startScale.x, self.endScale.x, t)
		local scaleY = self:Lerp(self.startScale.y, self.endScale.y, t)
		local scaleZ = self:Lerp(self.startScale.z, self.endScale.z, t)

		if self.objectToAnimate.SetScale then
			self.objectToAnimate:SetScale(Vec(scaleX, scaleY, scaleZ))
		end
	end
end

---@param a number Start value
---@param b number End value
---@param t number 0-1 interpolation
---@return number
function AnimateScaleRotate:Lerp(a, b, t)
	return a + (b - a) * t
end

function AnimateScaleRotate:inOutQuart(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * t ^ 4 + b
  else
    t = t - 2
    return -c / 2 * (t ^ 4 - 2) + b
  end
end


function AnimateScaleRotate:inOutQuint(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * t ^ 5 + b
  else
    t = t - 2
    return c / 2 * (t ^ 5 + 2) + b
  end
end

local sin = math.sin
local cos = math.cos
local pi = math.pi
local sqrt = math.sqrt
local abs = math.abs
local asin  = math.asin


function AnimateScaleRotate:inOutCubic(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * t * t * t + b
  else
    t = t - 2
    return c / 2 * (t * t * t + 2) + b
  end
end

function AnimateScaleRotate:inOutExpo(t, b, c, d)
  if t == 0 then return b end
  if t == d then return b + c end
  t = t / d * 2
  if t < 1 then
    return c / 2 * 2 ^ (10 * (t - 1)) + b - c * 0.0005
  else
    t = t - 1
    return c / 2 * 1.0005 * (2 - 2 ^ (-10 * t)) + b
  end
end
function AnimateScaleRotate:inOutCirc(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return -c / 2 * (sqrt(1 - t * t) - 1) + b
  else
    t = t - 2
    return c / 2 * (sqrt(1 - t * t) + 1) + b
  end
end
function AnimateScaleRotate:inOutSine(t, b, c, d)
  return -c / 2 * (cos(pi * t / d) - 1) + b
end

function AnimateScaleRotate:GatherProperties()

    return 
    {
        { name = "objectToAnimate", type = DatumType.Node3D },
        { name = "startRotation", type = DatumType.Vector },
        { name = "endRotation", type = DatumType.Vector },
        { name = "startScale", type = DatumType.Vector },
        { name = "endScale", type = DatumType.Vector },
        { name = "animationTime", type = DatumType.Float, default = 1 },
        { name = "lerpStyle", type = DatumType.String, default= "cubic" },
        { name = "setStartTransform", type = DatumType.Bool, default= false }

    }

end

