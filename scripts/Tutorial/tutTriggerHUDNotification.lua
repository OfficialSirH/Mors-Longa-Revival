--[[
#include "../../scripts/TDSU/tdsu.lua"
#include "../../Settings.lua"
]]

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

function init()
	Init_Settings()

	local flatKeybinds = {}
	flattenSettingsTable(Settings.keybinds,flatKeybinds)

	Colors = {
		red = Vec(1,0,0),
		white = Vec(1,1,1),
	}

	triggers = FindTriggers("tutNotification",true)

	for i,trigger in ipairs(triggers)do
		local Desc = GetDescription(trigger+1)
		Desc = Desc:gsub("(<[%w_]->)", flatKeybinds)
		SetDescription(trigger+1,Desc)
	end

	CurrentTriggerTitle = nil
	CurrentTrigger = nil
	Desc = ""

	playerNoMove = false
	playerNoMoveCD = 0

	triggerTriggered={}
end
function tick(dt)

	Focus_Bodies = FindBodies("focus", true)
	Focus_Shapes = FindShapes("focus", true)

	local osc = Oscillate(2)

	SetBool("level.tutorial", true)

	local pT = GetPlayerTransform()
	for i,trigger in ipairs(triggers)do
		if IsHandleValid(trigger)then
			if IsPointInTrigger(trigger,pT.pos)then

				Desc = GetDescription(trigger+1)
				-- SetString('hud.notification',Desc)

				CurrentTriggerTitle = string.gsub(GetTagValue(trigger, "tutNotification"), "_", " ")

				if CurrentTrigger and CurrentTrigger ~= trigger then
					beep()
					if not(triggerTriggered[trigger] or HasTag(trigger,'nostop')) then
						playerNoMove = true
						playerNoMoveCD = .5
						triggerTriggered[trigger]=true
					end
				end
				CurrentTrigger = trigger

				for _, body in ipairs(Focus_Bodies) do
					if IsPointInTrigger(CurrentTrigger, AabbGetBodyCenterPos(body)) then
						local c = Colors[GetTagValue(body, "focus")] or "white"
						DrawBodyOutline(body, c[1],c[2],c[3], 1)
						DrawBodyHighlight(body, osc/2)
					end
				end

				for _, shape in ipairs(Focus_Shapes) do
					if IsPointInTrigger(CurrentTrigger, AabbGetShapeCenterPos(shape)) then
						local c = Colors[GetTagValue(shape, "focus")] or "white"
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
	-- SetString('hud.notification',"")

end

function update(dt)
	--DebugWatch('playerNoMove',playerNoMove)
	--DebugWatch('playerNoMoveCD',playerNoMoveCD)
	local pV = GetPlayerVelocity()
	if playerNoMove then
		SetPlayerVelocity(Vec(pV[1]*.2,pV[2],pV[3]*.2))
		if playerNoMoveCD <= 0 then
			playerNoMove = false
		end	
		playerNoMoveCD = playerNoMoveCD - dt
	end
end

function draw()
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
