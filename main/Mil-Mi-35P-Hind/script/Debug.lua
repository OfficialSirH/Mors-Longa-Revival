--For adjusting helicopter part densities so that it is balanced around the rotor
--Technically controls can offset an unbalanced heli, but it's easier to get it balanced
function AdjustHeliCoM()
	local LocalRotorPos = TransformToLocalPoint(HeliTr,RotorPos)

    local COM = GetBodyCenterOfMass(Heli)
    local diff = VecSub(COM,LocalRotorPos)
    DebugPrint(VecStr(diff))

    DebugPrint("Too far forward " .. diff[3])
    DebugPrint("Too far right " .. -diff[1])
    DebugCross(TransformToParentPoint(HeliTr,COM))

    --local sameheightrotor = LocalRotorPosCurrentSetupMode
    --sameheightrotor[2] = COM[2]
    --DebugCross(TransformToParentPoint(HeliTr,sameheightrotor),0,1,0)
end

function AdjustRotorCoM()
    local COM = GetBodyCenterOfMass(MRotor)
    local diff = COM
    DebugPrint(VecStr(diff))

    DebugPrint("Too far forward " .. diff[3])
    DebugPrint("Too far right " .. -diff[1])
    DebugCross(TransformToParentPoint(GetBodyTransform(MRotor),COM))


    DebugCross(GetBodyTransform(MRotor).pos,0,1,0)
end



function ShowAxes()
    DebugLine(HeliTr.pos,VecAdd(HeliTr.pos,Axes[Forward]),0,0,1)
    DebugLine(HeliTr.pos,VecAdd(HeliTr.pos,Axes[Upward]),0,1,0)
    DebugLine(HeliTr.pos,VecAdd(HeliTr.pos,Axes[Right]),1,0,0)
end


function YawDebug()
    local z, y, z = GetQuatEuler(HeliTr.rot)
    local z2, y2, z2 = GetQuatEuler(HeliYawTr.rot)
    DebugPrint(y .. " " .. y2)
end

function FormatNo(flt, decimals)
	if decimals == nil then decimals = 2 end
	if flt  == nil then return "" end
	IsNeg = flt < 0
	OutNo = math.abs(flt)


	OutNo = math.floor(OutNo * 10^decimals)/(10^decimals)
	if OutNo == 0 then IsNeg = false end

	local output = OutNo

	local Sign = " "
	if IsNeg then Sign = "-" end
	output = Sign .. output

	--decimals
	Remainder = OutNo*100 - math.floor(OutNo)*100
	if Remainder ==0 then output = output .. ".0" end
	if Remainder %10 == 0 then output = output .. "0" end

	--space for >10
	if OutNo<10 then output = output .. " " end
	--if OutNo == 0 then output = " 0.00" end


	return output
end

function HighlightHeli()
    local sps = GetBodyShapes(Heli)
    for i = 1,#sps,1 do
        DrawShapeHighlight(sps[i],1)
    end
end

function DebugPIDAdjustment()
    GraphValue(GraphValP,GraphRn,"red",true)
    GraphValue(GraphValI,GraphRn,"green",false)
    GraphValue(GraphValD,GraphRn,"blue",false)
    GraphValue(GraphValC,GraphRn,"black",false)

    if InputPressed("n") then
        ShowOptions =not ShowOptions
    end

    if ShowOptions then
        UiMakeInteractive()
        DrawOptions("center","",1, 4)
    end
end

function TestingButtons()
    if InputPressed("b") then
        PilotDead = not PilotDead

    end

    if InputPressed("b") then
        AddShake(0.5)
    end
end

function ShowRotorSpeed(rotno)
    
    local f= 0
    if rotno == 1 then
        f = MRotSpeedFraction
    elseif rotno == 2 then
        f = SRotSpeedFraction
    end

    f = f*100
    f = Round(f,1)
    DebugWatch("Rotor power", f .. "%")
    DebugWatch("Time", DebugTimer)
end


function ShowHeliCoM()
    DebugCross(HeliCoM,0,0,1)
