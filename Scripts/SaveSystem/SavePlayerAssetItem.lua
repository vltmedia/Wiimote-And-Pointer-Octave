SavePlayerAssetItem = {}

function SavePlayerAssetItem:GatherProperties()
	return {
		{name="asset", type=DatumType.Asset },
		{name="assetType", type=DatumType.String, default="icon" },
		{name="assetName", type=DatumType.String }
	}
end

function SavePlayerAssetItem:Create()
	if self.assetType == "" then
		self.assetType = "icon"
	end
end

function SavePlayerAssetItem:GetData()
	return { name=self.assetName, type=self.assetType, asset=self.asset}
end
