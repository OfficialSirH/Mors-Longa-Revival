#version 2
#include "script/include/player.lua"
--[[
#include "script/common.lua"
#include "UiHealthOverlay_Draw.lua"
#include "UiHealthOverlay.lua"
#include "../../lib/TDSU/tdsu.lua"
#include "../../lib/Settings.lua"
#include "../../lib/Automatic.lua"
#include "../../npcs/Blood/Blood.lua"
]]


-- REG = {
-- 	float_addStun = "level.advhealth.addShock"
-- }


function client.init()

	TICK = 0

	Init_Settings()

	-- (v2) this machine's own (client-spawned, local) copies of the six hitboxes. They hold the per-limb state
	-- tags (QueriedDamage, S, Bleed, Fracture, CurrentHealth) that this script, the inventory and the guns read
	-- and write. They carry the "localhitbox" tag only, so NPC code never sees them; the real hit triggers per
	-- player are server-side (player/PlayerHitboxes.lua), which forwards damage to "health.incoming.*".
	for _, old in ipairs(FindTriggers("localhitbox", true)) do Delete(old) end
	Spawn(LOCAL_HITBOX_XML, GetPlayerTransform())
	Hitboxes = FindTriggers("localhitbox", true)
	init_health()
	init_armor()

	HealthMax      = 260 -- Hitboxes health values add up to 260 at start.
	HealthCritical = 150
	HeadshotTimer  = TimerCreateSeconds(1) -- No headshot lasering


	LastBodyState = {
		HEAD = {},
		TORSO = {},
		LLEG = {},
		RLEG = {},
		LARM = {},
		RARM = {},
	}

	Sounds = Sounds or {}
	Sounds.hitsnd    = LoadSound("MOD/player/HealthSystem/snd/Hit0.ogg")
	Sounds.death     = LoadSound("MOD/player/HealthSystem/snd/Death0.ogg")
	Sounds.hurt      = LoadSound("MOD/player/HealthSystem/snd/Hurt0.ogg")
	Sounds.headshot  = LoadSound("MOD/player/HealthSystem/snd/Headshot0.ogg")
	Sounds.injection = LoadSound("MOD/player/HealthSystem/snd/Injection.ogg")
	Sounds.critical  = LoadLoop("MOD/player/HealthSystem/snd/criticalcondition.ogg")
	Sounds.heartbeat = LoadLoop("MOD/player/HealthSystem/snd/Heartbeat.ogg")
	Sounds.fard      = LoadSound("MOD/player/HealthSystem/snd/Fard.ogg")
	Sounds.boneSnap  = LoadSound("MOD/player/HealthSystem/snd/BoneSnap0.ogg")


	--SetBool("guns.accidental.shoot", false)
	
	Godmode = GetBool("level.gamerule.god")
	Armored = GetBool("level.gamerule.armored")

	Saturation = GetPostProcessingProperty("saturation")
	Bloom = GetPostProcessingProperty("bloom")


	Shock = 0
	Confusion = 0
	C4F = 0.1
	C4B = 0.08
	BLDMG = 0
	DMGArmor = 0

	Permanentlyarmored = Armored

	MyHealthUiIsActive = true
	htim = 0
	Injected = 0
	Weed = false
	WTimer = 0
	MaxWTimer = 100
	Methamphetamine = false
	MTimer = 0
	MaxMTimer = 30

	Alchocol = false
	AlTimer = 0
	MaxAlTimer = 260

	Energy = false
	EnTimer = 0
	MaxEnTimer = 60

	Bleeding = false
	Healing = 0
	WoundClose = 1
	Adrenaline = false
	ATimer = 0
	MaxATimer = 15
	Morphine = false
	MoTimer = 0
	MaxMoTimer = 60
	Playerfov = GetFloat("options.gfx.fov")
	PlayerSlow = false
	Pen = 0
	RicochetChance = 1
	DMGREDUC = 1
	Bleedstoptim = 0
	Bleedstoprnd = 100
	extrastimtim = 0
	markedforfalldamage = false
	FallDamage = 1
	Falling = 0
	FartChance = 0.01
	playedinj = 0
	oldplayedinj = 0
	dead = false


	lastEXPPos   = Vec()
	lastTorsoPos = Vec()
	lastHitPos   = Vec()
	if GetString("savegame.mod.difficulty") == "hardcore" then
		DamageValues = {0, 15}
	else
		DamageValues = {10, 20}
	end

	hungertimer = 0
	thirsttimer = 0
	
	CurTool = nil
	cycled = false
	WalkingModes = 12
	CurWalkingMode = 12

	SetBool("level.healthScriptSpawned", true)

	LastPlayerVehicleVel = GetPlayerVehicle()
	PlayerExitedVehicle = GetPlayerVehicle() ~= LastPlayerVehicleVel

	init_hit_impact_sounds()

end

function init_health()
	Health = {
		HEAD = {
			MaxHP = "25",
			CurrentHealth = "25",
			Fracture = false,
			Bleed = false,
			Dismembered = false,
			Armor = 0,
			ArmorHealth = 0
		},
		TORSO = {
			MaxHP = "75",
			CurrentHealth = "75",
			Fracture = false,
			Bleed = false,
			Dismembered = false,
			Armor = 0,
			ArmorHealth = 0
		},
		LLEG = {
			MaxHP = "40",
			CurrentHealth = "40",
			Fracture = false,
			Bleed = false,
			Dismembered = false,
			Armor = 0,
			ArmorHealth = 0
		},
		RLEG = {
			MaxHP = "40",
			CurrentHealth = "40",
			Fracture = false,
			Bleed = false,
			Dismembered = false,
			Armor = 0,
			ArmorHealth = 0
		},
		LARM = {
			MaxHP = "40",
			CurrentHealth = "40",
			Fracture = false,
			Bleed = false,
			Dismembered = false,
			Armor = 0,
			ArmorHealth = 0
		},
		RARM = {
			MaxHP = "40",
			CurrentHealth = "40",
			Fracture = false,
			Bleed = false,
			Dismembered = false,
			Armor = 0,
			ArmorHealth = 0
		},
	}
end

function init_armor()
	Armor = {
		{
			Type = "Helmet",
			Name = "altyn",
			Health = 50,
			ProtectionLevel = 4,
			Bodyparts = { "HEAD" },
			Active = false,
		},
		{
			Type = "Helmet",
			Name = "ulach",
			Health = 35,
			ProtectionLevel = 2,
			Bodyparts = { "HEAD" },
			Active = false,
		},
		{
			Type = "Helmet",
			Name = "killa",
			Health = 50,
			ProtectionLevel = 4,
			Bodyparts = { "HEAD" },
			Active = false,
		},
		{
			Type = "BodyArmor",
			Name = "zabralo",
			Health = 90,
			ProtectionLevel = 5,
			Bodyparts = { "TORSO", "LARM", "RARM" },
			Active = false,
		},
		{
			Type = "BodyArmor",
			Name = "thor",
			Health = 70,
			ProtectionLevel = 4,
			Bodyparts = { "TORSO", "LARM", "RARM" },
			Active = false,
		},
		{
			Type = "BodyArmor",
			Name = "nfmthor",
			Health = 50,
			ProtectionLevel = 4,
			Bodyparts = { "TORSO" },
			Active = false,
		},
		{
			Type = "BodyArmor",
			Name = "gzhel",
			Health = 65,
			ProtectionLevel = 4,
			Bodyparts = { "TORSO" },
			Active = false,
		},
		{
			Type = "BodyArmor",
			Name = "hexgrid",
			Health = 50,
			ProtectionLevel = 5,
			Bodyparts = { "TORSO" },
			Active = false,
		},
		{
			Type = "BodyArmor",
			Name = "killa",
			Health = 60,
			ProtectionLevel = 3,
			Bodyparts = { "TORSO" },
			Active = false,
		},
		{
			Type = "BodyArmor",
			Name = "sixb2",
			Health = 50,
			ProtectionLevel = 2,
			Bodyparts = { "TORSO" },
			Active = false,
		},
		{
			Type = "BodyArmor",
			Name = "lbtplate",
			Health = 70,
			ProtectionLevel = 4,
			Bodyparts = { "TORSO" },
			Active = false,
		},
	}
end



