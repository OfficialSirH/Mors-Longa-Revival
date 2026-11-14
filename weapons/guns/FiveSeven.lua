#version 2
#include "script/include/player.lua"
#include "gunfunctions.lua"
#include "gunperks.lua"
#include "gunstats.lua"
#include "gunnet.lua"



function server.init()
	RegisterTool("gun-fiveseven", "TCP-57", "MOD/weapons/guns/Weapons/FiveSeven Tool.xml", 2)
	-- (v2, Phase 2) tools are enabled per player by inventory.lua (server)
	GunNet_ServerInit()
end

function server.tick(dt)
	-- (v2, Phase 2) tools are enabled per player by inventory.lua (server)
	GunNet_ServerTick(dt)
end

function client.init()
	conversion = "Semi"

	-- (v2) RegisterTool moved to server.init()
	-- (v2) tool enabled per player in server.init()/server.tick()
	GunName = "FiveSeven"
	Cartridge = "57x28"
	WeaponInit()
	------INITIALISE OPTIONS MENU------
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
	damage = 0.11
	gravity = Vec(0, -10, 0)
	hidePos = Vec(0, -200, 0)
	hideTrans = Transform(hidePos,QuatEuler())
	velocity = 320
	drag = 0.1 * 2
	maxMomentum = 1.5
	tracer = false

	recoilVertical = gunstats.fiveseven.recoilVertical
	recoilHorizontal = gunstats.fiveseven.recoilHorizontal
	recoilWander = gunstats.fiveseven.recoilWander

	lvl5armor = 0
	lvl4armor = 0.01
	lvl3armor = 0.15
	lvl2armor = 0.5
	lvl1armor = 0.7

	inside = {}
	for i = 1,50 do
		inside[i] = {0,0,0,0}
	end
	hoverindex = 0

	gunsound = LoadSound("MOD/assets/snd/Weapons/g17/g17_0.ogg")
	--suppressedgunsound = LoadSound("MOD/snd/Weapons/g17/g17_sup_0.ogg")
	suppressedgunsound = LoadSound("MOD/assets/snd/Weapons/g17/g17suppressed.ogg")
	grenadelaunchersound = LoadSound("MOD/assets/snd/Weapons/Handheld/Grenade/grenadelauncher.ogg")
	--[[ toprail = GetString("savegame.mod.toprail")
	muzzle = GetString("savegame.mod.muzzle")
	stock = GetString("savegame.mod.stock") ]]
	--realistic = GetBool("savegame.mod.realistic")
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
		local guninfo = Split(GetString("inventory.guns.2.item"), "_")
		magtable2[1] = {guninfo[3], tonumber(guninfo[5]), tonumber(guninfo[6]), {1,1}, guninfo[10]}
		for i = 1, 8 do
			for j = 1, 15 do
				if GetString("inventory.backpack."..i.."_"..j..".item") ~= "" then
					local maginfo = Split(GetString("inventory.backpack."..i.."_"..j..".item"), "_")
					local magtype, magammo, magammomax = maginfo[1], maginfo[3], maginfo[4]
					if string.sub(magtype, 1, 3) == "mag" and string.sub(magtype, 6, 13) == "fs-57x28" then
						table.insert(magtable2, {magtype,tonumber(magammo),tonumber(magammomax),{i,j}, maginfo[6]})
					end
				end
			end
		end
		totalmags = #magtable2
	else
		if totalmags == 0 then
			mslot1, mslot2 = "mag0", "mag0"
			--SetString("savegame.mod.mslot1", "mag0")
			--SetString("savegame.mod.mslot2", "mag0")
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
		local guninfo = Split(GetString("inventory.guns.2.item"), "_")
		mag = guninfo[3]
		reloadFactor = 1
	elseif realistic then
		mag = mslot1
		reloadFactor = 1
	else
		mag = GetString("savegame.mod.mag")
		reloadFactor = 1
	end
	side = GetString("savegame.mod.side")


	if inventoryenabled then
		item = GetString("inventory.guns.2.item")
		guninfo = Split(item, "_")
		if #guninfo >= 8 then
			attachmentinfo = Split(guninfo[8], "-")
			toprail = attachmentinfo[1]
			muzzle = attachmentinfo[2]
			stock = attachmentinfo[3]
			side = attachmentinfo[4]
			camo = attachmentinfo[5]
		else
			toprail = ""
			muzzle = ""
			stock = ""
			side = ""
			camo = ""
		end
	end


	cocksound = LoadSound("MOD/assets/snd/Weapons/g17/g17slide.ogg")
	cocksound2 = LoadSound("MOD/assets/snd/Weapons/g17/g17slidepull.ogg")
	reloadsound = LoadSound("MOD/assets/snd/Weapons/g17/g17reload.ogg")
	reloadsound2 = LoadSound("MOD/assets/snd/Weapons/g17/g17reload2.ogg")
	dryfiresound = LoadSound("MOD/assets/snd/Weapons/Shared/dryfire.ogg")
	refillsound = LoadSound("MOD/assets/snd/refill.ogg")
	selectsound = LoadSound("MOD/assets/snd/selectorswitch_ar.ogg")
	casingsound = LoadSound("MOD/assets/snd/Weapons/Shared/Shells/pistol_0.ogg")
	uiselect = LoadSound("MOD/assets/snd/uiselect.ogg")
	adsup = LoadSound("MOD/assets/snd/ads_up_pistol.ogg")
	adsdown = LoadSound("MOD/assets/snd/ads_down_pistol.ogg")
	inspectsound = LoadSound("MOD/assets/snd/Weapons/Shared/Inspect/weapon_inspect_0.ogg")

	reloadTime = 2.4
	shotDelay = 0.05
	spreadTimer = 1.25
	spreadFactor = 1.5
	accuracyFactor = 1

	if not realistic then
		if mag == "" or mag == "mag0-fs-57x28" then
			magsize = 20
			reloadFactor = 1
		elseif mag == "mag1-fs-57x28" then
			magsize = 33
			reloadFactor = 1.15
		elseif mag == "mag2-fs-57x28" then
			magsize = 50
			reloadFactor = 1.35
		else
			magsize = 20
			reloadFactor = 1
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
	if inventoryenabled then
		initammo = false
	end
	ammoleft = 0
	maxammoleft = 0
	nextammo = 0
	reloadFactor = 1
	barrellength = 0
	guardlength = 0
	barrelFactorx = 0.8
	barrelFactory = 1
	barrelFactordamage = 1.25
	grenadelauncherammo = 1
	reloading = false
	ironsight = false
	sliderelease = true
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

	magoutTimer = 0
	maginTimer = 0
	meleeTimer = 0
	magcheckTimer = 0
	selecttextTimer = 0
	cocksoundplaying = false
	cocksound2playing = false
	reloadsound2playing = true
	selectsoundplaying = false
	selectattachments = false
	selectmag = false
	jammed = false
	jamclearTimer = 0
	selectattachmentsTimer = 0
	inspectTimer = 0
	heldrTimer = 0

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
	dmgsnd = LoadSound("MOD/assets/snd/dmge.ogg")
	DrawHitmark = 0
	parts = FindTriggers("localhitbox",true)
	magdrillFactor = 1
	if GetBool("inventory.magdrills") then
		magdrillFactor = 1.5
	end
	
	
	-------------------------
	holocolors = {"red","green"}
	currentholocolor = 1
	holoreticles = {"reticle1","reticle1_1","reticle1_2","reticle1_3"}
	currentholoreticle = 1

