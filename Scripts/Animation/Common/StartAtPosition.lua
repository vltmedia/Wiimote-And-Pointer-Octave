StartAtPosition = {}

function StartAtPosition:GatherProperties()
	return {
		{name="startPosition", type=DatumType.Vector },
		{name="node3D", type=DatumType.Node3D },
	}
end


function StartAtPosition:Reset()
	self.node3D:SetPosition(self.startPosition)
end

function StartAtPosition:Start()
	self:Reset()
end
