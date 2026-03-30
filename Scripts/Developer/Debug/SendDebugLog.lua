SendDebugLog = {}


function SendDebugLog:Tick(deltaTime)

	if Input.IsPointerPressed(1) then
		Log.Debug("Pointer Pressed")
	end
	if Input.IsKeyDown(Key.A) then
		WindowManager.ShowWindow("windowa")
	end

end