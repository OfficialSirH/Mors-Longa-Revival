

reload_timer = 0.3
recovery_value = 0
reload_value= 0
reload_pos = Vec(0,0.2,0.3)

throw_force = 55

max_throw = 50

throw_charge = 0.1

throw_deviation = .25

cook_time = 0

zoomLevel = 0
zoomMultiplier = 1.5


fuze_time = 2
fuze_reliability = 0.25

function init()
	--Register tool and enable it
	RegisterTool("mgl", "MGL", "MOD/vox/MGL.vox",4)
	SetBool("game.tool.mgl.enabled", true)

	--Laser gun has 60 seconds of ammo.
	--If played in sandbox mode, the sandbox script will make it infinite automatically
	SetInt("game.tool.mgl.ammo", 60)
	
	ready = 0
	fireTime = 0

	spin_speed = 10
	primed = false

	throw_charge_inc = max_throw/throw_charge
	
	pull_pin_snd = LoadSound("MOD/snd/vgo.ogg")
end

--Return a random vector of desired length
function rndVec(length)
	local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
	return VecScale(v, length)
end


function rnd(mi, ma)
	return math.random()*(ma-mi)+mi
end


function tick(dt)

    unlimitedammo = GetBool("savegame.mod.unlimitedammo")

	if GetString("game.player.tool") == "mgl" then
		if(GetBool("game.player.canusetool")) then
			zoomAim()
		end
		if GetPlayerGrabShape() == 0 and GetBool("game.player.canusetool") and (InputPressed("usetool"))and GetFloat("game.tool.mgl.ammo") > 0  and recovery_value<=0.5 then
			PlaySound(pull_pin_snd)
			local player_pos =  GetPlayerCameraTransform()
			local grenade_pos = TransformToParentPoint(player_pos,Vec(0.2,-0.5,-0.8))
			throw_force = max_throw
			--Generate XML for one banana and spawn it at spawn position
			local xml = "MOD/prefabs/MGLgrenade.xml"
			local entities = Spawn(xml, Transform(grenade_pos))

			--Set velocity on spawned bodies (only one in this case)
			local fwd = VecSub(TransformToParentPoint(player_pos,Vec(0,0,-1)),player_pos.pos)
			local norm = VecNormalize(fwd)
			local current_throw_deviation =throw_force*throw_deviation
			local vel = VecScale(norm,rnd(throw_force-throw_deviation,throw_force+throw_deviation))--25,35))
			for i=1, #entities do

				if GetEntityType(entities[i]) == "body" then

						local t = GetBodyTransform(entities[i])
						t.rot = QuatLookAt(fwd,VecAdd(fwd,VecScale(vel,1)))
						-- DebugWatch("u",t)
						SetBodyTransform(entities[i],t)

						SetBodyVelocity(entities[i], vel)
					-- SetBodyAngularVelocity(entities[i], Vec(rnd(-spin_speed,spin_speed), rnd(-spin_speed,spin_speed), rnd(-spin_speed,spin_speed)))
				end
			end
			reload_value = 0
			throw_force = 0.5
			cook_time = 0
			recovery_value = 1
			SetValue("reload_value",1,"cosine",reload_timer*.5)
			SetValue("recovery_value",0,"cosine",reload_timer*2)
			primed = false
		end
		local b = GetToolBody()
		SetToolTransform(Transform(VecLerp(Vec(0,0,0),reload_pos,reload_value*recovery_value)))

		local shapes = GetBodyShapes(b)
		if b ~= body then
			body = b

			--Get default transforms
			t0 = GetShapeLocalTransform(shapes[2])
		end
		t = TransformCopy(t0)

		if(recovery_value>0.5) then
			t.pos = Vec(-600,-600,-600)
		else
			t.pos = t0.pos
		end
		--SetShapeLocalTransform(shapes[2], t)
	
	elseif(zoomLevel>0) then
		zoomLevel =0
	end
end

function zoomAim()
	local  FOV=GetInt("options.gfx.fov")
	if(InputDown("rmb") and not IsHandleValid(GetPlayerGrabBody())) then
		if(zoomLevel==0) then
			SetValue("zoomLevel", 1, "linear", 0.5)
		end


	elseif((InputReleased("rmb") and not IsHandleValid(GetPlayerGrabBody())) ) then
		SetValue("zoomLevel", 0, "linear", 0.25)
	end
	if(zoomLevel~=0) then
		local targetZoom =   1+zoomMultiplier*(zoomMultiplier*zoomLevel/zoomMultiplier)
		SetCameraFov(FOV/targetZoom)
	end
end



function draw(dt)
		if GetString("game.player.tool") == "mgl" and GetBool("game.player.canusetool") then

	        SetBool("hud.aimdot",false)
	        UiAlign("center middle")
	        UiTranslate(UiCenter(), UiMiddle());
   	        UiTranslate(UiCenter()*.01,0 );

        	UiImage("ui/hud/crosshair-launcher.png")
        end


end

function clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end
