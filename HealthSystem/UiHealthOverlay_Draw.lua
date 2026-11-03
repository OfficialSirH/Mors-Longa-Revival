HEALTH_UI_BACKGROUND_WIDTH = 400
HEALTH_UI_BACKGROUND_HEIGHT = 258
HEALTH_UI_CONTROLS_HEIGHT = 50

HEALTH_UI_DETAIL_BACKGROUND_WIDTH = 150
HEALTH_UI_DETAIL_BACKGROUND_HEIGHT = 230
HEALTH_UI_INFO_BACKGROUND_HEIGHT = 24

HEALTH_UI_BODYSTATE_WIDTH = 150
HEALTH_UI_BODYSTATE_HEIGHT = 300

HEALTH_UI_PADDING = 20


--- Root for health ui.
function DrawUiHealthOverlay(dt)

	if not showHealthMenu or not bodyState then
        return
    end


    Font_size = 24
    UiFont("bold.ttf", 28)


	local healthText = "All Good"
	if bodyState.overall == INJURED then healthText = "Injured" end
	if bodyState.overall == DEAD then healthText = "Dead" end

    -- DRAW MAIN BACKGROUND
    UiTranslate(10, UiHeight() - HEALTH_UI_BACKGROUND_HEIGHT --[[ - HEALTH_UI_CONTROLS_HEIGHT ]] - 20)
    drawBackground()

    -- DRAW BODY STATE
    UiPush()
        UiTranslate(20,20)
        UiDrawBodyState(bodyState)
    UiPop()
    UiPush()
        UiAlign("left top")
        -- UiTranslate(HEALTH_UI_BODYSTATE_WIDTH/2,HEALTH_UI_BACKGROUND_HEIGHT - Font_size * 1.2)
        UiTranslate(HEALTH_UI_PADDING/2 ,HEALTH_UI_BACKGROUND_HEIGHT - Font_size * 1.2)
        UiFont("regular.ttf", Font_size * 0.8)
        UiText("H: HIDE UI")
    UiPop()

    -- DRAW CONTENT
    --[[ if showHealthDetails then
        UiPush()
            UiTranslate(HEALTH_UI_BODYSTATE_WIDTH, 20)
            UiHealth_Details(w, h)
        UiPop()
    else
        UiPush()
            UiTranslate(HEALTH_UI_BODYSTATE_WIDTH, 20)
            UiHealth_Vitals(HEALTH_UI_BACKGROUND_WIDTH - HEALTH_UI_BODYSTATE_WIDTH - 20, Font_size * 1.5)
        UiPop()
	end ]]

    UiPush()
        UiTranslate(HEALTH_UI_BODYSTATE_WIDTH, 20)
        UiHealth_Vitals(HEALTH_UI_BACKGROUND_WIDTH - HEALTH_UI_BODYSTATE_WIDTH - 20, Font_size * 1.5)
    UiPop()

    -- DRAW CONTROLS
    --[[ UiPush()
        UiTranslate(0, HEALTH_UI_BACKGROUND_HEIGHT + 10)
        UiHealth_Controls()
    UiPop() ]]

end



--- Hunger, thrist and fuel.
function UiHealth_Vitals(w, h)

    hunger = tonumber(GetString("savegame.mod.hunger")) or 100
    thirst = tonumber(GetString("savegame.mod.thirst")) or 100

    UiPush()
        UiAlign("center top")
        UiTranslate(w/2, 0)
        UiFont('bold.ttf', 32)
        UiText(string.upper(bodyState.overall))
    UiPop()

    if GetFloat("game.player.health") > 0 then
        UiPush()
            local margin_y = h
            local content_h = margin_y * 0.9
            UiFont('regular.ttf', margin_y/2)

            local warning_percentage = 0.05

            UiTranslate(0, margin_y)
            UiProgressBarTitled("HUNGER", hunger, 100, w, content_h, 0.5, 1, 0.5, 0.5, warning_percentage)

            UiTranslate(0, margin_y)
            UiProgressBarTitled("THIRST", thirst, 100, w, content_h, 0.4, 0.8, 1, 0.5, warning_percentage)

            UiTranslate(0, margin_y)


            -- Draw fuel progress bar if in vehicle.
            local v = tonumber(GetString("FuelScript.vehicleToDraw")) or GetPlayerVehicle()
            if v ~= 0 then
                if HasTag(v, "fuelLevel") then
                    local fuel = tonumber(GetTagValue(v, "fuelLevel"))
                    local maxFuel = tonumber(GetTagValue(v, "fuelLevelMAX"))
                    UiProgressBarTitled("FUEL", fuel, maxFuel, w, content_h, 1, 0.7, 0.2, 0.5, warning_percentage)
                end
            end
			if GetBool("level.horde.enabled") then 
            
				UiTranslate(0, Font_size * 1.2)

				UiTranslate(0, Font_size * 1.2)
				UiHealth_WaveTime(w, h)

				UiTranslate(0, Font_size * 1.2)
				UiHealth_Wave(w, h)

				UiTranslate(0, Font_size * 1.2)
				UiHealth_Money()
			else
				UiTranslate(0, Font_size * 1.2)

				UiTranslate(0, Font_size * 1.2)
				UiHealth_Clock(w, h)

				UiTranslate(0, Font_size * 1.2)
				UiHealth_DistanceProgress()

				UiTranslate(0, Font_size * 1.2)
				UiHealth_Money()
			end
			
        UiPop()
    end

