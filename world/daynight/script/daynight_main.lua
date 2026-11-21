#version 2
#include "script/include/player.lua"
-- (2026-11-17, DEBUG) collector probe / skip switch, off unless level.debug.* is set (lib/GcProbe.lua)
#include "../../../lib/GcProbe.lua"
DL_LABEL = "daynight_main"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../../../lib/DeleteLog.lua"
GCP_LABEL = "daynight"
--[[
#include "../../../lib/Config.lua"
#include "../../../lib/utility.lua"
#include "env_templates.lua"
#include "env.lua"
#include "sandstorm.lua"
#include "uiTools.lua"
]]

-- (v2) server: clock, environment blending, sandstorm, campfire/bed time skip (any player).
-- Client: storm sound, campfire particles, the clock text while sleeping. level.daynight.* keys are synced.
function server.init()

    init_config()

    -- Config
    CFG = {
        TIME_RUN = true,
        SHOW_UI = true,
    }

    -- TIMESCALE EXAMPLES:
    -- CFG.timeScale = 1
    -- CFG.timeScale = HoursToSeconds(1) -- Each real second = 1 in-game hour.
    -- CFG.timeScale = MinutesToSeconds(2) -- Each real second = 2 in-game minutes.
    CFG.timeScale = MinutesToSeconds(1.5) -- Each real second = 1.5 in-game minutes.


    -- Seconds = HoursToSeconds(9) -- Sets starting hour to 9am
    Seconds = HoursToSeconds(10)
    r,g,b = 1,1,1


    if config.db then
        Seconds = HoursToSeconds(14)
    end

    DayPhases = {
        Morning = "Morning",
        Noon    = "Noon",
        Evening = "Evening",
        Night   = "Night",
    }

    DayPhasesTable = {
        {title = "Morning", name = "befosunrise",   startH = 3,   env = ENV_TEMPLATES.befosunrise},
        {title = "Morning", name = "sunrise",       startH = 6,   env = ENV_TEMPLATES.sunrise},
        {title = "Noon",    name = "sunny",         startH = 12,   env = ENV_TEMPLATES.sunny},
        {title = "Noon",    name = "sunset",        startH = 16,  env = ENV_TEMPLATES.sunny},
        {title = "Evening", name = "sunsetted",     startH = 17,  env = ENV_TEMPLATES.sunset},
        {title = "Night",   name = "befonight",     startH = 20,  env = ENV_TEMPLATES.sunsetted},
        {title = "Night",   name = "night",         startH = 22,  env = ENV_TEMPLATES.befonight},
        {title = "Night",   name = "night",         startH = 23,  env = ENV_TEMPLATES.night},
    }

    initSandstorm()

    shouldDrawTime =  GetBoolParam("shouldDrawTime", true)
	-- AddTime24(0,0,0,math.random())
end

function server.tick()

    ExternalOverride = GetBool("level.daynight.override")


    if CFG.TIME_RUN then

        Seconds = Seconds + GetTimeStep() * CFG.timeScale
        Minutes = SecondsToMinutes(Seconds)
        Hours = SecondsToHours(Seconds)
        Days = SecondsToDays(Seconds)

        Time = GetTimeStamp()
        Time12 = GetTimeFormatted12H(Seconds)

    end


    -- (2026-11-15, performance) the level-wide light search once a second instead of every tick
    if GetTime() >= (CampfiresAt or 0) then
        CampfiresAt = GetTime() + 1
        Campfires = FindLights("Campfire", true)
    end
    for i=1,#Campfires do
        CampfirePos = GetLightTransform(Campfires[i]).pos
        for p in Players() do
            if VecLength(VecSub(GetPlayerTransform(p).pos,CampfirePos)) < 10 then
                AddTime24(20,0,0,0)
                TryEndSandStorm(20/CFG.timeScale*60)
                break
            end
        end
    end

    -- Sleeping in a bed (was in draw in v1): any player holding interact on a "Bed" body skips time.
    for p in Players() do
        if InputDown("interact", p) and HasTag(GetPlayerInteractBody(p), "Bed") then
            AddTime24(0,0,0.05,0)
            TryEndSandStorm(HoursToSeconds(0.1)/CFG.timeScale*60)
            break
        end
    end


    if config.daynight.override_weather and not ExternalOverride then
        ManageEnvLerping()
    end

    tickSandstorm()


    -- (2026-11-15, performance) synced keys (sent to every client) written when they change, not every tick
    DaynightSync("level.daynight.seconds", math.floor(Seconds), SetInt)
    DaynightSync("level.dayphase", GetDayPhaseTitle(), SetString)
    DaynightSync("level.daynight.days", Days, SetFloat)
    DaynightSync("level.daynight.time_formatted", GetTimeFormatted12H(Seconds), SetString)


    -- Update daynight from other scripts through registry.
    if GetString("level.daynight.updateDayPhase") ~= "" then
        SetDayPhaseByTitle(GetString("level.daynight.updateDayPhase"))
        SetString("level.daynight.updateDayPhase", "") -- Reset reg updating.
    end


    CFG.TIME_RUN = config.daynight.runTime