end

function GetAimPos()
	local ct = GetCameraTransform()
	local forwardPos = TransformToParentPoint(ct, Vec(0, 0, -100))
    local direction = VecSub(forwardPos, ct.pos)
    local distance = VecLength(direction)
	local direction = VecNormalize(direction)
	QueryRejectBody(GetToolBody())
	local hit, hitDistance = QueryRaycast(ct.pos, direction, distance)
	if hit then
		forwardPos = TransformToParentPoint(ct, Vec(0, 0, -hitDistance))
		distance = hitDistance
	end
	return forwardPos, hit, distance
end

function FireRound(Type)
	local perk = "57x28"
	local perktable=GunPerkFor(perk, Type) -- (v2 fix) missing bullet type -> calibre default
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
	if shootTimer > 0 or ammo == 0 then
		return
	end

	ShakeCamera(0.375)

	aimpos, hit, distance = GetAimPos()

	local gt = GetBodyTransform(GetToolBody())
	local fwdpos = TransformToParentPoint(gt, Vec(0.275, -0.625, -100))
	local gunpos = TransformToParentPoint(gt, Vec(0.275, -0.625, -1.2))
	dir = VecNormalize(VecSub(fwdpos, gunpos))

	local ironsightFactor = 1
	if not ironsight then
		ironsightFactor = 2.5
	end

	local maxSpread = InputDown("crouch") and 2 or 3
	if ironsight then maxSpread = maxSpread / 3 end
	local factor = laserFactor*muzzleFactor*ironsightFactor*5
	rnd1, rnd2, rnd3, rnd4, rnd5, rnd6 = rnd1+(math.random()-0.5)*factor*recoilWander, rnd2+(math.random()-0.5)*factor*recoilWander, rnd3+(math.random()-0.5)*factor*recoilWander/4, (math.random()-0.5)*factor*recoilHorizontal, (math.random()-0.5)*factor*recoilHorizontal, (math.random()-0.5)*factor*recoilHorizontal/4

	if not ironsight then
		accuracyFactor = 12
	end
	if recoilAngle < recoilMax then
		recoilAngle = recoilAngle + recoilFactor*muzzleFactor
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
	loadedShell.predictedBulletVelocity = VecScale(dir, velocity*barrelFactory)
	projectileHandler.shellNum = (projectileHandler.shellNum%#projectileHandler.shells) + 1

	loadedShell.predictedBulletVelocity = VecAdd(loadedShell.predictedBulletVelocity, Vec((math.random()-0.5)*accuracyFactor*2, (math.random()-0.5)*accuracyFactor*2, (math.random()-0.5)*accuracyFactor*2))
	loadedShell.factor = barrelFactordamage or 1
	loadedShell.active = false -- simulated by gunnet.lua (client visuals + server world)
	GunNet_Fire(loadedShell, muzzle == "muzzle1" and "MOD/assets/snd/Weapons/g17/g17suppressed.ogg" or "MOD/assets/snd/Weapons/g17/g17_0.ogg", 0.7)

	local barrelend = barrellength + muzzlelength
	SpawnParticle("smoke", TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.25, -0.6, -1.3-barrelend*4/3)), VecAdd(VecScale(dir, 0.02), GetPlayerVelocity()), 0.3, 0.3)
	ParticleType("plain")
	ParticleTile(5)
	ParticleColor(1, 0.6, 0.4, 1, 0.3, 0.2)
	ParticleRadius(0.1)
	ParticleEmissive(5, 1)
	SpawnParticle(TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.25, -0.6, -1.2-barrelend*4/3)), VecAdd(VecScale(dir, 0.04), GetPlayerVelocity()), 0.2, 0.3)
	if muzzle == "muzzle1" then
		PlaySound(suppressedgunsound, GetPlayerTransform().pos, 0.5, false)
	elseif muzzle == "muzzle2" then
		PlaySound(gunsound, GetPlayerTransform().pos, 1, false)
	else
		PlaySound(gunsound, GetPlayerTransform().pos, 0.9, false)
	end

	if not unlimitedammo then
		bullettable[ammo] = nil
		ammo = ammo - 1
		if realistic then
			magtable2[curmagslot][2] = ammo
			magtable2[curmagslot][5] = table.concat(bullettable,"-")
			if inventoryenabled then
				name = "Unloaded"
				maxammo = 0
				id = mag
				if id == "mag0-fs-57x28" then name, maxammo = "TCP-57", 20
				elseif id == "mag1-fs-57x28" then name, maxammo = "TCP-57", 33
				elseif id == "mag2-fs-57x28" then name, maxammo = "P17-Drum", 50
				elseif id == "mag3-fs-57x28" then name, maxammo = "P17-Drum", 100
				end
				local guninfo = Split(GetString("inventory.guns.2.item"), "_")
				guninfo[3] = mag
				guninfo[4] = name
				guninfo[5] = ammo
				guninfo[6] = maxammo
				guninfo[10] = table.concat(bullettable,"-")
				SetString("inventory.guns.2.item", IDBuilder(guninfo))
				SetBool("inventory.update", true)
			end
		end
	end

	if ammo == 0 then
		SpawnParticle("fire", TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.35, -0.55, -1.1)), Vec(0, 0, 0), 0.4, 1)
	end

	shootTimer = shotDelay
	recoilTimer = shotDelay
	recoilTimer2 = shotDelay*3
	lightTimer = shotDelay/2

	if ammo == 0 then sliderelease = false end

	if spentcasingsoption then
		SpentCasing()
	end
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
		recoilAngle = recoilAngle + recoilFactor
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
		if ammo == 0 then
			reloadTimer = reloadTime
		else
			reloadTimer = reloadTime - 0.7
		end
		if realistic and totalmags > 0 then
			if not inventoryenabled then
			if ammo == 0 then
				magtable2[curmagslot][2] = ammo
			else
				magtable2[curmagslot][2] = ammo - 1
			end
			end
			if inventoryenabled then
				curmagslot = nextmagslot
				ammoleft = ammo - 1
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
			PlaySound(reloadsound, GetPlayerTransform().pos, 0.7, false)
		end
	end
end

function SelectFire()
	selectfire = selectfire + 1
	if selectfire > 1 then
		selectfire = 0
	end
	selectfireTimer = 1

	selectfire0 = selectfire0 + 1
	if selectfire0 > 1 then
		selectfire0 = 0
	end
	selectsoundplaying = false
