#include "gunfunctions.lua"
#include "gunperks.lua"
#include "gunstats.lua"



function init()
	--ammotype = GetString("savegame.mod.ammotype")
	ammotype = "308"

	RegisterTool("gun-scarhg", "TCR-308", "MOD/vox/scargrey.vox", 1)
	SetBool("game.tool.gun-scarhg.enabled", true)
	vox = ("MOD/vox/scargrey.vox")
	GunName = "ScarH"
	Cartridge = "762x51"
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
	damage = 0.125
	gravity = Vec(0, -10, 0)
	hidePos = Vec(0, -200, 0)
	hideTrans = Transform(hidePos,QuatEuler())
	velocity = 850
	drag = 0.1 * 1.7
	maxMomentum = 5
	tracer = false

	recoilVertical = gunstats.scarh.recoilVertical
	recoilHorizontal = gunstats.scarh.recoilHorizontal
	recoilWander = gunstats.scarh.recoilWander

	lvl5armor = 0.2
	lvl4armor = 0.6
	lvl3armor = 0.9
	lvl2armor = 1
	lvl1armor = 1

	inside = {}
	for i = 1,50 do
		inside[i] = {0,0,0,0}
	end
	hoverindex = 0

	--magazine and attachments system
	gunsound = LoadSound("MOD/snd/Weapons/scar/scarh_0.ogg")
	suppressedgunsound = LoadSound("MOD/snd/Weapons/scar/scarh_sup_0.ogg")
	grenadelaunchersound = LoadSound("MOD/snd/Weapons/Handheld/Grenade/grenadelauncher.ogg")
	toprail = GetString("savegame.mod.toprail")
	muzzle = GetString("savegame.mod.muzzle")
	stock = GetString("savegame.mod.stock")
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
		local guninfo = Split(GetString("inventory.guns."..GetInt("inventory.curprimary")..".item"), "_")
		magtable2[1] = {guninfo[3], tonumber(guninfo[5]), tonumber(guninfo[6]), {1,1}, guninfo[10]}
		for i = 1, 8 do
			for j = 1, 15 do
				if GetString("inventory.backpack."..i.."_"..j..".item") ~= "" then
					local maginfo = Split(GetString("inventory.backpack."..i.."_"..j..".item"), "_")
					local magtype, magammo, magammomax = maginfo[1], maginfo[3], maginfo[4]
					if string.sub(magtype, 1, 3) == "mag" and string.sub(magtype, 6, 16) == "scar-762x51" then
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
				if ammotype == "308" then
					magtable2[i][2] = 20
					magtable2[i][3] = 20
				else
					magtable2[i][2] = 30
					magtable2[i][3] = 30
				end
			elseif magslottype == "mag1" then
				magtable2[i][2] = 40
				magtable2[i][3] = 40
			elseif magslottype == "mag2" then
				magtable2[i][2] = 50
				magtable2[i][3] = 50
			elseif magslottype == "mag3" then
				magtable2[i][2] = 100
				magtable2[i][3] = 100
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
	guard = GetString("savegame.mod.guard")
	magnifier = GetString("savegame.mod.magnifier")
	 ]]
	magnified = false
	magnifierFactor = 1

	if inventoryenabled then
		item = GetString("inventory.guns."..GetInt("inventory.curprimary")..".item")
		guninfo = Split(item, "_")
		if #guninfo >= 8 then
			attachmentinfo = Split(guninfo[8], "-")
			toprail = attachmentinfo[1]
			muzzle = attachmentinfo[2]
			-- stock = attachmentinfo[3]
			grip = attachmentinfo[4]
			barrel = attachmentinfo[5]
			side = attachmentinfo[6]
			guard = attachmentinfo[7]
			magnifier = attachmentinfo[8]
			camo = attachmentinfo[9]
		else
			toprail = ""
			muzzle = ""
			-- stock = ""
			grip = ""
			barrel = ""
			side = ""
			guard = ""
			magnifier = ""
			camo = ""
		end
	end

	cocksound = LoadSound("MOD/snd/Weapons/scar/scar_boltrelease.ogg")
	cocksound2 = LoadSound("MOD/snd/scarcharge2.ogg")
	reloadsound = LoadSound("MOD/snd/Weapons/scar/scarh_reload.ogg")
	reloadsound2 = LoadSound("MOD/snd/Weapons/scar/scarh_reload2.ogg")
	dryfiresound = LoadSound("MOD/snd/Weapons/Shared/dryfire.ogg")
	refillsound = LoadSound("MOD/snd/refill.ogg")
	selectsound = LoadSound("MOD/snd/selectorswitch_ar.ogg")
	casingsound = LoadSound("MOD/snd/Weapons/Shared/Shells/sniper_0.ogg")
	uiselect = LoadSound("MOD/snd/uiselect.ogg")
	adsup = LoadSound("MOD/snd/ads_up.ogg")
	adsdown = LoadSound("MOD/snd/ads_down.ogg")
	zoomswitch = LoadSound("MOD/snd/zoomswitch.ogg")
	inspectsound = LoadSound("MOD/snd/Weapons/Shared/Inspect/weapon_inspect_0.ogg")

	reloadTime = 1.7
	shotDelay = 0.092
	spreadTimer = 1.25
	spreadFactor = 1.5
	accuracyFactor = 1
	bipodFactor = 1
	laserFactor = 1
	if not realistic then
		if ammotype == "308" then
			if mag ~= "" and mag ~= "mag2" then mag = "" --[[ SetString("savegame.mod.mag", "") ]] end
			if mag == "" or mag == "mag0" then
				magsize = 20
				reloadFactor = 1
			elseif mag == "mag2" then
				magsize = 50
				reloadFactor = 1.15
			end
		end
		if ammotype == "556" or ammotype == "" then
			if mag == "" then
				magsize = 30
				reloadFactor = 1
			elseif mag == "mag1" then
				magsize = 40
				reloadFactor = 1.15
			elseif mag == "mag2" then
				magsize = 50
				reloadFactor = 1.35
			elseif mag == "mag3" then
				magsize = 100
				reloadFactor = 1.5
			else
				magsize = 20
				reloadFactor = 1
			end
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
	currentbullettype = #bullettable
	barrellength = 0
	guardlength = 0
	fsightFactor = 0
	barrelFactorx = 0.8
	barrelFactory = 1.5
	barrelFactordamage = 1.15
	ammoFactory = 1
	ammoFactordamage = 1
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
	recoilAngle = 0
	recoilFactor = 0
	stockFactor = 0
	muzzleFactor = 0
	muzzlelength = 0
	gripfactorx = 0
	gripfactory = 0
	lightFactor = 1
	recoilMax = 0
	rnd1, rnd2, rnd3, rnd4, rnd5, rnd6 = 0, 0, 0, 0, 0, 0
	lightTimer = 0
	clickedmag = false
	fovTimer = 0
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
	selectfireText = "Semi"

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

	pdamage = 10
	dmgsnd = LoadSound("MOD/snd/dmge.ogg")
	DrawHitmark = 0
	parts = FindTriggers("hitbox",true)
	magdrillFactor = 1
	if GetBool("inventory.magdrills") then
		magdrillFactor = 1.5
	end
	
	if camo == "snakey" then
	vox = "MOD/vox/scarsnakey.vox"
	RegisterTool("gun-scarhg", "TCR-308", vox, 1)
	elseif camo == "grey" then
	vox = "MOD/vox/scargrey.vox"
	RegisterTool("gun-scarhg", "TCR-308", vox, 1)
	end
	-------------------------
	holocolors = {"red","green"}
	currentholocolor = 1
	holoreticles = {"reticle1","reticle1_1","reticle1_2","reticle1_3"}
	currentholoreticle = 1
end

