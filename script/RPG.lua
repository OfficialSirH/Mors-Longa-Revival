#version 2
#include "script/include/player.lua"
#include "gunfunctions.lua"
#include "gunnet.lua"
#include "../Settings.lua"

Init_Settings()

reload_value= 0
reload_pos = Vec(0,0.2,0.3)

throw_force = 0.5

max_throw = 20

throw_charge = 0.1

throw_deviation = .25

cook_time = 0

zoomLevel = 0
zoomMultiplier = 1.5


fuze_time = 4
fuze_reliability = 0.25

function server.init()
	RegisterTool("gun-rpg", "RPG-7", "MOD/vox/grenade_tool.vox", 1)
	-- (v2, Phase 2) tools are enabled per player by inventory.lua (server)
	GunNet_ServerInit()
end

function server.tick(dt)
	-- (v2, Phase 2) tools are enabled per player by inventory.lua (server)
	GunNet_ServerTick(dt)
end

function client.init()
	-- (v2) RegisterTool moved to server.init()

	--Laser gun has 60 seconds of ammo.
	--If played in sandbox mode, the sandbox script will make it infinite automatically
	inventoryenabled = true
	reserveammo = GetInt("inventory.ammocount_rocket")
	ammo = 0
	magtable2 = {}
	totalmags = 0
	curmagslot = 1
	nextmagslot = 1
	rockettype = "rocket0"

	ready = 0
	fireTime = 0

	spin_speed = 10
	primed = false

	throw_charge_inc = max_throw/throw_charge

	pull_pin_empty_snd = LoadSound("MOD/snd/Weapons/rpg/RPG_fire_plr_emty_0.ogg")

	reload_raise = LoadSound("MOD/snd/Weapons/rpg/reload/RPG_raise.ogg")

	reload_load_snd = LoadSound("MOD/snd/Weapons/rpg/reload/RPG_reload_fast_load_0.ogg")
	loadSoundPlayed = false

	gunsound = LoadSound("MOD/snd/Weapons/rpg/RPG_fire_plr_0.ogg")

	reloadTime = 2
	reloadTimer = 0
	shootTimer = 0
	reloading = false
	initammo = false

	lightTimer = 0

	ADSx = 0
	ADSy = 0
	ADSz = 0
	ADSrotx = 0
	ADSroty = 0
	ADSrotz = 0
	ADSx0 = 0
	ADSy0 = 0
	ADSz0 = 0
	ADSrotx0 = 0
	ADSroty0 = 0
	ADSrotz0 = 0
	ADSdelta = {0,0,0,0,0,0}
	ADSfov = 0
	SELx = 0
	SELy = 0
	SELz = 0
	SELrotx = 0
	SELroty = 0
	SELrotz = 0
	INSx = 0
	INSy = 0
	INSz = 0
	INSrotx = 0
	INSroty = 0
	INSrotz = 0
	recoilTimer = 0
	crouchoffset = 0

	hidePos = Vec(0, -200, 0)
	hideTrans = Transform(hidePos,QuatEuler())
end

--Return a random vector of desired length
function rndVec(length)
	local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
	return VecScale(v, length)
end


function rnd(mi, ma)
	return math.random()*(ma-mi)+mi
end


