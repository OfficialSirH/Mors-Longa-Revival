#version 2
#include "script/include/player.lua"
#include "gunfunctions.lua"
#include "gunperks.lua"
#include "gunstats.lua"
#include "gunnet.lua"



function server.init()
	RegisterTool("gun-ppsh41", "PPSh-41", "MOD/vox/ppsh41.vox", 1)
	-- (v2, Phase 2) tools are enabled per player by inventory.lua (server)
	GunNet_ServerInit()
end

function server.tick(dt)
	-- (v2, Phase 2) tools are enabled per player by inventory.lua (server)
	GunNet_ServerTick(dt)
end

function client.init()
	-- (v2) RegisterTool moved to server.init()
	-- (v2) tool enabled per player in server.init()/server.tick()
	GunName = "PPSH41"
	Cartridge = "762x25"
	WeaponInit()
	------INITIALISE OPTIONS MENU------
	--[[ damageoption = GetInt("savegame.mod.damage")
	if damageoption < 50 then
		damageoption = 100
		SetInt("savegame.mod.damage", 100)
	end ]]
	slots = {}
	for i = 1,8 do
		slots[i] = {}
		for j = 1,2 do
			slots[i][j] = {"", {0, 0}, 1, 1}
		end
	end
	grabbed = {{"", {0, 0}, 1, 1}, 0, 0}
	magtable = {}

	totalmags = GetInt("savegame.mod.totalmags")

	magplace = 1
	magplaceslot = 1
	for i = 1,#slots do
		for j = 1,#slots[i] do
			if slots[i][j][2][1] == 0 and magplace < totalmags+1 then
				local w, h = 1, 1
				local mag = GetString("savegame.mod.mslot"..magplace)
				if mag == "mag0" then
					w, h = 1, 2
				elseif mag == "mag1" then
					w, h = 1, 2
				elseif mag == "mag2" then
					w, h = 2, 2
				elseif mag == "mag3" then
					w, h = 3, 2
				else
					w, h = 1, 2
				end
				placeItem({{mag, {0, 0}, w, h}, 0, 0}, magplaceslot, 2)
				magplace = magplace + 1
				magplaceslot = magplaceslot + w
			else
			end
		end
	end

	--[[ local keybinds = {{"Lean-Left","q"},{"Lean-Right","e"},{"Melee","x"},{"Grenade-Launcher","c"}}
	for i = 1,#keybinds do
		if GetString("savegame.mod."..keybinds[i][1]) == "" then
			SetString("savegame.mod."..keybinds[i][1], keybinds[i][2])
		end
	end
	leanleftKey,leanrightKey,meleeKey,grenadeKey=GetString("savegame.mod.Lean-Left"),GetString("savegame.mod.Lean-Right"),GetString("savegame.mod.Melee"),GetString("savegame.mod.Grenade-Launcher") ]]


	------INITIALISE WEAPON FUNCTIONS------
	damage = 0.12
	gravity = Vec(0, -10, 0)
	hidePos = Vec(0, -200, 0)
	hideTrans = Transform(hidePos,QuatEuler())
	velocity = 450
	drag = 0.1 * 2
	maxMomentum = 1.4
	tracer = false

	recoilVertical = gunstats.ppsh41.recoilVertical
	recoilHorizontal = gunstats.ppsh41.recoilHorizontal
	recoilWander = gunstats.ppsh41.recoilWander

	weaponInaccuracy = 2

	--armor pen
	lvl5armor = 0
	lvl4armor = 0
	lvl3armor = 0.1
	lvl2armor = 0.5
	lvl1armor = 0.7

	inside = {}
	for i = 1,100 do
		inside[i] = {0,0,0,0}
	end
	hoverindex = 0

	gunsound = LoadSound("MOD/snd/Weapons/vector/vector_0.ogg")
	toprail = GetString("savegame.mod.toprail")
	muzzle = GetString("savegame.mod.muzzle")
	stock = GetString("savegame.mod.stock")
	-- realistic = GetBool("savegame.mod.realistic")
	realistic = true
	inventoryenabled = true

	--magazine system
	mslot1 = GetString("savegame.mod.mslot1")
	mslot2 = GetString("savegame.mod.mslot2")
	mslot3 = GetString("savegame.mod.mslot3")
	mslot4 = GetString("savegame.mod.mslot4")
	mslot5 = GetString("savegame.mod.mslot5")
	mslot6 = GetString("savegame.mod.mslot6")
	mslot7 = GetString("savegame.mod.mslot7")
	mslot8 = GetString("savegame.mod.mslot8")
	if inventoryenabled then
		magtable2 = {}
		local guninfo = Split(GetString("inventory.guns."..GetInt("inventory.curprimary")..".item"), "_")
		magtable2[1] = {guninfo[3], tonumber(guninfo[5]), tonumber(guninfo[6]), {1,1}, guninfo[10]}
		for i = 1, 8 do
			for j = 1, 15 do
				if GetString("inventory.backpack."..i.."_"..j..".item") ~= "" then
					local maginfo = Split(GetString("inventory.backpack."..i.."_"..j..".item"), "_")
					local magtype, magammo, magammomax = maginfo[1], maginfo[3], maginfo[4]
					if string.sub(magtype, 1, 3) == "mag" and string.sub(magtype, 6, 16) == "ppsh-762x25" then
						table.insert(magtable2, {magtype,tonumber(magammo),tonumber(magammomax),{i,j}, maginfo[6]})
					end
				end
			end
		end
		totalmags = #magtable2
	else
		if totalmags == 0 then
			mslot1, mslot2 = "mag0", "mag0"
			SetString("savegame.mod.mslot1", "mag0")
			SetString("savegame.mod.mslot2", "mag0")
		totalmags = 2
		end
		magtable2 = {{mslot1,0,0},{mslot2,0,0},{mslot3,0,0},{mslot4,0,0},{mslot5,0,0},{mslot6,0,0},{mslot7,0,0},{mslot8,0,0}}
		for i=1,8 do
			local magslottype = GetString("savegame.mod.mslot"..i)
			if magslottype == "mag0" then
				magtable2[i][2] = 30
				magtable2[i][3] = 30
			elseif magslottype == "mag1" then
				magtable2[i][2] = 40
				magtable2[i][3] = 40
			elseif magslottype == "mag2" then
				magtable2[i][2] = 60
				magtable2[i][3] = 60
			elseif magslottype == "mag3" then
				magtable2[i][2] = 100
				magtable2[i][3] = 100
			else
				magtable2[i][2] = 20
				magtable2[i][3] = 20
			end
		end
	end
	curmagslot = 1
	nextmagslot = 2
	if inventoryenabled then
		local guninfo = Split(GetString("inventory.guns."..GetInt("inventory.curprimary")..".item"), "_")
		mag = guninfo[3]
		reloadFactor = 1
		bullettable = Split(guninfo[10],"-")
	elseif realistic then
		mag = mslot1
		reloadFactor = 1
	else
		mag = GetString("savegame.mod.mag")
		reloadFactor = 1
	end
	--[[ grip = GetString("savegame.mod.grip")
	barrel = GetString("savegame.mod.barrel")
	side = GetString("savegame.mod.side")
	guard = GetString("savegame.mod.guard") ]]
	reloadsound = LoadSound("MOD/snd/ppshreload.ogg")
	reloadsound2 = LoadSound("MOD/snd/ppshreload2.ogg")
	dryfiresound = LoadSound("MOD/snd/Weapons/Shared/dryfire.ogg")
	refillsound = LoadSound("MOD/snd/refill.ogg")
	selectsound = LoadSound("MOD/snd/selectorswitch.ogg")
	casingsound = LoadSound("MOD/snd/Weapons/Shared/Shells/pistol_0.ogg")
	uiselect = LoadSound("MOD/snd/uiselect.ogg")
	adsup = LoadSound("MOD/snd/ads_up_smg.ogg")
	adsdown = LoadSound("MOD/snd/ads_down_smg.ogg")
	inspectsound = LoadSound("MOD/snd/Weapons/Shared/Inspect/weapon_inspect_0.ogg")

	reloadTime = 1.4
	shotDelay = 0.05
	spreadTimer = 1.25
	spreadFactor = 1.5
	accuracyFactor = 1*weaponInaccuracy
	bipodFactor = 1
	laserFactor = 1
	magsize = 35
	if not realistic then
		if mag == "" then
			magsize = 35
			reloadFactor = 1
		elseif mag == "mag1" then
			magsize = 71
			reloadFactor = 1.15
		end
		ammo = magsize
	else
		if not inventoryenabled then
			ammo = magtable2[curmagslot][2]
		else
			ammo = magtable2[1][2]
			bullettable = Split(magtable2[1][5],"-")
		end
	end
	ammoleft = 0
	maxammoleft = 0
	barrellength = 0
	guardlength = 0
	guardheight = 0
	barrelFactorx = 0.8
	barrelFactory = 1
	barrelFactordamage = 1.25
	grenadelauncherammo = 1
	mags = 2
	reloading = false
	ironsight = false
	AnimationInit()
	sideattachment = false
	range = 0
	grenadelauncher = false
	
	unlimitedammo = false
	--spentcasingsoption = GetBool("savegame.mod.spentcasingsoption")
	spentcasingsoption = true

	ProjectileHandlerInit()

	shootTimer = 0
	reloadTimer = 0
	recoilTimer = 0
	recoilTimer2 = 0
	recoilAngle = 0
	recoilFactor = 0
	stockFactor = 0
	muzzleFactor = 0
	muzzlelength = 0
	gripfactorx = 0
	gripfactory = 0
	recoilMax = 0
	rnd1, rnd2, rnd3, rnd4, rnd5, rnd6 = 0, 0, 0, 0, 0, 0
	lightTimer = 0
	clickedmag = false
	animationTimers = {0, 0, 0, 0, 0}
	fovTimer = 0
	animation1Timer = 0
	optionsrotx = -50
	optionsroty = 0
	optionszoom = 0
	optionsx = 0

	magoutTimer = 0
	maginTimer = 0
	meleeTimer = 0
	magcheckTimer = 0
	selecttextTimer = 0
	cocksoundplaying = false
	reloadsound2playing = true
	selectsoundplaying = false
	selectattachments = false
	selectmag = false
	jammed = false
	jamclearTimer = 0
	selectattachmentsTimer = 0
	inspectTimer = 0
	heldrTimer = 0
	scopeTimer = 0

	e = false
	q = false
	selectfire = 1
	selectfire0 = 0
	selectfireTimer = 0
	selectfireText = "Safe"

	sin1 = 0
	cos1 = 1
	sin2 = 0
	cos2 = 1
	swayx = 0
	swayy = 0
	swayx2 = 0
	swayy2 = 0
	swingx = 0
	swingy = 0
	swingx2 = 0
	swingy2 = 0

	pdamage = 3
	dmgsnd = LoadSound("MOD/snd/dmge.ogg")
	DrawHitmark = 0
	parts = FindTriggers("localhitbox",true)
	magdrillFactor = 1
	if GetBool("inventory.magdrills") then
		magdrillFactor = 1.5
	end
end

