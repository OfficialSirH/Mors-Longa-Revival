SunDir = Vec(0, 0, 0)



function ManageEnvLerping()

    local phaseIndex = FindTableItemByValue(DayPhasesTable, 'name', GetDayPhase()) -- Find the index of the current phase of day.
    local nextPhaseIndex = GetTableNextIndex(DayPhasesTable, phaseIndex) -- Index of the next phase of day.

    local dayPhase1 = DayPhasesTable[phaseIndex] -- Base env.
    local dayPhase2 = DayPhasesTable[nextPhaseIndex] -- Lerp target env.


    -- Convert phase time range to lerp fraction.
    local range = GetHourDistance(dayPhase1.startH, dayPhase2.startH) -- Total number of hours.
    local hoursCompleted = GetHourDistance(dayPhase1.startH, HoursMod()) -- Current Hours within range.
    local fraction = (gtZero(hoursCompleted)) / range

    LerpENVs(DeepCopy(dayPhase1.env), DeepCopy(dayPhase2.env), fraction)


    SunDir[1] =  2 * math.cos(math.pi * ((Hours)/12) + ((-6 * math.pi)/12))
    SunDir[2] = -2 * math.cos(math.pi * ((Hours)/12))
    -- SunDir[3] = -GetTime()
    SunDir[3] = 0
    SetEnvironmentProperty('sunDir', SunDir[1], SunDir[2], SunDir[3])


    -- if InputPressed('l') then PrintEnv() end


    -- Override sun brightness
    if GetBool("savegame.mod.config.daynight.override_sun_brightness") then
        local sun_brightness = GetFloat("savegame.mod.config.daynight.sun_brightness")
        SetEnvironmentProperty('sunBrightness', sun_brightness)
    end

       -- DebugWatch('fraction', fraction)
    -- DebugWatch('Hour of day', HoursMod())
--    DebugWatch('dayPhase1.startH', dayPhase1.startH)
--    DebugWatch('dayPhase2.startH', dayPhase2.startH)


end


-- Get current environment properties and format it as a lua table, printed to the console.
function PrintEnv()

    for name, header in pairs(MenuItems) do

        print(name .. ' = {')

        for index, prop in pairs(header) do

            print('    ' .. index .. ' = {')

            local args = {GetEnvironmentProperty(index)}

            for i, val in ipairs(args) do

                if type(val) == 'string' then
                    val = '"' .. val .. '"'
                end

                print('        ' .. tostring(val) .. ',')

            end

            print('    },')

        end

        print('},')

    end

end

function LerpENVs(env_template1, env_template2, fraction)

    for key, header in pairs(env_template1) do -- header = env categories.
        for name, env in pairs(header) do -- env = specific env table

            local p2env = env_template2[key][name]

            for i = 1, 4 do

                if type(env[i]) == 'number' then

                    if name == 'sunbrightness' then
                        env[i] = 2
                    else
                        env[i] = lerp(env[i], p2env[i], smoothstep(fraction, 0.5, 1))
                    end

                end

                if fraction > 0.5 then

                    if type(env[i]) == 'boolean' then

                        env[i] = env[i]

                    elseif type(env[i]) == 'string' then

                        env[i] = env[i]

                    end

                end

            end

            -- if key == 'Lighting' then
            --     DebugWatch(name, env[1])
            -- end

            SetEnvironmentProperty(name, env[1], env[2], env[3], env[4])

            if GetBool("inventory.nvg.enabled") then
                local curEyeWear = GetString("inventory.nvg.current")
                if curEyeWear == "thermals" then
                    -- Emin, Emax = GetEnvironmentProperty("exposure")
                    c1, c2, c3 = GetEnvironmentProperty("constant")
                    sun = GetEnvironmentProperty("sunBrightness")
                    sbb = GetEnvironmentProperty("skyboxbrightness")

                    -- SetEnvironmentProperty("exposure", Emin+9, Emax+9)
                    SetEnvironmentProperty("skyboxtint", 0, 0, 0)
                    SetEnvironmentProperty("constant", 0.1, 0.1, 0.1)
                    SetEnvironmentProperty("skyboxbrightness", sbb/10)
                    SetPostProcessingProperty("bloom", 0)
                    SetEnvironmentProperty("sunBrightness", 0.1)
                    SetPostProcessingProperty("saturation", 0)
				elseif curEyeWear == "pvs14" then
					Emin, Emax = GetEnvironmentProperty("exposure")
                    c1, c2, c3 = GetEnvironmentProperty("constant")
                    sun = GetEnvironmentProperty("sunBrightness")
                    SetEnvironmentProperty("exposure", Emin+9, Emax+9)
                    SetEnvironmentProperty("skyboxtint", 0, 12.9, .09)
                    SetPostProcessingProperty("colorbalance", 0.05, 0.15, .05)
                    SetEnvironmentProperty("constant", c1 - 0.7, c2 + 0.003, c3 + 0.01)
                    SetPostProcessingProperty("bloom", .7)
                    SetEnvironmentProperty("sunBrightness", sun*4 + 0.5)
                    SetPostProcessingProperty("saturation", 1.3)
				elseif curEyeWear == "pnv10t" then
					 Emin, Emax = GetEnvironmentProperty("exposure")
                    c1, c2, c3 = GetEnvironmentProperty("constant")
                    sun = GetEnvironmentProperty("sunBrightness")

                    SetEnvironmentProperty("exposure", Emin+4, Emax+4)
					SetEnvironmentProperty("skyboxtint", 0, 0.2, 0.05)
                    SetPostProcessingProperty("colorbalance", 0, 0.05, 0.15)
                    SetEnvironmentProperty("constant", c1 - 0.5, c2 + 0.05, c3 + 0.15)
                    SetPostProcessingProperty("bloom", 0)
                    SetEnvironmentProperty("sunBrightness", sun*8 + 0.5)
                    SetPostProcessingProperty("saturation", 1)
                elseif curEyeWear == "nvg" then
                    Emin, Emax = GetEnvironmentProperty("exposure")
                    c1, c2, c3 = GetEnvironmentProperty("constant")
                    sun = GetEnvironmentProperty("sunBrightness")

                    SetEnvironmentProperty("exposure", Emin+9, Emax+9)
                    SetEnvironmentProperty("skyboxtint", 0, 0.2, 0)
                    --SetPostProcessingProperty("colorbalance", 0, 0.2, 0)
                    SetEnvironmentProperty("constant", c1 - 0.5, c2 + 0.001, c3 - 0.5)
                    SetPostProcessingProperty("bloom", 0.5)
                    SetEnvironmentProperty("sunBrightness", sun*4 + 0.5)
                    SetPostProcessingProperty("saturation", 1)
                end
            else
                SetPostProcessingProperty("colorbalance", 1, 1, 1)
                SetPostProcessingProperty("saturation", 1)
            end
        end
    end

    -- SetEnvironmentProperty('skyboxrot', GetTime())

    
end


function smoothstep(x, edge1, edge2)

    local t = clamp((x - edge1) / (edge2 - edge1), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);

end