function client.tick(dt)

	-- (v2) "health.status.dead" is a one-tick pulse read by the inventory (drops items on death). v1 relied on
	-- Die.lua clearing it; that script now runs on the server, so the health script clears its own flag here.
	if GetBool("health.status.dead") then SetBool("health.status.dead", false) end
	HealthNet_Update()

	-- (v2) damage the server forwarded from this player's hit triggers
	for _, Hitbox in ipairs(Hitboxes) do
		local key = "health.incoming." .. GetTagValue(Hitbox, "localhitbox")
		local incoming = GetFloat(key)
		if incoming ~= 0 then
			SetFloat(key, 0)
			SetTag(Hitbox, "QueriedDamage", (tonumber(GetTagValue(Hitbox, "QueriedDamage")) or 0) + incoming)
		end
	end
	-- (v2) explosions relayed by the server (v1: handleCommand "explosion ...")
	local explosions = GetString("health.explosions")
	if explosions ~= "" then
		SetString("health.explosions", "")
		for s, x, y, z in explosions:gmatch("(%S+) (%S+) (%S+) (%S+);") do
			HealthExplosion(tonumber(s), tonumber(x), tonumber(y), tonumber(z))
		end
	end

	-- -- Match player vel to vehicle vel upon vehicle exit.
	-- PlayerExitedVehicle = GetPlayerVehicle() ~= LastPlayerVehicleVel
	-- if PlayerExitedVehicle then
	-- 	SetPlayerVelocity(GetBodyVelocity(GetVehicleBody(LastPlayerVehicleVel)))
	-- 	SetPlayerGroundVelocity(GetBodyVelocity(GetVehicleBody(LastPlayerVehicleVel)))
	-- 	print("pvel", unpack(GetPlayerVelocity()))
	-- end
	-- LastPlayerVehicleVel = GetPlayerVehicle()

	hunger = tonumber(GetString("savegame.mod.hunger"))
	thirst = tonumber(GetString("savegame.mod.thirst"))

	doBleed = GetBool("level.player.health.doBleed")

	TimerRunTime(HeadshotTimer)

	if GetBool("savegame.mod.config.game.heal") then
		health_heal()
		SetBool("savegame.mod.config.game.heal", false)
	end

	--DebugCross(lastEXPPos,1)
	--DebugCross(lastTorsoPos,0,1)
	--DebugCross(lastHitPos,0,0,1)
	if InputDown("O") and InputDown("F") and InputPressed("C") then
		FartChance = 100
		PlaySound(Sounds.fard)
	end


	Bleedstoptim = Bleedstoptim + dt
	if Bleedstoptim > 10 then
		Bleedstoptim = 0
		Bleedstoprnd = math.random(0,100)
		Stopped = false
	end

	process_perks(dt)


	if GetBool("health.statuseffects.pz1") then
		Methamphetamine = true
		SetBool("health.statuseffects.pz1", false)
	end
	if GetBool("health.statuseffects.adrenaline") then
		Adrenaline = true
		SetBool("health.statuseffects.adrenaline", false)
	end
	if GetBool("health.statuseffects.morphine") then
		Morphine = true
		SetBool("health.statuseffects.morphine", false)
	end

	if GetString("health.foodconsumed") == "food13" then
		Energy = true
		SetString("health.foodconsumed", "")
	end
	if GetString("health.foodconsumed") == "food6" then
		Alchocol = true
		SetString("health.foodconsumed", "")
	end

	FancyPostProcessingEffects(dt)

	armor = GetString("inventory.armor.1")
	armorinfo = Split(armor, "_")
	id = armorinfo[1] --something like vest-gzhel
	name = armorinfo[2] --string (display name)
	health = armorinfo[3] --integer
	maxhealth = armorinfo[4] --integer
	for i = 1, #Armor do

		if Armor[i]["Name"] == Split(id, "-")[2] then
			IsActive = true
			--DebugPrint("HAS ARMOR: ".. Armor[i]["Name"])
		else
			IsActive = false
			--DebugPrint("HAS ARMOR: bozo")
		end
		ArmorHP = Armor[i]["Health"] -- Health should be received from the inventory mod, but is currently set by this script locally
		if DMGArmor ~= 0 then
			ArmorHP = ArmorHP - DMGArmor
			DMGArmor = 0
		end
		--DebugPrint(IsActive)
		if IsActive and ArmorHP > 0 then
			for z = 1, #Armor[i]["Bodyparts"] do
				CAB = Armor[i]["Bodyparts"][z]
				Health[CAB]["Armor"] = Armor[i]["ProtectionLevel"] -- Sets protection level for limbs
			end
		else
			if IsActive then
				Health[CAB]["Armor"] = 0
			end
		end
	end

	TotalHealth = 0
	if GetPlayerHealth() > 0 and not HealthNet_Dying() then -- (v2) not while the server applies our death
		DeathPlayed = false
		if dead then
			for i = 1, #Hitboxes do
				Hitbox = Hitboxes[i]
				CurrentBodypart = GetTagValue(Hitbox, "localhitbox")
				Health[CurrentBodypart]["CurrentHealth"] = Health[CurrentBodypart]["MaxHP"] -- this reheals the player and removes all effects after they die
				RemoveTag(Hitbox, "Fracture")
				RemoveTag(Hitbox, "Bleed")
				--Restart()
			end
			dead = false
		end
	end

	if not dead then
		HealthNet_SetPlayerHealth(1)
		SetFloat("game.player.health", 1)
	end

	armor = GetString("inventory.armor.2")
	armorinfo = Split(armor, "_")
	id = armorinfo[1] --something like vest-gzhel
	name = armorinfo[2] --string (display name)
	health = armorinfo[3] --integer
	maxhealth = armorinfo[4] --integer
	


	for i = 1, #Armor do

		if Armor[i]["Name"] == Split(id, "-")[2] then
			IsActive = true
			--DebugPrint("HAS ARMOR: ".. Armor[i]["Name"])
		else
			IsActive = false
			--DebugPrint("HAS ARMOR: bozo")
		end
		ArmorHP = Armor[i]["Health"] -- Health should be received from the inventory mod, but is currently set by this script locally
		if DMGArmor ~= 0 then
			ArmorHP = ArmorHP - DMGArmor
			DMGArmor = 0
		end
		--DebugPrint(IsActive)
		if IsActive and ArmorHP > 0 then
			for z = 1, #Armor[i]["Bodyparts"] do
				CAB = Armor[i]["Bodyparts"][z]
				Health[CAB]["Armor"] = Armor[i]["ProtectionLevel"] -- Sets protection level for limbs
			end
		else
			if IsActive then
				Health[CAB]["Armor"] = 0
			end
		end
	end
	--if InputPressed("P") then
	--	Armor[2]["Active"] = false
	--end
	TotalHealth = 0
	if GetPlayerHealth() > 0 and not HealthNet_Dying() then -- (v2) not while the server applies our death
		DeathPlayed = false
		if dead then
			for i = 1, #Hitboxes do
				Hitbox = Hitboxes[i]
				CurrentBodypart = GetTagValue(Hitbox, "localhitbox")
				Health[CurrentBodypart]["CurrentHealth"] = Health[CurrentBodypart]["MaxHP"] -- this reheals the player and removes all effects after they die
				RemoveTag(Hitbox, "Fracture")
				RemoveTag(Hitbox, "Bleed")
				--Restart()
			end
			dead = false
		end
	end
	local BASE_PLAYER_WALK_SPEED = 7
	--local WF = (2-GetInt("inventory.weight")/159)/2
	if PlayerSlow and not Numbing then
		HealthNet_SetWalkingSpeed(BASE_PLAYER_WALK_SPEED * .5 * CurWalkingMode/WalkingModes)
	else
		if KeybindDown(Settings.keybinds.player.sprint) then
			if Athletic then
				HealthNet_SetWalkingSpeed(BASE_PLAYER_WALK_SPEED*1.5)
			else
				HealthNet_SetWalkingSpeed(BASE_PLAYER_WALK_SPEED*1.25)
			end
			if PlayerSlow then
				BLDMG = BLDMG + dt
			end
		else
			HealthNet_SetWalkingSpeed(BASE_PLAYER_WALK_SPEED * .8 * CurWalkingMode/WalkingModes)
		end
	end
	if GetString("savegame.mod.difficulty") == "hardcore" then
		--SetPlayerParam("JumpSpeed", GetPlayerParam("JumpSpeed")*.5)

		--Jumping
	end
	InPain = false

	-- (2026-11-15, performance) v1 searched the whole level for these two triggers every tick: only again when the
	-- handles are gone (the hitbox triggers were re-created)
	if not (RLEGL and IsHandleValid(RLEGL)) then RLEGL = FindTrigger("localRLEG", true) end
	if not (LLEGL and IsHandleValid(LLEGL)) then LLEGL = FindTrigger("localLLEG", true) end


	-- local inHeli = false
	-- local inHeliKeys = ListKeys("level.heli.drivingHeli")
	-- for _, key in ipairs(inHeliKeys) do
	-- 	if "level.heli.drivingHeli." .. key then
	-- 		inHeli = true
	-- 		break
	-- 	end
	-- end


	Plv = GetPlayerVelocity()
	if Plv[2] < -9/FallDamage and GetPlayerVehicle() == 0 and not Godmode and not GetBool("level.gamerule.helicopter")  then
		markedforfalldamage = true
		Falling = Falling + 0.5
	end

	--DebugPrint("EXPECTED FALL DAMAGE = "..Falling)
	if markedforfalldamage and Plv[2] > -0.5 then
		--DebugPrint("Fall damage executed")
		RLEGL = FindTrigger("localRLEG", true)
		LLEGL = FindTrigger("localLLEG", true)
		TORSO = FindTrigger("localTORSO", true)
		SetTag(RLEGL, "QueriedDamage", Falling*FallDamage)
		SetTag(RLEGL, "S", 1)
		SetTag(LLEGL, "QueriedDamage", Falling*FallDamage)
		SetTag(LLEGL, "S", 1)

		if Falling > DamageValues[1] then
		SetTag(RLEGL, "Fracture")
		SetTag(LLEGL, "Fracture")
		PlaySound(Sounds.boneSnap, GetPlayerCameraTransform().pos, 20)
		end

		if Falling > DamageValues[2] then
		SetTag(TORSO, "QueriedDamage", 10000)
		SetTag(TORSO, "S", 1)
		SetTag(RLEGL, "QueriedDamage", 10000)
		SetTag(RLEGL, "S", 1)
		SetTag(LLEGL, "QueriedDamage", 10000)
		SetTag(LLEGL, "S", 1)
		end

		markedforfalldamage = false
		Falling = 0
	end


	--[[ if InputPressed("p") then
		SetTag(GetRandomArrayValue(Hitboxes), "Bleed")
	end ]]

	FallDamage = 1
	for i = 1, #Hitboxes do

		Hitbox = Hitboxes[i]

		SetHitboxes()

		-- DebugWatch(CurrentBodypart, Health[CurrentBodypart]["CurrentHealth"])

		if GetTagValue(Hitbox, "localhitbox") == "HEAD" then
			RemoveTag(Hitbox, "Bleed")
			SetTag(Hitbox, "S", 0)
		end

		QueriedDamage = tonumber(GetTagValue(Hitbox, "QueriedDamage")) -- Gets damage done to player
		if QueriedDamage == nil then
			DebugPrint("QUERIED DAMAGE IS NIL, THIS IS A BUG, PLEASE REPORT IT")
		end

		if Armored then
			QueriedDamage = tonumber(GetTagValue(Hitbox, "QueriedDamage")) / 4
		end

		Pen = tonumber(GetTagValue(Hitbox, "S"))
		CurrentBodypart = GetTagValue(Hitbox, "localhitbox")
		TotalHealth = TotalHealth + Health[CurrentBodypart]["CurrentHealth"]
		CHP = tonumber(Health[CurrentBodypart]["CurrentHealth"]) -- health for bodypart
		CAL = tonumber(Health[CurrentBodypart]["Armor"]) or 0 -- armor level for bodypart
		CAHP = tonumber(Health[CurrentBodypart]["ArmorHealth"])

		if TimerConsumed(HeadshotTimer) then
			TimerResetTime(HeadshotTimer)

			-- Nerf headshots to avoid one shot headshot kills. Initially protects healthy heads.
			local hitboxHealth = Health[CurrentBodypart]["CurrentHealth"]
			if CurrentBodypart == "HEAD" then
				if hitboxHealth - QueriedDamage <= 0 and not GetString("savegame.mod.difficulty") == "hardcore" then
					QueriedDamage = QueriedDamage/2 -- Low health head will still die from significant headshots.
				elseif hitboxHealth - QueriedDamage <= 0 and GetString("savegame.mod.difficulty") == "hardcore" then
					if CAL ~= 0 then
						QueriedDamage = QueriedDamage/2
					else
						QueriedDamage = QueriedDamage
					end
				end

			end
		end


		if tonumber(GetTagValue(Hitbox, "QueriedDamage")) >= 1 then PlaySound(LoadSound("MOD/snd/Projectiles/Impacts/Player/Limbs/hit_0.ogg")) end

		SetTag(Hitbox, "QueriedDamage", 0) -- makes sure the damage doesnt apply again
		SetTag(Hitbox, "S", 0)

		if tonumber(Health[CurrentBodypart]["CurrentHealth"]) < tonumber(Health[CurrentBodypart]["MaxHP"]) then
			SetTag(Hitbox, "Damaged")
		else
			RemoveTag(Hitbox, "Damaged")
		end

		if HasTag(Hitbox, "Fracture") then
			InPain = true
		end
		local dmg_blood_amount = tonumber(GetTagValue(Hitbox, "QueriedDamage")) * 3
		if HasTag(Hitbox, "Bleed") then

			SetTag(Hitbox, "QueriedDamage", 0.05)
			SetTag(Hitbox, "S", 1)


			if doBleed then
				local dir2 = TransformToParentVec(GetPlayerTransform(), Vec(0,1,0))
				--Blood_Pool(VecAdd(GetPlayerTransform().pos,dir2), 1 + math.random(), 2, nil, ((math.random()+0.2)*2), clamp(math.random() ^ 0.75, 0, 0.8))
			end

			if Bleedstoprnd < WoundClose and not Stopped then
				RemoveTag(Hitbox, "Bleed")
				Stopped = true
			end
		end

		if Healing ~= 0 then
			SetTag(Hitbox, "QueriedDamage", -Healing)
		end

		SetTag(Hitbox, "CurrentHealth", Health[CurrentBodypart]["CurrentHealth"])
		SetTag(Hitbox, "MaxHP", Health[CurrentBodypart]["MaxHP"])

		--[[ if CurrentBodypart == "HEAD" and InputPressed("L") then
			--SetTag(Hitbox, "QueriedDamage", 9)
			--SetTag(Hitbox, "S", 1)
		end ]]
		--DebugPrint(FDM)

		if CurrentBodypart == "LLEG" or CurrentBodypart == "RLEG" then
			if HasTag(Hitbox, "Fracture") or HasTag(Hitbox, "BlackOut") then
				PlayerSlow = true
				FallDamage = FallDamage + 0.1
			end
			if CHP <= 0 or HasTag(Hitbox, "Fracture") then

				if BLDMG > 2 + math.random(1, 100) / 300 then
					SetTag(Hitbox, "QueriedDamage", 9) -- Damages leg if its broken and the player is sprinting
					SetTag(Hitbox, "S", 0)
					BLDMG = 0
				end
				PlayerSlow = true -- If player sustains enough leg damage or breaks their leg, player will be slow
			end
		end
		if FallDamage == 1 then
			PlayerSlow = false
		end



		-- DebugCross(Vec(0,1.5,0))
		if QueriedDamage ~= 0 then

			if doBleed then
				--Blood_Pop(VecAdd(GetPlayerTransform().pos,Vec(0,1,0)), 50, 3, nil, Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1)))
			end

			if CurrentBodypart == "HEAD" and QueriedDamage > 0 then -- If QDMG (Queried damage) is larger than 0, that means it hit the head. Add confusion effects.
				if not Godmode then
					if math.random() < FartChance then
						PlaySound(Sounds.fard)
					else
						PlaySound(Sounds.headshot)
					end
					if not GetString("savegame.mod.difficulty") == "hardcore" then
						Confusion = 1
					else
						Confusion = math.random(1,2) + math.random()
					end
				end
			end
			if QueriedDamage < 0 and CHP < tonumber(Health[CurrentBodypart]["MaxHP"]) then
				if not Godmode then
					Health[CurrentBodypart]["CurrentHealth"] = CHP - QueriedDamage
				end
			end
			if CHP > 0 and QueriedDamage > 0 then
				if CAL > 0 and QueriedDamage > 10 then
					rndgen = math.random(0, 100)
					if rndgen < RicochetChance then
						Ricochet = true
					else
						Ricochet = false
					end
				end
				if not Godmode then
					if not Ricochet or QueriedDamage <= 10 then
						--DebugPrint("Damage taken: "..QDMG)
						if Pen ~= 0 then
						Health[CurrentBodypart]["CurrentHealth"] = CHP - (QueriedDamage / (1 + CAL / 3)) * Pen -- This is very important, this sets the player health
					else
						Health[CurrentBodypart]["CurrentHealth"] = CHP - QueriedDamage
						end
					end
					if CAL > 0 then
						if CurrentBodypart ~= "HEAD" then
								damagetakenarm = (QueriedDamage / (1 + CAL / 3)) * Pen
							if Ricochet then
								damagetakenarm = ((QueriedDamage / (1 + CAL / 3)) * Pen) * 2
							end
							--DebugPrint("AdvancedHealthScript.lua | QueriedDamage = " .. QueriedDamage .. "")
						--	DebugPrint("AdvancedHealthScript.lua | Cal = " .. CAL .. "")
							--DebugPrint("AdvancedHealthScript.lua | Pen = " .. Pen .. "")
							if pen == 0 then
								SetFloat("level.damagetaken",math.random())
							else
								SetFloat("level.damagetaken",damagetakenarm/DMGREDUC)
							end
						end
						if CurrentBodypart == "HEAD" then
							damagetakenarm = (QueriedDamage / (1 + CAL / 3)) * Pen
							if Ricochet then
								damagetakenarm = ((QueriedDamage / (1 + CAL / 3)) * Pen) * 2
							end
							if pen == 0 then
								SetFloat("level.damagetaken2",math.random())
							else
								SetFloat("level.damagetaken2",damagetakenarm/DMGREDUC)
							end
						end
						if Ricochet and CAL ~= 0 then
							PlaySound(LoadSound("MOD/assets/snd/Projectiles/Impacts/Ricochets/ricochet" .. math.random(1, 3) .. ".ogg"))
							--DebugPrint("Ricochetted:")
							--DebugPrint(Ricochet)
							--DebugPrint("Queried Damage: "..QDMG)
							--DebugPrint("Pen: "..Pen)
							Ricochet = false
							QueriedDamage = 0
							Pen = 0
							SetTag(Hitbox, "QueriedDamage", 0) -- makes sure the damage doesnt apply again
							SetTag(Hitbox, "S", 0)
						end
						--SetString("savegame.mod.bodypartdamaged", CurrentBodypart)
					end
				end
				Ricochet = false
				if CurrentBodypart == "HEAD" and CAL == 0 then
					if not Godmode then
						Health[CurrentBodypart]["CurrentHealth"] = CHP - QueriedDamage
					end
				end
				Health[CurrentBodypart]["Armor"] = 0
				if QueriedDamage > 10 then
					PlaySound(Sounds.hitsnd)
					if CAL > 0 then
						DMGArmor = (QueriedDamage / (1 + CAL / 3)) * Pen
					end
					Shock = 0.5
				end
				if QueriedDamage < 10 and QueriedDamage > 3 and not dead and not Armored then
					PlaySound(Sounds.hurt)
				end
				if CurrentBodypart ~= "HEAD" and QueriedDamage > 1 then
					local bleedChance = math.random(0,100)/100 -- Bleed randomizer
					if bleedChance < C4B * Pen and CHP < tonumber(Health[CurrentBodypart]["MaxHP"]) then -- Checks if bleed should apply
						SetTag(Hitbox, "Bleed", true)
					end
					if CurrentBodypart ~= "TORSO" then
						local fractureChance = math.random(0,100)/100 -- Fracture randomizer
						if fractureChance < C4F * Pen and CHP < tonumber(Health[CurrentBodypart]["MaxHP"]) and QueriedDamage > 4 then -- Checks if fracture should apply
							SetTag(Hitbox, "Fracture", true)
						end
					end
				end
			end

			if CHP == 0 then -- This deals with blacked out (0 hp) bodyparts, distributing the damage equally to all other bodyparts if the blacked out bodypart is damaged again
				if QueriedDamage > 0 then
					if QueriedDamage > 10 then
						PlaySound(Sounds.hitsnd)
						Shock = 0.5
					else
						if QueriedDamage > 3 and not dead then
							PlaySound(Sounds.hurt)
							Shock = 0.5
						end
					end
					BlackOuts = FindTriggers("BlackOut")
					for z = 1, #Hitboxes do
						Hitbox2 = Hitboxes[z]
						if not HasTag(Hitbox2, "BlackOut") then
							DDMG = QueriedDamage / (#Hitboxes - #BlackOuts)
							CurrentBodypart2 = GetTagValue(Hitbox2, "localhitbox")
							CHP2 = tonumber(Health[CurrentBodypart2]["CurrentHealth"])
							if not Godmode then
								Health[CurrentBodypart2]["CurrentHealth"] = CHP2 - DDMG / (1 + CAL / 3)
							end
							DMGArmor = (DDMG / (1 + CAL / 3)) * Pen
							Health[CurrentBodypart]["Armor"] = 0
						end
					end
				end
			end
		end
		if CHP < 0 then
			Health[CurrentBodypart]["CurrentHealth"] = 0 -- if health is lower than 0, health will be 0 and bodypart will be given a tag
			SetTag(Hitbox, "BlackOut")
		end
		if CHP > 0 then
			RemoveTag(Hitbox, "BlackOut")
		end
		if CHP > tonumber(Health[CurrentBodypart]["MaxHP"]) then
			Health[CurrentBodypart]["CurrentHealth"] = Health[CurrentBodypart]["MaxHP"] -- If health is larger than max health, health will be max health
		end

		if CurrentBodypart == "HEAD" or CurrentBodypart == "TORSO" then
			if tonumber(Health[CurrentBodypart]["CurrentHealth"]) <= 0 then -- Kills player if health is 0 for head or torso
				HealthNet_SetPlayerHealth(0) -- (v2) also requests the death ragdoll, once per death
				SetBool("health.status.dead", true)
				dead = true
				if not DeathPlayed then
					PlaySound(Sounds.death) -- Plays death sound without spamming it
					DeathPlayed = true
				end
			end
		else
			--SetPlayerHealth(100)
		end
	end


	Shock = Shock + GetFloat("level.advhealth.addShock")
	SetFloat("level.advhealth.addShock", 0)


	Shock = Shock - 0.025
	Confusion = Confusion - 0.02
	if Confusion > 0 and not Godmode and not Numbing then -- adds camera shake if player is shot in the head and survives
		local time = GetTime()
		local shakeQ = QuatEuler(math.sin(time) * 20 * Confusion^1.5, math.sin(time) * 20 * Confusion^1.5, math.sin(time) * 20 * Confusion^1.5)
		shakeQ = QuatSlerp(Quat(),shakeQ,GetFloat("options.input.headbob")/100) -- scale based on user settings
		local shakeT = Transform(Vec(),shakeQ)
		SetPlayerCameraOffsetTransform(shakeT)
	end


	process_drugs(dt)


	if TotalHealth < HealthCritical and not dead then
		local t = GetTime()
  		local speed = VecLength(GetPlayerVelocity())  -- player speed in units per second
  		local period = 0.15        -- time it takes for the camera to complete one bobbing cycle, in seconds
  		local amplitude = 0.2      -- maximum displacement of the camera, in units
  		amplitude = amplitude * GetFloat("options.input.headbob")/100 -- scale based on user settings
  		local ax = amplitude * math.sin(2 * math.pi * t / period)
  		local ay = amplitude * math.cos(2 * math.pi * t / period)/3
  		SetPlayerCameraOffsetTransform(Transform(Vec(), QuatEuler(ax, ay, 0)))
	end

	SetBool("inventory.magdrills", Methamphetamine or Energy or Adrenaline)

	SetFloat("level.player.health", TotalHealth)
	SetFloat("level.player.health_max", TotalHealth)
	HealthNet_ReportTotal(TotalHealth) -- (v2 goreai) NPCs aim worse at hurt players (was level.player.health)

	health_debug(dt)
	--[[if InputDown("alt") then
		SetBool("game.input.locktool", true)
		local scrollVal = InputValue("mousewheel")
		CurWalkingMode=math.min(math.max(CurWalkingMode+scrollVal,1),WalkingModes)
		 if InputPressed("uparrow") then
			CurWalkingMode=(CurWalkingMode+1)%WalkingModes
		elseif InputPressed("downarrow") then
			if CurWalkingMode > 1 then CurWalkingMode = CurWalkingMode - 1 else CurWalkingMode = WalkingModes end
		end
	end ]]

	process_hit_voice()

	TICK = TICK + 1

end
--- Completely heal the player.
function health_heal(dt)
	init_health()
	reset_hitboxes()
end

function reset_hitboxes(dt)
	for _, Hitbox in ipairs(Hitboxes) do
		CurrentBodypart = GetTagValue(Hitbox, "localhitbox")
		Health[CurrentBodypart]["CurrentHealth"] = Health[CurrentBodypart]["MaxHP"] -- this reheals the player and removes all effects after they die
		RemoveTag(Hitbox, "Fracture")
		RemoveTag(Hitbox, "Bleed")
	end
end

function SetHitboxes(dt)
	--DebugPrint("Shoud")
	PlayerTrans = GetPlayerTransform()
	PCT = Transform(GetPlayerCameraTransform().pos, PlayerTrans.rot)
	minused = 2.3
	rad = 0.01

	if GetTagValue(Hitbox, "localhitbox") == "HEAD" then
		hbox = GetTriggerTransform(Hitbox)
		B = TransformToParentTransform(PCT, Transform(Vec(0, 2.2 - minused, 0)))
		if GetPlayerVehicle() ~= 0 then
			B.pos = VecAdd(B.pos, VecScale(GetBodyVelocity(GetVehicleBody(GetPlayerVehicle())), 1/30))
		end
		SetTriggerTransform(Hitbox, B)
		ParticleRadius(rad)
		--SpawnParticle(hbox.pos,Vec(0,0,0),1)
		--VisualizePoint(B.pos, 0.3, 1,1,1)
	end

	if GetTagValue(Hitbox, "localhitbox") == "TORSO" then
		hbox = GetTriggerTransform(Hitbox)
		B = TransformToParentTransform(PCT, Transform(Vec(0, 1.8 - minused, 0)))
		if GetPlayerVehicle() ~= 0 then
			B.pos = VecAdd(B.pos, VecScale(GetBodyVelocity(GetVehicleBody(GetPlayerVehicle())), 1/30))
		end
		SetTriggerTransform(Hitbox, B)
		ParticleRadius(rad)
		--SpawnParticle(hbox.pos,Vec(0,0,0),1)
		--VisualizePoint(B.pos, 0.6, 0.5,0.5,0.5)
	end

	if GetTagValue(Hitbox, "localhitbox") == "LARM" then
		hbox = GetTriggerTransform(Hitbox)
		B = ternary(
			GetPlayerVehicle() ~= 0, TransformToParentTransform(PCT, Transform(Vec(0, 1.6 - minused, 0))),
			TransformToParentTransform(PCT, Transform(Vec(-0.4, 1.6 - minused, 0)))
		)
		if GetPlayerVehicle() ~= 0 then
			B.pos = VecAdd(B.pos, VecScale(GetBodyVelocity(GetVehicleBody(GetPlayerVehicle())), 1/30))
		end
		SetTriggerTransform(Hitbox, B)
		ParticleRadius(rad)
		--SpawnParticle(hbox.pos,Vec(0,0,0),1)
		--VisualizePoint(B.pos, 0.8, 0,1,0)
	end

	if GetTagValue(Hitbox, "localhitbox") == "RARM" then
		hbox = GetTriggerTransform(Hitbox)
		B = ternary(
			GetPlayerVehicle() ~= 0, TransformToParentTransform(PCT, Transform(Vec(0, 1.6 - minused, 0))),
			TransformToParentTransform(PCT, Transform(Vec(0.4, 1.6 - minused, 0)))
		)
		if GetPlayerVehicle() ~= 0 then
			B.pos = VecAdd(B.pos, VecScale(GetBodyVelocity(GetVehicleBody(GetPlayerVehicle())), 1/30))
		end
		SetTriggerTransform(Hitbox, B)
		ParticleRadius(rad)
		--SpawnParticle(hbox.pos,Vec(0,0,0),1)
		--VisualizePoint(B.pos, 0.8, 1,0,0)
	end

	if GetTagValue(Hitbox, "localhitbox") == "LLEG" then
		hbox = GetTriggerTransform(Hitbox)
		B = ternary(
			GetPlayerVehicle() ~= 0, TransformToParentTransform(PCT, Transform(Vec(0, 1.6 - minused, 0))),
			TransformToParentTransform(PCT, Transform(Vec(-0.2, 1 - minused, 0)))
		)
		if GetPlayerVehicle() ~= 0 then
			B.pos = VecAdd(B.pos, VecScale(GetBodyVelocity(GetVehicleBody(GetPlayerVehicle())), 1/30))
		end
		SetTriggerTransform(Hitbox, B)
		ParticleRadius(rad)
		--SpawnParticle(hbox.pos,Vec(0,0,0),1)
		--VisualizePoint(B.pos, 0.8, 0,1,0)
	end
	if GetTagValue(Hitbox, "localhitbox") == "RLEG" then
		hbox = GetTriggerTransform(Hitbox)
		B = ternary(
			GetPlayerVehicle() ~= 0, TransformToParentTransform(PCT, Transform(Vec(0, 1.6 - minused, 0))),
			TransformToParentTransform(PCT, Transform(Vec(0.2, 1 - minused, 0)))
		)
		if GetPlayerVehicle() ~= 0 then
			B.pos = VecAdd(B.pos, VecScale(GetBodyVelocity(GetVehicleBody(GetPlayerVehicle())), 1/30))
		end
		SetTriggerTransform(Hitbox, B)
		ParticleRadius(rad)
		--SpawnParticle(hbox.pos,Vec(0,0,0),1)
		--VisualizePoint(B.pos, 0.8, 1,0,0)
	end
end

function VisualizePoint(Position, Size, R255, G255, B255)
	minimumt, maximumt = GetTriggerBounds(Hitbox)
	DrawLine(Vec(Position[1], minimumt[2], Position[3]), Vec(Position[1], maximumt[2], Position[3]), R255, G255, B255)
	--DrawLine(minimumt, maximumt, R255,G255,B255)
end

-- 0.5, 1, 0.5 nice looking green
function UpdateHealthState(dt)

	-- if InputPressed("f") then
	-- 	local index = math.random(2, #Hitboxes)
	-- 	SetTag(Hitboxes[index], "Fracture")
	-- end
	-- if InputPressed("b") then
	-- 	local index = math.random(2, #Hitboxes)
	-- 	SetTag(Hitboxes[index], "Bleed")
	-- end


	local Injured = false
	for i, hitBox in pairs(Hitboxes) do

		local CurrentBodypart = GetTagValue(hitBox, "localhitbox")

		local Bleed = HasTag(hitBox, "Bleed")
		local LastBleed = LastBodyState[CurrentBodypart]["Bleed"]
		local Fracture = HasTag(hitBox, "Fracture")
		local LastFracture = LastBodyState[CurrentBodypart]["Fracture"]

		local ColorValue = Health[CurrentBodypart]["CurrentHealth"] / Health[CurrentBodypart]["MaxHP"]
		local color
		if ColorValue == 0 then
			color = { r = 1, g = 1, b = 1, a = 1 }
		else
			color = { r = 1 - (.8 * ColorValue), g = 1 * ColorValue, b = .2 * ColorValue, a = 1 }
		end

		if CurrentBodypart == "HEAD" then
			SetHeadHealth(color)
			if Bleed ~= LastBleed then
				if Bleed then
					AddHeadHealthEffect("Bleeding", RED)
				else
					RemoveHeadHealthEffect("Bleeding")
				end
			end
			if Fracture ~= LastFracture then
				if Fracture then
					AddHeadHealthEffect("Bone Fracture", RED)
				else
					RemoveHeadHealthEffect("Bone Fracture")
				end
			end
		elseif CurrentBodypart == "TORSO" then

			-- if InputPressed("mmb") then
			-- 	Bleed = true
			-- 	SetTag(hitBox, "Bleed")
			-- end

			SetTorsoHealth(color)
			if Bleed ~= LastBleed then
				if Bleed then
					AddTorsoHealthEffect("Bleeding", RED)
				else
					RemoveTorsoHealthEffect("Bleeding")
				end
			end
			if Fracture ~= LastFracture then
				if Fracture then
					AddTorsoHealthEffect("Bone Fracture", RED)
				else
					RemoveTorsoHealthEffect("Bone Fracture")
				end
			end
		elseif CurrentBodypart == "LLEG" then
			SetLeftLegHealth(color)
			if Bleed ~= LastBleed then
				if Bleed then
					AddLeftLegHealthEffect("Bleeding", RED)
				else
					RemoveLeftLegHealthEffect("Bleeding")
				end
			end
			if Fracture ~= LastFracture then
				if Fracture then
					AddLeftLegHealthEffect("Bone Fracture", RED)
				else
					RemoveLeftLegHealthEffect("Bone Fracture")
				end
			end
		elseif CurrentBodypart == "RLEG" then
			SetRightLegHealth(color)
			if Bleed ~= LastBleed then
				if Bleed then
					AddRightLegHealthEffect("Bleeding", RED)
				else
					RemoveRightLegHealthEffect("Bleeding")
				end
			end
			if Fracture ~= LastFracture then
				if Fracture then
					AddRightLegHealthEffect("Bone Fracture", RED)
				else
					RemoveRightLegHealthEffect("Bone Fracture")
				end
			end
		elseif CurrentBodypart == "LARM" then
			SetLeftArmHealth(color)
			if Bleed ~= LastBleed then
				if Bleed then
					AddLeftArmHealthEffect("Bleeding", RED)
				else
					RemoveLeftArmHealthEffect("Bleeding")
				end
			end
			if Fracture ~= LastFracture then
				if Fracture then
					AddLeftArmHealthEffect("Bone Fracture", RED)
				else
					RemoveLeftArmHealthEffect("Bone Fracture")
				end
			end
		elseif CurrentBodypart == "RARM" then
			SetRightArmHealth(color)
			if Bleed ~= LastBleed then
				if Bleed then
					AddRightArmHealthEffect("Bleeding", RED)
				else
					RemoveRightArmHealthEffect("Bleeding")
				end
			end
			if Fracture ~= LastFracture then
				if Fracture then
					AddRightArmHealthEffect("Bone Fracture", RED)
				else
					RemoveRightArmHealthEffect("Bone Fracture")
				end
			end
		end

		LastBodyState[CurrentBodypart]["Bleed"] = Bleed
		LastBodyState[CurrentBodypart]["Fracture"] = Fracture

		Injured = Injured or Bleed or Fracture
	end

	if Injured then
		SetInjured()
	else
		SetHealthy()
	end

end

function health_debug(dt)

	Godmode = GetBool("savegame.mod.config.game.god")

	-- Draw hitboxes
	if GetBool("savegame.mod.config.game.draw_hitboxes") then
		for index, hb in ipairs(Hitboxes) do
			local min, max = GetTriggerBounds(hb)
			AabbDraw(min, max, 1,1,1, 1)
		end
	end

	-- Die
	if GetBool("savegame.mod.config.game.die") then
		dead = true
		HealthNet_SetPlayerHealth(0)
		SetBool("savegame.mod.config.game.die", false)
	end

end

function process_perks(dt)

	if GetInt("savegame.mod.perks.ricochet") ~= 0 then
		RicochetChance = GetInt("savegame.mod.perks.ricochet") * 5
	end

	if GetInt("savegame.mod.perks.sealingfabric") ~= 0 then
		DMGREDUC = 1 + GetInt("savegame.mod.perks.sealingfabric") * 10
	end

	if GetInt("savegame.mod.perks.woundclosing") ~= 0 then
		WoundClose = GetInt("savegame.mod.perks.woundclosing") *10
	end

	if GetInt("savegame.mod.perks.junkie") ~= 0 then
		extrastimtim = GetInt("savegame.mod.perks.junkie") * 0.2
	end

end

function process_drugs(dt)

	if Methamphetamine then
		if MTimer == 0 then
			PlaySound(Sounds.injection)
			Injected = 1
		end
		MTimer = MTimer + dt
		Armored = true
		Numbing = true
		Athletic = true
		SetPostProcessingProperty("bloom", 0)
		PlayLoop(Sounds.heartbeat, GetPlayerTransform().pos, 10)
		htim = htim + 0.2
		SetPostProcessingProperty("colorbalance", 1, 1 - math.abs(math.sin(htim) / 2), 1 - math.abs(math.sin(htim) / 2))
		SetCameraFov(Playerfov + math.sin(htim) * 2)
		if MTimer > MaxMTimer * (extrastimtim + 1) then
			MTimer = 0
			Methamphetamine = false
			if not Permanentlyarmored then
				Armored = false
			end
			Numbing = false
			Athletic = false
			SetPostProcessingProperty("colorbalance", 1, 1, 1)
			SetPostProcessingProperty("bloom", 1)
			htim = 0
		end
	end

	if Morphine then
		if MoTimer == 0 then
			PlaySound(Sounds.injection)
			Injected = 1
		end
		MoTimer = MoTimer + dt
		Numbing = true
		SetPostProcessingProperty("colorbalance", 0.5, 0.5, 1)
		if MoTimer > MaxMoTimer * (extrastimtim + 1) then
			MoTimer = 0
			Morphine = false
			Numbing = false
			SetPostProcessingProperty("colorbalance", 1, 1, 1)
		end
	end

	if Alchocol then
		if AlTimer == 0 then
			--PlaySound(Injection)
			Injected = 1
		end
		AlTimer = AlTimer + dt
		Numbing = true
		--SetPostProcessingProperty("colorbalance",1,1,1)
		--SetPostProcessingProperty("bloom", 0)
		--PlayLoop(Heartbeat,GetPlayerTransform().pos,10)
		--htim = htim + 0.2
		--SetPostProcessingProperty("colorbalance", 0.5, 0.5, 1)
		--SetCameraFov(Playerfov + math.sin(htim)*2)

		local t = GetTime()
  		local speed = VecLength(GetPlayerVelocity())  -- player speed in units per second
  		local period = 12         -- time it takes for the camera to complete one bobbing cycle, in seconds
  		local amplitude = 14      -- maximum displacement of the camera, in units
  		amplitude = amplitude * GetFloat("options.input.headbob")/100 -- scale based on user settings
  		local ax = amplitude * math.sin(2 * math.pi * t / period)
  		local ay = amplitude * math.cos(2 * math.pi * t / period)/3
  		SetPlayerCameraOffsetTransform(Transform(Vec(), QuatEuler(ax, ay, 0)))


		if AlTimer > MaxAlTimer then
			AlTimer = 0
			Alchocol = false
			Numbing = false
		end
	end

	if Energy then
		if EnTimer == 0 then
			--PlaySound(Injection)
			Injected = 1
		end
		EnTimer = EnTimer + dt
		Athletic = true
		if EnTimer > MaxEnTimer * (extrastimtim + 1) then
			EnTimer = 0
			Energy = false
			Morphine = false
			Numbing = false
			Athletic = false
		end
	end

	if Adrenaline then
		if ATimer == 0 then
			PlaySound(Sounds.injection)
			Injected = 1
		end
		ATimer = ATimer + dt
		Numbing = true
		Athletic = true
		Healing = 0.1
		--SetPostProcessingProperty("colorbalance",1,1,1)
		--SetPostProcessingProperty("bloom", 0)
		--PlayLoop(Heartbeat,GetPlayerTransform().pos,10)
		--htim = htim + 0.2
		SetPostProcessingProperty("colorbalance", 0.2, 0.7, 0.2)
		--SetCameraFov(Playerfov + math.sin(htim)*2)
		if ATimer > MaxATimer * (extrastimtim + 1) then
			ATimer = 0
			Adrenaline = false
			Numbing = false
			Athletic = false
			Healing = 0
			SetPostProcessingProperty("colorbalance", 1, 1, 1)
		end
	end

	if Weed then
		if WTimer == 0 then
			PlaySound(Sounds.injection)
			Injected = 1
		end
		WTimer = WTimer + dt
		Numbing = false
		Healing = 0.01
		SetPostProcessingProperty("colorbalance", 0.1, 0.9, 0.1)
		--SetCameraFov(Playerfov + math.sin(htim)*2)
		if WTimer > MaxWTimer * (extrastimtim + 1) then
			WTimer = 0
			Weed = false
			Numbing = false
			Athletic = false
			Healing = 0
			SetPostProcessingProperty("colorbalance", 1, 1, 1)
		end
	end

end


function client.draw(dt)
	
	
	
	
	-- DebugWatch("TotalHealth", TotalHealth)

	-- Draw_PlayerDamageWarnings()
	Draw_PlayerDamageOverlay()

	UiPush()
		UiColor(1, 1, 1, Injected)
		UiImageBox("MOD/player/HealthSystem/UI/Confusion.png", UiWidth(), UiHeight(), 10, 10)
		Injected = Injected - 0.05
		--DebugPrint(dead)
		--DebugPrint(TotalHealth)
		if not Numbing then
			UiColor(1, 1, 1, Shock)
			UiImageBox("MOD/player/HealthSystem/UI/Shock.png", UiWidth(), UiHeight(), 10, 10)
			UiImageBox("MOD/player/HealthSystem/UI/Critical.png", UiWidth(), UiHeight(), 10, 10) -- Draws all the onscreen effects
			UiColor(1, 1, 1, clamp(Confusion, 0, 1)* 0.75)
			UiImageBox("MOD/player/HealthSystem/UI/Confusion.png", UiWidth(), UiHeight(), 10, 10)
			if TotalHealth < 150 and not dead then
				PlayLoop(Sounds.critical)
				UiColor(1, 1, 1, 0.6)
				UiImageBox("MOD/player/HealthSystem/UI/Critical.png", UiWidth(), UiHeight(), 10, 10)
			end
		end
	UiPop()

	UiPush()
	--drawAPH()
	UiPop()

	CheckHealthUi()
	UpdateHealthState()
	DrawUiHealthOverlay(dt)

end
-- Draw red overlay around egdes of screen.
function Draw_PlayerDamageOverlay(dt)

	TotalHealthLast = TotalHealthLast or TotalHealth
	HudDamageAlpha = HudDamageAlpha or 0

	if TotalHealth < TotalHealthLast
	or GetFloat("level.player.health") < HealthCritical
	then
		HudDamageAlpha = 1
	end

	if HudDamageAlpha > 0 then
		UiPush()
			UiColor(1,1,1, HudDamageAlpha ^ 1.5)
			UiImageBox("MOD/assets/img/hud_player_damage.png", UiWidth(), UiHeight())
			UiColor(1,1,1, HudDamageAlpha)
			UiImageBox("MOD/assets/img/hud_player_damage.png", UiWidth(), UiHeight())
		UiPop()
	end

	HudDamageAlpha = HudDamageAlpha - GetTimeStep()
	TotalHealthLast = TotalHealth

end

function Draw_PlayerDamageWarnings(dt)

	if TotalHealth <= 0 then
		return
	end

	UiPush()

		UiTranslate(UiCenter(), UiMiddle()+ 300)

		for key, hitbox in pairs(Hitboxes) do

			if HasTag(hitbox, "Bleed") then

				local w, h = 400, 40

				UiTranslate(-w/2, -h/2)
				local s = Oscillate()/2
				-- UiProgressBarTitledA("BLEEDING OUT", TotalHealth, HealthMax, w, h, 0.7,0,0,s)

				UiColor(0.7,0,0, s)
				UiText("BLEEDING OUT")

				break

			end

		end

	UiPop()
end

function drawAPH(dt)
	for i = 1, #Hitboxes do
		Hitbox = Hitboxes[i]
		CurrentBodypart = GetTagValue(Hitbox, "localhitbox")
		ColorValue = Health[CurrentBodypart]["CurrentHealth"] / Health[CurrentBodypart]["MaxHP"]
		UiColor(1, ColorValue, 0, 1)
		if ColorValue == 0 then
			UiColor(1, 1, 1, 1)
		end
		if not HasTag(Hitbox, "Fracture") and not HasTag(Hitbox, "Bleed") then
			UiImageBox("MOD/player/HealthSystem/UI/" .. CurrentBodypart .. ".png", 250, 523, 10, 10)
		end
		if HasTag(Hitbox, "Bleed") then
			UiImageBox("MOD/player/HealthSystem/UI/" .. CurrentBodypart .. "B" .. ".png", 250, 523, 10, 10)
		end
		if HasTag(Hitbox, "Fracture") then
			UiImageBox("MOD/player/HealthSystem/UI/" .. CurrentBodypart .. "F" .. ".png", 250, 523, 10, 10)
		end
		if HasTag(Hitbox, "Fracture") and HasTag(Hitbox, "Bleed") then
			UiImageBox("MOD/player/HealthSystem/UI/" .. CurrentBodypart .. "BF" .. ".png", 250, 523, 10, 10)
		end
	end
end

function CheckHealthUi(dt)
	if KeybindPressed(Settings.keybinds.player.healthUI_toggle) then
		if not MyHealthUiIsActive then
			MyHealthUiIsActive = true
			SetBool("health.ui.shown", true)
		else
			MyHealthUiIsActive = false
			SetBool("health.ui.shown", false)
		end
	end

	if MyHealthUiIsActive then
		ShowUiHealthOverlay()
	else
		HideUiHealthOverlay()
	end

	--[[ if InputPressed("x") and MyHealthUiIsActive then
		ToggleUiHealthDetailsOverlay()
	end ]]
end

function FancyPostProcessingEffects(dt)
	if InPain and not Numbing then
		--SetPostProcessingProperty("saturation", 0)
		SetPostProcessingProperty("bloom", 15)
	else
		--SetPostProcessingProperty("saturation", Saturation)
		SetPostProcessingProperty("bloom", Bloom)
	end
end



function Unused(Position, Size, Color)
	Position = Vec(Position[1] + Size / 2, Position[2] + Size / 2, Position[3] + Size / 2)
	DrawLine(VecSub(Position, Vec(0, Size, 0)), Position, 1, 1, 0)
	DrawLine(VecSub(Position, Vec(0, Size, 0)), VecSub(Position, Vec(Size, Size, 0)), Color, Color, Color)
	DrawLine(VecSub(Position, Vec(0, Size, 0)), VecSub(Position, Vec(0, Size, Size)), Color, Color, Color)
	DrawLine(VecSub(Position, Vec(0, Size, Size)), VecSub(Position, Vec(Size, Size, Size)), Color, Color, Color)
	DrawLine(VecSub(Position, Vec(0, 0, Size)), Position, Color, Color, Color)
	DrawLine(VecSub(Position, Vec(0, 0, Size)), VecSub(Position, Vec(Size, 0, Size)), Color, Color, Color)
	DrawLine(VecSub(Position, Vec(0, 0, Size)), VecSub(Position, Vec(0, Size, Size)), Color, Color, Color)
	DrawLine(VecSub(Position, Vec(Size, 0, Size)), VecSub(Position, Vec(Size, Size, Size)), Color, Color, Color)
	DrawLine(VecSub(Position, Vec(Size, 0, 0)), Position, Color, Color, Color)
	DrawLine(VecSub(Position, Vec(Size, 0, 0)), VecSub(Position, Vec(Size, 0, Size)), Color, Color, Color)
	DrawLine(VecSub(Position, Vec(Size, 0, 0)), VecSub(Position, Vec(Size, Size, 0)), Color, Color, Color)
	DrawLine(VecSub(Position, Vec(Size, Size, 0)), VecSub(Position, Vec(Size, Size, Size)), Color, Color, Color)
end
function QuatToEuler(quat) -- Converts quat to euler
	local euler = {}
	local x, y, z = GetQuatEuler(quat)
	euler[1] = x
	euler[2] = y
	euler[3] = z
	return euler
end
function Split(s, delimiter)
	result = {}
	for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end
function hitByExplosion(strength, pos)

	local P = GetPlayerTransform()
	d = VecDist(P.pos, pos)

	--DebugPrint(strength)
	--DebugPrint(d)

	if d < strength then

		-- for i = 1, #Hitboxes do

		-- 	Hitbox = Hitboxes[i]

		-- 	SetTag(Hitbox, "QueriedDamage", 800)
		-- 	SetTag(Hitbox, "S", 1)

		-- end

	else

		AmountOfHitboxesHit = math.random(1,math.max(d*2-strength*2,1))
		for i=1,AmountOfHitboxesHit do
			whichhitboxhit = math.random(1,#Hitboxes)
			Hitbox = Hitboxes[whichhitboxhit]
			if Hitbox ~= nil then
				SetTag(Hitbox, "QueriedDamage", (strength*60)/d )
				SetTag(Hitbox, "S", 1)
			end
		end

	end

	if d < strength*7 then
		Confusion = 0.4
		if math.random(1,100)/100 < FartChance then
					PlaySound(Sounds.fard)
					else
					PlaySound(Sounds.headshot)
					end
	end

end
function client.handleCommand(cmd)
    local words = splitString(cmd, " ")
    if #words == 5 then
        if words[1] == "explosion" then
            HealthExplosion(tonumber(words[2]), tonumber(words[3]), tonumber(words[4]), tonumber(words[5]))
        end
    end
end

-- explosion near this player: line-of-sight check, then hitByExplosion (unchanged v1 logic)
function HealthExplosion(strength, x, y, z)
    do
        do
			local pos = Vec(x, y + 0.1, z)

			lastEXPPos=pos

			local playerT = GetPlayerTransform()
			local playerTorsoPos = VecAdd(playerT.pos, Vec(0,1,0))
			lastTorsoPos=playerTorsoPos
			local dist = VecDist(playerTorsoPos, pos)
			if dist < 20 then
				--DebugPrint('exp in range')
				QueryRequire('physical large')

				local hit, hitPos = RaycastFromTransform(Transform(playerTorsoPos, QuatLookAt(playerTorsoPos, pos)), dist)
				lastHitPos=hitPos

				--DebugPrint("dist from hitpos to exp source: "..VecDist(hitPos, pos))
				if not hit or VecDist(hitPos, pos) < .2 then
					--DebugPrint("yes LoS")
					hitByExplosion(strength, pos)
				end
			end

        end
    end
end


function init_hit_impact_sounds()

	Sounds.hits_limbs = {
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_1.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_2.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_3.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_4.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_5.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_6.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_7.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_8.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_9.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_10.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_11.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_12.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_13.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Limbs/player_impact_limbs_14.ogg"),
	}

	Sounds.hits_torso = {
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_1.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_2.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_3.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_4.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_5.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_6.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_7.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_8.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_9.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_10.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_11.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_12.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_13.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_14.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_15.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_16.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_17.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_18.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_19.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_20.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Torso/player_impact_torso_21.ogg"),
	}

	Sounds.hits_helmet = {
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Helmet/player_impact_helmet_1.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Helmet/player_impact_helmet_2.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Helmet/player_impact_helmet_3.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Helmet/player_impact_helmet_4.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Helmet/player_impact_helmet_5.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Helmet/player_impact_helmet_6.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Helmet/player_impact_helmet_7.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Helmet/player_impact_helmet_8.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Helmet/player_impact_helmet_9.ogg"),
		LoadSound("MOD/assets/snd/Projectiles/Impacts/Player/Helmet/player_impact_helmet_10.ogg"),
	}

    HitVoice = {
        playTimestamp = 0,
        playIntervalRange = { 1, 3 },
        playedLastTime = 0,
        pitch = 1,
        lastSoundPlayed = nil,
    }

	HealthPreviousTick = {
		HEAD = math.huge,
		TORSO = math.huge,
		LARM = math.huge,
		RARM = math.huge,
		LLEG = math.huge,
		RLEG = math.huge,
	}

	PlayerHitSoundsLimbs = {
		HEAD 	= Sounds.hits_limbs,
		TORSO 	= Sounds.hits_torso,
		LARM 	= Sounds.hits_limbs,
		RARM 	= Sounds.hits_limbs,
		LLEG 	= Sounds.hits_limbs,
		RLEG 	= Sounds.hits_limbs,
	}

	process_hit_voice()

end

function process_hit_voice()

	-- Why must more jank come from jank </3
	for _, Hitbox in ipairs(Hitboxes) do
		local currentBodypart = GetTagValue(Hitbox, "localhitbox")
		local currentHealth = tonumber(Health[currentBodypart]["CurrentHealth"])
		if currentHealth == 0 then
			return
		end
	end

	-- Check for damaged limbs.
	for _, Hitbox in ipairs(Hitboxes) do

		local currentBodypart = GetTagValue(Hitbox, "localhitbox")
		local currentHealth = tonumber(Health[currentBodypart]["CurrentHealth"])

		-- DebugWatch(currentBodypart, currentHealth)

		if currentHealth < tonumber(HealthPreviousTick[currentBodypart]) and not HasTag(Hitbox, "Bleed") then

			local randomPitch = AutoMap(math.random(), 0, 1, 0.9, 1.1)
			PlaySound(GetRandomArrayValue(PlayerHitSoundsLimbs[currentBodypart]), GetPlayerTransform().pos, 1, randomPitch)

			if currentBodypart == "HEAD" and Health.HEAD.Armor > 0 then
				PlaySound(GetRandomArrayValue(Sounds.hits_helmet), GetPlayerTransform().pos, 1, randomPitch)
			end

		end

	end

	-- Update limb data for next tick.
	for _, Hitbox in ipairs(Hitboxes) do

		local currentBodypart = GetTagValue(Hitbox, "localhitbox")
		local currentHealth = tonumber(Health[currentBodypart]["CurrentHealth"])
		HealthPreviousTick[currentBodypart] = currentHealth

	end

	-- if InputDown("alt") and InputPressed("b") then
	-- 	create_random_bleed()
	-- elseif InputDown("alt") and InputPressed("f") then
	-- 	create_random_fracture()
	-- end

end

function create_random_bleed()
	local hbs = DeepCopy(Hitboxes)
	TableShuffleInPlace(hbs)
	for _, Hitbox in ipairs(hbs) do
		SetTag(Hitbox, "Bleed")
		break
	end
end

function create_random_fracture()
	local hbs = DeepCopy(Hitboxes)
	TableShuffleInPlace(hbs)
	for _, Hitbox in ipairs(hbs) do
		SetTag(Hitbox, "Fracture")
		break
	end
end


-------------------------------------------------------------------------------------------------------------
-- (v2) Networking
-------------------------------------------------------------------------------------------------------------

LOCAL_HITBOX_XML = [[
<prefab version="1.5.0">
	<group>
		<trigger tags="localhitbox=HEAD QueriedDamage=0" pos="0.0 1.4 0.05" type="box" size=".3 .3 .3"/>
		<trigger tags="localhitbox=LARM QueriedDamage=0" pos="0.35 0.6 0.0" type="box" size=".2 .7 .2"/>
		<trigger tags="localhitbox=LLEG QueriedDamage=0 localLLEG" pos="0.15 0.0 0.0" type="box" size=".2 .7 .2"/>
		<trigger tags="localhitbox=RARM QueriedDamage=0" pos="-0.35 0.6 0.0" type="box" size=".2 .7 .2"/>
		<trigger tags="localhitbox=RLEG QueriedDamage=0 localRLEG" pos="-0.15 0.0 0.0" type="box" size=".2 .7 .2"/>
		<trigger tags="localhitbox=TORSO QueriedDamage=0 localTORSO" pos="0.0 0.8 0.0" type="box" size=".5 .6 .3"/>
	</group>
</prefab>
]]

-- SetPlayerHealth is server-only, so it takes a few frames to arrive. This script keeps the engine health at 1
-- while alive (its own per-limb health decides death); that keep-alive is only sent when the engine value differs,
-- at most 10 times per second.
-- Death is a state: the first death request goes out immediately (with the ragdoll request), and until the engine
-- health has actually reached 0 and come back (respawn) no keep-alive is sent and the "alive again -> reheal"
-- branch is skipped. v1 applied SetPlayerHealth(0) instantly; without this the reheal ran in the frames before the
-- server applied it, and the death branch spawned a ragdoll every tick.
local healthNetLastSend = -1
local healthNetDying = false        -- we asked the server to kill us
local healthNetDeathApplied = false -- the engine health has reached 0 since
local healthNetDyingSince = 0
function HealthNet_Dying()
	return healthNetDying
end
function HealthNet_Update()
	if not healthNetDying then return end
	if GetPlayerHealth() <= 0 then
		healthNetDeathApplied = true
	elseif healthNetDeathApplied then
		-- respawned: back to normal
		healthNetDying = false
		healthNetDeathApplied = false
	elseif GetTime() - healthNetDyingSince > 2 then
		-- the request got lost: ask again
		healthNetDyingSince = GetTime()
		ServerCall("server.healthSetPlayerHealth", GetLocalPlayer(), 0)
	end
end
function HealthNet_SetPlayerHealth(h)
	if h <= 0 then
		if not healthNetDying then
			healthNetDying = true
			healthNetDeathApplied = false
			healthNetDyingSince = GetTime()
			ServerCall("server.healthSetPlayerHealth", GetLocalPlayer(), 0)
			ServerCall("server.healthDied", GetLocalPlayer()) -- death ragdoll (was Die.lua), once per death
		end
		return
	end
	if healthNetDying then return end
	if math.abs(GetPlayerHealth() - h) > 0.001 and GetTime() - healthNetLastSend > 0.1 then
		healthNetLastSend = GetTime()
		ServerCall("server.healthSetPlayerHealth", GetLocalPlayer(), h)
	end
end

local healthNetWalkingSpeed = nil
function HealthNet_SetWalkingSpeed(s)
	if s ~= healthNetWalkingSpeed then
		healthNetWalkingSpeed = s
		ServerCall("server.healthSetWalkingSpeed", GetLocalPlayer(), s)
	end
end

-- (v2 goreai) Total limb health → server registry level.goreai.player_health.<p> (GoreAI_PlayerHealth).
local healthNetReported, healthNetReportTime = nil, -10
function HealthNet_ReportTotal(h)
	if healthNetReported ~= nil and h == healthNetReported then return end
	if healthNetReported ~= nil and math.abs(h - healthNetReported) < 5 and GetTime() - healthNetReportTime < 1 then return end
	healthNetReported, healthNetReportTime = h, GetTime()
	ServerCall("server.healthReport", GetLocalPlayer(), h)
end

function server.healthReport(p, h)
	SetFloat("level.goreai.player_health." .. p, h)
end

function server.healthSetPlayerHealth(p, h)
	SetPlayerHealth(h, p)
end

-- (v2 fix 2026-11-07) the engine resets the walking speed every frame (the official example sets it in every
-- server.tick), so a speed sent once was lost: sprint never worked. Remember each player's speed, apply every tick.
WalkingSpeeds = {}
function server.healthSetWalkingSpeed(p, s)
	WalkingSpeeds[p] = s
end

function server.tick(dt)
	for p, s in pairs(WalkingSpeeds) do
		if IsPlayerValid(p) then SetPlayerWalkingSpeed(s, p) else WalkingSpeeds[p] = nil end
	end
end

-- Death ragdoll for player p (moved here from player/HealthSystem/Die.lua, which only saw the host).
function server.healthDied(p)
	local pltrans = GetPlayerTransform(p)
	local x, y, z = GetQuatEuler(pltrans.rot)
	pltrans.rot = QuatEuler(x, y, z)
	pltrans.pos = Vec(pltrans.pos[1], pltrans.pos[2] + 1, pltrans.pos[3])
	local entities = Spawn("MOD/player/HealthSystem/prefab/" .. GetString("savegame.mod.difficulty") .. ".xml", pltrans)
	-- (v2) the ragdoll keeps the player's momentum (v1 launchragdoll.lua did this on its first tick; that script is
	-- now the client-side death camera only)
	local vel = GetPlayerVelocity(p)
	for _, e in ipairs(entities) do
		if GetEntityType(e) == "body" and HasTag(e, "bodypart") then SetBodyVelocity(e, vel) end
	end
end

