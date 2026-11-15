#version 2
#include "script/include/player.lua"
#include "gunfunctions.lua"
#include "gunperks.lua"
#include "gunstats.lua"
#include "gunnet.lua"



function server.init()
	RegisterTool("gun-sawedoff", "Qasira", "MOD/assets/vox/sawedoff.vox", 2)
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
	GunName = "SawedOff"
	Cartridge = "12ga"	
	WeaponInit()
	damage = 0.1
	gravity = Vec(0, -10, 0)
	hidePos = Vec(0, -200, 0)
	hideTrans = Transform(hidePos,QuatEuler())
	velocity = 200
	drag = 0.1 * 2
	maxMomentum = 1.1
	tracer = false

	recoilVertical = gunstats.sawedoff.recoilVertical
	recoilHorizontal = gunstats.sawedoff.recoilHorizontal
	recoilWander = gunstats.sawedoff.recoilWander

	--armor pen
	lvl5armor = 0
	lvl4armor = 0
	lvl3armor = 0
	lvl2armor = 0.35
	lvl1armor = 0.5

	inside = {}
	for i = 1,50 do
		inside[i] = {0,0,0,0}
	end
	hoverindex = 0

	gunsound = LoadSound("MOD/assets/snd/Weapons/mp43/mp43_0.ogg")
	suppressedgunsound = LoadSound("MOD/assets/snd/aksuppressed.ogg")
	grenadelaunchersound = LoadSound("MOD/assets/snd/Weapons/Handheld/Grenade/grenadelauncher.ogg")
	toprail = GetString("savegame.mod.toprail")
	muzzle = GetString("savegame.mod.muzzle")
	stock = "removed"
	barrel = "barrel1"
	choke = GetString("savegame.mod.choke")

	if inventoryenabled then
		item = GetString("inventory.guns.2.item")
		guninfo = Split(item, "_")
		if #guninfo >= 8 then
			attachmentinfo = Split(guninfo[8], "-")
			toprail = attachmentinfo[1]
			muzzle = attachmentinfo[2]
			stock = "removed"
			barrel = "barrel1"
			choke = attachmentinfo[5]
		else
			toprail = ""
			muzzle = ""
			stock = "removed"
			barrel = "barrel1"
			choke = ""
		end
	end

	mag = "mag0"
	maxMomentum = 1.1
	pelletSpread = 16
	pelletAmount = 8
	pelletDamage = damage

	--realistic = GetBool("savegame.mod.realistic")
	realistic = true
	inventoryenabled = true

	reloadsound = LoadSound("MOD/assets/snd/Weapons/mp43/mp43_open.ogg")
	reloadsound2 = LoadSound("MOD/assets/snd/Weapons/mp43/mp43_close.ogg")
	clipsound = LoadSound("MOD/assets/snd/clip.ogg")
	bulletsound = LoadSound("MOD/assets/snd/Weapons/mp43/mp43_load.ogg")
	dryfiresound = LoadSound("MOD/assets/snd/Weapons/Shared/dryfire.ogg")
	refillsound = LoadSound("MOD/assets/snd/refill.ogg")
	selectsound = LoadSound("MOD/assets/snd/selectorswitch.ogg")
	casingsound = LoadSound("MOD/assets/snd/Weapons/Shared/Shells/shotgun_0.ogg")
	uiselect = LoadSound("MOD/assets/snd/uiselect.ogg")
	adsup = LoadSound("MOD/assets/snd/ads_up.ogg")
	adsdown = LoadSound("MOD/assets/snd/ads_down.ogg")
	inspectsound = LoadSound("MOD/assets/snd/Weapons/Shared/Inspect/weapon_inspect_0.ogg")

	reloadTime = 2.4
	shotDelay = 0.1
	spreadTimer = 1.25
	spreadFactor = 1.5
	accuracyFactor = 1
	magsize = 2
	reloadFactor = 1
	barrellength = 0
	barrelFactorx = 0.8
	barrelFactory = 1
	barrelFactordamage = 1
	barrelFactorspread = 1
	ammo = magsize
	bullettable = ""
	if inventoryenabled then
		initammo = false
	end
	reserveammo = GetInt("inventory.ammocount_12ga")
	grenadelauncherammo = 1
	mags = 2
	reloading = false
	reloadcancelled = false
	ironsight = false
	ejected = false
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
	stockFactor = 1
	muzzleFactor = 1
	gripfactorx = 1
	gripfactory = 1
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
	cocksoundplaying = false
	reloadsound2playing = true
	selectsoundplaying = false
	selectattachments = false
	selectattachmentsTimer = 0
	inspectTimer = 0
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

	pdamage = 2
	dmgsnd = LoadSound("MOD/assets/snd/dmge.ogg")
	DrawHitmark = 0
	parts = FindTriggers("localhitbox",true)
	magdrillFactor = 1
	if GetBool("inventory.magdrills") then
		magdrillFactor = 1.5
	end
end