function FireRound(Type)
	if shootTimer > 0 or ammo == 0 then
		return
	end

	local perk = "762x25"
	local perktable=gunperks[perk][Type]
	local damage = perktable["damage"]
	local pdamage = perktable["pdamage"]
	local explosive = perktable["explosive"]
	local tracer = perktable["tracer"]
	local velocity = perktable["velocity"]
	local maxMomentum = perktable["maxMomentum"]

	local lvl5armor = perktable["lvl5armor"]
	local lvl4armor = perktable["lvl4armor"]
	local lvl3armor = perktable["lvl3armor"]
	local lvl2armor = perktable["lvl2armor"]
	local lvl1armor = perktable["lvl1armor"]

	PlaySound(casingsound,GetPlayerTransform().pos,0.6) ShakeCamera(0.375)

	aimpos, hit, distance = GetAimPos()

	local gt = GetBodyTransform(GetToolBody())
	local fwdpos = TransformToParentPoint(gt, Vec(0.275, -0.5, -100))
	local gunpos = TransformToParentPoint(gt, Vec(0.275, -0.5, -1.2))
	dir = VecNormalize(VecSub(fwdpos, gunpos))

	local ironsightFactor = 1
	if not ironsight then
		ironsightFactor = 2.5
	end

	local maxSpread = InputDown("crouch") and 2 or 3
	if ironsight then maxSpread = maxSpread / 3 end
	local factor = stockFactor*ironsightFactor
	rnd1, rnd2, rnd3, rnd4, rnd5, rnd6 = rnd1+(math.random()-0.5)*factor*recoilWander, rnd2+(math.random()-0.5)*factor*recoilWander, rnd3+(math.random()-0.5)*factor*recoilWander/4, (math.random()-0.5)*factor*recoilHorizontal, (math.random()-0.5)*factor*recoilHorizontal, (math.random()-0.5)*factor*recoilHorizontal/4

	if recoilAngle < recoilMax then
		recoilAngle = recoilAngle + recoilFactor
	end

	projectileHandler.shells[projectileHandler.shellNum] = deepcopy(projectileHandler.defaultShell)
	loadedShell = projectileHandler.shells[projectileHandler.shellNum] 
	loadedShell.armor = {lvl1armor,lvl2armor,lvl3armor,lvl4armor,lvl5armor}
	loadedShell.damage = damage
	loadedShell.pdamage = pdamage
	loadedShell.explosive = explosive
	loadedShell.tracer = tracer
	loadedShell.velocity = velocity
	loadedShell.maxmomentum = maxMomentum
	loadedShell.bloodamount = bloodamount
	loadedShell.active = true
	loadedShell.pos = gunpos
	loadedShell.momentum = maxMomentum
	loadedShell.predictedBulletVelocity = VecScale(dir, velocity)
	projectileHandler.shellNum = (projectileHandler.shellNum%#projectileHandler.shells) + 1

	loadedShell.predictedBulletVelocity = VecAdd(loadedShell.predictedBulletVelocity, Vec((math.random()-0.5)*accuracyFactor*2, (math.random()-0.5)*accuracyFactor*2, (math.random()-0.5)*accuracyFactor*2))
	loadedShell.factor = barrelFactordamage or 1
	loadedShell.active = false -- simulated by gunnet.lua (client visuals + server world)
	GunNet_Fire(loadedShell, muzzle == "muzzle1" and "MOD/snd/Weapons/vector/vector_0.ogg" or "MOD/snd/Weapons/vector/vector_0.ogg", 0.7)

	local barrelend = barrellength + muzzlelength
	SpawnParticle("smoke", TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.25, -0.55, -2.4-barrelend*4/3)), VecAdd(VecScale(dir, 2), GetPlayerVelocity()), 0.2, 0.3)
	ParticleType("plain")
	ParticleTile(5)
	ParticleColor(1, 0.6, 0.4, 1, 0.3, 0.2)
	ParticleRadius(0.2)
	ParticleEmissive(5, 1)
	SpawnParticle(TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.25, -0.55, -2.4-barrelend*4/3)), VecAdd(VecScale(dir, 4), GetPlayerVelocity()), shotDelay/2, 0.3)
	if muzzle == "muzzle1" then
		PlaySound(suppressedgunsound, GetPlayerTransform().pos, 1, false)
	elseif muzzle == "muzzle2" then
		PlaySound(gunsound, GetPlayerTransform().pos, 0.8, false)
	else
		PlaySound(gunsound, GetPlayerTransform().pos, 1, false)
	end

	if not unlimitedammo then
		table.remove(bullettable, ammo)
		ammo = ammo - 1
		if realistic then
			magtable2[curmagslot][2] = ammo
			magtable2[curmagslot][5] = table.concat(bullettable,"-")
			if inventoryenabled then
				name = "Unloaded"
				maxammo = 0
				id = mag
				
				if id == "mag0-ppsh-762x25" then name, maxammo = "PPSh-Mag", 35
				elseif id == "mag1-ppsh-762x25" then name, maxammo = "PPSh-Drum", 71
				end
				local guninfo = Split(GetString("inventory.guns."..GetInt("inventory.curprimary")..".item"), "_")
				guninfo[3] = mag
				guninfo[4] = name
				guninfo[5] = ammo
				guninfo[6] = maxammo
				guninfo[10] = table.concat(bullettable,"-")
				SetString("inventory.guns."..GetInt("inventory.curprimary")..".item", IDBuilder(guninfo))
				SetBool("inventory.update", true)
			end
		end
	end
	if ammo == 0 then
		SpawnParticle("fire", TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.35, -0.55, -1.1)), Vec(0, 0, 0), 0.4, 1)
	end

	--shootTimer = shotDelay
	recoilTimer = shotDelay
	recoilTimer2 = shotDelay*3
	lightTimer = shotDelay/2
	spreadTimer = spreadTimer + 1.25

	if spentcasingsoption then
		SpentCasing()
	end

	-- local jamrate = 1/600
	-- if realistic and math.random() < jamrate and ammo > 0 then
	-- 	jammed = true
	-- 	PlaySound(dryfiresound, GetPlayerTransform().pos, 1, false)
	-- end
	
	local pvel = GetPlayerVelocity()
	local prot = QuatToEuler(GetPlayerTransformWithPitch().rot)
	local ppos = GetPlayerTransform().pos
	local camrot = QuatToEuler(GetPlayerCameraTransform().rot)
	local ppos2 = Transform()
	ppos2.rot = QuatEuler(prot[1], camrot[2], camrot[3])
	ppos2.rot = QuatRotateQuat(ppos2.rot, QuatEuler(recoilFactor*muzzleFactor*gripfactory*barrelFactory*3-rnd4/4, -rnd5/4, -rnd6/4))
	ppos2.pos = ppos
	--SetPlayerTransform(ppos2, true)
	--SetPlayerVelocity(pvel)
	
end
function QuatToEuler(quat)
	local euler={}
	local x,y,z=GetQuatEuler(quat)
	euler[1]=x
	euler[2]=y
	euler[3]=z
	return euler
end

