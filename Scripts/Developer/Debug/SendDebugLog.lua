SendDebugLog = {}


function SendDebugLog:Tick(deltaTime)

	if Input.IsPointerPressed(1) then
		Log.Debug("Pointer Pressed")
	end
	if Input.IsKeyDown(Key.A) then
		DebugLogWindow.Instance:AddLog("Debug", "A Pressed")
		Log.Debug("A Pressed")
	end

end