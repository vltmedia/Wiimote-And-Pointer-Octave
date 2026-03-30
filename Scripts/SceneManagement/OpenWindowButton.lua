OpenWindowButton = {}


function OpenWindowButton:OnActivated()

	WindowManager.ShowWindow(self.windowName)
	if self.thisWindowName ~= "" then
	WindowManager.HideWindow(self.thisWindowName)
	end

end



function OpenWindowButton:GatherProperties()
	return {
{name="thisWindowName", type=DatumType.String	},
{name="windowName", type=DatumType.String	}

	}
end