function Shoot(Type)
	local perk = "762x51"
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
	if shootTimer > 0 or ammo == 0 then
		return
	end

	PlaySound(casingsound,GetPlayerTransform().pos,0.6) ShakeCamera(0.45)

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
	local factor = stockFactor*laserFactor*muzzleFactor*gripfactorx*barrelFactorx*ammoFactory*ironsightFactor
	rnd1, rnd2, rnd3, rnd4, rnd5, rnd6 = rnd1+(math.random()-0.5)*factor*recoilWander, rnd2+(math.random()-0.5)*factor*recoilWander, rnd3+(math.random()-0.5)*factor*recoilWander/4, (math.random()-0.5)*factor*recoilHorizontal, (math.random()-0.5)*factor*recoilHorizontal, (math.random()-0.5)*factor*recoilHorizontal/4

	if not ironsight then
		accuracyFactor = 4
	end
	if recoilAngle < recoilMax then
		recoilAngle = recoilAngle + recoilFactor*muzzleFactor*gripfactory*barrelFactory
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

	local barrelend = barrellength + muzzlelength
	SpawnParticle("smoke", TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.25, -0.5, -2.4-barrelend*4/3)), VecAdd(VecScale(dir, 2), GetPlayerVelocity()), 0.2, 0.3)
	ParticleType("plain")
	ParticleTile(5)
	ParticleColor(1, 0.6, 0.4, 1, 0.3, 0.2)
	ParticleRadius(0.2)
	ParticleEmissive(5, 1)
	SpawnParticle(TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.25, -0.5, -2.4-barrelend*4/3)), VecAdd(VecScale(dir, 4), GetPlayerVelocity()), shotDelay/2, 0.3)
	if muzzle == "muzzle1" then
		PlaySound(suppressedgunsound, GetPlayerTransform().pos, 1, false)
	elseif muzzle == "muzzle2" then
		PlaySound(gunsound, GetPlayerTransform().pos, 1, false)
	else
		PlaySound(gunsound, GetPlayerTransform().pos, 0.9, false)
	end

	if not unlimitedammo then
		bullettable[ammo] = nil
		ammo = ammo - 1
		currentbullettype = #bullettable
		if realistic then
			magtable2[curmagslot][2] = ammo
			magtable2[curmagslot][5] = table.concat(bullettable,"-")
			if inventoryenabled then
				name = "Unloaded"
				maxammo = 0
				id = mag
				if id == "mag0-scar-762x51" then name, maxammo = "TCR-20", 20
				elseif id == "mag2-scar-762x51" then name, maxammo = "TCR-50", 50
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

	if selectfire == 2 then
		shootTimer = shotDelay
		recoilTimer = shotDelay
		lightTimer = shotDelay/2
		spreadTimer = spreadTimer + 1.25
	else
		shootTimer = 0
		recoilTimer = shotDelay
		lightTimer = shotDelay/2
		spreadTimer = spreadTimer + 1.25
	end

	if spentcasingsoption then
		SpentCasing()
	end
	local jamrate = 1/400
	if realistic and math.random() < jamrate and ammo > 0 and not inventoryenabled then
		jammed = true
		PlaySound(dryfiresound, GetPlayerTransform().pos, 1, false)
	end

	local pvel = GetPlayerVelocity()
	local prot = QuatToEuler(GetPlayerTransform(true).rot)
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
		recoilAngle = recoilAngle + recoilFactor*muzzleFactor*gripfactory*barrelFactory
	end

	grenadeHandler.shells[grenadeHandler.shellNum] = deepcopy(grenadeHandler.defaultShell)
	loadedShell = grenadeHandler.shells[grenadeHandler.shellNum]
	loadedShell.active = true
	loadedShell.pos = gunpos
	loadedShell.predictedBulletVelocity = VecScale(dir, 0.35*(300/distance))
	grenadeHandler.shellNum = (grenadeHandler.shellNum%#grenadeHandler.shells) + 1

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
			reloadTimer = reloadTime - 0.3
		end
	else
		if ammo == 0 then
			reloadTimer = reloadTime
		else
			reloadTimer = reloadTime - 0.3
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
		-- magoutTimer = 0.6
		if mag == "none" and inventoryenabled then
			PlaySound(inspectsound)
			magoutTimer = 0.1
			reloadTimer = reloadTimer - 0.5
		else
			PlaySound(reloadsound, GetPlayerTransform().pos, 0.7, false)
			magoutTimer = 0.6
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
	local casingpos = TransformToParentPoint(gt, Vec(0.55, -0.45, -1.3))
	local fwdpos = TransformToParentPoint(gt, Vec(6+math.random()*4, -0.45+math.random()*4, -0.8+math.random()*4))
	local direction = VecAdd(GetPlayerVelocity(), VecSub(fwdpos, casingpos))
	casing = Spawn("MOD/vox/riflecasing.xml", Transform(casingpos, QuatEuler(math.random(0, 90), math.random(0, 90), math.random(0, 90))))
	SetBodyVelocity(casing[1], direction)
end

function Laser(active)
		local gt = GetBodyTransform(GetToolBody())
		local gunpos = TransformToParentPoint(gt, Vec(0.325, -0.275, -1.75))
		local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
		QueryRejectBody(GetToolBody())
		local hit, dist = QueryRaycast(gunpos, fwdpos, 500, 0, true)
		local hitpoint = VecAdd(gunpos, VecScale(fwdpos, dist))

		if active then
			SetShapeEmissiveScale(side1, 1)
			PointLight(hitpoint, 1, 0, 0, 0.5)
			DrawLine(gunpos, hitpoint, 1, 0.5, 0.5, 0.25)
			laserFactor = 0.9
		else
			SetShapeEmissiveScale(side1, 0)
			laserFactor = 1
		end
end
function Flashlight(active)
		local gt = GetBodyTransform(GetToolBody())
		local gunpos = TransformToParentPoint(gt, Vec(0.175, -0.625, -1.9))
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

function tick(dt)
	WeaponBackgroundTick(dt)

    unlimitedammo = GetBool("savegame.mod.unlimitedammo")
    checkUnlimitedBulletsValid()


	if inventoryenabled then
		guninfo = Split(GetString("inventory.guns."..GetInt("inventory.curprimary")..".item"),"_")
		if #guninfo > 7 then
			attachmentinfo = Split(guninfo[8],"_")
			if #attachmentinfo > 8 then
				camo = attachmentinfo[9]
			end
		end
	end
	local vox = "MOD/vox/scargrey.vox"
	if camo == "snakey" then
	vox = "MOD/vox/scarsnakey.vox"
	elseif camo == "grey" then
	vox = "MOD/vox/scargrey.vox"
	end
	RegisterTool("gun-scarhg", "TCR-308", vox, 1)

	if inventoryenabled and not reloading then
		item = GetString("inventory.guns."..GetInt("inventory.curprimary")..".item")
		if Split(item, "_")[1] == "gun-scarhg" then
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

	if GetBool("game.tool.gun-scarhg.enabled") then
	
	if inventoryenabled then


		magtable2 = {}
		local guninfo = Split(GetString("inventory.guns."..GetInt("inventory.curprimary")..".item"), "_")
		magtable2[1] = {guninfo[3], tonumber(guninfo[5]), tonumber(guninfo[6]), {1,1}, guninfo[10]}
		for i = 1, 8 do
			for j = 1, 15 do
				if GetString("inventory.backpack."..i.."_"..j..".item") ~= "" then
					local maginfo = Split(GetString("inventory.backpack."..i.."_"..j..".item"), "_")
					local magtype, magammo, magammomax = maginfo[1], maginfo[3], maginfo[4]
					if string.sub(magtype, 6, 16) == "scar-762x51" then
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
		SetString("game.player.tool", "gun-scarhg")
	end

	end

	if GetString("game.player.tool") == "gun-scarhg" and GetPlayerVehicle() == 0 then
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
		if InputDown("usetool") and not reloading and selectfire == 2 and not selectattachments and not selectmag and selectfireTimer == 0 and GetPlayerGrabShape() == 0 and inspectTimer <= 0 and magcheckTimer == 0 and not jammed and jamclearTimer == 0 then
			if grenadelauncherammo > 0 and grenadelauncher then
				ShootGrenade()
			elseif not grenadelauncher and ammo > 0 then
				Shoot(tostring(bullettable[ammo]))
			end
		elseif InputPressed("usetool") and not reloading and selectfire == 1 and not selectattachments and not selectmag and selectfireTimer == 0 and GetPlayerGrabShape() == 0 and inspectTimer <= 0 and magcheckTimer == 0 and not jammed and jamclearTimer == 0 then
			if grenadelauncherammo > 0 and grenadelauncher then
				ShootGrenade()
			elseif not grenadelauncher and ammo > 0 then
				Shoot(tostring(bullettable[ammo]))
				shootTimer = 0.11
			end
		end

		if GetBool("guns.accidental.shoot") and selectfire ~= 0 then
			--DebugPrint("Accidental Shoot")
			Shoot(tostring(bullettable[ammo]))
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

		if InputDown("grab") and selectfire > 0 and selectfireTimer == 0 and not selectattachments and not selectmag and GetPlayerGrabShape() == 0 and not KeybindDown(Settings.keybinds.player.sprint) and magcheckTimer == 0 and jamclearTimer == 0 and magcheckTimer == 0 and jamclearTimer == 0 then
			if InputPressed("grab") then
				PlaySound(adsup, GetPlayerTransform().pos, 1)
			end
			ironsight = true
			inspectTimer = 0
			if scopeTimer < 0.5 and not reloading and not (q or e) and selectfireTimer == 0 then
				scopeTimer = scopeTimer + dt
			end
		end
		if InputReleased("grab")then PlaySound(adsdown, GetPlayerTransform().pos, 1)end
		if not InputDown("grab") then
			ironsight = false
		end
		if selectfire == 0 and selectfireTimer <= 0 then
			ironsight = false
		end
		if (not InputDown("grab") or reloading or q or e or selectfireTimer > 0) and scopeTimer > 0 then scopeTimer = scopeTimer - dt end

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

		-- if InputPressed(meleeKey) and not reloading and not ironsight and shootTimer <= 0 and selectfire > 0 and stock ~= "removed" and not KeybindDown(Settings.keybinds.player.sprint) then
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

		if InputDown("t") and not reloading and selectfire > 0 and selectfireTimer <= 0 and not KeybindDown(Settings.keybinds.player.sprint) and magcheckTimer == 0 and jamclearTimer == 0 or GetBool("level.optionstriggered") then
			if KeybindPressed(Settings.keybinds.player.gun_attachment) and not GetBool("level.optionstriggered") then
				PlaySound(inspectsound)
				selectattachmentsTimer = 0.5
			end
			UiMakeInteractive()
			selectattachments = true
			ironsight = false
			inspectTimer = 0
		end
		if InputReleased("t") and not reloading and selectfire > 0 and selectfireTimer <= 0 and not KeybindDown(Settings.keybinds.player.sprint) then
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
			UiMakeInteractive()
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
			inspectTimer = 0
		end

		--[[ if grip == "grenade_launcher" then
			if InputPressed(grenadeKey) and not reloading then
				grenadelauncher = not grenadelauncher
			end
		else
			grenadelauncher = false
		end ]]

		if KeybindPressed(Settings.keybinds.player.gun_inspect) and not reloading and not KeybindDown(Settings.keybinds.player.sprint) and selectfireTimer <= 0 and not ironsight and selectfire > 0 and not selectattachments and magcheckTimer == 0 and jamclearTimer == 0 then
			if inspectTimer <= 0 then
				inspectTimer = 4
				ironsight = false
			else
				inspectTimer = 0
			end
		end

		if KeybindPressed(Settings.keybinds.player.alt_sight) and magnifier == "g33" then
			magnified = not magnified
			PlaySound(zoomswitch, GetPlayerTransform().pos, 1)
		elseif magnifier == "" then
			magnified = false
		end
		if magnified then
			magnifierFactor = 3
		else
			magnifierFactor = 1
		end

		if ironsight and not (q or e) and not reloading and toprail == "sight4" then
			local pvel = GetPlayerVelocity()
			local prot = QuatToEuler(GetPlayerTransform(true).rot)
			local ppos = GetPlayerTransform().pos
			local camrot = QuatToEuler(GetPlayerCameraTransform().rot)
			local ppos2 = Transform()
			ppos2.rot = QuatEuler(prot[1], camrot[2], camrot[3])
			ppos2.rot = QuatRotateQuat(ppos2.rot, QuatEuler(InputValue("mousedy")*GetFloat("options.input.sensitivity")*0.001, InputValue("mousedx")*GetFloat("options.input.sensitivity")*0.001*math.cos(camrot[1]*0.01745329), 0))
			ppos2.pos = ppos
			SetPlayerTransform(ppos2, true)
			SetPlayerVelocity(pvel)
		end


		------WEAPON FUNCTIONS AND ANIMATIONS------
		if selectfire == 2 then
			selectfireText = "Full"
		elseif selectfire == 1 then
			selectfireText = "Semi"
		else
			selectfireText = "Safe"
		end

		if shootTimer <= 0 then
			recoverySpeed = 0.085
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
			recoilFactor = recoilVertical*stockFactor*ammoFactory
		else
			recoilFactor = recoilVertical*stockFactor*ammoFactory*1.75
		end

		if ironsight then
			recoilMax = gunstats.scarh.recoilMax*muzzleFactor*gripfactory*barrelFactory*stockFactor*ammoFactory
		else
			recoilMax = gunstats.scarh.recoilMax*1.5*muzzleFactor*gripfactory*barrelFactory*stockFactor*ammoFactory
		end

		if GetBool("inventory.magdrills") then
			magdrillFactor = 1.5
		else
			magdrillFactor = 1
		end

		if toprail == "scope" and not (q or e) then
			spreadFactor = 1.25
		elseif toprail == "holo" and not (q or e) then
			spreadFactor = 1.5
		elseif toprail == "sight3" and not (q or e) then
			spreadFactor = 1.75
		elseif toprail == "sight4" and not (q or e) then
			spreadFactor = 1
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
		guard = GetString("savegame.mod.guard")
		ammotype = GetString("savegame.mod.ammotype") ]]
		ammotype = "308"
		if ammotype == "" then
			--SetString("savegame.mod.ammotype", "556")
			maxMomentum = 3
			ammoFactory = 1
			ammoFactordamage = 1
		elseif ammotype == "308" then
			maxMomentum = 5
			ammoFactory = 1.8
			ammoFactordamage = 1.2
		else
			maxMomentum = 5
			ammoFactory = 1
			ammoFactordamage = 1
		end
		-- magnifier = GetString("savegame.mod.magnifier")
		if inventoryenabled then
			item = GetString("inventory.guns."..GetInt("inventory.curprimary")..".item")
			guninfo = Split(item, "_")
			if #guninfo >= 8 then
				attachmentinfo = Split(guninfo[8], "-")
				toprail = attachmentinfo[1]
				muzzle = attachmentinfo[2]
				-- stock = attachmentinfo[3]
				grip = attachmentinfo[4]
				barrel = attachmentinfo[5]
				side = attachmentinfo[6]
				guard = attachmentinfo[7]
				magnifier = attachmentinfo[8]
				camo = attachmentinfo[9]
			else
				toprail = ""
				muzzle = ""
				-- stock = ""
				grip = ""
				barrel = ""
				side = ""
				guard = ""
				magnifier = ""
				camo = ""
			end
		end

		--perks
		

		local b = GetToolBody()
		if b ~= 0 then
			local magoffset = Vec(0, 0, 0)
			local grenadeoffset = Vec(-0.025, 0.025, 0)
			local boltoffset = Vec(-0.025, 0, 0)
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

			x,y,z,rotx,roty,rotz = -0.15,0.1,0,0,0,0
			if InputDown("crouch") then y = 0.3 end
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
				y = 0.3
				z = 0.1
				rotz = -15
			else
				if toprail == "holo" then
					x = 0.275
					y = 0.1875
					z = 0.1
					rotz = 0
				elseif toprail == "" then
					x = 0.275
					y = 0.1375
					z = 0.1
					rotz = 0
				elseif toprail == "removed" then
					x = 0.275
					y = 0.15
					z = 0.1
					rotz = 0
				elseif toprail == "scope" then
					x = 0.275
					y = 0.175
					z = 0.4
					rotz = 0.1
				elseif toprail == "sight3" then
					x = 0.275
					y = 0.175
					z = 0.2
					rotz = 0.1
				elseif toprail == "sight4" then
					x = 0.275
					y = 0.15
					z = 0.2
					rotz = 0.1
				end
			end

			if reloading or selectfireTimer > 0 then
				adsFOV, adsTime = 0, 0.15
			elseif not (q or e or grenadelauncher) then
				if toprail == "" then
					adsFOV, adsTime = 10, 0.15
				elseif toprail == "scope" then
					adsFOV, adsTime = 80, 0.25
				elseif toprail == "holo" then
					adsFOV, adsTime = 20, 0.1
				elseif toprail == "sight3" then
					adsFOV, adsTime = 10, 0.1
				elseif toprail == "sight4" then
					adsFOV, adsTime = 100, 0.3
				end
			elseif grenadelauncher then
				adsFOV, adsTime = 10, 0.15
			else
				adsFOV, adsTime = 0, 0.15
			end
			end

			-- offset = ADS(ironsight, adsFOV*magnifierFactor, adsTime, -x, y, z, rotz)

			local injuredarms = false
			for i = 1, 6 do
				if GetTagValue(parts[i], "hitbox") == "LARM" or GetTagValue(parts[i], "hitbox") == "RARM" then
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
				--[[btrans = GetBodyTransform(b)
				if toprail == "holo" and not (q or e) then
					local gt = GetBodyTransform(GetToolBody())
					local sightcenter = Vec(0.275, -0.1875, -1)
					local gunpos = TransformToParentPoint(gt, sightcenter)
					local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
					local hit, dist = QueryRaycast(gunpos, fwdpos, 500, 0, true)
					local hitpoint = VecAdd(gunpos, VecScale(fwdpos, dist))

					local camtrans = GetPlayerCameraTransform()
					local sightdist = VecLength(VecSub(camtrans.pos, gunpos))

					local holopoint = VecAdd(camtrans.pos, VecScale(VecNormalize(VecSub(camtrans.pos, hitpoint)), -sightdist))

					local holotrans = Transform(holopoint, QuatLookAt(camtrans.pos, hitpoint))

					if VecLength(VecSub(TransformToParentPoint(gt, sightcenter), holopoint)) < 0.1 then
						reticle1 = LoadSprite("MOD/img/reticle1.png")
						DrawSprite(reticle1, holotrans, 0.025, 0.025, 1, 1, 1, 1, true)
					end
				end--]]
			end

			local speed = math.clamp(VecLength(GetPlayerVelocity()), 0.8*bipodFactor^4, 10)
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
			-- offset.rot = QuatRotateQuat(offset.rot, QuatEuler(math.sin(2.1*GetTime())/9*bipodFactor^4,  math.sin(1.3*GetTime())/6*bipodFactor^4, 0))
			-- offset.pos = VecAdd(offset.pos, Vec(math.sin(1.1*GetTime())/360*bipodFactor^4,  math.sin(0.7*GetTime())/240*bipodFactor^4, 0))

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
							MakeHole(stockPos, 1)
						else
							MakeHole(stockPos, 0.3)
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
				-- offset.pos = VecAdd(offset.pos, Vec(0, -recoilTimer/16, recoilTimer/3))
				-- offset.rot = QuatRotateQuat(offset.rot, QuatEuler((recoilTimer-0.02)*6, 0, 0))

				recoilTimer = recoilTimer - dt
				boltoffset = Vec(-0.025, 0, recoilTimer*6)
			end
			local rx, ry, rz, rr1, rr2, rr3 = (rnd2+rnd5)/400, (recoilAngle/-200)-(rnd1+rnd4)/400-recoilTimer/2, recoilTimer, recoilAngle+(rnd1+rnd4)/4+(recoilTimer-0.02)*8, (rnd2+rnd5)/4, 0
			-- RECoffset = REC(true, rx, ry, rz, rr1, rr2, rr3)
			-- offset.pos = VecAdd(offset.pos, RECoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, RECoffset.rot)

			if jammed and jamclearTimer < 1 and jamclearTimer > 0.7 then
				boltoffset = Vec(0, 0, (1-jamclearTimer)*1.8)
				if not cocksoundplaying then
					cocksoundplaying = true
					PlaySound(cocksound2, GetPlayerTransform().pos, 0.45)
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
					if id == "mag0-scar-762x51" then name, maxammo = "TCR-20", 20
					elseif id == "mag2-scar-762x51" then name, maxammo = "TCR-50", 50
					end
					if mag ~= "none" then
						local newtable = deepcopy(bullettable)
						newtable[ammo] = nil
						SetString("inventory.pickup", mag.."_"..name.."_"..ammoleft.."_"..magtable2[1][3].."_7.62x51_"..table.concat(newtable,"-"))
					end
					SetString("inventory.remove", magtable2[nextmagslot][4][1].."_"..magtable2[nextmagslot][4][2])
					nextammo = magtable2[nextmagslot][2]
					nextbullet = magtable2[nextmagslot][5]
					mag = magtable2[nextmagslot][1]
				end

				maginTimer = 0.6
				magoutTimer = 0
				reloadsound2playing = false
				PlaySound(inspectsound)
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
					if magoutTimer > 0 or magcheckTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.1, 0.1, 0, -5, 10, -10
					elseif maginTimer > 0 or reloadTimer > 0.8 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0, 0, 0, -5, 10, 0
					elseif reloadTimer < 0.8 and ammo == 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.1, -0.1, -0.1, 0, -15, -20
					end
				elseif e then
					if magoutTimer > 0 or magcheckTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = -0.05, 0.1, 0.1, 0, -10, -10
					elseif maginTimer > 0 or (reloadTimer > 0.6 and ammo > 0) then
						x1, y1, z1, rotx1, roty1, rotz1 = 0, 0.15, 0.1, -5, -5, -15
					elseif reloadTimer < 0.8 and ammo == 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.1, -0.2, 0, 2, 10, -5
					end
				else
					if magoutTimer > 0 or magcheckTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.3, -0.05, -0.2, 5, 0, -15
					elseif maginTimer > 0 or (reloadTimer > 0.6 and ammo > 0) or (reloadTimer > 0.8 and ammo == 0) then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.5, 0.15, -0.15, 0, 10, -20
					elseif reloadTimer < 0.8 and ammo == 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.55, -0.2, -0.1, 10, 10, -10
					end
				end
			else
				if magoutTimer > 0.5 then
					x1, y1, z1, rotx1, roty1, rotz1 = 0.05, -0.1, 0, -5, 5, -5
				elseif magoutTimer > 0 or magcheckTimer > 0 then
					x1, y1, z1, rotx1, roty1, rotz1 = 0.3, 0.05, 0, 5, 20, -15
				elseif maginTimer > 0 or (reloadTimer > 0.6 and ammo > 0) then
					x1, y1, z1, rotx1, roty1, rotz1 = 0.2, -0.2, 0.15, 20, 15, -10
				elseif reloadTimer < 0.8 and ammo == 0 then
					x1, y1, z1, rotx1, roty1, rotz1 = 0.25, -0.05, 0, 10, 10, -5
				end
			end
			end

			-- RELoffset = REL(reloading or magcheckTimer > 0, x1, y1, z1, rotx1, roty1, rotz1)
			-- offset.pos = VecAdd(offset.pos, RELoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, RELoffset.rot)

			if reloadTimer > 0.2 and reloading and ammo == 0 then
				boltoffset = Vec(-0.025, 0, 0.34)
			elseif ammo == 0 and not reloading then
				boltoffset = Vec(-0.025, 0, 0.34)
			end

			ATToffset = {0,0,0,0,0,0}
			if not GetBool("level.optionstriggered") then
			-- if selectattachmentsTimer > 0 and selectattachments then
			-- 	local t1 = (0.5 - selectattachmentsTimer)/0.5
			-- 	ATToffset = VecAdd(offset.pos, Vec(1*t1, 0, -0.8*t1*180/GetInt("options.gfx.fov")))
			-- 	ATToffset.rot = QuatRotateQuat(offset.rot, QuatEuler(10*t1, 75*t1, -10*t1))
			-- elseif selectattachmentsTimer > 0 and not selectattachments then
			-- 	local t2 = selectattachmentsTimer/0.25
			-- 	ATToffset.pos = VecAdd(offset.pos, Vec(1*t2, 0, -0.8*t2*180/GetInt("options.gfx.fov")))
			-- 	ATToffset.rot = QuatRotateQuat(offset.rot, QuatEuler(10*t2, 75*t2, -10*t2))
			-- elseif selectattachments then
			-- 	ATToffset.pos = VecAdd(offset.pos, Vec(1, 0, -0.8*180/GetInt("options.gfx.fov")))
			-- 	ATToffset.rot = QuatRotateQuat(offset.rot, QuatEuler(10, 75, -10))
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
			elseif jamclearTimer > 0 then
				x2, y2, z2, rotx2, roty2, rotz2 = -0.1, -0.4, 0, 30, -40, 15
			end

			-- INSoffset = INS(inspectTimer > 0 or jamclearTimer > 0, x2, y2, z2, rotx2, roty2, rotz2)
			-- offset.pos = VecAdd(offset.pos, INSoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, INSoffset.rot)

			local x3, y3, z3, rotx3, roty3, rotz3 = 0, 0, 0, 0, 0, 0
			if (selectfire == 0 or KeybindDown(Settings.keybinds.player.sprint)) and selectfireTimer <= 0 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0.2, 0.25, -0.2, -20, 60, 0
			elseif ironsight and q and selectfireTimer > 0 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0, 0, 0, 0, 0, 0
			elseif ironsight and selectfireTimer > 0  then
				x3, y3, z3, rotx3, roty3, rotz3 = 0.15, 0, 0, 0, 5, -10
			elseif selectfireTimer > 0 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0.4, 0, -0.25, 0, 5, -20
			else
				x3, y3, z3, rotx3, roty3, rotz3 = 0, 0, 0, 0, 0, 0
			end

			-- if not GetBool("level.optionstriggered") then SELoffset = SEL((selectfireTimer > 0 or selectfire == 0 or KeybindDown(Settings.keybinds.player.sprint)) and not reloading, x3, y3, z3, rotx3, roty3, rotz3)
			-- offset.pos = VecAdd(offset.pos, SELoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, SELoffset.rot) end

			offset = ADS(true, adsFOV*magnifierFactor, adsTime, -x+x1+x2+x3+ATToffset[1]-swingx2/200+swayx*speed/200+swayx2/200, y+y1+y2+y3-math.abs(swingx)/200-swayy*speed/200+ATToffset[2]+swingy2/100+swayy2/200, z+z1+z2+z3+ATToffset[3], rotx+rotx1+rotx2+rotx3+swingy-swingy2+swayy*speed+swayy2+ATToffset[4], roty+roty1+roty2+roty3+swingx-swingx2+swayx*speed+swayx2+ATToffset[5], rotz+rotz1+rotz2+rotz3-swingx+ATToffset[6])

			RECoffset = REC(true, rx, ry, rz, rr1, rr2, rr3)
			offset.pos = VecAdd(offset.pos, RECoffset.pos)
			offset.rot = QuatRotateQuat(offset.rot, RECoffset.rot)

			clothingtype = GetString("savegame.mod.difficulty")
			local bs = GetBodyShapes(GetToolBody())
			for i = 50, 61 do
				SetShapeLocalTransform(bs[i], hideTrans)
			end
			if clothingtype == "peaceful" then
				hand1 = bs[53]
				arm1 = bs[55]
				hand2 = bs[54]
			elseif clothingtype == "normal" then
				hand1 = bs[56]
				arm1 = bs[58]
				hand2 = bs[57]
			elseif clothingtype == "hardcore" then
				hand1 = bs[59]
				arm1 = bs[61]
				hand2 = bs[60]
			else
				hand1 = bs[50]
				arm1 = bs[52]
				hand2 = bs[51]
			end

			SetToolTransform(offset, 0.2)
			toolTrans = GetBodyTransform(b)
			toolPos = TransformToParentPoint(toolTrans, Vec(0.275, -0.6, -2.6))

			if body ~= b then
				body = b
				local shapes = GetBodyShapes(b)
				mag0 = shapes[2]
				mag0_308 = shapes[44]
				bolt = shapes[3]
				bolt2 = shapes[30]
				selector = shapes[4]
				suppressor = shapes[5]
				scope = shapes[6]
				holo = shapes[7]
				holo2 = shapes[8]
				rail = shapes[9]
				stock1 = shapes[10]
				stock2 = shapes[48]
				muzzlebreak = shapes[11]
				muzzlebreak2 = shapes[12]
				mag1 = shapes[13]
				mag2 = shapes[14]
				mag2_308 = shapes[49]
				mag3 = shapes[15]
				mag5 = shapes[64]
				mag4 = shapes[40]
				grip1 = shapes[16]
				grip1_2 = shapes[17]
				grip2 = shapes[18]
				grip3 = shapes[22]
				grip3_1 = shapes[23]
				grip3_2 = shapes[24]
				grip4 = shapes[25]
				barrel0 = shapes[19]
				barrel1 = shapes[20]
				barrel2 = shapes[21]
				side1 = shapes[26]
				side2 = shapes[27]
				side3 = shapes[28]
				grenade = shapes[29]
				guard0 = shapes[31]
				guard0_2 = shapes[32]
				guard1 = shapes[33]
				guard1_2 = shapes[34]
				guard2 = shapes[35]
				guard2_2 = shapes[36]
				fwdassist = shapes[37]
				scope2 = shapes[38]
				scope2_2 = shapes[39]
				fsight = shapes[41]
				rsight = shapes[42]
				rsight2 = shapes[43]
				magwell = shapes[45]
				g33 = shapes[46]
				g33_2 = shapes[47]
				mag6 = shapes[65]
				mag7 = shapes[66]
				mag8 = shapes[67]
				magTrans = GetShapeLocalTransform(mag0)
				boltTrans = GetShapeLocalTransform(bolt)
				boltTrans2 = GetShapeLocalTransform(bolt2)
				selectorTrans = GetShapeLocalTransform(selector)
				suppressorTrans = GetShapeLocalTransform(suppressor)
				scopeTrans = GetShapeLocalTransform(scope)
				holoTrans = GetShapeLocalTransform(holo)
				holoTrans2 = GetShapeLocalTransform(holo2)
				g33Trans = GetShapeLocalTransform(g33)
				railTrans = GetShapeLocalTransform(rail)
				stock1Trans = GetShapeLocalTransform(stock1)
				stock2Trans = GetShapeLocalTransform(stock2)
				muzzlebreakTrans = GetShapeLocalTransform(muzzlebreak)
				muzzlebreakTrans2 = GetShapeLocalTransform(muzzlebreak2)
				gripTrans = GetShapeLocalTransform(grip1)
				barrelTrans0 = GetShapeLocalTransform(barrel0)
				barrelTrans1 = GetShapeLocalTransform(barrel1)
				barrelTrans2 = GetShapeLocalTransform(barrel2)
				sideTrans1 = GetShapeLocalTransform(side1)
				sideTrans2 = GetShapeLocalTransform(side2)
				sideTrans3 = GetShapeLocalTransform(side3)
				grenadeTrans = GetShapeLocalTransform(grenade)
				guardTrans0 = GetShapeLocalTransform(guard0)
				fwdassistTrans = GetShapeLocalTransform(fwdassist)
				scopeTrans2 = GetShapeLocalTransform(scope2)
				fsightTrans = GetShapeLocalTransform(fsight)
				rsightTrans = GetShapeLocalTransform(rsight)
				rsightTrans2 = GetShapeLocalTransform(rsight2)
				magwellTrans = GetShapeLocalTransform(magwell)
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
			ht2.pos = VecAdd(ht.pos, holooffset)

			sct2 = TransformCopy(scopeTrans2)
			sct2_2 = TransformCopy(scopeTrans2)

			g33t = TransformCopy(g33Trans)
			g33t2 = TransformCopy(g33Trans)

			fst = TransformCopy(fsightTrans)
			rst = TransformCopy(rsightTrans)
			rst2 = TransformCopy(rsightTrans2)

			rt = TransformCopy(railTrans)
			rt.pos = VecAdd(rt.pos, railoffset)

			stt1 = TransformCopy(stock1Trans)
			stt2 = TransformCopy(stock2Trans)

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

			fdat = TransformCopy(fwdassistTrans)
			mwt = TransformCopy(magwellTrans)

			-- if ammo == 0 and ((e and ironsight) or not ironsight) and reloading and reloadTimer > 0.35 and reloadTimer < 0.45 then
			-- 	bt2.pos = VecAdd(bt2.pos, Vec(0, 0, 0.2*(0.45-reloadTimer)/0.1))
			-- elseif ammo == 0 and ((e and ironsight) or not ironsight) and reloading and reloadTimer > 0.3 and reloadTimer < 0.35 then
			-- 	bt2.pos = VecAdd(bt2.pos, Vec(0, 0, 0.2))
			-- elseif ammo == 0 and ((e and ironsight) or not ironsight) and reloading and reloadTimer > 0.25 and reloadTimer < 0.3 then
			-- 	bt2.pos = VecAdd(bt2.pos, Vec(0, 0, 0.2*(reloadTimer-0.25)/0.05))
			-- end

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
				spt.pos = VecAdd(spt.pos, Vec(0.075, -0.05, -barrellength-fsightFactor))
				spt.rot = QuatEuler(-90, 0, 45)
				lightFactor = 0.4
				muzzlelength = 0.6
			else
				spt.pos = hidePos
				spt.rot = QuatEuler(0, 0, 0)
				lightFactor = 2
				muzzleFactor = 1
			end
			if muzzle == "muzzle2" then
				mbt.pos = VecAdd(mbt.pos, Vec(0.075, -0.05, -barrellength-fsightFactor))
				mbt2.pos = VecAdd(mbt2.pos, Vec(0, 0, -barrellength-fsightFactor))
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

			if toprail ~= "" then
				fst.rot = QuatRotateQuat(fst.rot, QuatEuler(-90, 0, 0))
				fst.pos = VecAdd(fst.pos, Vec(0, 0.05, 0))
				if barrel == "barrel1" then fst.pos = hidePos end
			end

			if guard == "" then
				fst.pos = fst.pos
			elseif guard == "guard1" then
				fst.pos = VecAdd(fst.pos, Vec(0, 0, 0.3))
			elseif guard == "guard2" then
				fst.pos = VecAdd(fst.pos, Vec(0, 0, -0.3))
			end
			if toprail ~= "" then
				rst2.pos = hidePos
			end
			rst.pos = hidePos
			fsightFactor = 0.25

			if toprail == "scope" and (not ironsight or reloading or scopeTimer < 0.5 or q or e) then
				sct.pos = Vec(0.2, -0.35, -0.8)
			else
				sct.pos = hidePos
			end
			if toprail == "holo" then
				ht.pos = Vec(0.175, -0.35, -0.95)
				ht2.pos = Vec(0.2, -0.325, -0.96)
			else
				ht.pos = hidePos
				ht2.pos = hidePos
			end
			if toprail == "sight4" and (not ironsight or reloading or scopeTimer < 0.5 or q or e) then
				sct2.pos = Vec(0.175, -0.35, -0.55)
				sct2_2.pos = Vec(0.2, -0.275, -0.55)
			else
				sct2.pos = hidePos
				sct2_2.pos = hidePos
			end
			if magnifier == "g33" then
				g33t.pos = Vec(0.175, -0.425+0.075, -0.675)
				if magnified then
					g33t2.pos = Vec(0.2, -0.3375+0.075, -0.475)
				else
					g33t2.pos = Vec(0.35, -0.1875+0.075, -0.475)
					g33t2.rot = QuatRotateQuat(g33t2.rot, QuatEuler(0, 90, 0))
				end
			else
				g33t.pos = hidePos
				g33t2.pos = hidePos
			end
			if stock == "removed" then
				stt1.pos = Vec(0.575, -0.95, -1.15)
				stt1.rot = QuatEuler(-90, -180, 0)
				stt2.pos = Vec(0.6, -0.925, -1.149)
				stt2.rot = QuatEuler(-90, -180, 0)
				stockFactor = 5
			else
				stt1.pos = Vec(0.2, -0.95, 0.35)
				stt1.rot = QuatEuler(-90, 0, 0)
				stt2.pos = Vec(0.175, -0.925, 0.349)
				stt2.rot = QuatEuler(-90, 0, 0)
				stockFactor = 1
			end
			rt.pos = VecAdd(rt.pos, Vec(-0.025, -0.025, -0.001))
			fdat.pos = VecAdd(fdat.pos, Vec(-0.01, 0, 0.02))
			fdat.rot = QuatRotateQuat(fdat.rot, QuatEuler(0, 0, 45))

			if ammotype ~= "308" then
				mwt.pos = hidePos
			end

				SetShapeLocalTransform(mag0, hideTrans)
				SetShapeLocalTransform(mag0_308, hideTrans)
				SetShapeLocalTransform(mag1, hideTrans)
				SetShapeLocalTransform(mag2, hideTrans)
				SetShapeLocalTransform(mag2_308, hideTrans)
				SetShapeLocalTransform(mag3, hideTrans)
				SetShapeLocalTransform(mag4, hideTrans)
				SetShapeLocalTransform(mag5, hideTrans)
				SetShapeLocalTransform(mag6, hideTrans)
				SetShapeLocalTransform(mag7, hideTrans)
				SetShapeLocalTransform(mag8, hideTrans)
			if mag == "" or mag == "mag0-scar-762x51" then
				if ammotype == "308" then
					magsize = 20
					reloadFactor = 1.5
					SetShapeLocalTransform(mag0_308, Transform(VecAdd(mt.pos, Vec(-0.025, 0.2, 0.025)), mt.rot))
				else
					magsize = 30
					reloadFactor = 1.4
					SetShapeLocalTransform(mag0, Transform(VecAdd(mt.pos, Vec(-0.025, 0.1, 0.025)), mt.rot))
				end
			elseif mag == "mag1-scar-556" then
				magsize = 40
				reloadFactor = 1.55
				SetShapeLocalTransform(mag1, Transform(VecAdd(mt.pos, Vec(-0.025, 0, 0.025)), mt.rot))
			elseif mag == "mag2-scar-762x51" then
				if ammotype == "308" then
					magsize = 50
					reloadFactor = 1.9
					SetShapeLocalTransform(mag2_308, Transform(VecAdd(mt.pos, Vec(-0.175, 0.1, 0.075)), mt.rot))
				else
					magsize = 60
					reloadFactor = 1.8
					SetShapeLocalTransform(mag2, Transform(VecAdd(mt.pos, Vec(-0.175, 0.1, 0.075)), mt.rot))
				end
			elseif mag == "mag3-scar-762x51" then
				magsize = 100
				reloadFactor = 2.3
				SetShapeLocalTransform(mag3, Transform(VecAdd(mt.pos, Vec(-0.475, 0.1, -0.02)), QuatRotateQuat(mt.rot, QuatEuler(10, 0, 0))))
			elseif mag == "mag4-ar-556" then
				magsize = 20
				reloadFactor = 1.3
				SetShapeLocalTransform(mag4, Transform(VecAdd(mt.pos, Vec(-0.025, 0.2, 0.025)), mt.rot))
			elseif mag == "mag5-ar-556" then
				magsize = 60
				reloadFactor = 1.7
				SetShapeLocalTransform(mag5, Transform(VecAdd(mt.pos, Vec(-0.025, 0.2, 0.025)), mt.rot))
			end

			if ammotype == "308" and not inventoryenabled then if mag ~= "" and mag ~= "mag2" then mag = "" --[[ SetString("savegame.mod.mag", "") ]] end end

			if grip == "grip1" then
				gripfactorx = 0.85
				gripfactory = 0.7
				gt1.pos = Vec(0.2, -0.75, -1.625-guardlength)
				gt1_2.pos = Vec(0.225, -0.95, -1.65-guardlength)
			else
				gt1.pos = hidePos
				gt1_2.pos = hidePos
			end
			if grip == "grip2" then
				gripfactorx = 0.7
				gripfactory = 0.85
				gt2.pos = Vec(0.225, -0.8, -1.5-guardlength)
			else
				gt2.pos = hidePos
			end
			if grip == "grip3" then
				local querypos = TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.25, -0.6, -2-barrellength*4/3))
				QueryRejectBody(GetToolBody())
				local hit, dist = QueryRaycast(querypos, Vec(0, -2, 0), 5, 0.2)
				local bipodded = (InputDown("crouch") or dist < 0.4) and selectfire > 0 and VecLength(GetPlayerVelocity()) < 0.1
				if bipodded then
					gripfactorx = 0.4
					gripfactory = 0.4
					bipodFactor = 0.5
					gt3_1.pos = Vec(0.4, -1.35, -1.95-guardlength)
					gt3_2.pos = Vec(0.05, -1.325, -1.95-guardlength)
					gt3_1.rot = QuatEuler(0, 0, 10)
					gt3_2.rot = QuatEuler(0, 0, -10)
				else
					gripfactorx = 1
					gripfactory = 1
					bipodFactor = 1
					gt3_1.pos = Vec(0.3, -0.675, -2.65-guardlength)
					gt3_2.pos = Vec(0.15, -0.675, -2.65-guardlength)
					gt3_1.rot = QuatEuler(90, 0, 0)
					gt3_2.rot = QuatEuler(90, 0, 0)
				end
				gt3.pos = Vec(0.225, -0.725, -1.85-guardlength)
				
			else
				gt3.pos = hidePos
				gt3_1.pos = hidePos
				gt3_2.pos = hidePos
			end
			if grip == "grenade_launcher" then
				gripfactorx = 1.1
				gripfactory = 1.1
				glt.pos = Vec(0.2, -0.9, -1.4)
			else
				glt.pos = hidePos
			end
			if grip == "" then
				gripfactorx = 1
				gripfactory = 1
			end

			if barrel == "" then
				barrelFactorx = 1
				barrelFactory = 1
				barrelFactordamage = 1
				accuracyFactor = 0.5*bipodFactor
				barrellength = 0.05
				brt0.pos = VecAdd(brt0.pos, Vec(0, 0, -fsightFactor))
				if guard == "guard2" then
					--SetString("savegame.mod.guard", "")
				end
			else
				brt0.pos = hidePos
			end
			if barrel == "barrel1" then
				barrelFactorx = 1.2
				barrelFactory = 0.8
				barrelFactordamage = 1
				accuracyFactor = 0.7*bipodFactor
				barrellength = -0.25
				brt1.pos = VecAdd(brt1.pos, Vec(0, 0, -fsightFactor))
				if guard == "" or guard == "guard2" then
					--SetString("savegame.mod.guard", "guard1")
				end
			else
				brt1.pos = hidePos
			end
			if barrel == "barrel2" then
				barrelFactorx = 0.8
				barrelFactory = 1.2
				barrelFactordamage = 1.15
				accuracyFactor = 0.3*bipodFactor
				barrellength = 0.35
				brt2.pos = VecAdd(brt2.pos, Vec(0, 0, -fsightFactor))
			else
				brt2.pos = hidePos
			end

			if side == "side1" then
				sdt1.pos = VecAdd(sdt1.pos, Vec(0, 0, -guardlength))
			else
				sdt1.pos = hidePos
			end
			if side == "side2" then
				sdt2.pos = VecAdd(sdt2.pos, Vec(0.025, 0, -guardlength))
			else
				sdt2.pos = hidePos
			end
			if side == "side3" then
				sdt3.pos = sdt3.pos
			else
				sdt3.pos = hidePos
			end

			if mag == "mag3" then
				--SetString("savegame.mod.stock", "")
			end
			if toprail ~= "holo" then
				--SetString("savegame.mod.magnifier", "")
			end

			if guard == "" then
				gdt0.pos = Vec(0.175, -0.625, -1.35)
				gdt0_2.pos = Vec(0.2, -0.6, -1.351)
				guardlength = 0
			else
				gdt0.pos = hidePos
				gdt0_2.pos = hidePos
			end
			if guard == "guard1" then
				gdt1.pos = Vec(0.175, -0.625, -1.35)
				gdt1_2.pos = Vec(0.2, -0.6, -1.351)
				guardlength = -0.1
			else
				gdt1.pos = hidePos
				gdt1_2.pos = hidePos
			end
			if guard == "guard2" then
				gdt2.pos = Vec(0.175, -0.625, -1.35)
				gdt2_2.pos = Vec(0.2, -0.6, -1.351)
				guardlength = 0.1
			else
				gdt2.pos = hidePos
				gdt2_2.pos = hidePos
			end

			SetShapeLocalTransform(bolt, bt)
			SetShapeLocalTransform(bolt2, bt2)
			SetShapeLocalTransform(selector, st)
			SetShapeLocalTransform(suppressor, spt)
			SetShapeLocalTransform(scope, sct)
			SetShapeLocalTransform(holo, ht)
			SetShapeLocalTransform(holo2, ht2)
			SetShapeLocalTransform(scope2, sct2)
			SetShapeLocalTransform(scope2_2, sct2_2)
			SetShapeLocalTransform(g33, g33t)
			SetShapeLocalTransform(g33_2, g33t2)
			SetShapeLocalTransform(fsight, fst)
			SetShapeLocalTransform(rsight, rst)
			SetShapeLocalTransform(rsight2, rst2)
			SetShapeLocalTransform(rail, rt)
			SetShapeLocalTransform(stock1, stt1)
			SetShapeLocalTransform(stock2, stt2)
			SetShapeLocalTransform(muzzlebreak, mbt)
			SetShapeLocalTransform(muzzlebreak2, mbt2)
			SetShapeLocalTransform(grip1, gt1)
			SetShapeLocalTransform(grip1_2, gt1_2)
			SetShapeLocalTransform(grip2, gt2)
			SetShapeLocalTransform(grip3, gt3)
			SetShapeLocalTransform(grip3_1, gt3_1)
			SetShapeLocalTransform(grip3_2, gt3_2)
			SetShapeLocalTransform(grip4, glt)
			SetShapeLocalTransform(barrel0, brt0)
			SetShapeLocalTransform(barrel1, brt1)
			SetShapeLocalTransform(barrel2, brt2)
			SetShapeLocalTransform(side1, sdt1)
			SetShapeLocalTransform(side2, sdt2)
			SetShapeLocalTransform(side3, sdt3)
			SetShapeLocalTransform(grenade, grt)
			SetShapeLocalTransform(guard0, gdt0)
			SetShapeLocalTransform(guard0_2, gdt0_2)
			SetShapeLocalTransform(guard1, gdt1)
			SetShapeLocalTransform(guard1_2, gdt1_2)
			SetShapeLocalTransform(guard2, gdt2)
			SetShapeLocalTransform(guard2_2, gdt2_2)
			SetShapeLocalTransform(fwdassist, fdat)
			SetShapeLocalTransform(magwell, mwt)
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
			if (KeybindPressed(Settings.keybinds.player.reload) or clickedmag) and selectfireTimer == 0 and not jammed then
				if not realistic and (ammo ~= magsize + 1 and not grenadelauncher) or (grenadelauncherammo == 0 and grenadelauncher) then
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
				mags = mags + 1
				PlaySound(refillsound, GetPlayerTransform().pos, 1, false)
			end

			if reloading then
				if reloadTimer > 0.4 then
					reloadTimer = reloadTimer - dt/reloadFactor*magdrillFactor
				elseif reloadTimer > 0 and not ((e and ironsight) or not ironsight) then
					reloadTimer = reloadTimer - dt*2
				elseif reloadTimer > 0 and ((e and ironsight) or not ironsight) then
					reloadTimer = reloadTimer - dt
				end
				-- if (e and ironsight) or not ironsight then
				-- 	if reloadTimer < 0.6 and not cocksoundplaying and ammo == 0 then
				-- 		cocksoundplaying = true
				-- 		PlaySound(cocksound2, GetPlayerTransform().pos, 0.8)
				-- 	end
				-- else
					if reloadTimer < 0.25 and not cocksoundplaying and ammo == 0 then
						cocksoundplaying = true
						PlaySound(cocksound, GetPlayerTransform().pos, 0.5)
						ADSImpulse(0.03, 0.02, 0, 0, 0, -2)
					end
				-- end
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
							if id == "mag0-scar-762x51" then name, maxammo = "TCR-20", 20
							elseif id == "mag2-scar-762x51" then name, maxammo = "TCR-50", 50
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
		local x2, y2, z2, rotx2, roty2, rotz2 = 0.175, -0.75, -1.8-guardlength, 0, 0, 0
		if reloading and ammo == 0 and reloadTimer < 0.3 and reloadTimer > 0.2 then
			x2, y2, z2, rotx2, roty2, rotz2 = 0.125, -0.5, -0.75+bt2.pos[3], 0, 0, 0
		elseif (reloading and reloadTimer > 0.2 and ammo == 0) or reloading and ammo > 0 then
			x2, y2, z2, rotx2, roty2, rotz2 = -0.05+mt.pos[1], 0.5+mt.pos[2], -0.15+mt.pos[3], 0, 0, 0
		elseif selectfireTimer > 0 then
			 x2, y2, z2, rotx2, roty2, rotz2 = 0.175, -0.825, -0.9, 0, 0, 0
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

		h2p1l = Vec(0.275, -0.95, -0.85)
		h2p2l = TransformToLocalPoint(btrans, TransformToParentPoint(GetPlayerTransform(), Vec(0.55, 1.1-crouchoffset-lookoffset, 0.9)))
		hnd2 = Transform(h2p1l, QuatRotateQuat(QuatLookAt(h2p2l, h2p1l), QuatEuler(0,90,90)))
		SetShapeLocalTransform(hand2, hnd2)


		sightattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.05, -0.5))
		muzzleattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.35, -2.5-barrellength))
		stockattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.4, -0.6))
		sideattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.45, -1.65))
		magattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.8, -0.9))
		magattachpoint2 = TransformToParentPoint(btrans, Vec(0.25, -0.7, -1.3))
		gripattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.85, -1.4-guardlength))
		barrelattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.65, -1.6))
		guardattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.25, -1.5))
		magnifierattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.25, -0.7))

		
	end
