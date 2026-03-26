HomeButonQuit = {}

function HomeButonQuit:Tick(delta)

	if Input.IsGamepadButtonJustDown(Gamepad.Home)then
		Engine.Quit()
	end

end