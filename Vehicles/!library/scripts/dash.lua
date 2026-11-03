function init()
	-- Actual current speed
	currentKmh=0
	-- Displayed speed (smoothly animated)
	displayKmh=0
	
	display=false
end
	
function tick()
	if v==GetPlayerVehicle() then
		display = true
	else
		display = false
	end
	
	body = GetShapeBody(GetScreenShape(screen))
	v=GetBodyVehicle(body)
	--Retrieve speed along forward direction (negative z axis)in local vehicle body transform
	local t=GetVehicleTransform(v)
	local vel=TransformToLocalVec(t,GetBodyVelocity(body))
	local speed=-vel[3]
	--Speed is in meter per second, convert to km/h
	currentKmh=math.abs(speed*3.6)
end

function update()
	--Doing this in update means it will be done independent of frame rate
	displayKmh=.9*displayKmh+.1*currentKmh
end

function draw()
	if not done then
		screen = UiGetScreen()
	end

	if display then
		UiAlign("center middle")
		UiPush()
			local scale = math.min(UiWidth()/300,UiHeight()/300)  
			--Only draw speedometer if visible
			UiTranslate(UiCenter()*4/3,UiMiddle())
			UiScale(scale)
			
			UiPush()
				local dash_max_speed=115 --max display speed
				local interval=10 --mark number every interval
				local init_rot=120 --initial rotation
				local rot_area=240 --size of the speedo
	
				local ratio=rot_area/dash_max_speed
				UiPush()
					UiTranslate(40,60)
					--Display speed
					UiFont("regular.ttf",75)
					UiText(round(displayKmh))
				UiPop()
	
				--Drawing Speedo
				UiPush()
					UiRotate(-init_rot)
					for i=0,dash_max_speed,interval/5 do
						UiPush()
							UiRotate(-i*ratio)
							if round(displayKmh)>=i then
								UiColor(1,0,0)
							else
								UiColor(1,1,1)
							end
							UiTranslate(100,0)
							UiAlign("right middle")
							if i%interval==0 then
								UiRectangle(20,2)
								UiTranslate(20,0)
								UiRotate(init_rot+i*ratio)
								UiAlign("center middle")
								UiFont("regular.ttf",26)
								UiText(i)
							else
								UiRectangle(10,1)
							end
						UiPop()
					end
				UiPop()
		
				UiPush()
					UiTranslate(0,-45)
					--Draw kmh sign
					UiFont("regular.ttf",25)
					UiText("mph")
				UiPop()
		
				UiPush()
					--Convert to rotation for kmh
					UiRotate(-init_rot-displayKmh*ratio)
					--Draw custom needle
					UiColor(1,0,0)
					UiAlign("left middle")
					UiRectangle(90,3)
					UiAlign("right middle")
					UiRectangle(20,3)
					UiAlign("center middle")
					UiImage("ui/common/dot.png")
				UiPop()
			UiPop()
		UiPop()
	end
end

function round(val,step)
	local steps=step or 1
	if val>=0 then return math.floor(val/steps+.5)*steps
	else return math.ceil(val/steps-.5)*steps end
end

function UiRectangle(w,h)
	UiImageBox("rect.png",w,h,0,0)
end