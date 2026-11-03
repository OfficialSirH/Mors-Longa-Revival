--[[
#include "script/common.lua"
#include "UiHealthOverlay_Draw.lua"
#include "UiHealthOverlay.lua"
#include "../scripts/TDSU/tdsu.lua"
#include "../Settings.lua"
#include "../Automatic.lua"
#include "../scripts/Game/Blood/Blood.lua"
]]
function InitDefaultHealth()
	Init_Settings()
	DefaultHealth = {
		Head = {
			MaxHP = math.ceil(TotalHealth / 10.4),
			CurrentHealth = math.ceil(TotalHealth / 10.4),
			Trigger = FindTrigger("PlayerHead"),
			State = {}
		},
		Torso = {
			MaxHP = math.ceil(TotalHealth / 3.4667),
			CurrentHealth = math.ceil(TotalHealth / 3.4667),
			Trigger = FindTrigger("PlayerTorso"),
			State = {}
		},
		LeftLeg = {
			MaxHP = math.ceil(TotalHealth / 6.5),
			CurrentHealth = math.ceil(TotalHealth / 6.5),
			Trigger = FindTrigger("PlayerLeftLeg"),
			State = {}
		},
		RightLeg = {
			MaxHP = math.ceil(TotalHealth / 6.5),
			CurrentHealth = math.ceil(TotalHealth / 6.5),
			Trigger = FindTrigger("PlayerRightLeg"),
			State = {}
		},
		LeftArm = {
			MaxHP = math.ceil(TotalHealth / 6.5),
			CurrentHealth = math.ceil(TotalHealth / 6.5),
			Trigger = FindTrigger("PlayerLeftArm"),
			State = {}
		},
		RightArm = {
			MaxHP = math.ceil(TotalHealth / 6.5),
			CurrentHealth = math.ceil(TotalHealth / 6.5),
			Trigger = FindTrigger("PlayerRightArm"),
			State = {}
		},
	}
end

function InitHealth()
	TotalHealth = 100
	InitDefaultHealth()

	Health = DefaultHealth
end

function init()
	InitHealth()
	Hitboxes = FindTriggers("hitbox")

	
end

function tick(dt)
	for i=1,40 do DebugPrint("") end
	for BodyPart, Info in pairs(Health) do
		
		DebugPrint("---------------------------------------"); DebugPrint(""..BodyPart.." | "..Info.CurrentHealth.."")
	
	end
end