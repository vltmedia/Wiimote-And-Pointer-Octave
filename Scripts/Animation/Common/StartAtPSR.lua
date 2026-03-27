StartAtPSR = {}

function StartAtPSR:GatherProperties()
	return {
		{name="startPosition", type=DatumType.Vector },
		{name="startRotation", type=DatumType.Vector },
		{name="startScale", type=DatumType.Vector, default = Vec(1,1,1) },
		{name="node3D", type=DatumType.Node3D },
	}
end


function StartAtPSR:Reset()
	self.node3D:SetPosition(self.startPosition)
	self.node3D:SetRotation(self.startRotation)
	self.node3D:SetScale(self.startScale)
end


function StartAtPSR:Start()
	self:Reset()
end