end

--- List of body parts and their statuses.
function UiHealth_Details(w, h)

    UiAlign("left top")

    local y = 0
    y = WriteDetailStatus("Head: ",       bodyState.head.effects, y)
    y = WriteDetailStatus("Body: ",       bodyState.body.effects, y)
    UiTranslate(0, 10)
    y = WriteDetailStatus("Left Arm: ",   bodyState.leftArm.effects, y)
    y = WriteDetailStatus("Right Arm: ",  bodyState.rightArm.effects, y)
    UiTranslate(0, 10)
    y = WriteDetailStatus("Left Leg: ",   bodyState.leftLeg.effects, y)
    y = WriteDetailStatus("Right Leg: ",  bodyState.rightLeg.effects, y)

    for i, effect in ipairs(bodyState.effects) do
        writeText(effect.text, 18, 10, y, false, effect.color)
        y = y + 20
    end

    local startHeight = 160
    for i, effect in ipairs(bodyState.effects) do
        writeText(effect.text, 18, 10, startHeight, false, effect.color)
        startHeight = startHeight + 20
    end

end

-- Displays the daynight info.
function UiHealth_Clock(w, h)

    local day_count_text = "DAY " .. math.floor(GetFloat("level.daynight.days"))
    local time_formatted = GetString("level.daynight.time_formatted")
    local day_phase = string.upper(GetString("level.dayphase"))

    local clock_text = day_count_text .. "  |  " .. time_formatted  .. "  |  " .. day_phase
    UiText(clock_text)

end

function UiHealth_Wave(w, h)

    local current_wave_text = "Wave: " .. sfnCommas(math.floor(GetInt("savegame.mod.player.current.wave")))
    UiText(current_wave_text)
	
end

function UiHealth_WaveTime(w, h)
	if not GetBool("level.horde.ongoing.enabled") then
		local wave = GetInt("savegame.mod.player.current.wave")
		local current_wave_text = "Time Until Wave " .. wave + 1 .. " : " .. sfnCommas(math.floor(GetInt("savegame.mod.player.current.wave.time")))
		UiText(current_wave_text)
	else 
		local wave = GetInt("savegame.mod.player.current.wave")
		local current_wave_text = "Wave " .. wave .. " Ongoing"
		UiText(current_wave_text)
	end
end

--- Displays meters travelled.
function UiHealth_DistanceProgress()

    local distance_meters_text = "Distance: " .. sfnCommas(math.floor(GetFloat("savegame.mod.distanceProgressed"))) .. " meters"
    UiText(distance_meters_text)

end

--- Displays shortcut keys
function UiHealth_Controls()

    -- drawRect(6, 6, HEALTH_UI_BACKGROUND_WIDTH, HEALTH_UI_CONTROLS_HEIGHT, 0, 0, 0, 0.7)
    UiImageBox("ui/common/box-solid-6.png", HEALTH_UI_BACKGROUND_WIDTH, HEALTH_UI_CONTROLS_HEIGHT, 6, 6)

    UiFont("regular.ttf", Font_size * 0.8)
    UiTranslate(20, HEALTH_UI_CONTROLS_HEIGHT/2)
    UiAlign("left middle")
    UiText("H: HIDE UI")

    UiTranslate(HEALTH_UI_BACKGROUND_WIDTH - 40, 0)
    UiAlign("right middle")

    if showHealthDetails then
        UiText("X: SHOW MAIN INFO")
    else
        UiText("X: SHOW HEALTH INFO")
    end

end

function UiHealth_Money()
    UiPush()
        UiColor(0,1,0)
        UiText("$"..sfnCommas(tostring(GetInt("savegame.mod.player.money"))))
    UiPop()
end