function FireRound(Type)

	local perk = "12ga"
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
	local pelletSpread = perktable["pelletSpread"]
	local pelletAmount = perktable["pelletAmount"]
	local incendiary = perktable["incendiary"] or false
	if shootTimer > 0 or ammo == 0 then
		return
	end

	ShakeCamera(0.425)

	aimpos, hit, distance = GetAimPos()

	local gt = GetBodyTransform(GetToolBody())
	if ammo == 1 then
		barrelx = 0.35
	else
		barrelx = 0.2
	end
	local fwdpos = TransformToParentPoint(gt, Vec(barrelx, -0.6, -100))
	local gunpos = TransformToParentPoint(gt, Vec(barrelx, -0.6, -0.7))
	dir = VecNormalize(VecSub(fwdpos, gunpos))

	local ironsightFactor = 1
	if not ironsight then
		ironsightFactor = 2.5
	end

	local maxSpread = InputDown("crouch") and 3 or 6
	if ironsight then maxSpread = maxSpread / 3 end
	local factor = stockFactor*laserFactor*muzzleFactor*gripfactorx*barrelFactorx*ironsightFactor
	rnd1, rnd2, rnd3, rnd4, rnd5, rnd6 = rnd1+(math.random()-0.5)*factor*recoilWander, rnd2+(math.random()-0.5)*factor*recoilWander, rnd3+(math.random()-0.5)*factor*recoilWander/4, (math.random()-0.5)*factor*recoilHorizontal, (math.random()-0.5)*factor*recoilHorizontal, (math.random()-0.5)*factor*recoilHorizontal/4

	if not ironsight then
		accuracyFactor = 4
	end
	if recoilAngle < recoilMax then
		recoilAngle = recoilAngle + recoilFactor*muzzleFactor*gripfactory*barrelFactory
	end

	for i = 1, pelletAmount do
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
	loadedShell.pelletamount = pelletAmount
	loadedShell.pelletspread = pelletSpread
	loadedShell.incendiary = incendiary
	loadedShell.active = true
	loadedShell.pos = gunpos
	loadedShell.momentum = maxMomentum
	loadedShell.predictedBulletVelocity = VecScale(dir, velocity*barrelFactory)
	projectileHandler.shellNum = (projectileHandler.shellNum%#projectileHandler.shells) + 1

	--loadedShell.predictedBulletVelocity = VecAdd(loadedShell.predictedBulletVelocity, Vec((math.random()-0.5)*accuracyFactor*2, (math.random()-0.5)*accuracyFactor*2, (math.random()-0.5)*accuracyFactor*2))
	loadedShell.predictedBulletVelocity = VecAdd(loadedShell.predictedBulletVelocity, Vec((math.random()-0.5)*pelletSpread*barrelFactorspread,(math.random()-0.5)*pelletSpread*barrelFactorspread,(math.random()-0.5)*pelletSpread*barrelFactorspread))
	loadedShell.factor = barrelFactordamage or 1
	loadedShell.active = false -- simulated by gunnet.lua (client visuals + server world)
	GunNet_Fire(loadedShell, muzzle == "muzzle1" and "MOD/assets/snd/aksuppressed.ogg" or "MOD/assets/snd/Weapons/mp43/mp43_0.ogg", 0.7)
	end

	SpawnParticle("smoke", TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(barrelx, -0.4, 0.2)), VecAdd(VecScale(dir, 0.02), GetPlayerVelocity()), 0.3, 0.3)
	ParticleType("plain")
	ParticleTile(5)
	ParticleColor(1, 0.6, 0.4, 1, 0.3, 0.2)
	ParticleRadius(0.1)
	ParticleEmissive(5, 1)
	SpawnParticle(TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(barrelx, -0.4, -3.2)), VecAdd(VecScale(dir, 0.04), GetPlayerVelocity()), 0.2, 0.3)
	if muzzle == "muzzle1" then
		PlaySound(suppressedgunsound, GetPlayerTransform().pos, 1, false)
	else
		PlaySound(gunsound, GetPlayerTransform().pos, 1, false)
	end

	if not unlimitedammo then
		ammo = ammo - 1
		bullettable[#bullettable] = nil
		if realistic then
			if inventoryenabled then
				guninfo[5] = ammo
				guninfo[6] = magsize
				guninfo[10] = table.concat(bullettable,"-")
				SetString("inventory.guns.2.item", IDBuilder(guninfo))
				SetBool("inventory.update", true)
			end
		end
	end

	if selectfire == 1 then
		if ammo > 0 then
			shootTimer = shotDelay
		end
		recoilTimer = shotDelay
		recoilTimer2 = shotDelay*2
		lightTimer = shotDelay/2
		spreadTimer = spreadTimer + 1.25
	else
		shootTimer = 0
		recoilTimer = shotDelay
		recoilTimer2 = shotDelay*2
		lightTimer = shotDelay/2
		spreadTimer = spreadTimer + 1.25
	end
end

function ShootGrenade()
	if shootTimer > 0 or grenadelauncherammo == 0 then
		return
	end

	aimpos, hit, distance = GetAimPos()

	local gt = GetBodyTransform(GetToolBody())
	local fwdpos = TransformToParentPoint(gt, Vec(0.4, -1, -100))
	local gunpos = TransformToParentPoint(gt, Vec(0.4, -1, -0.7))
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
	loadedShell.active = false -- simulated by gunnet.lua
	GunNet_FireGrenade(loadedShell)

	SpawnParticle("fire", gunpos, Vec(0, 1.0+math.random(1,10)*0.1, 0), 0.3, 0.1)
	PlaySound(grenadelaunchersound, GetPlayerTransform().pos, 0.75, false)

	if not unlimitedammo then
		grenadelauncherammo = grenadelauncherammo - 1
	end
end

function Reload()
	if reloading or unlimitedammo then
		return
	end
	reloading = true
	if not grenadelauncher then
		PlaySound(reloadsound, GetPlayerTransform().pos, 1, false)
	end
	if mag == "mag1" then
		reloadTimer = reloadTime
		mags = mags
	else
		reloadTimer = reloadTime
		magoutTimer = 0.6
		mags = mags
	end
end

function SelectFire()
	selectfire = selectfire + 1
	if selectfire > 2 then
		selectfire = 0
	end
	if selectfire ~= 2 then
		selectfireTimer = 1
	end

	selectfire0 = selectfire0 + 1
	if selectfire0 > 2 then
		selectfire0 = 0
	end
	selectsoundplaying = false
end

function SpentCasing()
	local gt = GetBodyTransform(GetToolBody())
	if ammo == 0 then
	local casingpos = TransformToParentPoint(gt, Vec(0.225, -0.55, -1.15))
	local fwdpos = TransformToParentPoint(gt, Vec(0.225+math.random()*4, 0.5+math.random()*4, -0.65+math.random()*4))
	local direction = VecAdd(GetPlayerVelocity(), VecSub(fwdpos, casingpos))
	GunNet_SpawnCasing("MOD/assets/vox/shotguncasing.xml", Transform(casingpos, QuatEuler(math.random(0, 90), math.random(0, 90), math.random(0, 90))), direction)
	PlaySound(casingsound,GetPlayerTransform().pos,0.6)
	end

	local casingpos = TransformToParentPoint(gt, Vec(0.325, -0.55, -1.15))
	local fwdpos = TransformToParentPoint(gt, Vec(0.325+math.random()*4, 0.5+math.random()*4, -0.65+math.random()*4))
	local direction = VecAdd(GetPlayerVelocity(), VecSub(fwdpos, casingpos))
	GunNet_SpawnCasing("MOD/assets/vox/shotguncasing.xml", Transform(casingpos, QuatEuler(math.random(0, 90), math.random(0, 90), math.random(0, 90))), direction)
	PlaySound(casingsound,GetPlayerTransform().pos,0.6)
end

function drawHint(info)
	UiPush()
		UiTranslate(info[1],info[2])
		local maxW=0
		for i=1,#info[8] do
			maxW=math.max(UiGetTextSize(info[8][i]),maxW)
			row=i
		end
		UiTranslate(-((info[3]+maxW+12)/2+10)*info[6],-((info[4]+(10+row*20)+12)/2+10)*info[7])
		UiColor(0,0,0,info[5]*.5)
		--UiImageBox("ui/common/box-solid-6.png",maxW,10+row*20,6,6)
		UiColor(1,1,1,info[5])
		--UiImageBox("ui/common/box-outline-6.png",maxW,10+row*20,6,6) UiTranslate(0,(row-1)*-10)
		UiFont("bold.ttf",20)
		UiText(info[8][1])
		UiFont("regular.ttf",15)
		for i=2,row do
			UiTranslate(0,20)
			UiText(info[8][i])
		end
	UiPop()
end

function AttachmentButton(itemType,itemID,wantHint,location,Description,W,H)
	local clicked=false
	UiPush()
		local item=GetString("savegame.mod."..itemType)
		if item==itemID then
			UiColor(.5,1,.5,.5)
		else
			UiColor(0,0,0,.5)
		end
		local w,h=UiGetImageSize("MOD/assets/img/icon/"..itemID..".png")
		local ww=W or w+12
		local wh=H or h+12
		UiImageBox("ui/common/box-solid-6.png",ww,wh,6,6)
		UiColor(1,1,1)
		UiImageBox("ui/common/box-outline-6.png",ww,wh,6,6)
		if UiImageButton("MOD/assets/img/icon/"..itemID..".png")then
			clicked=true
			PlaySound(uiselect, GetPlayerTransform().pos, 1)
			if item == itemID then
				SetString("savegame.mod."..itemType, "")
			else
				SetString("savegame.mod."..itemType, itemID)
			end
		end
		if wantHint then
			hoverindex=hoverindex+1
			local hover,x,y=hovering(ww,wh,hoverindex)
			if hover > 0 then
				hint=true
				info={location[1],location[2],ww,wh,hover,x,y,Description}
			else
				hint=hint or false
			end
		end
	UiPop()
	return clicked,ww,wh
end

function hovering(w,h,index)
	local dt=GetTimeStep()
	if UiIsMouseInRect(w,h)then
		local x,y=UiGetMousePos()
		x=x/(w/2)
		y=y/(h/2)
		local scale=math.max(math.abs(x),math.abs(y))
		if scale ~= 0 then
			inside[index][3]=(x/scale)*.1+inside[index][3]*.9
			inside[index][4]=(y/scale)*.1+inside[index][4]*.9
		end

		if inside[index][1]>=1 then
			inside[index][2]=math.min(1,inside[index][2]+dt*2)
		else
			inside[index][1]=math.min(1,inside[index][1]+dt*2)
		end
	else
		inside[index][1]=math.max(0,inside[index][1]-dt*4)
		inside[index][2]=math.max(0,inside[index][2]-dt*4)
	end
	return inside[index][2],inside[index][3],inside[index][4]
end

function Laser(active)
		local gt = GetBodyTransform(GetToolBody())
		local gunpos = TransformToParentPoint(gt, Vec(0.175, -0.625, -1.9))
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
		local gunpos = TransformToParentPoint(gt, Vec(0.175, -0.625, -1.9))
		local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
		QueryRejectBody(GetToolBody())
		local hit, dist = QueryRaycast(gunpos, fwdpos, 500, 0, true)

		if active then
			SetShapeEmissiveScale(side2, 1)
			PointLight(gunpos, 0.5, 0.5, 0.5, 0.1)
			for i = 1, dist*5 do
				local hitpoint = VecAdd(gunpos, VecScale(fwdpos, i/5))
				local b = 0.1
				PointLight(hitpoint, b/i^2.2, b/i^2.2, b/i^2.2, 2*i^2)
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
	if not GunInInventory("gun-sawedoff") then return end -- (2026-11-15, performance) idle gun: nothing more to do (gunfunctions.lua GunIdleNote)

    unlimitedammo = GetBool("savegame.mod.unlimitedammo")
    checkUnlimitedBulletsValid()


	if inventoryenabled and not reloading then
		reserveammo = GetInt("inventory.ammocount_12ga")
		item = GetString("inventory.guns.2.item")
		if Split(item, "_")[1] == "gun-sawedoff" then
			guninfo = Split(item, "_")
			if GetBool("inventory.update_guns2") or not initammo then
				ammo = tonumber(guninfo[5])
				bullettable = Split(guninfo[10],"-")
				SetBool("inventory.update_guns2", false)
				initammo = true
			end
		end
	end

	if IsToolEnabled("gun-sawedoff") and GunInInventory("gun-sawedoff") then

	if inventoryenabled and reloading then
		SetBool("inventory.reloading", true)
		GunNet_SetTool("gun-sawedoff")
	end

	end

	if GetPlayerTool() == "gun-sawedoff" and GetPlayerVehicle() == 0 then
		SetBool("hud.aimdot", false)
		WeaponTick(dt)
		if InputPressed("usetool") and not reloading and selectfire == 2 and not selectattachments and selectfireTimer == 0 and GetPlayerGrabShape() == 0 and inspectTimer <= 0 then
			if grenadelauncherammo > 0 and grenadelauncher then
				ShootGrenade()
			elseif not grenadelauncher and ammo > 0 then
				FireRound(bullettable[#bullettable])
				FireRound(bullettable[#bullettable])
			end
		elseif InputPressed("usetool") and not reloading and selectfire == 1 and not selectattachments and selectfireTimer == 0 and GetPlayerGrabShape() == 0 and inspectTimer <= 0 then
			if grenadelauncherammo > 0 and grenadelauncher then
				ShootGrenade()
			elseif not grenadelauncher and ammo > 0 and shootTimer <= 0 then
				FireRound(bullettable[#bullettable])
				if ammo > 0 then
					shootTimer = shotDelay
				end
			end
		end
		if GetBool("guns.accidental.shoot") and selectfire == 2 then
			--DebugPrint("Accidental Shoot")
			FireRound(bullettable[#bullettable])
			FireRound(bullettable[#bullettable])
			SetBool("guns.accidental.shoot", false)
		end
		if GetBool("guns.accidental.shoot") and selectfire == 1 then
			--DebugPrint("Accidental Shoot")
			FireRound(bullettable[#bullettable])
			SetBool("guns.accidental.shoot", false)
		end

		if InputPressed("usetool") and not reloading and inspectTimer <= 0 then
			spreadTimer = 1.25
			if (ammo == 0 or selectfire == 0) and not selectattachments then
				PlaySound(dryfiresound, GetPlayerTransform().pos, 1, false)
			end
		end

		if InputPressed("usetool") and reloading then
			reloadcancelled = true
		end

		if shootTimer < 0 then
			shootTimer = 0
			
		end

		if InputDown("grab") and selectfire > 0 and selectfireTimer == 0 and not selectattachments and GetPlayerGrabShape() == 0 and not KeybindDown(Settings.keybinds.player.sprint) then
			if InputPressed("grab") then
				PlaySound(adsup, GetPlayerTransform().pos, 1)
			end
			ironsight = true
			inspectTimer = 0
			if scopeTimer < 0.5 and not reloading and not (q or e) and selectfireTimer == 0 and not (altaim and toprail == "scope2") and not (switchsights and canted == "sight5") and not KeybindDown(Settings.keybinds.player.sprint) then
				scopeTimer = scopeTimer + dt
			end
		end
		if not InputDown("grab") then
			ironsight = false
		end
		if InputReleased("grab")then PlaySound(adsdown, GetPlayerTransform().pos, 1)end
		if selectfire == 0 then
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

		if InputPressed("x") and not reloading and not ironsight and shootTimer <= 0 and selectfire > 0 and stock ~= "removed" and not KeybindDown(Settings.keybinds.player.sprint) then
			meleeTimer = 0.8
		end

		if KeybindPressed(Settings.keybinds.player.select_fire) and not reloading and not selectattachments then
			SelectFire()
			inspectTimer = 0
			PlaySound(inspectsound)
		end

		if InputDown("y") and not reloading and selectfire > 0 and selectfireTimer <= 0 and not KeybindDown(Settings.keybinds.player.sprint) and not inventoryenabled then
			if KeybindPressed(Settings.keybinds.player.gun_attachment) then
				PlaySound(inspectsound)
				selectattachmentsTimer = 0.5
			end
			gunWantsInteractive = true
			selectattachments = true
			ironsight = false
			inspectTimer = 0
		end
		if InputReleased("y") and not reloading and selectfire > 0 and selectfireTimer <= 0 and not KeybindDown(Settings.keybinds.player.sprint) and not inventoryenabled then
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

		if KeybindPressed(Settings.keybinds.player.gun_inspect) and not reloading and not KeybindDown(Settings.keybinds.player.sprint) and selectfireTimer <= 0 and not ironsight and selectfire > 0 and not selectattachments then
			if inspectTimer <= 0 then
				inspectTimer = 4
				ironsight = false
			else
				inspectTimer = 0
			end
		end

		if selectfire == 1 then
			selectfireText = "Semi"
		elseif selectfire == 2 then
			selectfireText = "Burst"
		else
			selectfireText = "Safe"
		end

		if shootTimer <= 0 then
			recoverySpeed = 0.05
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
			recoilMax = gunstats.sawedoff.recoilMax*muzzleFactor*gripfactory*barrelFactory*stockFactor
		else
			recoilMax = gunstats.sawedoff.recoilMax*1.5*muzzleFactor*gripfactory*barrelFactory*stockFactor
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
		barrel = "barrel1"
		choke = GetString("savegame.mod.choke")

		if inventoryenabled then
			item = GetString("inventory.guns.2.item")
			guninfo = Split(item, "_")
			if #guninfo >= 8 then
				attachmentinfo = Split(guninfo[8], "-")
				toprail = attachmentinfo[1]
				muzzle = attachmentinfo[2]
				stock = attachmentinfo[3]
				barrel = "barrel1"
				choke = "removed"
			else
				toprail = ""
				muzzle = ""
				stock = "removed"
				barrel = "barrel1"
				choke = ""
			end
		end

		--perks
	

		local b = GetToolBody()
		if b ~= 0 then
			local magoffset = Vec(0, 0, 0)
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

			x,y,z,rotx,roty,rotz = -0.1,0.2,0,0,0,0
			if ironsight then
			if grenadelauncher then
				x = 0
				y = 0.45
				z = 0.2
				rotz = 0
			elseif q then
				x = 0.7
				y = -0.05
				z = 0.2
				rotz = 30
			elseif e then
				x = -0.1
				y = 0.45
				z = 0.2
				rotz = -15
			else
				if toprail == "holo" then
					x = 0.275
					y = 0.3125
					z = 0.2
					rotz = 0
				elseif toprail == "" then
					x = 0.275
					y = 0.45
					z = 0.2
					rotz = 0
				elseif toprail == "scope" then
					x = 0.275
					y = 0.275
					z = 0.2
					rotz = 0
				end
			end

			if reloading then
				adsFOV, adsTime = 0, 0.15
			elseif not (q or e or grenadelauncher) then
				if toprail == "" then
					adsFOV, adsTime = 10, 0.15
				elseif toprail == "scope" then
					adsFOV, adsTime = 90, 0.3
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
				recoilTimer2 = recoilTimer2 - (recoilTimer2*0.1+dt)
				offset.pos = VecAdd(offset.pos, Vec(0, 0, recoilTimer2/2))
				offset.rot = QuatRotateQuat(offset.rot, QuatEuler((recoilTimer2)*12, 0, 0))
			end
			if recoilTimer > 0 then
				recoilTimer = recoilTimer - dt
				if recoilTimer <= 0 then
					recoilTimer = 0
				end
			end
			local rx, ry, rz, rr1, rr2, rr3 = (rnd2+rnd5)/200, (recoilAngle/-200)-(rnd1+rnd4)/200-recoilTimer2/2, recoilAngle/75+(rnd3+rnd6)/200+recoilTimer2, recoilAngle+(rnd1+rnd4)/2+(recoilTimer2-0.02)*8, (rnd2+rnd5)/2, (rnd3+rnd6)/4
			-- RECoffset = REC(recoilTimer>0, rx, ry, rz, rr1, rr2, rr3)
			-- offset.pos = VecAdd(offset.pos, RECoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, RECoffset.rot)

			if lightTimer > 0 then
				PointLight(toolPos, 1, 0.75, 0.25, (lightTimer/shotDelay)*lightFactor)
				lightTimer = lightTimer - dt
			end

			if magoutTimer > 0 then
				magoutTimer = magoutTimer - dt
			end
			if magoutTimer < 0 then
				maginTimer = 0.6
				magoutTimer = 0
				reloadsound2playing = false
			end
			if reloadTimer < 0.2 and not reloadsound2playing then
					PlaySound(reloadsound2, GetPlayerTransform().pos, 0.5, false)
					reloadsound2playing = true
			end
			if maginTimer > 0 then
				maginTimer = maginTimer - dt/reloadFactor*magdrillFactor
			end
			if maginTimer < 0 then
				maginTimer = 0
				if grenadelauncher then
					PlaySound(uiselect, GetPlayerTransform().pos, 1)
				end
			end
			if not grenadelauncher or (grenadelauncherammo == 0 and not reloading) then
				grenadeoffset = hidePos
			end

			local x1, y1, z1, rotx1, roty1, rotz1 = 0, 0, 0, 0, 0, 0
			if reloading then
			if grenadelauncher then
					x1, y1, z1, rotx1, roty1, rotz1 = 0.1, -0.2, 0, 10, 5, -10
			else
			if ironsight then
				if q then
					if magoutTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0.1, 0.1, 0, -5, 10, -10
					elseif maginTimer > 0 or reloadTimer > 0.8 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0, 0, 0, -5, 10, 0
					end
				elseif e then
					if magoutTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0, -0.05, 0, 10, -10, 10
					elseif maginTimer > 0 or reloadTimer > 0.6 then
						x1, y1, z1, rotx1, roty1, rotz1 = 0, 0, 0, 5, -5, 0
					end
				else
					if magoutTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = -0.05, -0.25, 0.1, 10, -10, -10
					elseif maginTimer > 0 or reloadTimer > 0.6 then
						x1, y1, z1, rotx1, roty1, rotz1 = -0.05, -0.35, 0.1, 15, -5, -10
					else
						x1, y1, z1, rotx1, roty1, rotz1 = -0.05, -0.35, 0.1, 15, -5, -10
					end
				end
			else
				if magoutTimer > 0 then
						x1, y1, z1, rotx1, roty1, rotz1 = -0.2, -0.15, 0.1, 10, -10, -10
					elseif maginTimer > 0 or reloadTimer > 0.6 then
						x1, y1, z1, rotx1, roty1, rotz1 = -0.25, -0.25, 0.1, 15, -5, -10
					else
						x1, y1, z1, rotx1, roty1, rotz1 = -0.2, -0.25, 0.1, 15, -5, -10
					end
				end
			end
			end

			-- RELoffset = REL(reloading or (shootTimer > 0.25 and shootTimer < 0.8 and ammo > 0), x1, y1, z1, rotx1, roty1, rotz1)
			-- offset.pos = VecAdd(offset.pos, RELoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, RELoffset.rot)

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

			-- INSoffset = INS(inspectTimer > 0, x2, y2, z2, rotx2, roty2, rotz2)
			-- offset.pos = VecAdd(offset.pos, INSoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, INSoffset.rot)

			local x3, y3, z3, rotx3, roty3, rotz3 = 0, 0, 0, 0, 0, 0
			if (selectfire == 0 or KeybindDown(Settings.keybinds.player.sprint)) and selectfireTimer <= 0 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0.3, 0.25, -0.1, -20, 60, 0
			elseif ironsight and q and selectfireTimer > 0 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0, 0, 0, 0, 0, 10
			elseif ironsight and selectfireTimer > 0  then
				x3, y3, z3, rotx3, roty3, rotz3 = 0, -0.1, 0, 10, 5, 0
			elseif selectfireTimer > 0 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0, -0.1, 0.25, 10, 5, 0
			else
				x3, y3, z3, rotx3, roty3, rotz3 = 0, 0, 0, 0, 0, 0
			end

			-- SELoffset = SEL(selectfireTimer > 0 or selectfire == 0 or KeybindDown(Settings.keybinds.player.sprint), x3, y3, z3, rotx3, roty3, rotz3)
			-- offset.pos = VecAdd(offset.pos, SELoffset.pos)
			-- offset.rot = QuatRotateQuat(offset.rot, SELoffset.rot)

			offset = ADS(true, adsFOV, adsTime, -x+x1+x2+x3+ATToffset[1]-swingx2/200+swayx*speed/200+swayx2/200, y+y1+y2+y3-math.abs(swingx)/200-swayy*speed/200+ATToffset[2]+swingy2/100+swayy2/200, z+z1+z2+z3+ATToffset[3], rotx+rotx1+rotx2+rotx3+swingy-swingy2+swayy*speed+swayy2+ATToffset[4], roty+roty1+roty2+roty3+swingx-swingx2+swayx*speed+swayx2+ATToffset[5], rotz+rotz1+rotz2+rotz3-swingx+ATToffset[6])

			RECoffset = REC(true, rx, ry, rz, rr1, rr2, rr3)
			offset.pos = VecAdd(offset.pos, RECoffset.pos)
			offset.rot = QuatRotateQuat(offset.rot, RECoffset.rot)

			clothingtype = GetString("savegame.mod.difficulty")
			local bs = GetBodyShapes(GetToolBody())
			for i = 31, 42 do
				SetShapeLocalTransform(bs[i], hideTrans)
			end
			if clothingtype == "peaceful" then
				hand1 = bs[34]
				arm1 = bs[36]
				hand2 = bs[35]
			elseif clothingtype == "normal" then
				hand1 = bs[37]
				arm1 = bs[39]
				hand2 = bs[38]
			elseif clothingtype == "hardcore" then
				hand1 = bs[40]
				arm1 = bs[42]
				hand2 = bs[41]
			else
				hand1 = bs[31]
				arm1 = bs[33]
				hand2 = bs[32]
			end

			SetToolTransform(offset, 0.2)
			toolTrans = GetBodyTransform(b)
			toolPos = TransformToParentPoint(toolTrans, Vec(0.275, -0.6, -2.6))

			if body ~= b then
				body = b
				local shapes = GetBodyShapes(b)
				mag0 = shapes[2]
				bolt = shapes[3]
				bolt2 = shapes[30]
				selector = shapes[4]
				suppressor = shapes[5]
				scope = shapes[6]
				holo = shapes[7]
				holo2 = shapes[8]
				rail = shapes[9]
				stock1 = shapes[10]
				muzzlebreak = shapes[11]
				muzzlebreak2 = shapes[12]
				mag1 = shapes[13]
				mag2 = shapes[14]
				mag3 = shapes[15]
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
				magTrans = GetShapeLocalTransform(mag0)
				boltTrans = GetShapeLocalTransform(bolt)
				selectorTrans = GetShapeLocalTransform(selector)
				suppressorTrans = GetShapeLocalTransform(suppressor)
				scopeTrans = GetShapeLocalTransform(scope)
				holoTrans = GetShapeLocalTransform(holo)
				holoTrans2 = GetShapeLocalTransform(holo2)
				railTrans = GetShapeLocalTransform(rail)
				stock1Trans = GetShapeLocalTransform(stock1)
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
			end

			mt = TransformCopy(magTrans)
			mt.pos = VecAdd(mt.pos, magoffset)

			bt = TransformCopy(boltTrans)

			st = TransformCopy(selectorTrans)

			spt = TransformCopy(suppressorTrans)
			spt.pos = VecAdd(spt.pos, suppressoroffset)

			sct = TransformCopy(scopeTrans)
			sct.pos = VecAdd(sct.pos, scopeoffset)

			ht = TransformCopy(holoTrans)
			ht.pos = VecAdd(ht.pos, holooffset)
			ht2 = TransformCopy(holoTrans2)
			ht2.pos = VecAdd(ht.pos, holooffset)

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

			bt0 = TransformCopy(barrelTrans0)
			bt0.pos = VecAdd(bt0.pos, barreloffset)

			bt1 = TransformCopy(barrelTrans1)
			bt1.pos = VecAdd(bt1.pos, barreloffset)

			bt2 = TransformCopy(barrelTrans2)
			bt2.pos = VecAdd(bt2.pos, barreloffset)

			sdt1 = TransformCopy(sideTrans1)
			sdt1.pos = VecAdd(sdt1.pos, sideoffset)
			sdt2 = TransformCopy(sideTrans2)
			sdt2.pos = VecAdd(sdt2.pos, sideoffset)
			sdt3 = TransformCopy(sideTrans3)
			sdt3.pos = VecAdd(sdt3.pos, sideoffset)

			grt = TransformCopy(grenadeTrans)
			grt.pos = VecAdd(grt.pos, grenadeoffset)

			if selectfireTimer < 0.4 then
				if selectfire ~= 0 then
					st.rot = QuatEuler(180, 0, 0)
				else
					st.rot = QuatEuler(90, 0, 0)
				end
			elseif selectfireTimer > 0 then
				if selectfire0 ~= 0 then
					st.rot = QuatEuler(180, 0, 0)
				else
					st.rot = QuatEuler(90, 0, 0)
				end
			end

			if reloadTimer > reloadTime - 0.2 then
				bt.pos = VecAdd(bt.pos, Vec(0, 0.125*(reloadTime-reloadTimer)/0.2, 0.025*(reloadTime-reloadTimer)/0.2))
				bt.rot = QuatRotateQuat(bt.rot, QuatEuler(-35*(reloadTime-reloadTimer)/0.2, 0, 0))
				if not ejected and spentcasingsoption then
					--SpentCasing()
					ejected = true
				end
			elseif reloadTimer < 0.1 and reloading then
				bt.pos = VecAdd(bt.pos, Vec(0, 0.125*reloadTimer/0.1, 0.025*reloadTimer/0.1))
				bt.rot = QuatRotateQuat(bt.rot, QuatEuler(-35*reloadTimer/0.1, 0, 0))
			elseif reloading then
				bt.pos = VecAdd(bt.pos, Vec(0, 0.125, 0.025))
				bt.rot = QuatRotateQuat(bt.rot, QuatEuler(-35, 0, 0))
			end

			if reloading and magoutTimer > 0 then
				mt.rot = QuatRotateQuat(mt.rot, QuatEuler(-35, 0, 0))
				if ammo == 1 then
					mt.pos = VecAdd(mt.pos, Vec(0.375, 0.225+magoutTimer*0.5, -0.05+magoutTimer*0.75))
				elseif ammo == 2 then
					mt.pos = VecAdd(mt.pos, Vec(0.525, 0.225+magoutTimer*0.5, -0.05+magoutTimer*0.75))
				end
			else
				mt.pos = hidePos
			end

			if muzzle == "muzzle1" then
				spt.pos = VecAdd(spt.pos, Vec(0.075, -0.05, -barrellength))
				spt.rot = QuatEuler(-90, 0, 45)
				lightFactor = 0.4
			else
				spt.pos = hidePos
				spt.rot = QuatEuler(0, 0, 0)
				lightFactor = 2
				muzzleFactor = 1
			end
			if muzzle == "muzzle2" then
				mbt.pos = VecAdd(mbt.pos, Vec(0.075, -0.05, -barrellength))
				mbt2.pos = VecAdd(mbt2.pos, Vec(0, 0, -barrellength))
				mbt.rot = QuatEuler(-90, 0, 45)
				lightFactor = 3
				muzzleFactor = 0.75
			else
				mbt.pos = hidePos
				mbt2.pos = hidePos
				mbt.rot = QuatEuler(0, 0, 0)
				lightFactor = 2
				muzzleFactor = 1
			end
			if toprail == "scope" and ((not ironsight or reloading or scopeTimer < 0.5 or q or e) or (shootTimer < 0.8 and shootTimer > 0 and ammo > 0)) then
				sct.pos = Vec(0.2, -0.5, -0.55)
			else
				sct.pos = hidePos
			end
			if toprail == "holo" then
				ht.pos = Vec(0.175, -0.475, -0.875)
				ht2.pos = Vec(0.225, -0.4, -0.875)
			else
				ht.pos = hidePos
				ht2.pos = hidePos
			end
			--if stock == "removed" then
				stt.pos = hidePos
				--stockFactor = 5
			--else
				--stt.pos = Vec(0.2, -0.95, 0.25)
				--stt.rot = QuatEuler(-90, 0, 0)
				stockFactor = 1
			--end
			rt.pos = VecAdd(rt.pos, Vec(-0.025, 0.025, 0))

			if inventoryenabled then
				mag = "mag1"
			end

			magsize = 2
			--if mag == "mag0" then
				--reloadFactor = 1
				--SetShapeLocalTransform(mag0, mt)
				--SetShapeLocalTransform(mag1, hideTrans)
				--SetShapeLocalTransform(mag2, hideTrans)
				--SetShapeLocalTransform(mag3, hideTrans)
			--elseif mag == "mag1" then
				reloadFactor = 0.6
				SetShapeLocalTransform(mag1, Transform(VecAdd(mt.pos, Vec(0, 0, 0)), mt.rot))
				SetShapeLocalTransform(mag0, hideTrans)
				SetShapeLocalTransform(mag2, hideTrans)
				SetShapeLocalTransform(mag3, hideTrans)
			--end

			if grip == "grip1" then
				gripfactorx = 0.85
				gripfactory = 0.6
				gt1.pos = Vec(0.2, -0.85, -1.575)
				gt1_2.pos = Vec(0.225, -0.95, -1.6)
			else
				gt1.pos = hidePos
				gt1_2.pos = hidePos
			end
			if grip == "grip2" then
				gripfactorx = 0.6
				gripfactory = 0.85
				gt2.pos = Vec(0.25, -0.9, -1.5)
			else
				gt2.pos = hidePos
			end
			if grip == "grip3" then
				local querypos = TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.25, -0.6, -2-barrellength*4/3))
				QueryRejectBody(GetToolBody())
				local hit, dist = QueryRaycast(querypos, Vec(0, -2, 0), 5, 0.2)
				local bipodded = (InputDown("crouch") or dist < 0.4) and selectfire > 0
				if bipodded then
					gripfactorx = 0.4
					gripfactory = 0.4
					gt3_1.pos = Vec(0.4, -1.35, -2.05-barrellength*4/3)
					gt3_2.pos = Vec(0.05, -1.325, -2.05-barrellength*4/3)
					gt3_1.rot = QuatEuler(0, 0, 10)
					gt3_2.rot = QuatEuler(0, 0, -10)
				else
					gripfactorx = 1
					gripfactory = 1
					if barrel == "barrel2" then
						gt3_1.pos = Vec(0.3, -0.725, -1.3-barrellength)
						gt3_2.pos = Vec(0.15, -0.725, -1.3-barrellength)
					else
						gt3_1.pos = Vec(0.3, -0.675, -2.75-barrellength)
						gt3_2.pos = Vec(0.15, -0.675, -2.75-barrellength)
						gt3_1.rot = QuatEuler(90, 0, 0)
						gt3_2.rot = QuatEuler(90, 0, 0)
					end
					
				end
				gt3.pos = Vec(0.225, -0.725, -1.95-barrellength)
				
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

			barrelFactorx = 1
			barrelFactory = 1
			barrelFactordamage = 1
			accuracyFactor = 0.7*stockFactor
			barrellength = 0

			bt0.pos = hidePos
			bt1.pos = hidePos
			bt2.pos = hidePos

			local barrelFactorpelletSpread = 1
			if barrel == "barrel1" then
				SetShapeLocalTransform(bolt, hideTrans)
				SetShapeLocalTransform(bolt2, bt)
				barrelFactorpelletSpread = 2
			else
				SetShapeLocalTransform(bolt, bt)
				SetShapeLocalTransform(bolt2, hideTrans)
				barrelFactorpelletSpread = 0.8
			end

			if choke == "choke" then
				pelletSpread = 8*barrelFactorpelletSpread
			else
				pelletSpread = 16*barrelFactorpelletSpread
			end

			if side == "side1" then
				sdt1.pos = sdt1.pos
			else
				sdt1.pos = hidePos
			end
			if side == "side2" then
				sdt2.pos = sdt2.pos
			else
				sdt2.pos = hidePos
			end
			if side == "side3" then
				sdt3.pos = sdt3.pos
			else
				sdt3.pos = hidePos
			end

			SetShapeLocalTransform(selector, st)
			SetShapeLocalTransform(suppressor, spt)
			SetShapeLocalTransform(scope, sct)
			SetShapeLocalTransform(holo, ht)
			SetShapeLocalTransform(holo2, ht2)
			SetShapeLocalTransform(rail, rt)
			SetShapeLocalTransform(stock1, stt)
			SetShapeLocalTransform(muzzlebreak, mbt)
			SetShapeLocalTransform(muzzlebreak2, mbt2)
			SetShapeLocalTransform(grip1, gt1)
			SetShapeLocalTransform(grip1_2, gt1_2)
			SetShapeLocalTransform(grip2, gt2)
			SetShapeLocalTransform(grip3, gt3)
			SetShapeLocalTransform(grip3_1, gt3_1)
			SetShapeLocalTransform(grip3_2, gt3_2)
			SetShapeLocalTransform(grip4, glt)
			SetShapeLocalTransform(barrel0, bt0)
			SetShapeLocalTransform(barrel1, bt1)
			SetShapeLocalTransform(barrel2, bt2)
			SetShapeLocalTransform(side1, sdt1)
			SetShapeLocalTransform(side2, sdt2)
			SetShapeLocalTransform(side3, sdt3)
			SetShapeLocalTransform(grenade, grt)
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
			if (KeybindPressed(Settings.keybinds.player.reload) or clickedmag) and selectfireTimer == 0 and shootTimer <= 0 then
				if (ammo ~= magsize and not grenadelauncher) or (grenadelauncherammo == 0 and grenadelauncher) then
					Reload()
					inspectTimer = 0
				end
			end

			if reloading then
				if reloadTimer > 0.4 then
					reloadTimer = reloadTimer - dt/reloadFactor*magdrillFactor
				elseif reloadTimer > 0 then
					if mag == "mag1" and ammo < magsize and reserveammo > 0 and not reloadcancelled then
						ammo = ammo + 1
						reserveammo = reserveammo - 1
						bullettable[ammo] = Split(GetString("inventory.ammocount.table_12ga"),"-")[1]
						if inventoryenabled then
							SetString("inventory.removeammo", "12ga_1")
							guninfo[5] = ammo
							guninfo[6] = magsize
							guninfo[10] = table.concat(bullettable,"-")
							SetString("inventory.guns.2.item", IDBuilder(guninfo))
							SetBool("inventory.update", true)
						end
						PlaySound(bulletsound, GetPlayerTransform().pos, 1)
						reloadTimer = 1.7
						magoutTimer = 0.6
					else
						reloadTimer = reloadTimer - dt
					end
				end
				if reloadTimer < 1.6 and not cocksoundplaying and ammo == 0 and mag == "mag0" then
					cocksoundplaying = true
					PlaySound(clipsound, GetPlayerTransform().pos, 0.85)
				end
				if reloadTimer < 0 then
					cocksoundplaying = false
					if not inventoryenabled then
						ammo = magsize
					end
					reloadTimer = 0
					reloading = false
					reloadcancelled = false
					SetBool("inventory.reloading", false)
					PlaySound(inspectsound)
					ejected = false
				end
			end

			if selectfireTimer < 0.55 and selectfireTimer > 0 and not selectsoundplaying and selectfire ~= 2 then
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
		local x2, y2, z2, rotx2, roty2, rotz2 = 0.175, -0.8, -2, 0, 0, 0
		if reloading and reloadTimer >= 2.2 then
			x2, y2, z2 = 0.175, -0.7-0.4*(2.4-reloadTimer)/0.2, -2
		elseif reloading and reloadTimer >= 1.8 then
			x2, y2, z2 = 0.175, -1.1, -2
		elseif reloading and reloadTimer < 1.8 and reloadTimer > 1 and not (magoutTimer > 0 or maginTimer > 0) and ammo < 2 then
			x2, y2, z2 = 0.25, -0.5, -0.5
		elseif reloading and reloadTimer < 1 and reloadTimer > 0.3 and not (magoutTimer > 0 or maginTimer > 0 and ammo == 2) then
			x2, y2, z2 = 0.275, -0.35, -0.8
		elseif reloading and reloadTimer > 0.6 and (magoutTimer > 0 or maginTimer > 0 and ammo < 2) then
			x2, y2, z2 = 0+mt.pos[1], -0.3+0.4*(magoutTimer-0.6)/0.6, -0.15+mt.pos[3]
		elseif reloading and reloadTimer < 0.2 then
			x2, y2, z2 = 0.175, -1.1+0.4*(0.2-reloadTimer)/0.2, -2
		elseif reloading and reloadTimer < 0.6 then
			x2, y2, z2 = 0.175, -1.1, -2
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


		sightattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.15, -1))
		muzzleattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.35, -2.5))
		stockattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.4, -0.6))
		sideattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.45, -1.65))
		magattachpoint = TransformToParentPoint(btrans, Vec(0.25, -0.65, -1))
		gripattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.85, -1.4))
		barrelattachpoint = TransformToParentPoint(btrans, Vec(0.1, -0.65, -1.6))

	
	end
end

function client.draw()
	if not GunInInventory("gun-sawedoff") then return end -- (v2, Phase 2) see gunfunctions.lua
	if gunWantsInteractive then UiMakeInteractive() gunWantsInteractive = false end
	GunNet_DebugParts()
	if GetPlayerTool() == "gun-sawedoff" and GetPlayerVehicle() == 0 then

    UiPush()
      UiAlign("center middle")
      UiTranslate(UiCenter(), UiHeight()/2)
      UiFont("bold.ttf", 50)
      UiColor(0.1,0.1,0.1,DrawHitmark)
      UiText("<  +  >")
    UiPop()
    DrawHitmark = DrawHitmark - 0.1

		------SCOPE RETICLE------
	if not GetBool("level.killcam.active") then
		if toprail == "scope" and ironsight and not reloading and scopeTimer >= 0.5 and not (q or e) and not (shootTimer < 0.8 and shootTimer > 0 and ammo > 0) then
			local gt = GetBodyTransform(GetToolBody())
			local sightcenter = Vec(0.275, -0.275, -1.8)
			local sightrear = Vec(0.275, -0.275, -1.4)
			local gunpos = TransformToParentPoint(gt, sightcenter)
			local rearpos = TransformToParentPoint(gt, sightrear)
			local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
			QueryRejectBody(GetToolBody())
			local hit, dist = QueryRaycast(gunpos, fwdpos, 500, 0, true)
			local hitpoint = VecAdd(gunpos, VecScale(fwdpos, dist))

			local camtrans = GetPlayerCameraTransform()
			local sightdist = VecLength(VecSub(camtrans.pos, gunpos))

			local holopoint = VecAdd(camtrans.pos, VecScale(VecNormalize(VecSub(camtrans.pos, hitpoint)), -sightdist))
			UiPush()
				local w, h = UiGetImageSize("MOD/assets/img/reticle2.png")
				local x, y = UiWorldToPixel(holopoint)
				UiTranslate(x-w/2, y-h/2)
				UiImage("MOD/assets/img/reticle2.png")
			UiPop()
			UiPush()
				local w, h = UiGetImageSize("MOD/assets/img/reticleoutline.png")
				-- (2026-11-15) centred on the reticle's point instead of the rear lens: they drifted apart (user, SV-98)
				local x, y = UiWorldToPixel(hitpoint)
				UiTranslate(x-w/2, y-h/2)
				Gun3P_ScopeOverlay() UiImage("MOD/assets/img/reticleoutline.png")
				UiTranslate(0, h)
				UiImage("MOD/assets/img/black.png")
				UiTranslate(0, h)
				UiImage("MOD/assets/img/black.png")
				UiTranslate(0, h)
				UiImage("MOD/assets/img/black.png")
				UiTranslate(0, h)
				UiImage("MOD/assets/img/black.png")
				UiTranslate(0, h)
				UiImage("MOD/assets/img/black.png")
				UiTranslate(0, h)
				UiImage("MOD/assets/img/black.png")
			UiPop()
		end
	end


		if not unlimitedammo and GetPlayerVehicle() == 0 then
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
					UiText(ammo.."/"..magsize*math.max(0, mags-1).." - "..selectfireText..((bullettable[#bullettable] or "") ~= "" and " - "..bullettable[#bullettable] or ""))
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
	if GetPlayerTool() == "gun-sawedoff" and grenadelauncher and not selectattachments then
		UiPush()
			UiTranslate(UiCenter(), UiMiddle())
			UiAlign("center middle")
			UiImage("ui/hud/crosshair-launcher.png")
		UiPop()
	end
	if GetPlayerTool() == "gun-sawedoff" and sideattachment and side == "side3" then
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

	if selectattachments then
	if hint then drawHint(info) end
	hoverindex=0
		UiPush()
			local x,y,dist=UiWorldToPixel(sightattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					clickedscope = AttachmentButton("toprail","scope",true,{curx,cury},{"Scope","3x magnification sight for medium range combat."})
					UiTranslate(-70,0)
				UiPop()
			end
		UiPop()
		UiPush()
			local x,y,dist=UiWorldToPixel(stockattachpoint)
			if dist > 0 then
				UiTranslate(x-50,y+20)
				local curx,cury=UiGetRelativePos()
				UiPush()
					UiAlign("center middle")
					--clickedstockremoved = AttachmentButton("stock","removed",true,{curx,cury},{"Stock","Foldable for badasses only."})
					UiTranslate(-70,0)
				UiPop()
			end
		UiPop()
	end
end