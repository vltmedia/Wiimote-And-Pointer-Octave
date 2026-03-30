SavePlayerAssets = {}
SavePlayerAssets.assets = {}
SavePlayerAssets.instance = nil

function SavePlayerAssets:GatherProperties()
	return {
		{name="playerAssets", type=DatumType.Widget, array = true }
	}
end

function SavePlayerAssets:Create()
end

function SavePlayerAssets:Start()
	for _, asset in ipairs(self.playerAssets) do
		self:Register(asset:GetData())
	end
	SavePlayerAssets.instance = self
end

function SavePlayerAssets:Register(asset)
	--- Adds an item like { name="untitle.thing", type="icon", asset=%assetReference%}
	table.insert(SavePlayerAssets.assets, asset)
end


function SavePlayerAssets:GetAsset(name)
	for _, asset in ipairs(SavePlayerAssets.assets) do
		if asset.name == name then
			return asset
		end
		
	end
	return nil
end