function ShootGrenade()
	if shootTimer > 0 or grenadelauncherammo == 0 then
		return
	end

	aimpos, hit, distance = GetAimPos()

	local gt = GetBodyTransform(GetToolBody())
	local fwdpos = TransformToParentPoint(gt, Vec(0.4, -1, -100))
	local gunpos = TransformToParentPoint(gt, Vec(0.4, -1, -2.2))
	dir = VecSub(fwdpos, gunpos)

	if recoilAngle < recoilMax then
		recoilAngle = recoilAngle + recoilFactor*muzzleFactor
	end

	grenadeHandler.shells[grenadeHandler.shellNum] = deepcopy(grenadeHandler.defaultShell)
	loadedShell = grenadeHandler.shells[grenadeHandler.shellNum]
	loadedShell.active = true
	loadedShell.pos = gunpos
	loadedShell.predictedBulletVelocity = VecScale(dir, 0.35*(300/distance))
	grenadeHandler.shellNum = (grenadeHandler.shellNum%#grenadeHandler.shells) + 1
	loadedShell.active = false -- simulated by gunnet.lua
	GunNet_FireGrenade(loadedShell)

	SpawnParticle("fire", gunpos, Vec(0, 1.0+math.random(1,10)*0.1, 0), 0.3, 0.1)
	PlaySound(grenadelaunchersound, GetPlayerTransform().pos, 0.75, false)

	if not unlimitedammo then
		grenadelauncherammo = grenadelauncherammo - 1
	end
end

function Reload()
	if reloading or totalmags == 1 or unlimitedammo then
		return
	end
	reloading = true
	if grenadelauncher then
		if grenadelauncherammo == 0 then
			reloadTimer = reloadTime - 1
		end
		magoutTimer = 0.6
	else
		reloadTimer = reloadTime
		if realistic and totalmags > 0 then
			if not inventoryenabled then
				magtable2[curmagslot][2] = ammo
			end
			if inventoryenabled then
				curmagslot = nextmagslot
				ammoleft = ammo
				if ammoleft < 0 then ammoleft = 0 bullettable = {} end
				maxammoleft = magtable2[curmagslot][3]
			else
				curmagslot = nextmagslot
			end
		end
		magoutTimer = 0.6
		if mag == "none" and inventoryenabled then
			PlaySound(inspectsound)
		else
			PlaySound(reloadsound, GetPlayerTransform().pos, 0.5, false)
		end
	end
end

function SelectFire()
	selectfire = selectfire + 1
	if selectfire > 2 then
		selectfire = 0
	end
	selectfireTimer = 1

	selectfire0 = selectfire0 + 1
	if selectfire0 > 2 then
		selectfire0 = 0
	end
	selectsoundplaying = false
end

function SpentCasing()
	local gt = GetBodyTransform(GetToolBody())
	local casingpos = TransformToParentPoint(gt, Vec(0.275, -0.3, -1.4))
	local fwdpos = TransformToParentPoint(gt, Vec(0.35+math.random()*4, 4+math.random()*4, 0.5+math.random()*4))
	local direction = VecAdd(GetPlayerVelocity(), VecSub(fwdpos, casingpos))
	GunNet_SpawnCasing("MOD/vox/pistolcasing.xml", Transform(casingpos, QuatEuler(math.random(0, 90), math.random(0, 90), math.random(0, 90))), direction)
end

function Laser(active)
		local gt = GetBodyTransform(GetToolBody())
		local gunpos = TransformToParentPoint(gt, Vec(0.275, -0.5, -1.9))
		local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
		QueryRejectBody(GetToolBody())
		local hit, dist = QueryRaycast(gunpos, fwdpos, 500, 0, true)
		local hitpoint = VecAdd(gunpos, VecScale(fwdpos, dist))

		if active then
			SetShapeEmissiveScale(side1, 1)
			PointLight(hitpoint, 0, 1, 0, 0.2)
			DrawLine(gunpos, hitpoint, 0, 1, 0, 0.2)
			laserFactor = 0.9
		else
			SetShapeEmissiveScale(side1, 0)
			laserFactor = 1
		end
end
function Flashlight(active)
		local gt = GetBodyTransform(GetToolBody())
		local gunpos = TransformToParentPoint(gt, Vec(0.275, -0.5, -1.9))
		local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
		QueryRejectBody(GetToolBody())
		local hit, dist = QueryRaycast(gunpos, fwdpos, 40, 0, true)

		if active then
			SetShapeEmissiveScale(side2, 1)
			PointLight(gunpos, 0.5, 0.5, 0.5, 0.1)
			for i = 1, dist*5 do
				local hitpoint = VecAdd(gunpos, VecScale(fwdpos, i/5))
				local b = 0.1
				PointLight(hitpoint, 1, 1, 1, 0.0001*(i^2))
			end
		else
			SetShapeEmissiveScale(side2, 0)
		end
end
function Rangefinder(active)
		local gt = GetBodyTransform(GetToolBody())
		local gunpos = TransformToParentPoint(gt, Vec(0.175, -0.625, -1.9))
		local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
		QueryRejectBody(GetToolBody())
		local hit, dist = QueryRaycast(gunpos, fwdpos, 500, 0, true)

		if active then
			range = dist
		else
			range = 0
		end
end

function client.tick(dt)
	GunNet_ClientTick(dt)
	WeaponBackgroundTick(dt)

    unlimitedammo = GetBool("savegame.mod.unlimitedammo")
    checkUnlimitedBulletsValid()


	if inventoryenabled and not reloading then
		item = GetString("inventory.guns."..GetInt("inventory.curprimary")..".item")
		if Split(item, "_")[1] == "gun-ppsh41" then
			guninfo = Split(item, "_")
			if GetBool("inventory.update_guns1") or not initammo then
				ammo = tonumber(guninfo[5])
				mag = guninfo[3]
				bullettable = Split(guninfo[10], "-")
				SetBool("inventory.update_guns1", false)
				initammo = true
			end
		end
	end

	if IsToolEnabled("gun-ppsh41") and GunInInventory("gun-ppsh41") then
	
	if inventoryenabled then
		magtable2 = {}
		local guninfo = Split(GetString("inventory.guns."..GetInt("inventory.curprimary")..".item"), "_")
		magtable2[1] = {guninfo[3], tonumber(guninfo[5]), tonumber(guninfo[6]), {1,1}, guninfo[10]}
		for i = 1, 8 do
			for j = 1, 15 do
				if GetString("inventory.backpack."..i.."_"..j..".item") ~= "" then
					local maginfo = Split(GetString("inventory.backpack."..i.."_"..j..".item"), "_")
					local magtype, magammo, magammomax = maginfo[1], maginfo[3], maginfo[4]
					if string.sub(magtype, 1, 3) == "mag" and string.sub(magtype, 6, 16) == "ppsh-762x25" then
						table.insert(magtable2, {magtype,tonumber(magammo),tonumber(magammomax),{i,j}, maginfo[6]})
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
		GunNet_SetTool("gun-ppsh41")
	end

	end

	if GetPlayerTool() == "gun-ppsh41" and GetPlayerVehicle() == 0 then
		SetBool("hud.aimdot", false)
		WeaponTick(dt)
		if shootTimer > 0 or ammo == 0 then
			shootTimer = shootTimer - dt
		end
		------CONTROLS------
		if InputDown("usetool") and not reloading and selectfire == 2 and not selectattachments and not selectmag and selectfireTimer == 0 and GetPlayerGrabShape() == 0 and inspectTimer <= 0 and magcheckTimer == 0 and not jammed and jamclearTimer == 0 then
			if grenadelauncherammo > 0 and grenadelauncher then
				ShootGrenade()
			elseif not grenadelauncher and ammo > 0 and shootTimer <= 0 then
				FireRound(tostring(bullettable[ammo]))
				shootTimer = 0.1
			end
		elseif InputPressed("usetool") and not reloading and selectfire == 1 and not selectattachments and not selectmag and selectfireTimer == 0 and GetPlayerGrabShape() == 0 and inspectTimer <= 0 and magcheckTimer == 0 and not jammed and jamclearTimer == 0 then
			if grenadelauncherammo > 0 and grenadelauncher then
				ShootGrenade()
			elseif not grenadelauncher and ammo > 0 then
				FireRound(tostring(bullettable[ammo]))
			end
		end
		if GetBool("guns.accidental.shoot") and selectfire ~= 0 then
			--DebugPrint("Accidental Shoot")
			FireRound(tostring(bullettable[ammo]))
			SetBool("guns.accidental.shoot", false)
		end

		if InputPressed("usetool") and not reloading and inspectTimer <= 0 and magcheckTimer == 0 and jamclearTimer == 0 then
			spreadTimer = 1.25
			if (ammo == 0 or selectfire == 0 or jammed) and not selectattachments and not selectmag then
				PlaySound(dryfiresound, GetPlayerTransform().pos, 1, false)
			end
		end
		
		if InputDown("grab") and selectfire > 0 and selectfireTimer == 0 and not selectattachments and not selectmag and GetPlayerGrabShape() == 0 and not KeybindDown(Settings.keybinds.player.sprint) and not selectmag and magcheckTimer == 0 and jamclearTimer == 0 then
			if InputPressed("grab") then
				PlaySound(adsup, GetPlayerTransform().pos, 1)
			end
			ironsight = true
			inspectTimer = 0
		end
		if not InputDown("grab") then
			ironsight = false
		end
		if InputReleased("grab")then PlaySound(adsdown, GetPlayerTransform().pos, 1)end
		if selectfire == 0 and selectfireTimer <= 0 then
			ironsight = false
		end

		-- if InputPressed(leanrightKey) then
		-- 	e = not e
		-- q = false
		-- end

		if GetBool("inventory.nvg.enabled") then
			q = true
		end
		if KeybindPressed(Settings.keybinds.player.canted_sight) and not GetBool("inventory.nvg.enabled") then
			q = not q
			if ironsight then PlaySound(inspectsound) end
		end
		e = false

		if InputPressed(meleeKey or "x") and not reloading and not ironsight and shootTimer <= 0 and selectfire > 0 and stock ~= "removed" and not KeybindDown(Settings.keybinds.player.sprint) then
			meleeTimer = 0.8
			inspectTimer = 0
		end

		if KeybindPressed(Settings.keybinds.player.select_fire) and not reloading and not selectattachments and not selectmag and magcheckTimer == 0 and jamclearTimer == 0 then
			SelectFire()
			inspectTimer = 0
			selecttextTimer = 3
		end
		if selecttextTimer > 0 then
			selecttextTimer = selecttextTimer - dt
		end
		if selecttextTimer < 0 then
			selecttextTimer = 0
		end

		if InputDown("y") and not reloading and selectfire > 0 and selectfireTimer <= 0 and not KeybindDown(Settings.keybinds.player.sprint) and magcheckTimer == 0 and jamclearTimer == 0 or GetBool("level.optionstriggered") and not realistic then
			if KeybindPressed(Settings.keybinds.player.gun_attachment) and not GetBool("level.optionstriggered") then
				PlaySound(inspectsound)
				selectattachmentsTimer = 0.5
			end
			gunWantsInteractive = true
			selectattachments = true
			ironsight = false
			inspectTimer = 0
		end
		if InputReleased("y") and not reloading and selectfire > 0 and selectfireTimer <= 0 and not KeybindDown(Settings.keybinds.player.sprint) and not realistic then
			selectattachments = false
			selectattachmentsTimer = 0.25
		end

		if KeybindPressed(Settings.keybinds.player.side_toggle) and side ~= "" then
			sideattachment = not sideattachment
			PlaySound(uiselect, GetPlayerTransform().pos, 0.75)
		end
		Laser(sideattachment and side == "side1")
		Flashlight(sideattachment and side == "side2")
		Rangefinder(sideattachment and side == "side3")

		if KeybindPressed(Settings.keybinds.player.mag_check) and realistic and not reloading and selectfire > 0 and selectfireTimer <= 0 and not KeybindDown(Settings.keybinds.player.sprint) and magcheckTimer == 0 and jamclearTimer == 0 and not inventoryenabled then
			magcheckTimer = 4
			PlaySound(reloadsound, GetPlayerTransform().pos, 0.5)
			inspectTimer = 0
		end
		if magcheckTimer > 0 then
			magcheckTimer = magcheckTimer - dt*1.5
			ironsight = false
		end
		if magcheckTimer < 0 then
			magcheckTimer = 0
			PlaySound(reloadsound2, GetPlayerTransform().pos, 0.5)
		end

		if KeybindDown(Settings.keybinds.player.reload) and not reloading and selectfire > 0 and selectfireTimer <= 0 and not KeybindDown(Settings.keybinds.player.sprint) and magcheckTimer == 0 and not jammed and jamclearTimer == 0 then heldrTimer = heldrTimer + dt end
		if KeybindDown(Settings.keybinds.player.reload) and realistic and not reloading and selectfire > 0 and selectfireTimer <= 0 and not KeybindDown(Settings.keybinds.player.sprint) and magcheckTimer == 0 and not jammed and jamclearTimer == 0 and heldrTimer > 0.2 then
			gunWantsInteractive = true
			selectmag = true
			ironsight = false
		else
			selectmag = false
		end
		if InputReleased("r") and heldrTimer <= 0.2 and realistic and not reloading and selectfire > 0 and selectfireTimer <= 0 and magcheckTimer == 0 and not jammed and jamclearTimer == 0 then
			for i = 1, totalmags do
				if magtable2[i][2] > magtable2[nextmagslot][2] and i ~= curmagslot then
					nextmagslot = i
				end
			end
			inspectTimer = 0
			if not (realistic and inventoryenabled and curmagslot == nextmagslot) then
				Reload()
			end
		end
		if InputReleased("r") then heldrTimer = 0 end

		if KeybindPressed(Settings.keybinds.player.clear_jam) and not reloading and selectfire > 0 and selectfireTimer <= 0 and not KeybindDown(Settings.keybinds.player.sprint) and magcheckTimer == 0 and jammed and jamclearTimer == 0 then
			jamclearTimer = 2
		end
		if jamclearTimer > 0 then
			jamclearTimer = jamclearTimer - dt
			ironsight = false
		end
		if jamclearTimer < 0 then
			jamclearTimer = 0
			jammed = false
			cocksoundplaying = false
		end

		if KeybindDown(Settings.keybinds.player.sprint) then
			ironsight = false
			selectattachments = false
			selectmag = false
			inspectTimer = 0
		end

		--[[ if grip == "grenade_launcher" then
			if InputPressed(grenadeKey) and not reloading then
				grenadelauncher = not grenadelauncher
			end
		else
			grenadelauncher = false
		end ]]

		if KeybindPressed(Settings.keybinds.player.gun_inspect) and not reloading and not KeybindDown(Settings.keybinds.player.sprint) and selectfireTimer <= 0 and not ironsight and selectfire > 0 and not selectattachments and not selectmag and magcheckTimer == 0 and magcheckTimer == 0 and jamclearTimer == 0 then
			if inspectTimer <= 0 then
				inspectTimer = 4
				ironsight = false
			else
				inspectTimer = 0
			end
		end

		if selectfire == 2 then
			selectfireText = "Full"
		elseif selectfire == 1 then
			selectfireText = "Semi"
		else
			selectfireText = "Safe"
		end

		if shootTimer <= 0 then
			recoverySpeed = 0.1
			if math.abs(recoilAngle) < 0.01 then
				recoilAngle = 0
			elseif recoilAngle > 0 then
				recoilAngle = recoilAngle - (recoilAngle+0.05)*recoverySpeed
			elseif recoilAngle < 0 then
				recoilAngle = recoilAngle - (rnd1-0.05)*recoverySpeed
			end
			if math.abs(rnd1) < 0.05 then
				rnd1 = 0
			elseif rnd1 > 0 then
				rnd1 = rnd1 - (rnd1+0.25)*recoverySpeed
			elseif rnd1 < 0 then
				rnd1 = rnd1 - (rnd1-0.25)*recoverySpeed
			end
			if math.abs(rnd2) < 0.05 then
				rnd2 = 0
			elseif rnd2 > 0 then
				rnd2 = rnd2 - (rnd2+0.25)*recoverySpeed
			elseif rnd2 < 0 then
				rnd2 = rnd2 - (rnd2-0.25)*recoverySpeed
			end
			if math.abs(rnd3) < 0.05 then
				rnd3 = 0
			elseif rnd3 > 0 then
				rnd3 = rnd3 - (rnd3+0.25)*recoverySpeed
			elseif rnd3 < 0 then
				rnd3 = rnd3 - (rnd3-0.25)*recoverySpeed
			end
			if math.abs(rnd4) < 0.05 then
				rnd4 = 0
			elseif rnd4 > 0 then
				rnd4 = rnd4 - (rnd4+0.25)*recoverySpeed
			elseif rnd4 < 0 then
				rnd4 = rnd4 - (rnd4-0.25)*recoverySpeed
			end
			if math.abs(rnd5) < 0.05 then
				rnd5 = 0
			elseif rnd5 > 0 then
				rnd5 = rnd5 - (rnd5+0.25)*recoverySpeed
			elseif rnd5 < 0 then
				rnd5 = rnd5 - (rnd5-0.25)*recoverySpeed
			end
			if math.abs(rnd6) < 0.05 then
				rnd6 = 0
			elseif rnd6 > 0 then
				rnd6 = rnd6 - (rnd6+0.25)*recoverySpeed
			elseif rnd6 < 0 then
				rnd6 = rnd6 - (rnd6-0.25)*recoverySpeed
			end
		end

		if ironsight then
			recoilFactor = recoilVertical*stockFactor
		else
			recoilFactor = recoilVertical*stockFactor*1.75
		end

		if ironsight then
			recoilMax = gunstats.ppsh41.recoilMax*muzzleFactor*stockFactor
		else
			recoilMax = gunstats.ppsh41.recoilMax*1.5*muzzleFactor*stockFactor
		end

		if GetBool("inventory.magdrills") then
			magdrillFactor = 1.5
		else
			magdrillFactor = 1
		end

		if toprail == "scope" and not (q or e) then
			spreadFactor = 1
		elseif toprail == "holo" and not (q or e) then
			spreadFactor = 1.75
		else
			spreadFactor = 2
		end

		toprail = GetString("savegame.mod.toprail")
		muzzle = GetString("savegame.mod.muzzle")
		stock = GetString("savegame.mod.stock")
		if realistic or inventoryenabled then
			if maginTimer > 0 then
				if totalmags == 0 then
					mag = "none"
					maginTimer = 0
				elseif not inventoryenabled then
					mag = magtable2[curmagslot][1]
				end
			end
		else
			if maginTimer > 0 then
				mag = GetString("savegame.mod.mag")
			end
		end
		if GetBool("level.optionstriggered") then
			if realistic then
				mag = magtable[1] or ""
			else
				mag = GetString("savegame.mod.mag")
			end
		end
		--[[ grip = GetString("savegame.mod.grip")
		barrel = GetString("savegame.mod.barrel")
		side = GetString("savegame.mod.side")
		guard = GetString("savegame.mod.guard") ]]

		local b = GetToolBody()
		if b ~= 0 then
			local magoffset = Vec(0, 0, 0)
			local grenadeoffset = Vec(-0.025, 0.025, 0)
			local boltoffset = Vec(0, 0.01, 0)
			local selectoroffset = Vec(-0.025, 0.005, 0)
			local sightoffset = Vec(0, 0, -0.005)
			local suppressoroffset = Transform()
			local scopeoffset = Transform()
			local holooffset = Transform()
			local holooffset2 = Transform()
			local railoffset = Transform()
			local magtimer = magoutTimer + maginTimer
			offset = Transform(Vec(0, heightOffset, 0))
			local adsFOV, adsTime = 0, 0
			local defaultTrans = Transform(Vec(0.25, 0.15, 0.25), QuatEuler(0, 0, 0))

			x,y,z,rotx,roty,rotz = -0.2,0,0,0,0,0
			if ironsight then
			if grenadelauncher then
				x = 0
				y = 0.45
				z = 0
				rotz = 0
			elseif q then
				x = 0.7
				y = -0.05
				z = 0.2
				rotz = 30
			elseif e then
				x = -0.3
				y = 0.2
				z = 0
				rotz = -15
			else
				if toprail == "holo" then
					x = 0.275
					y = 0.2625
					z = 0.2
					rotz = 0
				elseif toprail == "" then
					x = 0.275
					y = 0.35
					z = 0
					rotz = 0
				elseif toprail == "scope" then
					x = 0.275
					y = 0.25
					z = 0
					rotz = 0
				elseif toprail == "sight3" then
					x = 0.275
					y = 0.2175
					z = 0
					rotz = 0
				end
			end

			if reloading then
				adsFOV, adsTime = 0, 0.15
			elseif not (q or e or grenadelauncher) then
				if toprail == "" then
					adsFOV, adsTime = 10, 0.15
				elseif toprail == "scope" then
					adsFOV, adsTime = 80, 0.25
				elseif toprail == "holo" then
					adsFOV, adsTime = 20, 0.1
				elseif toprail == "sight3" then
					adsFOV, adsTime = 10, 0.075
				end
			elseif grenadelauncher then
				adsFOV, adsTime = 10, 0.15
			else
				adsFOV, adsTime = 0, 0.15
			end
			end

			-- offset = ADS(ironsight, adsFOV, adsTime, -x, y, z, rotz)

			local injuredarms = false
			for i = 1, 6 do
				if GetTagValue(parts[i], "localhitbox") == "LARM" or GetTagValue(parts[i], "localhitbox") == "RARM" then
					if tonumber(GetTagValue(parts[i], "CurrentHealth")) == 0 or HasTag(parts[i], "Fracture") then
						injuredarms = true
					end
				end
			end
			if injuredarms then
				swayx2 = math.sin(2.1*GetTime())*0.75
				swayy2 = math.sin(1.3*GetTime())*0.5
			else
				swayx2 = 0
				swayy2 = 0
			end

			local limit = 15
			swingx = math.clamp(swingx + InputValue("mousedx")/30, -limit, limit)
			swingy = math.clamp(swingy + InputValue("mousedy")/30, -limit, limit)
			swingx, swingy = swingx*0.35, swingy*0.35
			if not (selectattachments or GetBool("level.optionstriggered") or selectmag) and not ironsight then swingx2 = math.clamp(swingx2 + InputValue("mousedx")/40, -limit, limit) end
			if swingx2 > 0 and ironsight then
				swingx2 = swingx2 - swingx2*0.32
			elseif swingx2 < 0 and ironsight then
				swingx2 = swingx2 - swingx2*0.32
			end
			if not (selectattachments or GetBool("level.optionstriggered") or selectmag) and not ironsight then swingy2 = math.clamp(swingy2 + InputValue("mousedy")/40, -limit, limit) end
			if swingy2 > 0 and ironsight then
				swingy2 = swingy2 - swingy2*0.32
			elseif swingy2 < 0 and ironsight then
				swingy2 = swingy2 - swingy2*0.32
			end

			if ironsight then
				btrans = GetBodyTransform(b)
				pvel = GetPlayerVelocity()
				if toprail == "holo" then
					local gt = GetBodyTransform(GetToolBody())
					local sightcenter = Vec(0.275, -0.325, -1.1)
					local gunpos = TransformToParentPoint(gt, sightcenter)
					local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
					QueryRejectBody(GetToolBody())
					local hit, dist = QueryRaycast(gunpos, fwdpos, 500, 0, true)
					local hitpoint = VecAdd(gunpos, VecScale(fwdpos, dist))
					local camtrans = GetPlayerCameraTransform()
					local sightdist = VecLength(VecSub(camtrans.pos, gunpos))
					local holopoint = VecAdd(VecAdd(camtrans.pos, VecScale(VecNormalize(VecSub(camtrans.pos, hitpoint)), -sightdist)), VecScale(GetPlayerVelocity(), 0.02))

					local holotrans = Transform(holopoint, QuatLookAt(camtrans.pos, hitpoint))

					if VecLength(VecSub(TransformToParentPoint(gt, sightcenter), holopoint)) < 0.1 then
						reticle1 = LoadSprite("MOD/img/reticle1.png")
						DrawSprite(reticle1, holotrans, 0.025, 0.025, 1, 1, 1, 1, true)
					end
				end
				if toprail == "sight3" then
					local gt = GetBodyTransform(GetToolBody())
					local sightcenter = Vec(0.275, -0.2125, -1.25)
					local gunpos = TransformToParentPoint(gt, sightcenter)
					local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
					QueryRejectBody(GetToolBody())
					local hit, dist = QueryRaycast(gunpos, fwdpos, 500, 0, true)
					local hitpoint = VecAdd(gunpos, VecScale(fwdpos, dist))

					local camtrans = GetPlayerCameraTransform()
					local sightdist = VecLength(VecSub(camtrans.pos, gunpos))

					local holopoint = VecAdd(VecAdd(camtrans.pos, VecScale(VecNormalize(VecSub(camtrans.pos, hitpoint)), -sightdist)), VecScale(GetPlayerVelocity(), 0.02))

					local holotrans = Transform(holopoint, QuatLookAt(camtrans.pos, hitpoint))

					if VecLength(VecSub(TransformToParentPoint(gt, sightcenter), holopoint)) < 0.1 then
						reticle4 = LoadSprite("MOD/img/reticle4.png")
						DrawSprite(reticle4, holotrans, 0.2, 0.15, 1, 1, 1, 1, true)
					end
				end
				if toprail == "scope" then
					scopepoint = TransformToParentTransform(btrans, Transform(Vec(0.2745, -0.252, -1.05), QuatEuler(0, 180, 0)))
					reticle2 = LoadSprite("MOD/img/reticle2.png")
					DrawSprite(reticle2, scopepoint, 0.075, 0.075, 1, 1, 1, 1, true)
				end
			end

			local speed = math.clamp(VecLength(GetPlayerVelocity()), 0.8, 10)
			sin1 = math.clamp(sin1 + cos1*dt*speed*2.8, -1.2, 1.2)
			cos1 = math.clamp(cos1 - sin1*dt*speed*2.8, -1.2, 1.2)
			sin2 = math.clamp(sin2 + cos2*dt*speed*0.7, -1.2, 1.2)
			cos2 = math.clamp(cos2 - sin2*dt*speed*0.7, -1.2, 1.2)
			swayy = sin1/5
			swayx = sin2/10
			if KeybindDown(Settings.keybinds.player.sprint) then
				swayy = sin1/3
				swayx = sin2/2
			end
			-- offset.rot = QuatRotateQuat(offset.rot, QuatEuler(swayy*speed, swayx*speed, 0))
			-- offset.rot = QuatRotateQuat(offset.rot, QuatEuler(math.sin(2.1*GetTime())/9,  math.sin(1.3*GetTime())/6, 0))
			-- offset.pos = VecAdd(offset.pos, Vec(math.sin(1.1*GetTime())/360,  math.sin(0.7*GetTime())/240, 0))

			if meleeTimer > 0 then
				if meleeTimer > 0.6 then
					offset.rot = QuatEuler(0, (0.8-meleeTimer)*800, (0.8-meleeTimer)*50)
					offset.pos = VecAdd(offset.pos, Vec((0.8-meleeTimer)*1, (0.8-meleeTimer)*-1, (0.8-meleeTimer)*-7.5))
				elseif meleeTimer > 0.4 then
					offset.rot = QuatEuler(0, 160, 0)
					offset.pos = VecAdd(offset.pos, Vec(0.4+(meleeTimer-0.4)*1.5, 0, -2.5+(meleeTimer-0.4)*-1.5))
					stockPos = TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0, -0.5, -0.65))
					if meleeTimer > 0.55 then
						if GetShapeMaterialAtPosition(shape, stockPos) == "glass" and math.random() > 0.8 then
							GunNet_MakeHole(stockPos, 1)
						else
							GunNet_MakeHole(stockPos, 0.3)
						end
					end
				else
					offset.rot = QuatEuler(0, meleeTimer*400, meleeTimer*100)
					offset.pos = VecAdd(offset.pos, Vec(0, 0, meleeTimer*-5))
				end

				meleeTimer = meleeTimer - dt
			end

			if selectfireTimer > 0 then
				selectfireTimer = selectfireTimer - dt
			end

			if inspectTimer > 0 then
				inspectTimer = inspectTimer - dt
			end

			if recoilTimer2 > 0 then
				recoilTimer2 = recoilTimer2 - dt
			end
			if recoilTimer > 0 then
				recoilTimer = recoilTimer - dt
			end
			if shootTimer > 0 then
				boltoffset = Vec(0, 0.01, (shotDelay-shootTimer)*-4)
			end
			local rx, ry, rz, rr1, rr2, rr3 = (rnd2+rnd5)/400, (recoilAngle/-250)-(rnd1+rnd4)/400-recoilTimer2/10, recoilAngle/50+recoilTimer2/2+recoilAngle/125, recoilAngle+(rnd1+rnd4)/4+recoilTimer2*2, (rnd2+rnd5)/4, 0
			-- RECoffset = REC(true, rx, ry, rz, rr1, rr2, rr3)
			-- offset.pos = VecAdd(offset.pos, RECoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, RECoffset.rot)

			if jammed and jamclearTimer < 1 and jamclearTimer > 0.7 then
				boltoffset = Vec(0, 0.01, 1-jamclearTimer)
				if not cocksoundplaying then
					cocksoundplaying = true
					PlaySound(cocksound2, GetPlayerTransform().pos, 0.5)
				end
			end

			if lightTimer > 0 then
				PointLight(toolPos, 1, 0.75, 0.25, (lightTimer/shotDelay)*lightFactor)
				lightTimer = lightTimer - dt
			end

			if magoutTimer < 0 then
				if inventoryenabled then
					name = "Unloaded"
					maxammo = 0
					id = mag
					if id == "mag0-ppsh-762x25" then name, maxammo = "PPSh-Mag", 35
					elseif id == "mag1-ppsh-762x25" then name, maxammo = "PPSh-Drum", 71
					end
					if mag ~= "none" then
						SetString("inventory.pickup", mag.."_"..name.."_"..ammoleft.."_"..magtable2[1][3].."_7.62x25_"..table.concat(bullettable,"-"))
					end
					SetString("inventory.remove", magtable2[nextmagslot][4][1].."_"..magtable2[nextmagslot][4][2])
					nextammo = magtable2[nextmagslot][2]
					nextbullet = magtable2[nextmagslot][5]
					mag = magtable2[nextmagslot][1]
				end

				maginTimer = 0.6
				magoutTimer = 0
				reloadsound2playing = false
			end
			if maginTimer < 0 then
				maginTimer = 0
				if grenadelauncher then
					PlaySound(uiselect, GetPlayerTransform().pos, 1)
				end
			end
			if maginTimer < 0.3 and not reloadsound2playing and not grenadelauncher then
					PlaySound(reloadsound2, GetPlayerTransform().pos, 0.5, false)
					reloadsound2playing = true
			end
			if magoutTimer > 0 then
				if grenadelauncher then
					grenadeoffset = Vec(-0.025, -magoutTimer*3+0.025, -0.6)
				else
					magoffset = Vec(0, -(0.6-magoutTimer)*4, 0)
				end
				magoutTimer = magoutTimer - dt/reloadFactor*magdrillFactor
			end
			if maginTimer > 0 then
				if grenadelauncher then
					grenadeoffset = Vec(-0.025, 0.025, -maginTimer)
				else
					magoffset = Vec(0, -maginTimer*4, 0)
				end
				maginTimer = maginTimer - dt/reloadFactor*magdrillFactor
			end
			if magcheckTimer > 3.4 then
				magoffset = Vec(0, -(4-magcheckTimer)*2, 0)
			elseif magcheckTimer > 2.8 then
				magoffset = Vec(-(3.4-magcheckTimer)*0.5, (3.4-magcheckTimer)*2-1.2, 0)
			elseif magcheckTimer > 1.2 then
				magoffset = Vec(-0.3, 0, 0)
			elseif magcheckTimer > 0.6 then
				magoffset = Vec(-magcheckTimer*0.5+0.3, magcheckTimer*2-1.2-1.2, 0)
			elseif magcheckTimer > 0 then
				magoffset = Vec(0, -magcheckTimer*2, 0)
			end
			if not grenadelauncher or (grenadelauncherammo == 0 and not reloading) then
				grenadeoffset = hidePos
			end

			local x1, y1, z1, rotx1, roty1, rotz1 = 0, 0, 0, 0, 0, 0
			if reloading then
			if grenadelauncher then
					x1, y1, z1, rotx1, roty1, rotz1 = 0.1, -0.2, 0, 10, 5, -10
			elseif ironsight then
				if q then
					if magoutTimer > 0.4 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.075, 0.1, 0, 0, 0, -10
					elseif magoutTimer > 0 or magcheckTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.1, 0.2, 0, -5, 0, -10
					elseif maginTimer > 0 or reloadTimer > 0.8 then
						x1, y1, z1, rotx1, roty1, rotz1 = -0.1, 0, -0.05, 0, -5, -5
					end
				elseif e then
					if magoutTimer > 0 or magcheckTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.1, -0.1, 0, 5, -10, -10
					elseif maginTimer > 0 or reloadTimer > 0.6 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.15, -0.3, 0.1, 15, 15, -10
					end
				else
					if magoutTimer > 0 or magcheckTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.3, -0.05, 0, 0, 0, -20
					elseif maginTimer > 0 or reloadTimer > 0.4 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.4, 0.05, 0, 0, 0, -25
					else
						x1, y1, z1, rotx1, roty1, rotz1 = -0.05, 0, 0, 0, 0, 0
					end
				end
			else
				if magoutTimer > 0 or magcheckTimer > 0 then
					x1, y1, z1, rotx1, roty1, rotz1 = 0.15, -0.05, 0, 5, -5, -20
				elseif maginTimer > 0 or reloadTimer > 0.6 then
					x1, y1, z1, rotx1, roty1, rotz1 = 0.35, -0.05, 0.1, 10, 10, -25
				end
			end
			end

			-- RELoffset = REL(reloading or magcheckTimer > 0, x1, y1, z1, rotx1, roty1, rotz1)
			-- offset.pos = VecAdd(offset.pos, RELoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, RELoffset.rot)

			ATToffset = {0,0,0,0,0,0}
			if not GetBool("level.optionstriggered") then
			-- if selectattachmentsTimer > 0 and selectattachments then
			-- 	local t1 = (0.5 - selectattachmentsTimer)/0.5
			-- 	offset.pos = VecAdd(offset.pos, Vec(1*t1, 0, -0.8*t1*180/GetInt("options.gfx.fov")))
			-- 	offset.rot = QuatRotateQuat(offset.rot, QuatEuler(10*t1, 75*t1, -10*t1))
			-- elseif selectattachmentsTimer > 0 and not selectattachments then
			-- 	local t2 = selectattachmentsTimer/0.25
			-- 	offset.pos = VecAdd(offset.pos, Vec(1*t2, 0, -0.8*t2*180/GetInt("options.gfx.fov")))
			-- 	offset.rot = QuatRotateQuat(offset.rot, QuatEuler(10*t2, 75*t2, -10*t2))
			-- elseif selectattachments then
			-- 	offset.pos = VecAdd(offset.pos, Vec(1, 0, -0.8*180/GetInt("options.gfx.fov")))
			-- 	offset.rot = QuatRotateQuat(offset.rot, QuatEuler(10, 75, -10))
			-- end
			if selectattachments then ATToffset = {1,0,-0.8*180/GetInt("options.gfx.fov"),10,75,-10} end
			end
			if GetBool("level.optionstriggered") then
				offset.pos = VecAdd(offset.pos, Vec(optionsx+0.2+math.cos(math.pi*optionsrotx/180), 0.2, -1.5-math.sin(math.pi*optionsrotx/180)+optionszoom))
				offset.rot = QuatRotateQuat(offset.rot, QuatEuler(0, 100+optionsrotx, optionsroty))
				
				if InputValue("mousewheel") > 0 and optionszoom < 1 then
					optionszoom = optionszoom + 0.05
				elseif InputValue("mousewheel") < 0 and optionszoom > -2 then
					optionszoom = optionszoom - 0.05
				end
				if InputDown("grab") and grabbed[1][1] == "" then
					optionsrotx = optionsrotx + InputValue("mousedx")/2
				end
				if InputDown("grab") and grabbed[1][1] == "" then
					optionsroty = optionsroty + InputValue("mousedy")/20
				end
				if optionsroty > 0.1 then optionsroty = optionsroty - optionsroty*0.05 - 0.05 end
				if optionsroty < 0.1 then optionsroty = optionsroty - optionsroty*0.05 + 0.05 end
				if InputDown("usetool") and grabbed[1][1] == "" then
					optionsx = optionsx + InputValue("mousedx")/400
				end
			end

			if selectattachmentsTimer > 0 then
				selectattachmentsTimer = selectattachmentsTimer*0.9 - dt/20
			elseif selectattachmentsTimer < 0 then
				selectattachmentsTimer = 0
			end

			local x2, y2, z2, rotx2, roty2, rotz2 = 0, 0, 0, 0, 0, 0
			if inspectTimer > 2.5 then
				x2, y2, z2, rotx2, roty2, rotz2 = 0.45, -0.15, 0.2, 15, 30, 10
			elseif inspectTimer > 1.25 then
				x2, y2, z2, rotx2, roty2, rotz2 = 0.3, 0.05, 0.2, 5, 15, -10
			elseif inspectTimer > 0 then
				x2, y2, z2, rotx2, roty2, rotz2 = -0.6, -0.5, 0.25, 5, -5, 60
			-- elseif jamclearTimer > 0 then
			-- 	x2, y2, z2, rotx2, roty2, rotz2 = -0.1, -0.4, 0, 30, -40, 15
			end

			-- INSoffset = INS(inspectTimer > 0 or jamclearTimer > 0, x2, y2, z2, rotx2, roty2, rotz2)
			-- offset.pos = VecAdd(offset.pos, INSoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, INSoffset.rot)

			local x3, y3, z3, rotx3, roty3, rotz3 = 0, 0, 0, 0, 0, 0
			if selectfire == 0 and selectfireTimer <= 0 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0.2, 0.2, -0.2, -20, 60, 0
			elseif KeybindDown(Settings.keybinds.player.sprint) and selectfireTimer <= 0 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0.15, -0.9, 0.5, 50, 0, -10
			elseif ironsight and selectfireTimer > 0  then
				x3, y3, z3, rotx3, roty3, rotz3 = 0.15, 0, 0, 0, 5, -10
			elseif selectfireTimer > 0 and selectfire ~= 1 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0.4, 0, -0.25, 0, 5, -20
			elseif selectfireTimer > 0 and selectfire == 1 then
				x3, y3, z3, rotx3, roty3, rotz3 = -0.3, 0, 0.25, 0, 5, 20
			else
				x3, y3, z3, rotx3, roty3, rotz3 = 0, 0, 0, 0, 0, 0
			end

			-- if not GetBool("level.optionstriggered") then SELoffset = SEL((selectfireTimer > 0 or selectfire == 0 or KeybindDown(Settings.keybinds.player.sprint)) and not reloading, x3, y3, z3, rotx3, roty3, rotz3)
			-- offset.pos = VecAdd(offset.pos, SELoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, SELoffset.rot) end

			offset = ADS(true, adsFOV, adsTime, -x+x1+x2+x3+ATToffset[1]-swingx2/200+swayx*speed/200+swayx2/200, y+y1+y2+y3-math.abs(swingx)/200-swayy*speed/200+ATToffset[2]+swingy2/100+swayy2/200, z+z1+z2+z3+ATToffset[3], rotx+rotx1+rotx2+rotx3+swingy-swingy2+swayy*speed+swayy2+ATToffset[4], roty+roty1+roty2+roty3+swingx-swingx2+swayx*speed+swayx2+ATToffset[5], rotz+rotz1+rotz2+rotz3-swingx+ATToffset[6])

			RECoffset = REC(true, rx, ry, rz, rr1, rr2, rr3)
			offset.pos = VecAdd(offset.pos, RECoffset.pos)
			offset.rot = QuatRotateQuat(offset.rot, RECoffset.rot)

			clothingtype = GetString("savegame.mod.difficulty")
			local bs = GetBodyShapes(GetToolBody())
			for i = 10, 21 do
				SetShapeLocalTransform(bs[i], hideTrans)
			end
			if clothingtype == "peaceful" then
				hand1 = bs[13]
				arm1 = bs[15]
				hand2 = bs[14]
			elseif clothingtype == "normal" then
				hand1 = bs[16]
				arm1 = bs[18]
				hand2 = bs[17]
			elseif clothingtype == "hardcore" then
				hand1 = bs[19]
				arm1 = bs[21]
				hand2 = bs[20]
			else
				hand1 = bs[10]
				arm1 = bs[12]
				hand2 = bs[11]
			end

			SetToolTransform(offset, 0.2)
			toolTrans = GetBodyTransform(b)
			toolPos = TransformToParentPoint(toolTrans, Vec(0.275, -0.6, -2.6))

			if body ~= b then
				body = b
				local shapes = GetBodyShapes(b)
				mag0 = shapes[2]
				bolt = shapes[3]
				selector = shapes[9]
				rail = shapes[4]
				stock1 = shapes[5]
				mag1 = shapes[6]
				barrel0 = shapes[7]
				guard0 = shapes[8]
				magTrans = GetShapeLocalTransform(mag0)
				boltTrans = GetShapeLocalTransform(bolt)
				selectorTrans = GetShapeLocalTransform(selector)
				railTrans = GetShapeLocalTransform(rail)
				stock1Trans = GetShapeLocalTransform(stock1)
				barrelTrans0 = GetShapeLocalTransform(barrel0)
				guardTrans0 = GetShapeLocalTransform(guard0)
			end

			mt = TransformCopy(magTrans)
			mt.pos = VecAdd(mt.pos, magoffset)

			bt = TransformCopy(boltTrans)
			bt.pos = VecAdd(bt.pos, boltoffset)

			st = TransformCopy(selectorTrans)
			st.pos = VecAdd(st.pos, selectoroffset)
			st2 = TransformCopy(selectorTrans2)
			st2.pos = VecAdd(st2.pos, selectoroffset)

			spt = TransformCopy(suppressorTrans)
			spt.pos = VecAdd(spt.pos, suppressoroffset)

			sct = TransformCopy(scopeTrans)

			ht = TransformCopy(holoTrans)
			ht2 = TransformCopy(holoTrans2)

			rdt = TransformCopy(reddotTrans)
			rdt2 = TransformCopy(reddotTrans)

			rt = TransformCopy(railTrans)
			rt.pos = VecAdd(rt.pos, railoffset)

			stt = TransformCopy(stock1Trans)
			stt.pos = VecAdd(stt.pos, stock1offset)

			mbt = TransformCopy(muzzlebreakTrans)
			mbt.pos = VecAdd(mbt.pos, muzzlebreakoffset)
			mbt2 = TransformCopy(muzzlebreakTrans2)
			mbt2.pos = VecAdd(mbt2.pos, muzzlebreakoffset2)

			gt1 = TransformCopy(gripTrans)
			gt1.pos = VecAdd(gt1.pos, gripoffset)
			gt1_2 = TransformCopy(gripTrans)
			gt1_2.pos = VecAdd(gt1_2.pos, gripoffset)

			gt2 = TransformCopy(gripTrans)
			gt2.pos = VecAdd(gt2.pos, gripoffset)

			gt3 = TransformCopy(gripTrans)
			gt3.pos = VecAdd(gt3.pos, gripoffset)
			gt3_1 = TransformCopy(gripTrans)
			gt3_1.pos = VecAdd(gt3_1.pos, gripoffset)
			gt3_2 = TransformCopy(gripTrans)
			gt3_2.pos = VecAdd(gt3_2.pos, gripoffset)

			glt = TransformCopy(gripTrans)
			glt.pos = VecAdd(glt.pos, gripoffset)

			brt0 = TransformCopy(barrelTrans0)
			brt0.pos = VecAdd(brt0.pos, barreloffset)

			brt1 = TransformCopy(barrelTrans1)
			brt1.pos = VecAdd(brt1.pos, barreloffset)

			brt2 = TransformCopy(barrelTrans2)
			brt2.pos = VecAdd(brt2.pos, barreloffset)

			sdt1 = TransformCopy(sideTrans1)
			sdt1.pos = VecAdd(sdt1.pos, sideoffset)
			sdt2 = TransformCopy(sideTrans2)
			sdt2.pos = VecAdd(sdt2.pos, sideoffset)
			sdt3 = TransformCopy(sideTrans3)
			sdt3.pos = VecAdd(sdt3.pos, sideoffset)

			grt = TransformCopy(grenadeTrans)
			grt.pos = VecAdd(grt.pos, grenadeoffset)

			gdt0 = TransformCopy(guardTrans0)
			gdt0.pos = VecAdd(gdt0.pos, guardoffset)
			gdt0_2 = TransformCopy(guardTrans0)
			gdt0_2.pos = VecAdd(gdt0.pos, guardoffset)
			gdt1 = TransformCopy(guardTrans0)
			gdt1.pos = VecAdd(gdt0.pos, guardoffset)
			gdt1_2 = TransformCopy(guardTrans0)
			gdt1_2.pos = VecAdd(gdt0.pos, guardoffset)
			gdt2 = TransformCopy(guardTrans0)
			gdt2.pos = VecAdd(gdt0.pos, guardoffset)
			gdt2_2 = TransformCopy(guardTrans0)
			gdt2_2.pos = VecAdd(gdt0.pos, guardoffset)

			mwt = TransformCopy(magwellTrans)
			mwt.pos = VecAdd(mwt.pos, magwelloffset)

			-- if reloadTimer < 0.3 and reloadTimer > 0.2 and reloading and ammo == 0 then
			-- 	bt2.rot = QuatRotateQuat(bt2.rot, QuatEuler(0, 0, -10*(0.3-reloadTimer)/0.1))
			-- elseif reloadTimer < 0.2 and reloadTimer > 0.1 and reloading and ammo == 0 then
			-- 	bt2.rot = QuatRotateQuat(bt2.rot, QuatEuler(0, 0, -10*(reloadTimer-0.1)/0.1))
			-- end

			-- if jamclearTimer < 1 and jamclearTimer > 0.7 then
			-- 	bt3.pos = VecAdd(bt3.pos, Vec(0.1*(1-jamclearTimer)/0.3, 0, 0.3*(1-jamclearTimer)/0.3))
			-- 	bt3.rot = QuatRotateQuat(bt3.rot, QuatEuler(0, 0, 90*(1-jamclearTimer)/0.3))
			-- end

			if selectfireTimer < 0.4 then
				if selectfire == 1 then
					st.rot = QuatRotateQuat(st.rot, QuatEuler(0, 0, 0))
					st.pos = VecAdd(st.pos, Vec(0, 0, 0))
				elseif selectfire == 2 then
					st.rot = QuatRotateQuat(st.rot, QuatEuler(40, 0, 0))
					st.pos = VecAdd(st.pos, Vec(0, -0.05, -0.025))
				elseif selectfire == 3 then
					st.rot = QuatRotateQuat(st.rot, QuatEuler(90, 0, 0))
					st.pos = VecAdd(st.pos, Vec(0, -0.05, -0.1))
				else
					st.rot = QuatRotateQuat(st.rot, QuatEuler(0, 0, 0))
					st.pos = VecAdd(st.pos, Vec(0, 0, 0))
				end
				if selectfire > 0 then
					st2.rot = QuatRotateQuat(st2.rot, QuatEuler(90, 0, 0))
					st2.pos = VecAdd(st2.pos, Vec(0, -0.05, -0.1))
				else
					st2.rot = QuatRotateQuat(st2.rot, QuatEuler(0, 0, 0))
					st2.pos = VecAdd(st2.pos, Vec(0, 0, 0))
				end
			elseif selectfireTimer > 0 then
				if selectfire0 == 1 then
					st.rot = QuatRotateQuat(st.rot, QuatEuler(0, 0, 0))
					st.pos = VecAdd(st.pos, Vec(0, 0, 0))
				elseif selectfire0 == 2 then
					st.rot = QuatRotateQuat(st.rot, QuatEuler(40, 0, 0))
					st.pos = VecAdd(st.pos, Vec(0, -0.05, -0.025))
				elseif selectfire0 == 3 then
					st.rot = QuatRotateQuat(st.rot, QuatEuler(90, 0, 0))
					st.pos = VecAdd(st.pos, Vec(0, -0.05, -0.1))
				else
					st.rot = QuatRotateQuat(st.rot, QuatEuler(0, 0, 0))
					st.pos = VecAdd(st.pos, Vec(0, 0, 0))
				end
				if selectfire > 0 then
					st2.rot = QuatRotateQuat(st2.rot, QuatEuler(90, 0, 0))
					st2.pos = VecAdd(st2.pos, Vec(0, -0.05, -0.1))
				else
					st2.rot = QuatRotateQuat(st2.rot, QuatEuler(0, 0, 0))
					st2.pos = VecAdd(st2.pos, Vec(0, 0, 0))
				end
			end

			muzzlelength = 0
			lightFactor = 1
			muzzleFactor = 1

			sct.pos = VecAdd(sct.pos, sightoffset)
			ht.pos = VecAdd(ht.pos, sightoffset)
			ht2.pos = VecAdd(ht2.pos, sightoffset)
			rdt.pos = VecAdd(rdt.pos, sightoffset)
			rdt2.pos = VecAdd(rdt2.pos, sightoffset)

			if stock == "removed" then
				stt.pos = Vec(0.5, -0.95, -1.15)
				stt.rot = QuatEuler(-90, -180, 0)
				stockFactor = 5
			else
				stt.pos = stt.pos
				stockFactor = 1
			end
			rt.pos = VecAdd(rt.pos, Vec(-0.025, 0.025, -0.005))
			mwt.pos = VecAdd(mwt.pos, Vec(0, 0.16, 0.135))
			mwt.rot = QuatRotateQuat(mwt.rot, QuatEuler(-15, 0, 0))

			if mag == "" or mag == "mag0-ppsh-762x25" then
				magsize = 35
				reloadFactor = 1
				SetShapeLocalTransform(mag0, Transform(VecAdd(mt.pos, Vec(0, 0, 0)), mt.rot))
				SetShapeLocalTransform(mag1, hideTrans)
				SetShapeLocalTransform(mag2, hideTrans)
				SetShapeLocalTransform(mag3, hideTrans)
			elseif mag == "mag1-ppsh-762x25" then
				magsize = 71
				reloadFactor = 1.5
				SetShapeLocalTransform(mag1, Transform(VecAdd(mt.pos, Vec(-0.25, 0.2, 0)), mt.rot))
				SetShapeLocalTransform(mag0, hideTrans)
				SetShapeLocalTransform(mag2, hideTrans)
			elseif mag == "none" then
				SetShapeLocalTransform(mag0, hideTrans)
				SetShapeLocalTransform(mag1, hideTrans)
				SetShapeLocalTransform(mag2, hideTrans)
			end

			SetShapeLocalTransform(bolt, bt)
			SetShapeLocalTransform(selector, st)
			SetShapeLocalTransform(rail, rt)
			SetShapeLocalTransform(stock1, stt)
			SetShapeLocalTransform(barrel0, brt0)
			SetShapeLocalTransform(guard0, gdt0)
		end

		if selectattachments then
			clickedmag = clickedmag1 or clickedmag2 or clickedmag3
			if clickedmag and selectattachments and not KeybindPressed(Settings.keybinds.player.gun_attachment) then
				Reload()
			end
		end
		if reloading and not clickedmag and selectattachments then
			selectattachments = false
			selectattachmentsTimer = 0.25
		end

		if not selectattachments then
			if (KeybindPressed(Settings.keybinds.player.reload) or clickedmag) and selectfireTimer == 0 then
				if not realistic and (ammo ~= magsize and not grenadelauncher) or (grenadelauncherammo == 0 and grenadelauncher) then
					Reload()
					inspectTimer = 0
				end
			end

			if (InputReleased("r") or clickedmag) and selectfireTimer == 0 then
				if realistic and curmagslot ~= nextmagslot and magcheckTimer == 0 then
					Reload()
					inspectTimer = 0
				end
			end
			
			if GetBool("ammobox.refill") then
				SetBool("ammobox.refill", false)
				mags = mags + 1
				PlaySound(refillsound, GetPlayerTransform().pos, 1, false)
			end

			if reloading then
				if reloadTimer > 0.4 then
					reloadTimer = reloadTimer - dt/reloadFactor*magdrillFactor
				elseif reloadTimer > 0 then
					reloadTimer = reloadTimer - dt
				end
				-- if reloadTimer < 0.4 and not cocksoundplaying and ammo == 0 then
				-- 	cocksoundplaying = true
				-- 	PlaySound(cocksound, GetPlayerTransform().pos, 0.45)
				-- end
				if reloadTimer < 0 then
					cocksoundplaying = false
					if grenadelauncher then
						grenadelauncherammo = 1
					else
						if inventoryenabled then
							ammo = nextammo
							bullettable = Split(nextbullet,"-")
							name = "Unloaded"
							maxammo = 0
							id = mag
							if id == "mag0-ppsh-762x25" then name, maxammo = "PPSh-Mag", 35
							elseif id == "mag1-ppsh-762x25" then name, maxammo = "PPSh-Drum", 71
							end
							local guninfo = Split(GetString("inventory.guns."..GetInt("inventory.curprimary")..".item"), "_")
							guninfo[3] = mag
							guninfo[4] = name
							guninfo[5] = ammo
							guninfo[6] = maxammo
							guninfo[10] = table.concat(bullettable,"-")
							SetString("inventory.guns."..GetInt("inventory.curprimary")..".item", IDBuilder(guninfo))
							SetBool("inventory.update", true)
							curmagslot = 1
						elseif realistic then
							ammo = magtable2[curmagslot][2]
						else
							ammo = magsize
						end
					end
					reloadTimer = 0
					reloading = false
					SetBool("inventory.reloading", false)
					PlaySound(inspectsound)
				end
			end

			if selectfireTimer < 0.55 and selectfireTimer > 0 and not selectsoundplaying then
				selectsoundplaying = true
				PlaySound(selectsound, GetPlayerTransform().pos, 0.85)
			end
			if selectfireTimer < 0 then
				selectsoundplaying = false
				selectfireTimer = 0
				PlaySound(inspectsound)
			end
			
		end

		btrans = GetBodyTransform(b)

		if InputDown("crouch") then
			crouchoffset = math.min(crouchoffset + dt*3, 0.8)
		else
			crouchoffset = math.max(crouchoffset - dt*3, 0)
		end
		local x2, y2, z2, rotx2, roty2, rotz2 = 0.175, -0.7, -1.7, 0, 0, 0
		if reloading then
			x2, y2, z2, rotx2, roty2, rotz2 = 0+mt.pos[1], 0.5+mt.pos[2], -0.15+mt.pos[3], 0, 0, 0
		elseif KeybindDown(Settings.keybinds.player.sprint) and VecLength(GetPlayerVelocity()) > 2 then
			x2, y2, z2, rotx2, roty2, rotz2 = -0.7-swayx*0.2, -1.6, -1+swayx*0.2, 0, 0, 0
		end

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

		local x3, y3, z3, rotx3, roty3, rotz3 = 0.275, -0.95, -0.85, 0, 0, 0
		-- if reloading and ammo == 0 and reloadTimer < 0.9 and reloadTimer > 0.2 then
		-- 	x3, y3, z3, rotx3, roty3, rotz3 = 0.3, -0.75, -0.4+bt.pos[3], 0, 0, 0
		if selectfireTimer > 0 then
			x3, y3, z3, rotx3, roty3, rotz3 = 0.3, -0.05+st.pos[3], -0.3+st.pos[3], 0, 0, 0
		end

		h2p1l = SEL(true, x3, y3, z3, rotx3, roty3, rotz3).pos

		--h2p1l = Vec(0.275, -0.95, -0.85)
		h2p2l = TransformToLocalPoint(btrans, TransformToParentPoint(GetPlayerTransform(), Vec(0.55, 1.1-crouchoffset-lookoffset, 0.9)))
		hnd2 = Transform(h2p1l, QuatRotateQuat(QuatLookAt(h2p2l, h2p1l), QuatEuler(0,90,90)))
		SetShapeLocalTransform(hand2, hnd2)


		sightattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.15, -0.75))
		muzzleattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.35, -2.5-barrellength))
		stockattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.4, -0.6))
		sideattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.45, -1.65))
		magattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.65, -1))
		gripattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.85, -1.4-guardlength))
		barrelattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.65, -1.6))
		guardattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.25, -1.5))

		
	end
