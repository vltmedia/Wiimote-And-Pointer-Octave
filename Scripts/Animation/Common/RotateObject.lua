RotateObject = {}

function RotateObject:Create()

	if self.angularVelocity == Vec(0,0,0) then
    self.angularVelocity = Vec()
	end

end

function RotateObject:GatherProperties()

    return 
    {
        { name = "objectToRotate", type = DatumType.Node3D },
        { name = "angularVelocity", type = DatumType.Vector }
    }

end

function RotateObject:Tick(deltaTime)

    self.objectToRotate:AddRotation(self.angularVelocity * deltaTime)
    
end
