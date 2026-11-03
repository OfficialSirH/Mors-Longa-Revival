

--[[


A simple method that will check if AVF is running and inform the user if they are in an AVF vehicle without AVF active.


]]

check_AVF = {}

function AVF_INIT_FUNCTIONS()

	function check_AVF:init(vehicle)
		self.maxTime = 1
		self.timer = 0
		self.vehicle = vehicle
		self.enabled = true
		self.hideKey = {[0]="ctrl",[1]="c"}
	end

	function check_AVF:tick()
		if(self.timer<self.maxTime) then
			self.timer = self.timer + GetTimeStep()
		end

		if((InputPressed(self.hideKey[0])or InputDown(self.hideKey[0])) and
			(InputPressed(self.hideKey[1])or InputDown(self.hideKey[1]))) then
			self.enabled = false
			SetBool("level.avf.messageShown", true)
		end
	end

	function check_AVF:draw()
		if self.enabled and (GetPlayerVehicle() == self.vehicle and (not GetBool("level.avf.enabled"))) then
			self:drawMessage()
		end
	end

	function check_AVF:drawMessage()

			message = {
					[1] = "Please ensure you have the AVF (Armed Vehicles Framework) mod downloaded from the steam workshop and enabled in Teardown's mod manager. this vehicle won't shoot or function properly otherwise.",
			}
			header = "ERROR: AVF MOD NOT ENABLED!"
			message2 = [[Please ensure you have the AVF (Armed Vehicles Framework) mod downloaded from the steam workshop and enabled in Teardown's mod manager. Otherwise this vehicle won't shoot or function properly.

			press ctrl + c to hide this message]]

			UiPush()
			UiAlign("top left")
			local w = 400
			local h = #message*22 + 200
			UiTranslate(UiCenter() - w/2, UiMiddle() - h/2) -- because I don't know how big the official vehicle UI will be
			UiColor(1,0,0,0.5)
			UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
			UiTranslate(w, 32)
			UiColor(1,1,1)
			UiTranslate(-w, 0)

			UiFont("bold.ttf", 22)
			UiAlign("left")
			UiText(header)

			UiTranslate(0, 32)
			UiWordWrap(w)
			UiText(message2)
			UiPop()
	end

end

AVF_INIT_FUNCTIONS()

function init()
	check_AVF:init(GetPlayerVehicle())
end

function tick()
	check_AVF:tick()
end

function draw()
	check_AVF:draw()
end

function handleCommand(cmd) handle_quickload(cmd) end

function handle_quickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
			AVF_INIT_FUNCTIONS()
		end
		break
	end
end

function splitString(str, delimiter)
    local result = {}
    for word in string.gmatch(str, '([^'..delimiter..']+)') do
        result[#result+1] = trim(word)
    end
    return result
end

function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
 end