end

DaynightSent = {}
function DaynightSync(key, value, setter)
    if DaynightSent[key] ~= value then
        DaynightSent[key] = value
        setter(key, value, true)
    end
end

function client.init()
    initSandstormSounds()
end

function client.tick()
    tickSandstormSounds()
    -- (2026-11-15, performance) the level-wide light search once a second instead of every frame
    if GetTime() >= (ClientCampfiresAt or 0) then
        ClientCampfiresAt = GetTime() + 1
        ClientCampfires = FindLights("Campfire", true)
    end
    for _, light in ipairs(ClientCampfires) do
        CampfirePos = GetLightTransform(light).pos -- global read by smoke()/fire()
        if VecLength(VecSub(GetPlayerTransform().pos, CampfirePos)) < 10 then
            smoke()
            fire()
        end
    end
end

function client.draw()

    if InputDown("interact") and HasTag(GetPlayerInteractBody(), "Bed") then

        UiPush()
        UiTranslate(UiCenter(), UiMiddle() - 100)
            UiFont("regular.ttf", 100)
            UiAlign("center middle")
            UiTextShadow(0, 0, 0, 1, 1, 1)
            UiText(GetString("level.daynight.time_formatted"))
        UiPop()

    end


    -- if not shouldDrawTime then
    --     return
    -- end

    -- do UiPush()

    --     UiAlign('right top')
    --     UiFont('regular.ttf', 48)
    --     UiColor(1,1,1, 1)
    --     UiTextShadow(0,0,0, 0.5, 1,1)


    --     UiTranslate(UiWidth() - 50, 50)
    --     -- UiText(Time)
    --     UiText('Day ' .. sfn(Days, 0))

    --     UiTranslate(0, 60)
    --     UiText(Time12)

    --     UiTranslate(0, 60)
    --     UiText(GetDayPhaseTitle())

    -- UiPop() end

end



--- Convert the current time or seconds to a 12h time string. Returns something like "12:32 AM"
---@param seconds number Total number of seconds to convert to 12h time.
---@return string
function GetTimeFormatted12H(seconds)

    local h = ternary(seconds, SecondsToHours(seconds), Hours)
    local m = ternary(seconds, SecondsToMinutes(seconds), Minutes)

    local hf = h or 0
    local mf = m or 0

    local ampm = ternary(Hours % 24 >= 12, 'PM', 'AM')

    local timeStr = "TIME PAUSED"
    if CFG.TIME_RUN then
        timeStr = sfnPadZeroes(sfnInt(hf) % 12, 2) .. ':' .. sfnPadZeroes(sfnInt(mf) % 60, 2) .. ' ' .. ampm
    end

    return timeStr

end


-- Convert time to a formatted full time clock. Example: "d:1 h:21 m:34 s:02"
function GetTimeStamp()
    return
    'd:' .. sfnPadZeroes(sfnInt(Days)) .. '  ' ..
    'h:' .. sfnPadZeroes(sfnInt(Hours % 24)) .. '  ' ..
    'm:' .. sfnPadZeroes(sfnInt(Minutes % 60)) .. '  ' ..
    's:' .. sfnPadZeroes(sfnInt(Seconds % 60)) .. '  '
end


--- Gets the phase of the day from the DayPhases table. Ex: Morning, Noon, etc...
function GetDayPhase()

    local ht = Hours % 24 -- 24h

    for index, phase in ipairs(DayPhasesTable) do

        local nextPhase = DayPhasesTable[GetTableNextIndex(DayPhasesTable, index)]

        if phase.startH < nextPhase.startH then
            if ht >= phase.startH and ht <= nextPhase.startH then -- Check if ht is between phase interval.
                return phase.name
            end
        else
            if phase.startH - nextPhase.startH < 24 then -- Offset 24h loop and check interval.
                return phase.name
            end
        end

    end