end

function SpentCasing()
	local gt = GetBodyTransform(GetToolBody())
	local casingpos = TransformToParentPoint(gt, Vec(0.325, -0.4, -0.65))
	local fwdpos = TransformToParentPoint(gt, Vec(1+math.random()*4, 4+math.random()*4, -0.3+math.random()*4))
	local direction = VecAdd(GetPlayerVelocity(), VecSub(fwdpos, casingpos))
	GunNet_SpawnCasing("MOD/assets/vox/pistolcasing.xml", Transform(casingpos, QuatEuler(math.random(0, 90), math.random(0, 90), math.random(0, 90))), direction)
	PlaySound(casingsound,GetPlayerTransform().pos,0.6)
end

function Laser(active)
		local gt = GetBodyTransform(GetToolBody())
		local gunpos = TransformToParentPoint(gt, Vec(0.25, -0.75, -1.4))
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
		local gunpos = TransformToParentPoint(gt, Vec(0.275, -0.525, -1.9))
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

function client.tick(dt)
	GunNet_ClientTick(dt)
	WeaponBackgroundTick(dt)

    unlimitedammo = GetBool("savegame.mod.unlimitedammo")
    checkUnlimitedBulletsValid()


	if inventoryenabled and not reloading then
		item = GetString("inventory.guns.2.item")
		if Split(item, "_")[1] == "gun-fiveseven" then
			guninfo = Split(item, "_")
			if GetBool("inventory.update_guns2") or not initammo then
				ammo = tonumber(guninfo[5])
				mag = guninfo[3]
				bullettable = Split(guninfo[10], "-")
				SetBool("inventory.update_guns2", false)
				initammo = true
			end
		end
	end

	if IsToolEnabled("gun-fiveseven") and GunInInventory("gun-fiveseven") then
	
	if inventoryenabled then
		magtable2 = {}
		local guninfo = Split(GetString("inventory.guns.2.item"), "_")
		magtable2[1] = {guninfo[3], tonumber(guninfo[5]), tonumber(guninfo[6]), {1,1}, guninfo[10]}
		for i = 1, 8 do
			for j = 1, 15 do
				if GetString("inventory.backpack."..i.."_"..j..".item") ~= "" then
					local maginfo = Split(GetString("inventory.backpack."..i.."_"..j..".item"), "_")
					local magtype, magammo, magammomax = maginfo[1], maginfo[3], maginfo[4]
					if string.sub(magtype, 1, 3) == "mag" and string.sub(magtype, 6, 13) == "fs-57x28" then
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
		GunNet_SetTool("gun-fiveseven")
	end

	end

	if GetPlayerTool() == "gun-fiveseven" and GetPlayerVehicle() == 0 then
		SetBool("hud.aimdot", false)
		WeaponTick(dt)

		------CONTROLS------
		if toprail == "holo" then
			if InputPressed"j" then
				if currentholoreticle < #holoreticles then
					currentholoreticle = currentholoreticle + 1
					SetFloat("level.holoreticle", currentholoreticle)
				else
					currentholoreticle = 1
				end
			elseif InputPressed"k" then
				if currentholocolor < #holocolors then
					currentholocolor = currentholocolor + 1
					SetFloat("level.holocolor", currentholocolor)
				else
					currentholocolor = 1
				end
			end
		end
		if InputDown("usetool") and not reloading and selectfire == 1 and conversion == "Full" and not selectattachments and selectfireTimer == 0 and GetPlayerGrabShape() == 0 and inspectTimer <= 0 and not selectmag then
			if ammo > 0 then
				FireRound(tostring(bullettable[ammo]))
			end
		elseif InputPressed("usetool") and not reloading and selectfire == 1 and conversion == "Semi" and not selectattachments and selectfireTimer == 0 and GetPlayerGrabShape() == 0 and inspectTimer <= 0 and not selectmag then
			if ammo > 0 then
				FireRound(tostring(bullettable[ammo]))
				shootTimer = 0.05
			end
		end
		if GetBool("guns.accidental.shoot") and selectfire ~= 0 then
			--DebugPrint("Accidental Shoot")
			FireRound(tostring(bullettable[ammo]))
			SetBool("guns.accidental.shoot", false)
		end

		if InputPressed("usetool") and not reloading and inspectTimer <= 0 then
			spreadTimer = 1.25
			if (ammo == 0 or selectfire == 0) and not selectattachments then
				PlaySound(dryfiresound, GetPlayerTransform().pos, 1, false)
			end
		end

		if InputReleased("lmb") and not reloading and selectfire > 0 then
			shootTimer = 0
		end

		
		if InputDown("grab") and selectfire > 0 and selectfireTimer == 0 and not selectattachments and GetPlayerGrabShape() == 0 and not KeybindDown(Settings.keybinds.player.sprint) then
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
		if selectfire == 0  and selectfireTimer <= 0 then
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

		-- if InputPressed("x") and not reloading and not ironsight and shootTimer <= 0 and selectfire > 0 and stock ~= "removed" and not KeybindDown(Settings.keybinds.player.sprint) then
		-- 	meleeTimer = 0.8
		-- 	inspectTimer = 0
		-- end

		if KeybindPressed(Settings.keybinds.player.select_fire) and not reloading and not selectattachments and not selectmag and magcheckTimer == 0 and jamclearTimer == 0 then
			SelectFire()
			inspectTimer = 0
			selecttextTimer = 3
			PlaySound(inspectsound)
		end
		if selecttextTimer > 0 then
			selecttextTimer = selecttextTimer - dt
		end
		if selecttextTimer < 0 then
			selecttextTimer = 0
		end

		if InputDown("y") and not reloading and selectfire > 0 and selectfireTimer <= 0 and not KeybindDown(Settings.keybinds.player.sprint) and magcheckTimer == 0 and jamclearTimer == 0 and not realistic or GetBool("level.optionstriggered") then
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

		if KeybindPressed(Settings.keybinds.player.mag_check) and realistic and not reloading and selectfire > 0 and selectfireTimer <= 0 and not KeybindDown(Settings.keybinds.player.sprint) and magcheckTimer == 0 and jamclearTimer == 0 and not inventoryenabled then
			magcheckTimer = 4
			PlaySound(reloadsound, GetPlayerTransform().pos, 0.7)
			inspectTimer = 0
		end
		if magcheckTimer > 0 then
			magcheckTimer = magcheckTimer - dt*1.5
			ironsight = false
		end
		if magcheckTimer < 0 then
			magcheckTimer = 0
			PlaySound(reloadsound2, GetPlayerTransform().pos, 0.7)
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

		if KeybindDown(Settings.keybinds.player.sprint) then
			ironsight = false
			selectattachments = false
			inspectTimer = 0
		end

		if grip == "grenade_launcher" then
			if InputPressed("c") and not reloading then
				grenadelauncher = not grenadelauncher
			end
		else
			grenadelauncher = false
		end

		if KeybindPressed(Settings.keybinds.player.gun_inspect) and not reloading and not KeybindDown(Settings.keybinds.player.sprint) and selectfireTimer <= 0 and not ironsight and selectfire > 0 then
			if inspectTimer <= 0 then
				inspectTimer = 4
				ironsight = false
			else
				inspectTimer = 0
			end
		end

		if selectfire == 1 then
			selectfireText = conversion
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
			recoilFactor = recoilVertical
		else
			recoilFactor = recoilVertical*1.75
		end

		if ironsight then
			recoilMax = gunstats.fiveseven.recoilMax*muzzleFactor
		else
			recoilMax = gunstats.fiveseven.recoilMax*1.5*muzzleFactor
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

		--[[ toprail = GetString("savegame.mod.toprail")
		muzzle = GetString("savegame.mod.muzzle")
		stock = GetString("savegame.mod.stock") ]]
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
		side = GetString("savegame.mod.side")

		if inventoryenabled then
			item = GetString("inventory.guns.2.item")
			guninfo = Split(item, "_")
			if #guninfo >= 8 then
				attachmentinfo = Split(guninfo[8], "-")
				toprail = attachmentinfo[1]
				muzzle = attachmentinfo[2]
				stock = attachmentinfo[3]
				side = attachmentinfo[4]
				camo =  attachmentinfo[5]
			else
				toprail = ""
				muzzle = ""
				stock = ""
				side = ""
				camo = ""
			end
		end
		if conversion == "" then conversion = "Semi" end

		--perks
		
		local b = GetToolBody()
		if b ~= 0 then
			local magoffset = Vec(-0.025, 0, -0.0125)
			local grenadeoffset = Vec(-0.025, 0.025, 0)
			local boltoffset = Vec(0, 0, 0)
			local selectoroffset = Transform()
			local suppressoroffset = Transform()
			local scopeoffset = Transform()
			local holooffset = Transform()
			local holooffset2 = Transform()
			local railoffset = Transform()
			local magtimer = magoutTimer + maginTimer
			offset = Transform(Vec(0, heightOffset, 0))
			local adsFOV, adsTime = 0, 0
			local defaultTrans = Transform(Vec(0.25, 0.15, 0.25), QuatEuler(0, 0, 0))

			x,y,z,rotx,roty,rotz = -0.2,0.35,-0.5,0,0,0
			if ironsight then
			if grenadelauncher then
				x = 0
				y = 0.45
				z = -0.4
				rotz = 0
			elseif q then
				x = 0.6
				y = 0.1
				z = -0.2
				rotz = 30
			elseif e then
				x = -0.3
				y = 0.4
				z = -0.4
				rotz = -15
			else
				if toprail == "holo" then
					x = 0.275
					y = 0.4375
					z = -0.45
					rotz = 0
				elseif toprail == "" then
					x = 0.275
					y = 0.5
					z = -0.45
					rotz = 0
				elseif toprail == "scope" then
					x = 0.275
					y = 0.4
					z = 0.25
					rotz = -0.25
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
				if toprail == "holo" then
					local gt = GetBodyTransform(GetToolBody())
					local sightcenter = Vec(0.275, -0.4375, -0.7)
					local gunpos = TransformToParentPoint(gt, sightcenter)
					local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
					QueryRejectBody(GetToolBody())
					local hit, dist = QueryRaycast(gunpos, fwdpos, 500, 0, true)
					local hitpoint = VecAdd(gunpos, VecScale(fwdpos, dist))

					local camtrans = GetPlayerCameraTransform()
					local sightdist = VecLength(VecSub(camtrans.pos, gunpos))

					local holopoint = VecAdd(camtrans.pos, VecScale(VecNormalize(VecSub(camtrans.pos, hitpoint)), -sightdist))

					local holotrans = Transform(holopoint, QuatLookAt(camtrans.pos, hitpoint))

					--if VecLength(VecSub(TransformToParentPoint(gt, sightcenter), holopoint)) < 0.08 then
					--	reticle4 = LoadSprite("MOD/assets/img/reticle4.png")
						--DrawSprite(reticle4, holotrans, 0.2, 0.15, 1, 1, 1, 1, true)
					--end
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

			if recoilTimer > 0 then
				recoilTimer = recoilTimer - dt
				boltoffset = Vec(0, 0, recoilTimer*5)
			end
			if recoilTimer2 > 0 then
				recoilTimer2 = recoilTimer2 - (recoilTimer2*0.1+dt)
				-- offset.pos = VecAdd(offset.pos, Vec(0, -recoilTimer2/2, recoilTimer2))
				-- offset.rot = QuatRotateQuat(offset.rot, QuatEuler(recoilTimer2*40, 0, 0))
			end
			local rx, ry, rz, rr1, rr2, rr3 = (rnd2+rnd5)/400, (recoilAngle/-100)-(rnd1+rnd4)/400-recoilTimer2/2, recoilTimer2, recoilAngle + (rnd1+rnd4)/4+recoilTimer2*40, (rnd2+rnd5)/4, (rnd3+rnd6)/4
			-- RECoffset = REC(true, rx, ry, rz, rr1, rr2, rr3)
			-- offset.pos = VecAdd(offset.pos, Vec((rnd2+rnd5)/400, (recoilAngle/-100)-(rnd1+rnd4)/400, 0))
			-- offset.rot = QuatRotateQuat(offset.rot, QuatEuler(recoilAngle + (rnd1+rnd4)/4, (rnd2+rnd5)/4, (rnd3+rnd6)/4))

			if lightTimer > 0 then
				PointLight(toolPos, 1, 0.75, 0.25, (lightTimer/shotDelay)*lightFactor)
				lightTimer = lightTimer - dt
			end

			if magoutTimer < 0 then
				if inventoryenabled then
					name = "Unloaded"
					maxammo = 0
					id = mag
					if id == "mag0-fs-57x28" then name, maxammo = "TCP-57", 20
					elseif id == "mag1-fs-57x28" then name, maxammo = "TCP-57", 33
					elseif id == "mag2-fs-57x28" then name, maxammo = "P17-Drum", 50
					elseif id == "mag3-fs-57x28" then name, maxammo = "P17-Drum", 100
					end
					if mag ~= "none" then
						local newtable = deepcopy(bullettable)
						newtable[ammo] = nil
						SetString("inventory.pickup", mag.."_"..name.."_"..ammoleft.."_"..magtable2[1][3].."_5.7x28_"..table.concat(newtable,"-"))
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
			if maginTimer < 0.25 and not reloadsound2playing and not grenadelauncher then
					PlaySound(reloadsound2, GetPlayerTransform().pos, 0.7, false)
					reloadsound2playing = true
			end
			if magoutTimer > 0 then
				if grenadelauncher then
					grenadeoffset = Vec(-0.025, -magoutTimer*3+0.025, -0.6)
				else
					magoffset = Vec(-0.025, -(0.6-magoutTimer)*4, -0.0125+(0.6-magoutTimer)*2)
				end
				magoutTimer = magoutTimer - dt/reloadFactor*magdrillFactor
			end
			if maginTimer > 0 then
				if grenadelauncher then
					grenadeoffset = Vec(-0.025, 0.025, -0.0125-maginTimer)
				else
					magoffset = Vec(-0.025, -maginTimer*4, -0.0125+maginTimer*2)
				end
				maginTimer = maginTimer - dt/reloadFactor*magdrillFactor
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
					if magoutTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.1, 0.1, 0, -5, 10, -10
					elseif maginTimer > 0 or (reloadTimer > 0 and ammo > 0) then
						x1, y1, z1, rotx1, roty1, rotz1 = 0, 0, 0, -5, 10, 0
					elseif reloadTimer < 0.8 and ammo == 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.25, -0.1, 0, 20, -20, -20
					end
				elseif e then
					if magoutTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0, -0.05, 0, 10, -10, 10
					elseif maginTimer > 0 or (reloadTimer > 0 and ammo > 0) then
						x1, y1, z1, rotx1, roty1, rotz1 = 0, 0, 0, 5, -5, 0
					elseif reloadTimer < 0.8 and ammo == 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0, -0.05, 0, 10, -30, -5
					end
				else
					if magoutTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.3, -0.05, 0, 0, 0, -20
					elseif maginTimer > 0 or (reloadTimer > 0 and ammo > 0) or (reloadTimer > 1 and ammo == 0) then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.5, 0.1, 0, 0, 0, -35
					elseif reloadTimer < 0.8 and ammo == 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.35, 0, 0.15, 10, 5, -10
					end
				end
			else
				if magoutTimer > 0 then
					x1, y1, z1, rotx1, roty1, rotz1 = 0.2, 0, 0.1, 10, -10, -20
				elseif maginTimer > 0 or (reloadTimer > 0 and ammo > 0) then
					x1, y1, z1, rotx1, roty1, rotz1 = 0.15, 0, 0, 5, 10, -10
				elseif reloadTimer < 0.8 and ammo == 0 then
					x1, y1, z1, rotx1, roty1, rotz1 = 0.25, -0.05, 0, 10, 10, -5
				end
			end
			end

			-- RELoffset = REL(reloading, x1, y1, z1, rotx1, roty1, rotz1)
			-- offset.pos = VecAdd(offset.pos, RELoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, RELoffset.rot)

			if (reloadTimer > 0.4 or reloadTimer <= 0) and ammo == 0 and not sliderelease then
				boltoffset = Vec(0, 0, 0.15)
				holooffset = Vec(0, 0, 0.15)
			elseif reloadTimer > 0.2 and ammo == 0 and not sliderelease then
				boltoffset = Vec(0, 0, 0.15)
				holooffset = Vec(0, 0, 0.15)
			elseif ammo == 0 and reloading then
				if reloadTimer < 0.42 and reloadTimer > 0.2 and not cocksound2playing and sliderelease then PlaySound(cocksound2, GetPlayerTransform().pos, 0.7) cocksound2playing = true end
				if reloadTimer < 0.4 and reloadTimer > 0.2 then
					boltoffset = Vec(0, 0, 0.15*(0.4-reloadTimer)/0.2)
					holooffset = Vec(0, 0, 0.15*(0.4-reloadTimer)/0.2)
				elseif reloadTimer < 0.2 and reloadTimer > 0.175 then
					boltoffset = Vec(0, 0, 0.15*(reloadTimer-0.175)/0.025)
					holooffset = Vec(0, 0, 0.15*(reloadTimer-0.175)/0.025)
					cocksound2playing = false
				end
			end

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

			if selectattachmentsTimer > 0 then
				selectattachmentsTimer = selectattachmentsTimer*0.9 - dt/20
			elseif selectattachmentsTimer < 0 then
				selectattachmentsTimer = 0
			end

			local x2, y2, z2, rotx2, roty2, rotz2 = 0, 0, 0, 0, 0, 0
			if inspectTimer > 2.5 then
				x2, y2, z2, rotx2, roty2, rotz2 = -0.1, -0.55, 0.4, 40, 10, -10
			elseif inspectTimer > 1.25 then
				x2, y2, z2, rotx2, roty2, rotz2 = -0.55, -0.55, 0.35, 40, -10, 20
			elseif inspectTimer > 0 then
				x2, y2, z2, rotx2, roty2, rotz2 = 0.2, -0.25, 0.25, 20, 30, 0
			end

			-- INSoffset = INS(inspectTimer > 0, x2, y2, z2, rotx2, roty2, rotz2)
			-- offset.pos = VecAdd(offset.pos, INSoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, INSoffset.rot)

			local x3, y3, z3, rotx3, roty3, rotz3 = 0, 0, 0, 0, 0, 0
			if selectfire == 0 and selectfireTimer <= 0 then
				x3, y3, z3, rotx3, roty3, rotz3 = -0.25, -0.1, -0.1, -20, 20, 10
			elseif KeybindDown(Settings.keybinds.player.sprint) and selectfireTimer <= 0 and not reloading then
				x3, y3, z3, rotx3, roty3, rotz3 = -0.25, -0.1, -0.1, -20, 20, 10
			elseif ironsight and q and selectfireTimer > 0 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0, 0, 0, 0, 0, 0
			elseif ironsight and selectfireTimer > 0  then
				x3, y3, z3, rotx3, roty3, rotz3 = 0.15, 0, 0, 0, 5, -10
			elseif selectfireTimer > 0 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0.4, 0, -0.25, 0, 5, -20
			else
				x3, y3, z3, rotx3, roty3, rotz3 = 0, 0, 0, 0, 0, 0
			end

			-- SELoffset = SEL((selectfireTimer > 0 or selectfire == 0 or KeybindDown(Settings.keybinds.player.sprint)) and not reloading, x3, y3, z3, rotx3, roty3, rotz3)
			-- offset.pos = VecAdd(offset.pos, SELoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, SELoffset.rot)

			offset = ADS(true, adsFOV, adsTime, -x+x1+x2+x3+ATToffset[1]-swingx2/200+swayx*speed/200+swayx2/200, y+y1+y2+y3-math.abs(swingx)/200-swayy*speed/200+ATToffset[2]+swingy2/100+swayy2/200, z+z1+z2+z3+ATToffset[3], rotx+rotx1+rotx2+rotx3+swingy-swingy2+swayy*speed+swayy2+ATToffset[4], roty+roty1+roty2+roty3+swingx-swingx2+swayx*speed+swayx2+ATToffset[5], rotz+rotz1+rotz2+rotz3-swingx+ATToffset[6])

			RECoffset = REC(true, rx, ry, rz, rr1, rr2, rr3)
			offset.pos = VecAdd(offset.pos, RECoffset.pos)
			offset.rot = QuatRotateQuat(offset.rot, RECoffset.rot)

			clothingtype = GetString("savegame.mod.difficulty")
			local bs = GetBodyShapes(GetToolBody())
			for i = 15, 26 do
				SetShapeLocalTransform(bs[i], hideTrans)
			end
			if clothingtype == "peaceful" then
				hand1 = bs[18]
				arm1 = bs[20]
				hand2 = bs[19]
			elseif clothingtype == "normal" then
				hand1 = bs[21]
				arm1 = bs[23]
				hand2 = bs[22]
			elseif clothingtype == "hardcore" then
				hand1 = bs[24]
				arm1 = bs[26]
				hand2 = bs[25]
			else
				hand1 = bs[15]
				arm1 = bs[17]
				hand2 = bs[16]
			end

			SetToolTransform(offset, 0.2)
			toolTrans = GetBodyTransform(b)
			toolPos = TransformToParentPoint(toolTrans, Vec(0.275, -0.6, -2.6))

			if body ~= b then
				local weaponPrefab = "MOD/weapons/guns/Weapons/FiveSeven-"..(camo or "")..".xml"
				body = b
				gunToolShapesPending = true
				end
				if gunToolShapesPending and #GetBodyShapes(b) > 8 then
				gunToolShapesPending = false
				local shapes = GetBodyShapes(b)
				GunNet_FixToolParts(shapes)
				mag0 = shapes[2]
				mag1 = shapes[13]
				mag2 = shapes[14]
				bolt = shapes[3]
				selector = shapes[4]
				suppressor = shapes[5]
				holo = shapes[6]
				holo2 = shapes[7]
				muzzlebreak = shapes[8]
				muzzlebreak2 = shapes[9]
				side1 = shapes[11]
				side2 = shapes[12]
				barrel = shapes[10]
				magTrans = GetShapeLocalTransform(mag0)
				boltTrans = GetShapeLocalTransform(bolt)
				selectorTrans = GetShapeLocalTransform(selector)
				suppressorTrans = GetShapeLocalTransform(suppressor)
				holoTrans = GetShapeLocalTransform(holo)
				holoTrans2 = GetShapeLocalTransform(holo2)
				muzzlebreakTrans = GetShapeLocalTransform(muzzlebreak)
				muzzlebreakTrans2 = GetShapeLocalTransform(muzzlebreak2)
				sideTrans1 = GetShapeLocalTransform(side1)
				sideTrans2 = GetShapeLocalTransform(side2)
				sideTrans3 = GetShapeLocalTransform(side3)
				barrelTrans0 = GetShapeLocalTransform(barrel)
			end

			mt = TransformCopy(magTrans)
			mt.pos = VecAdd(mt.pos, magoffset)

			bt = TransformCopy(boltTrans)
			bt.pos = VecAdd(bt.pos, boltoffset)
			bt2 = TransformCopy(boltTrans2)
			bt2.pos = VecAdd(bt2.pos, boltoffset)

			st = TransformCopy(selectorTrans)
			st.pos = VecAdd(st.pos, selectoroffset)

			spt = TransformCopy(suppressorTrans)
			spt.pos = VecAdd(spt.pos, suppressoroffset)

			sct = TransformCopy(scopeTrans)
			sct.pos = VecAdd(sct.pos, scopeoffset)

			ht = TransformCopy(holoTrans)
			ht.pos = VecAdd(ht.pos, holooffset)
			ht2 = TransformCopy(holoTrans2)
			ht2.pos = VecAdd(ht.pos, holooffset2)

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

			if reloading and ammo == 0 then
				if q and ironsight then
					if reloadTimer < 0.4 and reloadTimer > 0.2 then
						bt2.rot = QuatRotateQuat(bt2.rot, QuatEuler(0, 0, -90*(0.4-reloadTimer)/0.2))
					elseif reloadTimer < 0.2 and reloadTimer > 0.15 then
						bt2.rot = QuatRotateQuat(bt2.rot, QuatEuler(0, 0, -90*(reloadTimer-0.15)/0.05))
					end
				else
					if reloadTimer < 0.4 and reloadTimer > 0.2 then
						bt2.rot = QuatRotateQuat(bt2.rot, QuatEuler(0, 0, 90*(0.4-reloadTimer)/0.2))
					elseif reloadTimer < 0.2 and reloadTimer > 0.15 then
						bt2.rot = QuatRotateQuat(bt2.rot, QuatEuler(0, 0, 90*(reloadTimer-0.15)/0.05))
					end
				end
			end

			if selectfireTimer < 0.4 then
				if selectfire == 1 then
					st.rot = QuatEuler(-65, 0, 0)
					st.pos = VecAdd(st.pos, Vec(-0.025, -0.01, -0.015))
				elseif selectfire == 2 then
					st.rot = QuatEuler(-10, 0, 0)
					st.pos = VecAdd(st.pos, Vec(-0.025, -0.005, -0.045))
				else
					st.rot = QuatEuler(45, 0, 0)
					st.pos = VecAdd(st.pos, Vec(-0.025, 0.025, -0.0625))
				end
			elseif selectfireTimer > 0 then
				if selectfire0 == 1 then
					st.rot = QuatEuler(-65, 0, 0)
					st.pos = VecAdd(st.pos, Vec(-0.025, -0.01, -0.015))
				elseif selectfire0 == 2 then
					st.rot = QuatEuler(-10, 0, 0)
					st.pos = VecAdd(st.pos, Vec(-0.025, -0.005, -0.045))
				else
					st.rot = QuatEuler(45, 0, 0)
					st.pos = VecAdd(st.pos, Vec(-0.025, 0.025, -0.0625))
				end
			end

			muzzlelength = 0




			if muzzle == "muzzle1" then
				spt.pos = VecAdd(spt.pos, Vec(0.025, 0, 0))
				lightFactor = 0.4
				muzzlelength = 0.8
			else
				spt.pos = hidePos
				spt.rot = QuatEuler(0, 0, 0)
				lightFactor = 2
				muzzleFactor = 1
			end
			if muzzle == "muzzle2" then
				mbt.pos = VecAdd(mbt.pos, Vec(0.075, -0.05, 0))
				mbt2.pos = VecAdd(mbt2.pos, Vec(0, 0, 0))
				mbt.rot = QuatEuler(-90, 0, 45)
				lightFactor = 3
				muzzleFactor = 0.75
				muzzlelength = 0.2
			else
				mbt.pos = hidePos
				mbt2.pos = hidePos
				mbt.rot = QuatEuler(0, 0, 0)
				lightFactor = 2
				muzzleFactor = 1
			end
			if toprail == "scope" then
				sct.pos = Vec(0.2, -0.375, -0.9)
			else
				sct.pos = hidePos
			end
			if toprail == "holo" then
				if ammo > 0 then
					ht.pos = VecAdd(ht.pos, Vec(0.025, 0, recoilTimer*2.5))
					ht2.pos = VecAdd(ht2.pos, Vec(0.025, 0.075, -0.025+recoilTimer*2.5))
				else
					ht.pos = VecAdd(ht.pos, Vec(0.025, 0, 0))
					ht2.pos = VecAdd(ht2.pos, Vec(0.025, 0.075, -0.025))
				end
			else
				ht.pos = hidePos
				ht2.pos = hidePos
			end
			if stock == "removed" then
				stt.pos = Vec(0.5, -1, -1.5)
				stt.rot = QuatEuler(-90, -180, 0)
				stockFactor = 2.5
			else
				stt.pos = Vec(0.2, -1, 0.5)
				stt.rot = QuatEuler(-90, 0, 0)
				stockFactor = 1
			end
			rt.pos = Vec(0.175, -0.725, -0.85)

			brt0.pos = VecAdd(brt0.pos, Vec(-0.025, -0.025, 0.005))

			if mag == "" or mag == "mag0-fs-57x28" then
				magsize = 20
				reloadFactor = 1.25
				SetShapeLocalTransform(mag0, Transform(VecAdd(mt.pos, Vec(0, 0, 0)), mt.rot))
				SetShapeLocalTransform(mag1, hideTrans)
				SetShapeLocalTransform(mag2, hideTrans)
			elseif mag == "mag1-fs-57x28" then
				magsize = 33
				reloadFactor = 1.5
				SetShapeLocalTransform(mag1, Transform(VecAdd(mt.pos, Vec(0, -0.25, 0.1)), mt.rot))
				SetShapeLocalTransform(mag0, hideTrans)
				SetShapeLocalTransform(mag2, hideTrans)
			elseif mag == "mag2-fs-57x28" then
				magsize = 50
				reloadFactor = 1.7
				SetShapeLocalTransform(mag2, Transform(VecAdd(mt.pos, Vec(-0.1, -0.35, -0.05)), mt.rot))
				SetShapeLocalTransform(mag0, hideTrans)
				SetShapeLocalTransform(mag1, hideTrans)
			elseif mag == "none" then
				SetShapeLocalTransform(mag0, hideTrans)
				SetShapeLocalTransform(mag1, hideTrans)
				SetShapeLocalTransform(mag2, hideTrans)
			end

			if side == "side1" then
				sdt1.pos = sdt1.pos
			else
				sdt1.pos = hidePos
			end
			if side == "side2" then
				sdt2.pos = VecAdd(sdt2.pos, Vec(0.025, -0.025, 0))
			else
				sdt2.pos = hidePos
			end
			if side == "side3" then
				sdt3.pos = sdt3.pos
			else
				sdt3.pos = hidePos
			end

			if mag == "mag2-fs-57x28" or mag == "mag3" then
				--SetString("savegame.mod.stock", "")
			end

			if guard == "" then
				gdt0.pos = Vec(0.225, -0.625, -1.75)
				gdt0_2.pos = Vec(0.2, -0.7, -1.75)
				guardlength = 0
			else
				gdt0.pos = hidePos
				gdt0_2.pos = hidePos
			end
			if guard == "guard1" then
				gdt1.pos = Vec(0.225, -0.625, -1.75)
				gdt1_2.pos = Vec(0.2, -0.7, -1.75)
				guardlength = -0.2
			else
				gdt1.pos = hidePos
				gdt1_2.pos = hidePos
			end
			if guard == "guard2" then
				gdt2.pos = Vec(0.225, -0.725, -1.75)
				gdt2_2.pos = Vec(0.2, -0.7, -1.75)
				guardlength = 0.3
			else
				gdt2.pos = hidePos
				gdt2_2.pos = hidePos
			end
			accuracyFactor = 1.5

			SetShapeLocalTransform(barrel, brt0)
			SetShapeLocalTransform(bolt, bt)
			SetShapeLocalTransform(selector, st)
			SetShapeLocalTransform(suppressor, spt)
			SetShapeLocalTransform(holo, ht)
			SetShapeLocalTransform(holo2, ht2)
			SetShapeLocalTransform(muzzlebreak, mbt)
			SetShapeLocalTransform(muzzlebreak2, mbt2)
			SetShapeLocalTransform(side1, sdt1)
			SetShapeLocalTransform(side2, sdt2)
		end

		if selectattachments then
			clickedmag = clickedmag1 or clickedmag2 or clickedmag3
			if clickedmag and selectattachments and not KeybindPressed(Settings.keybinds.player.gun_attachment) and not GetBool("level.optionstriggered") then
				Reload()
			end
		end
		if reloading and not clickedmag and selectattachments then
			selectattachments = false
			selectattachmentsTimer = 0.25
		end

		if not selectattachments then
			if (KeybindPressed(Settings.keybinds.player.reload) or clickedmag) and selectfireTimer == 0 then
				if not realistic and (ammo ~= magsize + 1 and not grenadelauncher) or (grenadelauncherammo == 0 and grenadelauncher) and not jammed then
					Reload()
					inspectTimer = 0
				end
			end

			if (InputReleased("r") or clickedmag) and selectfireTimer == 0 and not jammed then
				if realistic and curmagslot ~= nextmagslot and magcheckTimer == 0 then
					Reload()
					inspectTimer = 0
				end
			end
			
			if GetBool("ammobox.refill") then
				SetBool("ammobox.refill", false)
				PlaySound(refillsound, GetPlayerTransform().pos, 1, false)
			end

			if reloading then
				if reloadTimer > 0.4 then
					reloadTimer = reloadTimer - dt/reloadFactor*magdrillFactor*1.25
				elseif reloadTimer > 0 then
					reloadTimer = reloadTimer - dt
				end
				if reloadTimer < 0.35 and not cocksoundplaying and ammo == 0 and not sliderelease then
					cocksoundplaying = true
					PlaySound(cocksound, GetPlayerTransform().pos, 0.7)
				end
				if reloadTimer < 0 then
					cocksoundplaying = false
					if grenadelauncher then
						grenadelauncherammo = 1
					else
						if inventoryenabled then
							if ammo == 0 then
								ammo = nextammo
								bullettable = Split(nextbullet,"-")
							else
								local currentbullettable = bullettable[#bullettable]
								local newbullettable = Split(nextbullet,"-")
								if newbullettable[1] ~= "" then

									table.insert(newbullettable, currentbullettable)
								else
									newbullettable = {currentbullettable}
								end	
								
								bullettable = newbullettable
								ammo = nextammo + 1
							end
							name = "Unloaded"
							maxammo = 0
							id = mag
							if id == "mag0-fs-57x28" then name, maxammo = "TCP-57", 20
							elseif id == "mag1-fs-57x28" then name, maxammo = "TCP-57", 33
							elseif id == "mag2-fs-57x28" then name, maxammo = "P17-Drum", 50
							elseif id == "mag3-fs-57x28" then name, maxammo = "P17-Drum", 100
							end
							local guninfo = Split(GetString("inventory.guns.2.item"), "_")
							guninfo[3] = mag
							guninfo[4] = name
							guninfo[5] = ammo
							guninfo[6] = maxammo
							guninfo[10] = table.concat(bullettable,"-")
							SetString("inventory.guns.2.item", IDBuilder(guninfo))
							SetBool("inventory.update", true)
							curmagslot = 1
						elseif realistic then
							if ammo == 0 then
								ammo = magtable2[curmagslot][2]
							else
								ammo = magtable2[curmagslot][2] + 1
							end
						else
							if ammo == 0 then
								ammo = magsize
							else
								ammo = magsize + 1
							end
						end
					end
					reloadTimer = 0
					reloading = false
					SetBool("inventory.reloading", false)
					PlaySound(inspectsound)
					sliderelease = true
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
		local x2, y2, z2, rotx2, roty2, rotz2 = 0.15, -0.95, -0.85, 0, 0, 0
		if reloading and ammo == 0 and reloadTimer < 0.8 and reloadTimer > 0.2 then
			x2, y2, z2, rotx2, roty2, rotz2 = 0.1, -0.7, -0.2+bt.pos[3], 0, 0, 0
		elseif reloading then
			x2, y2, z2, rotx2, roty2, rotz2 = -0.1+mt.pos[1], 0.05+mt.pos[2], -0.2+mt.pos[3], 0, 0, 0
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

		h2p1l = Vec(0.275, -0.95, -0.75)
		h2p2l = TransformToLocalPoint(btrans, TransformToParentPoint(GetPlayerTransform(), Vec(0.55, 1.1-crouchoffset-lookoffset, 0.9)))
		hnd2 = Transform(h2p1l, QuatRotateQuat(QuatLookAt(h2p2l, h2p1l), QuatEuler(0,90,90)))
		SetShapeLocalTransform(hand2, hnd2)


		sightattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.15, -0.6))
		muzzleattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.35, -1.6))
		stockattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.4, -0.6))
		sideattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.6, -1.25))
		magattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.85, -0.5))
		gripattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.85, -1.4-guardlength))
		barrelattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.65, -1.6))
		guardattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.25, -1.5))

		
	end
