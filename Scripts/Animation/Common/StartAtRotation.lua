StartAtRotation = {}

function StartAtRotation:GatherProperties()
	return {
		{name="startRotation", type=DatumType.Vector },
		{name="node3D", type=DatumType.Node3D },
	}
end


function StartAtRotation:Reset()
	self.node3D:SetRotation(self.startRotation)
end


function StartAtRotation:Start()
	self:Reset()
end