end

--- Gets the phase of the day from the DayPhases table. Ex: Morning, Noon, etc...
function GetDayPhaseTitle()

    local ht = Hours % 24 -- 24h

    for index, phase in ipairs(DayPhasesTable) do

        local nextPhase = DayPhasesTable[GetTableNextIndex(DayPhasesTable, index)]

        if phase.startH < nextPhase.startH then
            if ht >= phase.startH and ht <= nextPhase.startH then -- Check if ht is between phase interval.
                return phase.title
            end
        else
            if phase.startH - nextPhase.startH < 24 then -- Offset 24h loop and check interval.
                return phase.title
            end
        end

    end

end


--- Finds the day phase and sets the time to that phase.
function SetDayPhase(phase)

    -- local ht = Hours % 24 -- 24h

    for index, dayPhase in ipairs(DayPhasesTable) do

        if dayPhase.name == phase then

            SetTime24(0,0,dayPhase.startH)

        end

    end

end


--- Finds the day phase and sets the time to that phase.
function SetDayPhaseByTitle(phase)

    -- local ht = Hours % 24 -- 24h

    for index, dayPhase in ipairs(DayPhasesTable) do

        if dayPhase.title == phase then

            SetTime24(0,0,dayPhase.startH)

        end

    end

end


---The number of hours between two hour values. Example: hours between 6 and 13 = 7 or 23 and 1 = 2.
---@param h1 number Earlier time.
---@param h2 number Later time.
function GetHourDistance(h1, h2)
    if h2 > h1 then -- No 24h loop.
        return h2 - h1
    else -- 24h loop.
        return math.abs(h1 - 24) + h2
    end
end



---Set the date/time by each unit of time.
---@param s number Seconds
---@param m number Minutes
---@param h number Hours
---@param d number Days
function SetTime24(s, m, h, d)

    local sec = 0

    sec = s or 0
    sec = sec + MinutesToSeconds(m or 0)
    sec = sec + HoursToSeconds(h or 0)
    sec = sec + DaysToSeconds(d or 0)

    Seconds = sec

end


---Add units of time to the existing time.
---@param s number Seconds
---@param m number Minutes
---@param h number Hours
---@param d number Days
function AddTime24(s, m, h, d)

    local sec = 0

    sec = s
    sec = sec + MinutesToSeconds(m)
    sec = sec + HoursToSeconds(h)
    sec = sec + DaysToSeconds(d)

    Seconds = Seconds + sec

end


-- Get phase of the day.
function isMorning() return GetDayPhaseTitle() == 'Morning' end
function isNoon() return GetDayPhaseTitle() == 'Noon' end
function isEvening() return GetDayPhaseTitle() == 'Evening' end
function isNight() return GetDayPhaseTitle() == 'Night' end


-- Time unit conversions.
function SecondsToMinutes(s) return s / 60 end
function SecondsToHours(s) return s / 60 / 60 end
function SecondsToDays(s) return s / 60 / 60 / 24 end
function DaysToSeconds(d) return d * 24 * 60 * 60 end
function HoursToSeconds(h) return h * 60 * 60 end
function MinutesToSeconds(m) return m * 60 end


function WeeksMod(weeks, mod) return weeks % mod or 4 end
function DaysMod(days, mod) return days % mod or 7 end
function HoursMod(hours, mod) return (hours or Hours) % (mod or 24) end
function MinutesMod(minutes, mod) return minutes % mod or 60 end

function smoke()
   ParticleType("smoke")
   ParticleColor(0.5,0.5,0.5)
   --ParticleEmissive(2,0,"linear",0,0.5)
   ParticleRadius(0.2,2)
   ParticleAlpha(0.5,0)
   ParticleCollide(0)
   ParticleGravity(1)
   ParticleDrag(0.6)
   SpawnParticle(CampfirePos, Vec(math.random(-100,100)/350, math.random(-100,100)/350, math.random(-100,100)/350), 8)
   ParticleReset()
end
function fire()
   ParticleColor(1,0.6,0.3,0.1,0.1,0.1,"linear",0,0.5)
   ParticleEmissive(2,0,"linear",0,0.5)
   ParticleRadius(0.3,0)
   ParticleAlpha(1.0,0.0)
   ParticleCollide(0)
   ParticleGravity(3)
   SpawnParticle(CampfirePos, Vec(math.random(-100,100)/250, math.random(-100,100)/250, math.random(-100,100)/250), 2)
   ParticleReset()
end