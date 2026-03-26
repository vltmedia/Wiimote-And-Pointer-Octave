ExitButton = {}


function ExitButton:OnActivated()

	if self.windowManager then
		self.windowManager:OpenWindow(self.exitWindowName, true)
	end
end



function ExitButton:GatherProperties()
	return {
{name="windowManager", type=DatumType.Widget},
{name="exitWindowName", type=DatumType.String	}

	}
end