end

function client.draw()
	if not GunInInventory("gun-ppsh41") then return end -- (v2, Phase 2) see gunfunctions.lua
	if gunWantsInteractive then UiMakeInteractive() gunWantsInteractive = false end
	GunNet_DebugParts()
	if GetPlayerTool() == "gun-ppsh41" and GetPlayerVehicle() == 0 or inventoryenabled and GetPlayerTool() == "gun-ppsh41" and GetPlayerVehicle() == 0 then

		UiPush()
      UiAlign("center middle")
      UiTranslate(UiCenter(), UiHeight()/2)
      UiFont("bold.ttf", 50)
      UiColor(0.1,0.1,0.1,DrawHitmark)
      UiText("<  +  >")
    UiPop()
    DrawHitmark = DrawHitmark - 0.1

		if not realistic and not GetBool("level.optionstriggered") or inventoryenabled and GetPlayerTool() == "gun-ppsh41" and GetPlayerVehicle() == 0 then
		if not unlimitedammo then
			UiPush()
				UiTranslate(UiCenter(), UiHeight()-60)
				UiAlign("center middle")
				UiColor(1, 1, 1)
				UiFont("bold.ttf", 32)
				UiTextOutline(0,0,0,1,0.1)
				if reloading then
					UiText("Reloading")
				elseif grenadelauncher then
					UiText(grenadelauncherammo.."/1 - Grenade")
				else
					if realistic then
						UiText(ammo.."/"..magtable2[curmagslot][3].." - "..selectfireText..(bullettable[ammo] and " - "..bullettable[ammo] or ""))
					else
						UiText(ammo.."/"..magsize.." - "..selectfireText)
					end
				end
			UiPop()
		else
			UiPush()
				UiTranslate(UiCenter(), UiHeight()-60)
				UiAlign("center middle")
				UiColor(1, 1, 1)
				UiFont("bold.ttf", 32)
				UiTextOutline(0,0,0,1,0.1)
				if reloading then
					UiText("Reloading")
				elseif grenadelauncher then
					UiText(grenadelauncherammo.."/1 - Grenade")
				else
					UiText("Infinite")
				end
			UiPop()
		end
		end
		if realistic then
		if magcheckTimer > 0 and magcheckTimer < 2 then
			UiTranslate(UiCenter(), UiHeight()-60)
			UiAlign("center middle")
			UiAlign("center middle")
			UiColor(1, 1, 1, magcheckTimer)
			UiFont("bold.ttf", 32)
			local checkammo = CheckAmmo(curmagslot)
			UiText(checkammo)
		end
		if selecttextTimer > 0 and not inventoryenabled then
			UiTranslate(UiCenter(), UiHeight()-60)
			UiAlign("center middle")
			UiAlign("center middle")
			UiColor(1, 1, 1, selecttextTimer)
			UiFont("bold.ttf", 32)
			UiText(selectfireText)
		end
		if jammed and jamclearTimer == 0 and not inventoryenabled then
			UiTranslate(UiCenter(), UiHeight()-60)
			UiAlign("center middle")
			UiAlign("center middle")
			UiColor(1, 1, 1, 1)
			UiFont("bold.ttf", 32)
			UiText("Jammed")
		elseif jamclearTimer > 0 and not inventoryenabled then
			UiTranslate(UiCenter(), UiHeight()-60)
			UiAlign("center middle")
			UiAlign("center middle")
			UiColor(1, 1, 1, jamclearTimer)
			UiFont("bold.ttf", 32)
			UiText("Jammed")
		end
		end
	end
	if GetPlayerTool() == "gun-ppsh41" and grenadelauncher and not selectattachments then
		UiPush()
			UiTranslate(UiCenter(), UiMiddle())
			UiAlign("center middle")
			UiImage("ui/hud/crosshair-launcher.png")
		UiPop()
	end
	if GetPlayerTool() == "gun-ppsh41" and sideattachment and side == "side3" then
		UiPush()
			local x,y,dist = UiWorldToPixel(sideattachpoint)
			UiTranslate(x, y)
			UiAlign("center middle")
			UiColor(1, 0.1, 0.1)
			UiFont("bold.ttf", 32)
			UiTextOutline(0,0,0,1,0.1)
			UiText(math.floor(range))
		UiPop()
	end

	if realistic and selectmag and GetPlayerTool() == "gun-ppsh41" then
		hoverindex=0
		UiPush()
			local x,y,dist=UiWorldToPixel(magattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					for i = 1, totalmags do
					clickedslot = MagButton(nextmagslot,i,true,{curx,cury},{"Ammo: ", CheckAmmo(i)},60,60)
					UiTranslate(60,0)
					curx,cury=curx+60,cury
					end
				UiPop()
			end
		UiPop()
	end


	------ATTACHMENTS MENU------
	if not realistic or GetBool("level.optionstriggered") then
	if selectattachments and GetPlayerTool() == "gun-ppsh41" and GetPlayerVehicle() == 0 then
	hoverindex=0
		if not realistic then
		UiPush()
			local x,y,dist=UiWorldToPixel(magattachpoint)
			if dist > 0 then
				UiTranslate(x,y)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					clickedmag1 = AttachmentButton("mag","mag1",true,{curx,cury},{"71rnd Mag","Pew Pew Pew"})
				UiPop()
			end
		UiPop()
		end
	end
	end
	if selectattachments and GetPlayerTool() == "gun-ppsh41" and GetPlayerVehicle() == 0 or GetBool("level.optionstriggered") and GetPlayerTool() == "gun-ppsh41" then
	hoverindex=0
	UiPush()
		local x,y,dist=UiWorldToPixel(stockattachpoint)
			if dist > 0 then
				UiTranslate(x,y)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					clickedstockremoved = AttachmentButton("stock","removed",true,{curx,cury},{"Fold Stock","Folds stock for a smaller profile weapon."})
				UiPop()
			end
		UiPop()
	end
	if hint and (selectattachments or KeybindDown(Settings.keybinds.player.reload) and heldrTimer > 0.2) then drawHint(info) end


	------OPTIONS UI------
	if GetBool("level.optionstriggered") and GetPlayerTool() == "gun-ppsh41" then
	UiPush()
		UiAlign("center middle")
		UiTranslate(UiCenter(), 70)
		UiFont("bold.ttf", 60)
		UiText("WEAPON MODDING")
	UiPop()
	end
	
	if GetBool("level.optionstriggered") and GetPlayerTool() == "gun-ppsh41" then

	UiAlign("center middle")
	UiTranslate(300, 250)
	UiFont("bold.ttf", 48)
	UiText("PPSh-41")
	UiFont("regular.ttf", 26)
	UiTranslate(0, 70)
	UiPush()
		UiText("Unlimited Ammo")
		UiTranslate(0, 40)
		UiAlign("center")
		UiColor(0.5, 0.8, 1)
		if realistic then
			UiText("Unvavailable")
		else
		if unlimitedammo then
			if UiTextButton("Yes", 20, 20) then
				unlimitedammo = false
				SetBool("savegame.mod.unlimitedammo", unlimitedammo)
			end
		else
			if UiTextButton("No", 20, 20) then
				unlimitedammo = true
				SetBool("savegame.mod.unlimitedammo", unlimitedammo)
			end
		end
		end
	UiPop()
	UiTranslate(0, 80)
	UiPush()
		UiText("Spent Casings")
		UiTranslate(15, 40)
		UiAlign("right")
		UiColor(0.5, 0.8, 1)
		if spentcasingsoption then
			if UiTextButton("Yes", 20, 20) then
				spentcasingsoption = false
				SetBool("savegame.mod.spentcasingsoption", spentcasingsoption)
			end
		else
			if UiTextButton("No", 20, 20) then
				spentcasingsoption = true
				SetBool("savegame.mod.spentcasingsoption", spentcasingsoption)
			end
		end
	UiPop()
	UiTranslate(0, 80)
	UiPush()
		UiText("Damage: "..damageoption.."%")
		UiTranslate(-50, 40)
		UiAlign("right")
		UiColor(0.5, 0.8, 1)
		damageoption = optionsSlider(damageoption, 50, 1000, 10)
		SetInt("savegame.mod.damage", damageoption)
	UiPop()

	UiTranslate(0, 70)
	UiPush()
		UiText("Realistic Mode")
		UiTranslate(0, 40)
		UiAlign("center")
		UiColor(0.5, 0.8, 1)
		if realistic then
			if UiTextButton("Yes", 20, 20) then
				realistic = false
				SetBool("savegame.mod.realistic", realistic)
			end
		else
			if UiTextButton("No", 20, 20) then
				realistic = true
				SetBool("savegame.mod.realistic", realistic)
				SetBool("savegame.mod.unlimitedammo", false)
			end
		end
	UiPop()

	UiTranslate(0, 100)
	hoverindex=0
	if realistic then
	magtable = {}

	UiPush()
		UiTranslate(-180, 150)
		MagButton2("mag0", 1, 2, "30rnd Mag")
		UiTranslate(60, 0)
		MagButton2("mag1", 1, 2, "40rnd Mag")
		UiTranslate(90, 0)
		MagButton2("mag2", 2, 2, "50rnd Drum")
		UiTranslate(150, 0)
		MagButton2("mag3", 3, 2, "100rnd Double Drum")
	UiPop()

	UiPush()
		UiAlign("center middle")
		UiTranslate(-30*(#slots-1), 20+30*(#slots[1]-1))
		for i = 1,#slots do
			for j = 1,#slots[i] do
				local w, h = slots[i][j][3], slots[i][j][4]
				UiTranslate(30*(w-1), 30*(h-1))
				local inside2 = UiIsMouseInRect(60*w-1, 60*h-1)
				UiTranslate(-30*(w-1), -30*(h-1))
				if inside2 then
					UiTranslate(30*(w-1), 30*(h-1))
					UiImageBox("ui/common/box-solid-6.png", 60*w, 60*h, 6, 6)
					UiTranslate(-30*(w-1), -30*(h-1))
				elseif slots[i][j][2][1] == i or slots[i][j][2][2] == j or slots[i][j][2][1] == 0 then
					UiTranslate(30*(w-1), 30*(h-1))
					UiColor(0.1, 0.2, 0.1)
					UiImageBox("ui/common/box-solid-6.png", 60*w, 60*h, 6, 6)
					UiColor(1, 1, 1)
					UiImageBox("ui/common/box-outline-6.png", 60*w, 60*h, 6, 6)
					UiTranslate(-30*(w-1), -30*(h-1))
				end
				UiTranslate(0, -60)
			end
			UiTranslate(60, 60*#slots[i])
		end
		UiTranslate(-60*#slots, 0)
		for i = 1,#slots do
			for j = 1,#slots[i] do
				local item, w, h = slots[i][j][1], slots[i][j][3], slots[i][j][4]
				UiTranslate(30*(w-1), 30*(h-1))
				if slots[i][j][1] ~= "" then
					UiImageBox("MOD/img/icon/"..item..".png", 60*w, 60*h, 0, 0)
					table.insert(magtable, item)
				end
				UiTranslate(-30*(w-1), -30*(h-1))
				if not InputDown("usetool") and UiIsMouseInRect(59, 59) and grabbed[1][1] ~= "" then
					placeItem(grabbed, i, j)
					grabbed = {{"", {0, 0}, 1, 1}, 0, 0}
				end
				if InputPressed("usetool") and UiIsMouseInRect(60, 60) then
					if slots[i][j][1] ~= "" then
						local w, h = slots[i][j][3], slots[i][j][4]
						grabbed = {slots[i][j], i, j}
						slots[i][j] = {"", {0, 0}, w, h}
					elseif slots[i][j][2][1] ~= 0 then
						local a = slots[i][j][2][1][1]
						local b = slots[i][j][2][1][2]
						local w, h = slots[a][b][3], slots[a][b][4]
						grabbed = {slots[a][b], a, b}
						slots[a][b] = {"", {0, 0}, w, h}
					end
				end
				UiTranslate(0, -60)
			end
			UiTranslate(60, 60*#slots[i])
		end
		if grabbed[1][1] ~= "" then
			local item, w, h = grabbed[1][1], grabbed[1][3], grabbed[1][4]
			local x, y = UiGetMousePos()
			UiTranslate(x+30*(w-1), y+30*(h-1))
			UiImageBox("MOD/img/icon/"..item..".png", 60*w, 60*h, 0, 0)
		end
		if not InputDown("usetool") and grabbed[1][1] ~= "" then
			clearItem(grabbed)
			grabbed = {{"", {0, 0}, 1, 1}, 0, 0}
		end
	UiPop()

	SetInt("savegame.mod.totalmags", #magtable)
	for i = 1, #magtable do
		--SetString("savegame.mod.mslot"..i, magtable[i])
	end
	end

	if realistic then
		UiTranslate(0, 240)
	end
	if UiTextButton("Close", 80, 40) then
		Menu()
	end

	if not realistic then
		UiTranslate(0, 340)
	else
		UiTranslate(0, 100)
	end

	UiPush()
		UiTranslate(800+optionsx*100, -80)
		UiFont("bold.ttf", 26)
		UiTranslate(-120, 70)
		UiText("Horizontal Recoil: "..round(recoilHorizontal*stockFactor, 2))
		UiTranslate(260, 0)
		UiText("Vertical Recoil: "..round(recoilFactor, 2))
		UiTranslate(200, 0)
		UiText("Accuracy: "..round(1/accuracyFactor, 2))
	UiPop()

	UiPush()
		UiTranslate(-200, 50)
		UiPush()
			UiAlign("center middle")
			KeybindButton("Reload")
			UiTranslate(124, 0)
			KeybindButton("Check-Mag")
			UiTranslate(140, 0)
			KeybindButton("Fire-Mode")
			UiTranslate(132, 0)
			KeybindButton("Lean-Left")
			UiTranslate(132, 0)
			KeybindButton("Lean-Right")
			UiTranslate(152, 0)
			KeybindButton("Attachments")
			UiTranslate(132, 0)
			KeybindButton("Melee")
			UiTranslate(148, 0)
			KeybindButton("Side-Attachment")
			UiTranslate(204, 0)
			KeybindButton("Grenade-Launcher")
			UiTranslate(204, 0)
			KeybindButton("Inspect-Weapon")
			UiTranslate(164, 0)
			KeybindButton("Clear-Jam")
		UiPop()
	UiPop()
	end
end