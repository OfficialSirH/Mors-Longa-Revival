#version 2
--[[
#include "../../lib/TDSU/tdsu.lua"
#include "../../lib/Settings.lua"
]]
-- (v2) Tutorial tips. Client (every player): shows the title/text of the "tutNotification" trigger the LOCAL player
-- stands in, with <key> placeholders replaced by that player's own keybinds (v1 rewrote the entity description once;
-- keybinds are per machine, so each client keeps its own copy), and outlines the "focus" bodies/shapes inside it.
-- Server: when a player enters a new tip (not tagged "nostop"), slows them down for 0.5 s (SetPlayerVelocity is
-- server-only; the client asks with ServerCall). level.tutorial is set on both sides (inventory reads it on the client).

function flattenSettingsTable(t,res)
	for k,val in pairs(t) do
		if val.type==nil then
			flattenSettingsTable(val,res)
		else
			local keys = {
				val.values.k1,
				ternary(val.values.k2 == "none", nil, val.values.k2),
				ternary(val.values.k3 == "none", nil, val.values.k3),
			}
			local str = ""
			for i,key in ipairs(keys)do
				str = ", <"..key:upper()..">".. str
			end
			str = str:sub(3,#str)
			res["<"..k..">"] = str
		end

	end
end

------------------------------------------------------------------ server

function server.init()
	SetBool("level.tutorial", true)
	Slowed = {} -- [player] = seconds left
end

function server.tutSlow(p)
	Slowed[p] = .5
end

function server.update(dt)
	for p, cd in pairs(Slowed) do
		if IsPlayerValid(p) then
			local pV = GetPlayerVelocity(p)
			SetPlayerVelocity(Vec(pV[1]*.2,pV[2],pV[3]*.2), p)
		end
		cd = cd - dt
		Slowed[p] = cd > 0 and cd or nil
	end
end

------------------------------------------------------------------ client

function client.init()
	Init_Settings()

	FlatKeybinds = {}
	flattenSettingsTable(Settings.keybinds,FlatKeybinds)

	Colors = {
		red = Vec(1,0,0),
		white = Vec(1,1,1),
	}

	triggers = FindTriggers("tutNotification",true)
	Descriptions = {} -- [trigger] = text with this player's keybinds

	CurrentTriggerTitle = nil
	CurrentTrigger = nil
	Desc = ""

	triggerTriggered={}
end

-- the tip text is the description of the entity after the trigger (v1 layout)
function TriggerDescription(trigger)
	if not Descriptions[trigger] then
		local d = GetDescription(trigger+1):gsub("(<[%w_]->)", FlatKeybinds)
		Descriptions[trigger] = d:gsub("%s*\\n%s*", "\n") -- (v2 fix) the xml text has a literal "\n" (shown as-is in v1)
	end
	return Descriptions[trigger]
end

function client.tick(dt)

	Focus_Bodies = FindBodies("focus", true)
	Focus_Shapes = FindShapes("focus", true)

	local osc = Oscillate(2)

	SetBool("level.tutorial", true)

	local pT = GetPlayerTransform()
	for i,trigger in ipairs(triggers)do
		if IsHandleValid(trigger)then
			if IsPointInTrigger(trigger,pT.pos)then

				Desc = TriggerDescription(trigger)

				CurrentTriggerTitle = string.gsub(GetTagValue(trigger, "tutNotification"), "_", " ")

				if CurrentTrigger and CurrentTrigger ~= trigger then
					beep()
					if not(triggerTriggered[trigger] or HasTag(trigger,'nostop')) then
						ServerCall("server.tutSlow", GetLocalPlayer())
						triggerTriggered[trigger]=true
					end
				end
				CurrentTrigger = trigger

				for _, body in ipairs(Focus_Bodies) do
					if IsPointInTrigger(CurrentTrigger, AabbGetBodyCenterPos(body)) then
						local c = Colors[GetTagValue(body, "focus")] or Colors.white
						DrawBodyOutline(body, c[1],c[2],c[3], 1)
						DrawBodyHighlight(body, osc/2)
					end
				end

				for _, shape in ipairs(Focus_Shapes) do
					if IsPointInTrigger(CurrentTrigger, AabbGetShapeCenterPos(shape)) then
						local c = Colors[GetTagValue(shape, "focus")] or Colors.white
						DrawShapeOutline(shape, c[1],c[2],c[3], 1)
						DrawShapeHighlight(shape, osc/2)
					end
				end
				break
			end
		else
			table.remove(triggers,i)
			triggerTriggered[trigger]=nil
		end
	end

end

function client.draw()
	draw_trigger_title(CurrentTrigger)
end

function draw_trigger_title(trigger)
	if trigger then

		UiTranslate(UiCenter(), 20)
		UiAlign("center top")

		-- Background
		UiColor(0,0,0, 0.5)
		UiRect(UiCenter(), 50)

		UiColor(1,1,1, 1)
		UiTextShadow(0,0,0, 1, 0.2)
		UiFont("bold.ttf", 50)

		UiWordWrap(UiCenter())

		UiPush()
			UiAlign("left top")
			UiTranslate(-UiCenter()/2, 0)
			UiText(CurrentTriggerTitle)
		UiPop()

		UiTranslate(-UiCenter()/2, 60)
		UiAlign("left top")


		-- Background
		UiColor(0,0,0, 0.5)
		UiRect(UiCenter(), 120)

		UiColor(1,1,1, 1)
		UiFont("bold.ttf", 30)
		UiText(Desc)

	end
end
