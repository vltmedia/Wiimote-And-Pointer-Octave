EmptySaveButton = {}

function EmptySaveButton:GatherProperties()
	return {
		{name="createWindow", type=DatumType.String },
		{name="saveListViewItem", type=DatumType.Widget },
	}
end

function EmptySaveButton:Start()
	self:ConnectSignal("Activated", self, EmptySaveButton.Activated)

end
function EmptySaveButton:Activated()
	Log.Debug("EmptySaveButton")
	self.saveListViewItem:SetSelected(true)

end