end

function ShowMainRotorCoM()
    DebugWatch("rotor body", MRotor)
    DebugCross(RotorPos,1,0,0)
end


--Selector functions for running the setup based on the chosen values
function RunSetupInInitConfigUpdate()
    if CurrentSetupMode == "" then return end
    DebugPrint(CurrentSetupMode)
    DebugPrint("------------------------------------------------")
    if CurrentSetupMode == "Adjust Rotor CoM" then
        IsHostile = false
        RotorDragForce = 0
        return 
    end

    if CurrentSetupMode == "Adjust Heli CoM" then
        IsHostile = false
        RotorDragForce = 0
        return 
    end

    if CurrentSetupMode == "Adjust Main Rotor power" then
        IsHostile = false
        RotorDragForce = 0
        return 
    end

    if CurrentSetupMode == "Adjust Main Rotor power" or CurrentSetupMode == "Adjust Tail Rotor power" then
        RotorForceConfig = RotorForceConfig/10
        RotorDragForce = 0
        return
    end

    if CurrentSetupMode == "Adjust Rotation Force" then
        SavedRotorDragForce = RotorDragForce
        RotorDragForceTimer = 6
        RotorDragForce = 0
        return 
    end
end



function RunSetupInInit()
    if CurrentSetupMode == "" then return end

    if CurrentSetupMode == "Adjust Rotor CoM" then
        AdjustRotorCoM()
        return 
    end

    if CurrentSetupMode == "Adjust Heli CoM" then
        AdjustHeliCoM()
        return 
    end

    if CurrentSetupMode == "Adjust Main Rotor power" or CurrentSetupMode == "Adjust Tail Rotor power" or CurrentSetupMode == "Adjust lift force" then
        RotorDragForce = 0
        TakeControl()
        return 
    end

    if CurrentSetupMode == "PID adjustment" then
        TakeControl()
        return 
    end

    if CurrentSetupMode == "Flight test" then
        TakeControl()
        return 
    end
    
end

function DebugDamagedParts()
    DebugWatch("PilotDead", PilotDead)
    DebugWatch("MRotorHealth", MRotorHealth)
    DebugWatch("SRotorHealth", SRotorHealth)
    DebugWatch("HeliMassLoss", HeliMassLoss)
    DebugWatch("EngineHealth", EngineHealth)
    DebugWatch("IsGunBroken", IsGunBroken)

    DebugWatch("IsGunBroken", IsGunBroken)
    DebugWatch("IsRocketBroken", IsRocketBroken)
    DebugWatch("RotorGone", RotorGone)
    DebugWatch("SRotorGone", SRotorGone)
    DebugWatch("TailHealth", TailHealth)
    DebugWatch("ConsoleBroken", ConsoleBroken)
    DebugWatch("TotalDamage", TotalDamage)

    DebugWatch("FuelLeak", FuelLeak)

    DebugWatch("IsSensorDamagedRPM", IsSensorDamagedRPM)
    DebugWatch("IsSensorDamagedAltitude", IsSensorDamagedAltitude)
    DebugWatch("IsSensorDamagedSpeed", IsSensorDamagedSpeed)
end


function RunSetupTick(dt)
    
    if CurrentSetupMode == "" then return end
    DebugTimer = DebugTimer + dt

    if CurrentSetupMode == "Adjust Main Rotor power" then
        ShowRotorSpeed(1)
        return 
    end
    if CurrentSetupMode == "Adjust Tail Rotor power" then
        ShowRotorSpeed(2)
        return 
    end

    if  CurrentSetupMode == "Adjust lift force" then
        ShowHeliCoM()
        ShowMainRotorCoM()
        return 
    end


    if CurrentSetupMode == "Adjust Rotation Force" then
        if RotorDragForceTimer > 0 then
            RotorDragForceTimer = RotorDragForceTimer - dt
            if RotorDragForceTimer<0 then
                RotorDragForce = SavedRotorDragForce
                SRotorGone = true
                DebugPrint("rotation start")
            end
        end
        return 
    end

end


