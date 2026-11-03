debug = GetBoolParam('debug',false)

function init()
	--for HUD UI use
	showHealth = false
	healthFade = 0

	--Tank steering
	main_vehicle = FindVehicle('tank_steering_main')
	--there can be multiple left/right tracks, for more complex track setup
	l_tracks = FindVehicles('tank_steering_l_track')
	r_tracks = FindVehicles('tank_steering_r_track')

	if debug then
		if main_vehicle~= 0 then
			DebugPrint('tank_steering_main found: '..main_vehicle)
		else
			DebugPrint('tank_steering_main not found')
		end
		if #l_tracks > 0 then
			local txt = ""
			for i,l_track in ipairs(l_tracks)do
				txt = txt.. " ".. i .. ": " ..  l_track
			end
			DebugPrint('tank_steering_l_track(s) found: '..txt)
		else
			DebugPrint('tank_steering_l_track not found')
		end
		if #r_tracks > 0 then
			local txt = ""
			for i,r_track in ipairs(r_tracks)do
				txt = txt.. " ".. i .. ": " ..  r_track
			end
			DebugPrint('tank_steering_r_track(s) found: '..txt)
		else
			DebugPrint('tank_steering_r_track not found')
		end
	end

	--STRV hydrolic suspension
	hydrolic_avaliable = false
	hydrolics = FindJoints('STRV_hydrolic')
	--is there any hydrolic suspensions?
	if #hydrolics > 0 then
		hydrolic_avaliable = true
	end
	if hydrolic_avaliable then
		--set all hydrolic suspensions to motorized 0
		for i,hydrolic in ipairs(hydrolics)do
			SetJointMotorTarget(hydrolic,0)
		end
		hydrolic_target = 0
		last_hydrolic_target = 0
	end
end

function tick(dt)
	--if the player is driving the main body vehicle
	if GetPlayerVehicle() == main_vehicle and GetVehicleHealth(GetPlayerVehicle()) > 0 then
		--find the raw drive/steer/handbrake values
		local drive = InputValue('up') - InputValue('down')
		local steer = InputValue('right') - InputValue('left')
		local handbrake = InputDown('handbrake')
		--figure out the left/right track drive values, clamped between the -1, 1 (this feels surprisling nice with controller, they would love it :D)
		local l_track_drive = clamp(drive + steer,-1,1)
		local r_track_drive = clamp(drive - steer,-1,1)
		if drive < 0 then
			l_track_drive = clamp(drive - steer,-1,1)
			r_track_drive = clamp(drive + steer,-1,1)
		end
		if debug then
			DebugWatch('drive',drive)
			DebugWatch('steer',steer)
			DebugWatch('handbrake',handbrake)
			DebugWatch('l_track_drive',l_track_drive)
			DebugWatch('r_track_drive',r_track_drive)
		end
		--now drive all left/right tracks with the freshly made drive value and handbrake value
		for _,l_track in ipairs(l_tracks)do
			DriveVehicle(l_track, l_track_drive, 0, handbrake)
		end
		for _,r_track in ipairs(r_tracks)do
			DriveVehicle(r_track, r_track_drive, 0, handbrake)
		end

		--STRV hydrolic suspension
		if hydrolic_avaliable then
			--this does not work with controller :(
			hydrolic_target = hydrolic_target+(InputValue('F')-InputValue('R')) * dt * 5 -- speed multiplier, default is 1 deg/sec, this is in 5 deg/sec
			--find min/max of the first joint, they should be the same anyways
			local min,max = GetJointLimits(hydrolics[1])
			--figure out the joints target value, clamped between the min/max
			hydrolic_target = clamp(hydrolic_target,min,max)
			--would this improve the performance and decrese some jankiness? i hope so
			if hydrolic_target ~= last_hydrolic_target then
				last_hydrolic_target = hydrolic_target
				--power each joints to their respective angles
				for _,hydrolic in ipairs(hydrolics)do
					SetJointMotorTarget(hydrolic,hydrolic_target)
				end
			end
		end
	end
end
function clamp(x,min,max)
	return math.max(math.min(x,max),min)
end

function draw()
	--logic ripped from ingame lua files, dont need to understand it
	--but this would allow the extra control window to place nicely on top of the default one

	--only draw extra help box when this is a hydrolic vehicle that the player is driving
	if GetPlayerVehicle() == main_vehicle and hydrolic_avaliable then
		--get healthFade value, used for positioning the control help box
		local health = GetFloat("game.player.health")
		local show = health < 1
		if show and not showHealth then
			SetValue("healthFade", 1, "easeout", 0.5)
		elseif not show and showHealth then
			SetValue("healthFade", 0, "easein", 0.5)
		end
		showHealth = show
		--healthFade section end

		--custom control help window section start
		local vehicle = GetPlayerVehicle()

		local info = {}
		if HasTag(vehicle, "cranetop") then
			info[#info+1] = {""}
			info[#info+1] = {""}
			info[#info+1] = {""}
			info[#info+1] = {""}
		else
			info[#info+1] = {""}
			info[#info+1] = {""}
			info[#info+1] = {""}
			if HasTag(vehicle, "cranebottom") then
				info[#info+1] = {""}
				info[#info+1] = {""}
			elseif HasTag(vehicle, "crane") then
				info[#info+1] = {""}
				info[#info+1] = {""}
				info[#info+1] = {""}
			elseif HasTag(vehicle, "dumptruck") then
				info[#info+1] = {""}
				info[#info+1] = {""}
			elseif HasTag(vehicle, "frontloader") then
				info[#info+1] = {""}
				info[#info+1] = {""}
			elseif HasTag(vehicle, "skylift") then
				info[#info+1] = {""}
				info[#info+1] = {""}
			elseif HasTag(vehicle, "forklift") then
				info[#info+1] = {""}
				info[#info+1] = {""}
			elseif HasTag(vehicle, "tank") then
				info[#info+1] = {""}
				info[#info+1] = {""}
			elseif HasTag(vehicle, "boat") then
			else
				info[#info+1] = {""}
			end
		end
		info[#info+1] = {""}

		local new_info = {}
		new_info[#new_info+1] = {"R", "Aim down"}
		new_info[#new_info+1] = {"F", "Aim up"}
		UiPush()
			UiAlign("top left")

			local kw = 0
			local vw = 0
			for i=1, #new_info do
				UiFont("bold.ttf", 22)
				local w0 = UiGetTextSize(new_info[i][1])
				UiFont("regular.ttf", 22)
				local w1 = UiGetTextSize(new_info[i][2])
				kw = math.max(kw,w0)
				vw = math.max(vw,w1)
			end

			local w = kw + vw + 50
			local h = #new_info*22 + 30
			UiTranslate(UiWidth()-w-20, UiHeight()-h-20-#info*22-30-healthFade*50)
			UiColor(0,0,0,0.5)
			UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
			UiTranslate(kw + 20, 32)
			UiColor(1,1,1)
			for i=1, #new_info do
				local key = new_info[i][1]
				local func = new_info[i][2]
				UiFont("bold.ttf", 22)
				UiAlign("right")
				UiText(key)
				UiTranslate(10, 0)
				UiFont("regular.ttf", 22)
				UiAlign("left")
				UiText(func)
				UiTranslate(-10, 22)
			end
		UiPop()
		--custom control help window section end
	end
end