end

function client.update(dt)
if IsToolEnabled("gun-fiveseven") and GunInInventory("gun-fiveseven") then
	if inventoryenabled then
			item = GetString("inventory.guns.2.item")
			guninfo = Split(item, "_")
			if #guninfo >= 8 then
				attachmentinfo = Split(guninfo[8], "-")
				toprail = attachmentinfo[1]
				muzzle = attachmentinfo[2]
				stock = attachmentinfo[3]
				side = attachmentinfo[4]
				camo = attachmentinfo[5]
			else
				toprail = ""
				muzzle = ""
				stock = ""
				side = ""
				camo = ""
			end
		end




end
end

function client.draw()
	if not GunInInventory("gun-fiveseven") then return end -- (v2, Phase 2) see gunfunctions.lua
	if gunWantsInteractive then UiMakeInteractive() gunWantsInteractive = false end
	GunNet_DebugParts()
	if GetPlayerTool() == "gun-fiveseven" and GetPlayerVehicle() == 0 or inventoryenabled then

		UiPush()
      UiAlign("center middle")
      UiTranslate(UiCenter(), UiHeight()/2)
      UiFont("bold.ttf", 50)
      UiColor(0.1,0.1,0.1,DrawHitmark)
      UiText("<  +  >")
    UiPop()
    DrawHitmark = DrawHitmark - 0.1

		if not GetBool("level.killcam.active") then
			------HOLO SIGHTS------
			if ironsight then
				drawHoloSight(toprail == "holo", Vec(0.275, -0.4375, -0.7), 0.05+VecLength(GetPlayerVelocity())/100,"MOD/assets/img/holo/" .. holocolors[currentholocolor].. "" .. holoreticles[currentholoreticle].. ".png", 20)
			end
		end

		------IN-GAME UI------
		if not realistic and not GetBool("level.optionstriggered") or inventoryenabled and GetPlayerTool() == "gun-fiveseven" and GetPlayerVehicle() == 0 then
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
					UiText("Infinite".." - "..selectfireText)
				end
			UiPop()
		end
		end
		if realistic and not GetBool("level.optionstriggered") then
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
	if GetPlayerTool() == "gun-fiveseven" and grenadelauncher and not selectattachments then
		UiPush()
			UiTranslate(UiCenter(), UiMiddle())
			UiAlign("center middle")
			UiImage("ui/hud/crosshair-launcher.png")
		UiPop()
	end
	if GetPlayerTool() == "gun-fiveseven" and sideattachment and side == "side3" then
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

	if realistic and selectmag and GetPlayerTool() == "gun-fiveseven" then
		hoverindex=0
		UiPush()
			local x,y,dist=UiWorldToPixel(VecAdd(magattachpoint, Vec(0, 0.3, 0)))
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

	if selectattachments and GetPlayerTool() == "gun-fiveseven" and GetPlayerVehicle() == 0 then
	if hint then drawHint(info) end
	hoverindex=0
		UiPush()
			local x,y,dist=UiWorldToPixel(sightattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					clickedholo = AttachmentButton("toprail","holo",true,{curx,cury},{"Holographic Sight","1x magnification sight for close range combat."})
					UiTranslate(-70,0)
				UiPop()
			end
		UiPop()
		UiPush()
			local x,y,dist=UiWorldToPixel(muzzleattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					clickedmuzzle1 = AttachmentButton("muzzle","muzzle1",true,{curx,cury},{"Suppressor","Suppresses gun noise for sneaky combat."})
					UiTranslate(-70,0)
					curx,cury=curx-70,cury
					clickedmuzzle2 = AttachmentButton("muzzle","muzzle2",true,{curx,cury},{"Compensator","Reduces horizontal recoil, but turns your barrel into a flashbang."})
					UiTranslate(-70,0)
				UiPop()
			end
		UiPop()
		UiPush()
			local x,y,dist=UiWorldToPixel(magattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					clickedmag1 = AttachmentButton("mag","mag1-fs-57x28",true,{curx,cury},{"33rnd Mag","Pew Pew Pew"})
					UiTranslate(-70,0)
					curx,cury=curx-70,cury
					clickedmag2 = AttachmentButton("mag","mag2-fs-57x28",true,{curx,cury},{"50rnd Drum","Pew Pew Pew Pew Pew Pew"})
					UiTranslate(-70,0)
				UiPop()
			end
		UiPop()
		UiPush()
			local x,y,dist=UiWorldToPixel(sideattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					clickedside1 = AttachmentButton("side","side1",true,{curx,cury},{"Laser","A laser that points where you shoot."})
					UiTranslate(-70,0)
					curx,cury=curx-70,cury
					clickedside2 = AttachmentButton("side","side2",true,{curx,cury},{"Flashlight","Lights up the area in front of you."})
					UiTranslate(-70,0)
				UiPop()
			end
		UiPop()
	end
end