end

function draw()
	if GetString("game.player.tool") == "gun-scarhg" and GetPlayerVehicle() == 0 then


	if not GetBool("level.killcam.active") then


		------HOLO SIGHTS------
		if ironsight then
			drawHoloSight(toprail == "holo", Vec(0.275, -0.1875, -1), 0.05+VecLength(GetPlayerVelocity())/100, "MOD/img/holo/" .. holocolors[currentholocolor].. "" .. holoreticles[currentholoreticle].. ".png", 20)
		end


		------SCOPE RETICLE------
		if toprail == "scope" and ironsight and not reloading and scopeTimer >= 0.5 and not (q or e) then
			local gt = GetBodyTransform(GetToolBody())
			local sightcenter = Vec(0.275, -0.175, -1.8)
			local sightrear = Vec(0.275, -0.175, -1.4)
			local gunpos = TransformToParentPoint(gt, sightcenter)
			local rearpos = TransformToParentPoint(gt, sightrear)
			local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
			-- local hit, dist = QueryRaycast(gunpos, fwdpos, 500, 0, true)
			local dist = 500
			local hitpoint = VecAdd(gunpos, VecScale(fwdpos, dist))

			local camtrans = GetPlayerCameraTransform()
			local sightdist = VecLength(VecSub(camtrans.pos, gunpos))

			local holopoint = VecAdd(camtrans.pos, VecScale(VecNormalize(VecSub(camtrans.pos, hitpoint)), -sightdist))
			UiPush()
				local w, h = UiGetImageSize("MOD/img/reticle2.png")
				local x, y = UiWorldToPixel(hitpoint)
				UiTranslate(x-w/2, y-h/2)
				UiImage("MOD/img/reticle2.png")
				UiPush()
					UiTranslate(0, h)
					UiImage("MOD/img/black.png")
					UiTranslate(0, h)
					UiImage("MOD/img/black.png")
					UiTranslate(0, h)
					UiImage("MOD/img/black.png")
				UiPop()
				UiPush()
					UiTranslate(0, -h)
					UiImage("MOD/img/black.png")
				UiPop()
			UiPop()
			UiPush()
				UiAlign("center middle")
				local w, h = UiWidth(), UiHeight()
				local iw, ih = UiGetImageSize("MOD/img/reticleoutline.png")
				local x, y = UiWorldToPixel(rearpos)
				x = math.clamp(x,w/2-200,w/2+200)
				y = math.clamp(y,h/2-100,10000)
				UiTranslate(-(x-w), -(y-h))
				UiImage("MOD/img/reticleoutline.png")
				UiTranslate(0, ih)
				UiImage("MOD/img/black.png")
				UiTranslate(0, ih)
				UiImage("MOD/img/black.png")
				UiTranslate(0, ih)
				UiImage("MOD/img/black.png")
				UiTranslate(0, ih)
				UiImage("MOD/img/black.png")
			UiPop()
		elseif toprail == "sight4" and ironsight and not reloading and scopeTimer >= 0.5 and not (q or e) then
			local gt = GetBodyTransform(GetToolBody())
			local sightcenter = Vec(0.275, -0.142, -1.8)
			local sightrear = Vec(0.275, -0.142, -1.4)
			local gunpos = TransformToParentPoint(gt, sightcenter)
			local rearpos = TransformToParentPoint(gt, sightrear)
			local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
			-- local hit, dist = QueryRaycast(gunpos, fwdpos, 500, 0, true)
			local dist = 500
			local hitpoint = VecAdd(gunpos, VecScale(fwdpos, dist))

			local camtrans = GetPlayerCameraTransform()
			local sightdist = VecLength(VecSub(camtrans.pos, gunpos))

			local holopoint = VecAdd(camtrans.pos, VecScale(VecNormalize(VecSub(camtrans.pos, hitpoint)), -sightdist))
			UiPush()
				local w, h = UiGetImageSize("MOD/img/reticle2.png")
				local x, y = UiWorldToPixel(hitpoint)
				UiTranslate(x-w/2, y-h/2)
				UiImage("MOD/img/reticle3.png")
				UiPush()
					UiTranslate(0, h)
					UiImage("MOD/img/black.png")
					UiTranslate(0, h)
					UiImage("MOD/img/black.png")
					UiTranslate(0, h)
					UiImage("MOD/img/black.png")
				UiPop()
				UiPush()
					UiTranslate(0, -h)
					UiImage("MOD/img/black.png")
				UiPop()
			UiPop()
			UiPush()
				UiAlign("center middle")
				local w, h = UiWidth(), UiHeight()
				local iw, ih = UiGetImageSize("MOD/img/reticleoutline.png")
				local x, y = UiWorldToPixel(rearpos)
				x = math.clamp(x,w/2-200,w/2+200)
				y = math.clamp(y,h/2-100,10000)
				UiTranslate(-(x-w), -(y-h))
				UiImage("MOD/img/reticleoutline.png")
				UiTranslate(0, ih)
				UiImage("MOD/img/black.png")
				UiTranslate(0, ih)
				UiImage("MOD/img/black.png")
				UiTranslate(0, ih)
				UiImage("MOD/img/black.png")
				UiTranslate(0, ih)
				UiImage("MOD/img/black.png")
			UiPop()
		end
	end

			

		------IN-GAME UI------
		if not realistic and not GetBool("level.optionstriggered") or inventoryenabled and GetString("game.player.tool") == "gun-scarhg" and GetPlayerVehicle() == 0 then
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
						UiText(ammo.."/"..magtable2[curmagslot][3].." - "..selectfireText.." - "..bullettable[ammo])
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
	if GetString("game.player.tool") == "gun-scarhg" and grenadelauncher and not selectattachments then
		UiPush()
			UiTranslate(UiCenter(), UiMiddle())
			UiAlign("center middle")
			UiImage("ui/hud/crosshair-launcher.png")
		UiPop()
	end
	if GetString("game.player.tool") == "gun-scarhg" and sideattachment and side == "side3" then
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

	if realistic and selectmag and GetString("game.player.tool") == "gun-scarhg" then
		hoverindex=0
		UiPush()
			local x,y,dist=UiWorldToPixel(magattachpoint2)
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
	if selectattachments and GetString("game.player.tool") == "gun-scarhg" and GetPlayerVehicle() == 0 then
	hoverindex=0
		UiPush()
			local x,y,dist=UiWorldToPixel(sightattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					curx,cury=curx-70,cury
					clickedholo = AttachmentButton("toprail","removed",true,{curx,cury},{"Remove Iron Sights","Removes small flip-up iron sights."})
					UiTranslate(-70,0)
					clickedscope = AttachmentButton("toprail","scope",true,{curx,cury},{"Scope","3x magnification sight for medium range combat."})
					UiTranslate(-70,0)
					curx,cury=curx-70,cury
					clickedholo = AttachmentButton("toprail","holo",true,{curx,cury},{"Holographic Sight","1x magnification sight for close range combat."})
					UiTranslate(-70,0)
					UiAlign("center middle")
					clickedscope = AttachmentButton("toprail","sight3",true,{curx,cury},{"Scope","1x magnification sight for close range combat."})
					UiTranslate(-70,0)
					curx,cury=curx-70,cury
					clickedholo = AttachmentButton("toprail","sight4",true,{curx,cury},{"Precision Scope","8x magnification sight for long range combat."})
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
					curx,cury=curx-70,cury
					clickedside3 = AttachmentButton("side","side3",true,{curx,cury},{"Rangefinder","Displays the range to your target."})
					UiTranslate(-70,0)
				UiPop()
			end
		UiPop()
		if not realistic then
		UiPush()
			local x,y,dist=UiWorldToPixel(magattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					if ammotype ~= "308" then
					clickedmag4 = AttachmentButton("mag","mag4",true,{curx,cury},{"20rnd Mag","Pew Pew"})
					UiTranslate(-70,0)
					clickedmag1 = AttachmentButton("mag","mag1",true,{curx,cury},{"40rnd Mag","Pew Pew Pew"})
					UiTranslate(-70,0)
					curx,cury=curx-70,cury
					end
					clickedmag2 = AttachmentButton("mag","mag2",true,{curx,cury},{"50rnd Drum","Pew Pew Pew Pew Pew Pew"})
					UiTranslate(-70,0)
					curx,cury=curx-70,cury
					if ammotype ~= "308" then
					clickedmag3 = AttachmentButton("mag","mag3",true,{curx,cury},{"100rnd Double Drum","Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew Pew"})
					end
				UiPop()
			end
		UiPop()
		end
		UiPush()
			local x,y,dist=UiWorldToPixel(gripattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					clickedgrip1 = AttachmentButton("grip","grip1",true,{curx,cury},{"Vertical Grip","Decreased vertical recoil."})
					UiTranslate(-70,0)
					curx,cury=curx-70,cury
					clickedgrip2 = AttachmentButton("grip","grip2",true,{curx,cury},{"Angled Grip","Decreased horizontal recoil."})
					UiTranslate(-70,0)
					curx,cury=curx-70,cury
					clickedgrip3 = AttachmentButton("grip","grip3",true,{curx,cury},{"Bipod","Increased accuracy while crouching or resting the gun on a ledge."})
					UiTranslate(-70,0)
					curx,cury=curx-70,cury
					--clickedgrip4 = AttachmentButton("grip","grenade_launcher",true,{curx,cury},{"GP-25","Grenade launcher for increased collateral damage."})
					UiTranslate(-70,0)
				UiPop()
			end
		UiPop()
		UiPush()
			local x,y,dist=UiWorldToPixel(barrelattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					clickedbarrel1 = AttachmentButton("barrel","barrel1",true,{curx,cury},{"Carbine Barrel","Decreased accuracy but less vertical recoil."})
					UiTranslate(-100,0)
					curx,cury=curx-70,cury
					clickedbarrel2 = AttachmentButton("barrel","barrel2",true,{curx,cury},{"Heavy Barrel","Increased accuracy and damage but more vertical recoil."})
					UiTranslate(-70,0)
				UiPop()
			end
		UiPop()
		UiPush()
			local x,y,dist=UiWorldToPixel(guardattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					clickedguard1 = AttachmentButton("guard","guard1",true,{curx,cury},{"Short Guard","For carbine barrel."})
				UiPop()
			end
		UiPop()
		UiPush()
			local x,y,dist=UiWorldToPixel(magnifierattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					if toprail == "holo" then
						clickedmagnifier1 = AttachmentButton("magnifier","g33",true,{curx,cury},{"Thermal Magnifier","Foldable 3x magnifier for close range optics that shows heat signatures. Press 'Z' to fold/unfold."})
					end
					UiTranslate(-100,0)
				UiPop()
			end
		UiPop()
	end
	end
	if selectattachments and GetString("game.player.tool") == "gun-scarhg" and GetPlayerVehicle() == 0 or GetBool("level.optionstriggered") and GetString("game.player.tool") == "gun-scarhg" then
	hoverindex=0
	UiPush()
		local x,y,dist=UiWorldToPixel(stockattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
				UiAlign("center middle")
				if not KeybindDown(Settings.keybinds.player.sprint) then
					clickedstockremoved = AttachmentButton("stock","removed",true,{curx,cury},{"Fold Stock","Folds stock for a smaller profile weapon."})
				end
				UiTranslate(-70,0)
			UiPop()
		end
	UiPop()
	end
	if hint and (selectattachments or KeybindDown(Settings.keybinds.player.reload) and heldrTimer > 0.2) then drawHint(info) end


	------OPTIONS UI------
	if GetBool("level.optionstriggered") and GetString("game.player.tool") == "gun-scarhg" then
	UiPush()
		UiAlign("center middle")
		UiTranslate(UiCenter(), 70)
		UiFont("bold.ttf", 60)
		UiText("WEAPON MODDING")
	UiPop()
	end
	
	if GetBool("level.optionstriggered") and GetString("game.player.tool") == "gun-scarhg" then

	UiAlign("center middle")
	UiTranslate(300, 250)
	UiFont("bold.ttf", 48)
	ammotype = GetString("savegame.mod.ammotype")
	local ammotext = "L"
	if ammotype == "308" then
		ammotext = "H"
	end
	UiText("gun-scarh-"..ammotext)
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

	UiTranslate(0, 100)
	UiPush()
		local curx,cury=120,635
		UiAlign("center middle")
		UiTranslate(50,0)
		clickedammo1 = AttachmentButton("ammotype","556",true,{curx,cury},{"5.56x45","Smaller, high velocity round that does less damage to target."})
		UiTranslate(-100,0)
		clickedammo3 = AttachmentButton("ammotype","308",true,{curx,cury},{"7.62x51","Larger, higher velocity round that does more damage to target."})
	UiPop()
	if GetString("savegame.mod.ammotype") == "" then
		--SetString("savegame.mod.ammotype", "556")
	end

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
		if ammotype == "308" then
			UiTranslate(-60, 150)
			MagButton2("mag0", 1, 2, "20rnd Mag")
			UiTranslate(90, 0)
			MagButton2("mag2", 2, 2, "50rnd Drum")
		else
			UiPush()
			UiTranslate(-210, 150)
			MagButton2("mag4", 1, 2, "20rnd Mag")
			UiTranslate(60, 0)
			MagButton2("mag0", 1, 2, "30rnd Mag")
			UiTranslate(60, 0)
			MagButton2("mag1", 1, 2, "40rnd Mag")
			UiTranslate(90, 0)
			MagButton2("mag2", 2, 2, "60rnd Drum")
			UiTranslate(150, 0)
			MagButton2("mag3", 3, 2, "100rnd Double Drum")
			UiPop()
		end
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
				if ammotype == "308" and slots[i][j][1] ~= "mag0" and slots[i][j][1] ~= "mag2" and slots[i][j][1] ~= "" then
					clearItem({slots[i][j], i, j})
					slots[i][j][1] = ""
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
		UiTranslate(0, 240)
	end

	UiPush()
		UiTranslate(800+optionsx*100, -80)
		UiFont("bold.ttf", 26)
		UiTranslate(-120, 70)
		UiText("Horizontal Recoil: "..round(recoilHorizontal*stockFactor*laserFactor*muzzleFactor*gripfactorx*barrelFactorx*ammoFactory, 2))
		UiTranslate(260, 0)
		UiText("Vertical Recoil: "..round(recoilFactor*muzzleFactor*gripfactory*barrelFactory*ammoFactory, 2))
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