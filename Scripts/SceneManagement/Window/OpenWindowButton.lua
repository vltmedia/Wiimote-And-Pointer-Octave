OpenWindowButton = {}


function OpenWindowButton:OnActivated()

	if self.windowManager then
		self.windowManager:OpenWindow(self.windowName, true)
	end
end



function OpenWindowButton:GatherProperties()
	return {
{name="windowManager", type=DatumType.Widget},
{name="windowName", type=DatumType.String	}

	}
end
