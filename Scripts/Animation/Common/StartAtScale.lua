StartAtScale = {}

function StartAtScale:GatherProperties()
	return {
		{name="startScale", type=DatumType.Vector },
		{name="node3D", type=DatumType.Node3D },
	}
end


function StartAtScale:Reset()
	self.node3D:SetScale(self.startScale)
end

function StartAtScale:Start()
	self:Reset()
end
