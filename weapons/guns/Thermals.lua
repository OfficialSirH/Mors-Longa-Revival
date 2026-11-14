#version 2
#include "script/include/player.lua"
#include "../../npcs/Blood/Blood.lua"

-- (v2) client only: per-player night/thermal vision.
-- v1 also recoloured "Bleedable" shapes with EditPalette, but EditPalette is not defined in this script's include
-- chain and no prefab has a "Bleedable" shape, so that never ran; a client may not edit server shapes anyway.
-- It is replaced by DrawShapeHighlight (client-side, only on the wearer's screen).
-- v1 faded each enemy's "blood" tag value by writing the tag; a client may not change server entities, so the
-- fading value is kept locally (BloodFade[body]).
-- (v2 fix) v1 searched FindBodies("bodypart"), but in the standard ragdoll that tag is on shapes and only the
-- head is a tagged body, so only heads were (faintly) highlighted. Now every NPC from the GoreNPCs lists
-- (level.goreai.api.npcs.alive/dead, torso handles) is highlighted with all bodies jointed to its torso.

function client.init()
	NVGON = false
	THERMAL = false
	findtimer = 0
	Enemies = FindNpcBodies()
	Shapes = FindShapes("Bleedable", true)
	BloodFade = {}
end

-- torso + every body reachable through joints (limbs, head), for all living and dead NPCs
function FindNpcBodies()
	local result, seen = {}, {}
	local function add(body)
		-- skip vehicle bodies: an NPC jointed to a car seat must not light up the whole car
		if body ~= 0 and not seen[body] and IsHandleValid(body) and GetBodyVehicle(body) == 0 then
			seen[body] = true
			result[#result + 1] = body
			return true
		end
		return false
	end
	for _, list in ipairs({"level.goreai.api.npcs.alive", "level.goreai.api.npcs.dead"}) do
		for _, key in ipairs(ListKeys(list)) do
			local torso = GetInt(list .. "." .. key)
			if add(torso) then
				local queue = { torso }
				while #queue > 0 and #result < 2000 do
					local b = table.remove(queue)
					for _, j in ipairs(GetJointedBodies(b)) do
						if add(j) then queue[#queue + 1] = j end
					end
				end
			end
		end
	end
	for _, b in ipairs(FindBodies("bodypart", true)) do add(b) end -- as v1 (heads)
	return result
end

local function HighlightEnemy(body, fallback)
	if HasTag(body, "blood") then
		local Opacity = BloodFade[body] or tonumber(GetTagValue(body, "blood")) or fallback
		Opacity = Opacity - .001
		if Opacity > 0.35 then
			BloodFade[body] = Opacity
			DrawBodyHighlight(body, Opacity)
		else
			DrawBodyHighlight(body, .35)
		end
	else
		DrawBodyHighlight(body, fallback)
	end
end

function client.tick(dt)
	findtimer = findtimer - dt
	DURABILITY = GetFloat("inventory.nvg.durability")
	NVGON = GetBool("inventory.nvg.enabled")
	local curEyeWear = GetString("inventory.nvg.current")
	NVG = curEyeWear == "nvg"
	THERMAL = curEyeWear == "thermals"
	PVS14 = curEyeWear == "pvs14"
	PNV10T = curEyeWear == "pnv10t"

	if NVGON and (THERMAL or PNV10T) then
		if findtimer < 0 then
			Shapes = FindShapes("Bleedable", true)
			Enemies = FindNpcBodies()
			findtimer = .25
		end
		for i=1,#Shapes do
			DrawShapeHighlight(Shapes[i], THERMAL and 0.5 or 0.2)
		end
		for i=1,#Enemies do
			HighlightEnemy(Enemies[i], THERMAL and 0.7 or 1)
		end
	end
end

function client.draw()
	if NVGON then
		UiPush()
			UiAlign("center middle")
			UiTranslate(UiWidth()/2, UiHeight()/2)
			if THERMAL then
				UiImageBox("MOD/assets/img/thermaloverlay.png", UiWidth(), UiHeight())
			elseif PVS14 then
				UiImageBox("MOD/assets/img/thermaloverlay.png", UiWidth(), UiHeight())
			elseif PNV10T then
				UiImageBox("MOD/assets/img/nvgoverlay.png", UiWidth(), UiHeight())
				UiPush()
					UiTranslate(700, 0)
					if DURABILITY > 80 then
						UiImageBox("MOD/assets/img/Battery Icons1.png", UiWidth()/10, UiHeight()/7)
					elseif DURABILITY > 60 then
						UiImageBox("MOD/assets/img/Battery Icons2.png", UiWidth()/10, UiHeight()/7)
					elseif DURABILITY > 40 then
						UiImageBox("MOD/assets/img/Battery Icons3.png", UiWidth()/10, UiHeight()/7)
					elseif DURABILITY > 20 then
						UiImageBox("MOD/assets/img/Battery Icons4.png", UiWidth()/10, UiHeight()/7)
					elseif DURABILITY > 0 then
						UiImageBox("MOD/assets/img/Battery Icons5.png", UiWidth()/10, UiHeight()/7)
					end
				UiPop()
			else
				UiImageBox("MOD/assets/img/nvgoverlay.png", UiWidth(), UiHeight())
			end
			--local lol = math.random(1,5)
			UiColor(0.3,0.3,0.3,0.4)
			if PVS14 then
				UiColor(0.15,0.7,0.15,0.30)
				UiImageBox("MOD/assets/img/nvgoverlay3.png", UiWidth(), UiHeight(), 10, 10)
			elseif PNV10T then
				UiColor(0.2,1.5,1.5,0.1)
				UiImageBox("MOD/assets/img/nvgoverlay4.png", UiWidth(), UiHeight(), 10, 10)
			elseif NVG then
				UiColor(0.2,0.5,0.2,0.25)
				UiImageBox("MOD/assets/img/nvgoverlay2.png", UiWidth(), UiHeight(), 10, 10)
			end
			UiImageBox("MOD/assets/img/noise" .. math.random(1,5) .. ".png", UiWidth(), UiHeight(), 10, 10)
		UiPop()
	end

end