function client.tick(dt)
	GunNet_ClientTick(dt)

    unlimitedammo = GetBool("savegame.mod.unlimitedammo")
    checkUnlimitedBulletsValid()

	if IsToolEnabled("gun-rpg") and GunInInventory("gun-rpg") then

	if inventoryenabled and not reloading then
		reserveammo = GetInt("inventory.ammocount_rocket")
		item = GetString("inventory.guns."..GetInt("inventory.curprimary")..".item")
		if Split(item, "_")[1] == "gun-rpg" then
			guninfo = Split(item, "_")
			if GetBool("inventory.update_guns1") or not initammo then
				ammo = tonumber(guninfo[5])
				rockettype = guninfo[3]
				SetBool("inventory.update_guns1", false)
				initammo = true
			end
		end
	end

	if inventoryenabled then
		magtable2 = {}
		local guninfo = Split(GetString("inventory.guns."..GetInt("inventory.curprimary")..".item"), "_")
		magtable2[1] = {guninfo[3], tonumber(guninfo[5]), tonumber(guninfo[6]), {1,1}}
		for j = 15, 1, -1 do
			for i = 1, 8 do
				if GetString("inventory.backpack."..i.."_"..j..".item") ~= "" then
					local maginfo = Split(GetString("inventory.backpack."..i.."_"..j..".item"), "_")
					local magtype, magammo, magammomax = maginfo[1], maginfo[3], maginfo[4]
					if string.sub(magtype, 1, 6) == "rocket" then
						table.insert(magtable2, {magtype,tonumber(magammo),tonumber(magammomax),{i,j}})
					end
				end
			end
		end
		totalmags = #magtable2
		if nextmagslot > totalmags then
			nextmagslot = 1
		end
	end

	if inventoryenabled and reloading then
		SetBool("inventory.reloading", true)
		GunNet_SetTool("gun-rpg")
	end

	end
	if Split(GetString("inventory.guns."..GetInt("inventory.curprimary")..".item"), "_")[5] == "1" then
		ammo = 1
	else
		ammo = 0
		reload_value = 0
	end
	-- DebugPrint(ammo)
	if GetPlayerTool() == "gun-rpg" then
		if GetPlayerCanUseTool()then
			if GetPlayerGrabShape() == 0 and InputPressed("usetool") then
				if ammo > 0 then
					local rocketname = "PG-7V"
					if rockettype == "rocket1" then rocketname = "OG-7V"
					end
					SetString("inventory.guns."..GetInt("inventory.curprimary")..".item", "gun-rpg_RPG_none_Unloaded_0_1_Rocket")
					SetBool("inventory.update", true)
					ammo = 0

					PlaySound(gunsound)
					ShakeCamera(0.5)

					local exaust_pos = TransformToParentPoint(GetBodyTransform(GetToolBody()),Vec(0.075,-0.4,1.75))
					local exaust_rear = TransformToParentPoint(GetBodyTransform(GetToolBody()),Vec(0.075,-0.4,5))
					local exaust_vec = VecSub(exaust_rear,exaust_pos)

			        ParticleReset()
			        ParticleType("smoke")
			        ParticleTile(0)
			        ParticleSticky(0)
			        ParticleRadius(0.7, 0.2)
			        ParticleAlpha(1, 0)
			        ParticleColor(1, 0.95, 0.9, 1, 0.25, 0.25)
			        ParticleGravity(-0.4)
			        ParticleDrag(0.2)
			        ParticleCollide(0)
			        for i = 1, math.random(12, 20) do
			          	SpawnParticle(exaust_pos, VecAdd(exaust_vec,VecScale(Vec(math.random()-0.5,math.random()-0.5,math.random()-0.5),6)), math.random()*8)
			        end

			        GunNet_MakeHole(exaust_pos, 1) -- (v2) backblast hole on the server

					local player_pos =  GetPlayerCameraTransform()
					local grenade_pos = TransformToParentPoint(GetBodyTransform(GetToolBody()),Vec(0.225,-0.475,-2))
					throw_force = max_throw
					--Generate XML for one banana and spawn it at spawn position
					local xml = "MOD/prefabs/grenade.xml"
					-- (v2) the rocket is spawned and launched on the server (gunnet.lua)
					local fwd = VecSub(TransformToParentPoint(player_pos,Vec(0,0,-1)),player_pos.pos)
					local norm = VecNormalize(fwd)
					local vel = VecScale(norm,120)
					GunNet_SpawnCasing(xml, Transform(grenade_pos,GetBodyTransform(GetToolBody()).rot), vel)
					reload_value = 0
					throw_force = 0.5
					cook_time = 0
				else
					PlaySound(pull_pin_empty_snd, GetPlayerTransform().pos, 0.7)
				end
			end

			for i = 1, totalmags do
				if totalmags > 1 then
					nextmagslot = 2
				end
			end

			if KeybindPressed(Settings.keybinds.player.reload) and totalmags > 0 and ammo == 0 and nextmagslot ~= curmagslot and not reloading then
				primed = false
				PlaySound(reload_raise)
				reloadTimer = reloadTime
				reloading = true

				SetString("inventory.remove", magtable2[nextmagslot][4][1].."_"..magtable2[nextmagslot][4][2])
				rockettype = magtable2[nextmagslot][1]
			end
		end
		--SetString("savegame.mod.rpg_type", rockettype)

		if reloadTimer >= 0 and reloading then
			reloadTimer = reloadTimer - dt
		elseif reloadTimer < 0 and reloading then
			reloading = false
			ammo = 1
			local rocketname = "PG-7V"
			if rockettype == "rocket1" then rocketname = "OG-7V"
			end
			SetString("inventory.guns."..GetInt("inventory.curprimary")..".item", "gun-rpg_RPG_"..rockettype.."_"..rocketname.."_1_1_Rocket")
			SetBool("inventory.update", true)
			SetBool("inventory.reloading", false)
		end

		-- DebugPrint(nextmagslot)
		-- DebugPrint(curmagslot)
		-- DebugPrint(rockettype)
		-- DebugPrint(totalmags)

		if lightTimer > 0 then
			PointLight(TransformToParentPoint(GetBodyTransform(GetToolBody()),Vec(0.2,-0.5,0.2)), 1, 0.75, 0.25, 10)
		end

		shootTimer = shootTimer - dt
		lightTimer = lightTimer - dt

		if InputDown("grab") then
			ironsight = true
			zoomLevel = 15
		else
			ironsight = false
			zoomLevel = 0
		end

		if InputPressed("grab") then
			PlaySound(LoadSound("MOD/snd/Weapons/rpg/reload/RPG_ads_up.ogg"))
		elseif InputReleased("grab") then
			PlaySound(LoadSound("MOD/snd/Weapons/rpg/reload/RPG_ads_down.ogg"))
		end

		local b = GetToolBody()

		x,y,z,rotx,roty,rotz = 0,-0.15,-0.4,0,0,0
		if ironsight then
			x = -0.265
			y = -0.1
			z = -0.3
			rotz = 0
		end

		local x1, y1, z1, rotx1, roty1, rotz1 = 0, 0, 0, 0, 0, 0
		if reloading then
			x1, y1, z1, rotx1, roty1, rotz1 = 0.3, -0.5, 0.4, 20, 15, 10
		end

		offset = ADS(true, zoomLevel, 1, x+x1, y+y1, z+z1, rotx+rotx1, roty+roty1, rotz+rotz1)

		SetToolTransform(offset, 0.5)

		local shapes = GetBodyShapes(b)
		if b ~= body then
			body = b

			--Get default transforms
			t0 = GetShapeLocalTransform(shapes[2])
		end
		t = TransformCopy(t0)

		if reloading then
			if reloadTimer > 0.4 then
				t.pos = VecAdd(t0.pos,Vec(0,-(reloadTimer-0.4),-0.5))
			else
				t.pos = VecAdd(t0.pos,Vec(0,0,-0.5*(reloadTimer)/0.4))
			end
			if reloadTimer < 0.4 and not loadSoundPlayed then
				PlaySound(reload_load_snd)
				loadSoundPlayed = true
			end
		elseif ammo == 0 then
			t.pos = Vec(-600,-600,-600)
		else
			loadSoundPlayed = false
			t.pos = t0.pos
		end
		local currocketshape = 2
		if rockettype == "rocket0" then
			currocketshape = 2
		elseif rockettype == "rocket1" then
			currocketshape = 3
		elseif rockettype == "rocket2" then
			currocketshape = 4
		else
			currocketshape = 5
		end
		if currocketshape == 3 then
			t.pos = VecAdd(t.pos,Vec(0.05,0.05,0))
		end
		for i = 2,#shapes do
			SetShapeLocalTransform(shapes[i], hideTrans)
		end
		SetShapeLocalTransform(shapes[currocketshape], t)

		-- Hands
		clothingtype = GetString("savegame.mod.difficulty")
		local bs = GetBodyShapes(GetToolBody())
		for i = 6, 17 do
			SetShapeLocalTransform(bs[i], hideTrans)
		end
		if clothingtype == "peaceful" then
			hand1 = bs[9]
			arm1 = bs[11]
			hand2 = bs[10]
		elseif clothingtype == "normal" then
			hand1 = bs[12]
			arm1 = bs[14]
			hand2 = bs[13]
		elseif clothingtype == "hardcore" then
			hand1 = bs[15]
			arm1 = bs[17]
			hand2 = bs[16]
		else
			hand1 = bs[6]
			arm1 = bs[8]
			hand2 = bs[7]
		end

		if InputDown("crouch") then
			crouchoffset = math.min(crouchoffset + dt*3, 0.8)
		else
			crouchoffset = math.max(crouchoffset - dt*3, 0)
		end
		local x2, y2, z2, rotx2, roty2, rotz2 = 0.225, -0.4, -0.4, 0, 0, 0
		rocketpos = TransformToParentPoint(t, Vec(0, 0.7, 0))
		if reloading then
			x2, y2, z2, rotx2, roty2, rotz2 = 0+rocketpos[1], -0.1+rocketpos[2], -0.2+rocketpos[3], 0, 0, 0
		end

		local btrans = GetBodyTransform(b)

		h1p1l = INS(true, x2, y2, z2, rotx2, roty2, rotz2).pos

		local pcrx,pcry,pcrz=GetQuatEuler(GetPlayerCameraTransform().rot)
		pitch=pcrx*0.0174532925199
		lookoffset=math.sin(pitch)

		-- h1p1l = Vec(0.225, -0.85, -1.9)
		h1p2l = TransformToLocalPoint(btrans, TransformToParentPoint(GetPlayerTransform(), Vec(-0.6, 0.7-crouchoffset, 0.2-lookoffset)))
		hnd1 = Transform(h1p1l, QuatRotateQuat(QuatLookAt(h1p2l, h1p1l), QuatEuler(0,90,90)))
		a1p1l = VecAdd(h1p1l, TransformToParentVec(hnd1, Vec(0, 1, 0)))
		a1p2l = TransformToLocalPoint(btrans, TransformToParentPoint(GetPlayerTransform(), Vec(-0.45, 1.5-crouchoffset-lookoffset*0.5, 0.5-lookoffset)))
		amt1 = Transform(a1p1l, QuatRotateQuat(QuatLookAt(a1p2l, a1p1l), QuatEuler(0,90,90)))
		SetShapeLocalTransform(hand1, hnd1)
		SetShapeLocalTransform(arm1, amt1)

		h2p1l = Vec(0.2, -0.4, -0.6)
		h2p2l = TransformToLocalPoint(btrans, TransformToParentPoint(GetPlayerTransform(), Vec(0.55, 1.1-crouchoffset-lookoffset, 0.9)))
		hnd2 = Transform(h2p1l, QuatRotateQuat(QuatLookAt(h2p2l, h2p1l), QuatEuler(0,90,90)))
		SetShapeLocalTransform(hand2, hnd2)
	end
end

function client.draw(dt)
	GunNet_DebugParts()
	if GetPlayerTool() == "gun-rpg" and GetPlayerCanUseTool() then

		SetBool("hud.aimdot",false)
		UiAlign("center middle")
		UiTranslate(UiCenter(), UiMiddle());
   		UiTranslate(UiCenter()*.01, 0);

		UiImage("ui/hud/crosshair-launcher.png")
	end
end

function clamp(val, lower, upper)
	if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
	return math.max(lower, math.min(upper, val))
end

function Split(s, delimiter)
	result = {};
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match);
	end
	return result;
end
