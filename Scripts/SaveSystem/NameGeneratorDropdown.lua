NameGeneratorDropdown = {}

function NameGeneratorDropdown:GatherProperties()
	return {
		{name="nameGenerator", type=DatumType.Widget },
		{name="dropdownType", type=DatumType.String, default="adjective"}
	}
end

function NameGeneratorDropdown:Create()
	self.OnRun = Signal:Create()
end

function NameGeneratorDropdown:ApplyOptions(options)
	self:ClearOptions()
	for _, word in ipairs(options) do
		self:AddOption(word.value)
	end
end

function NameGeneratorDropdown:Start()

	if self.dropdownType == "adjective" then
		self:ApplyOptions(self.nameGenerator:GetAdjectives())
	else
		self:ApplyOptions(self.nameGenerator:GetNouns())
	end
end
function NameGeneratorDropdown:Tick(deltaTime)

end