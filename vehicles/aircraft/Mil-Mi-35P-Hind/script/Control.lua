
--Negative P means it's moving right and corrects by leaning left
function MoveSideways()
    if EngineHealth<0.95 then
        MoveSideOffset = MoveSideOffset*EngineHealth
    end

    local P = TransformToLocalVec(HeliYawTr,HeliVel)[1] - MoveSideOffset
    local D = (P-MoveRightLastP)*60
    MoveRightLastP = P
    local I = MoveRightI + P/60
    MoveRightI = I

    local PConst = 0.4
    local IConst = 0.4
    local DConst = 0.126
    local Range = 3.5
    if IsHostile then Range = Range*0.9 end

    local environmentalvisibility = 1
    if GetBool("level.IsSandstorm") then environmentalvisibility = environmentalvisibility*0.66 end
    if GetString("level.dayphase") == "Night" then environmentalvisibility = environmentalvisibility*0.66 end
    Range = Range*environmentalvisibility

    local C = math.clamp(-PConst*(P+IConst*I+DConst*D),-Range,Range)

    RightLeanOffset = C

    --If the distance is far the then I controller doesn't help, so clear it
    --at high distances the P controller is sufficient
    --At high distances I destabilisies
    --High distance coudl be due to something temporarily holding back the heli, or just changing controls, the I remembering these would not help
    if math.abs(P)>1 then
        MoveRightI = 0
    end
    --Start slowly reducing the I we are getting close to the ideal position
    --without this, it would forever oscillate around the desired position
    --Setting I to 0 here would mean periodic drift in cases when only the I controller held it in place (eg side was movement due to tail rotor)
    if math.abs(P)<0.01 then
        MoveRightI = MoveRightI*(1-0.001)
    end
end

--Positive leaning is moving forward
function MoveForward()
    if EngineHealth<0.95 then
        MoveForwardOffset = MoveForwardOffset*EngineHealth
    end

    local P = TransformToLocalVec(HeliYawTr,HeliVel)[3]-MoveForwardOffset
    local D = (P-MoveForwardLastP)*60
    MoveForwardLastP= P
    local I = MoveForwardI + P/60
    MoveForwardI = I

    local PConst = 0.25
    local IConst = 0.4
    local DConst = 0.54
    local Range = 3.5
    if IsHostile then Range = Range*0.9 end
    local environmentalvisibility = 1
    if GetBool("level.IsSandstorm") then environmentalvisibility = environmentalvisibility*0.66 end
    if GetString("level.dayphase") == "Night" then environmentalvisibility = environmentalvisibility*0.66 end
    Range = Range*environmentalvisibility

    if IsSensorDamagedSpeed then
        if NoiseAmountNS3 == nil then NoiseAmountNS3 = 0 end
        P = P + NoiseAmountNS3*2
        PConst = PConst * 1.5
        Range = Range*0.8
    end





    local C = math.clamp(-PConst*(P+IConst*I+DConst*D),-Range,Range)
    
    ForwardLeanOffset = C

    --If the distance is far the then I controller doesn't help, so clear it
    --at high distances the P controller is sufficient
    --At high distances I destabilisies
    --High distance coudl be due to something temporarily holding back the heli, or just changing controls, the I remembering these would not help
    if math.abs(P)>1 then
        MoveForwardI = 0
    end
    --Start slowly reducing the I we are getting close to the ideal position
    --without this, it would forever oscillate around the desired position
    if math.abs(P)<0.01 then
        MoveForwardI = MoveForwardI*(1-0.001)
    end


    --DebugPrint("P:" .. FormatNo(P,2) .. " I:" .. FormatNo(I,2) .. " D:" .. FormatNo(D,2) .. " C:" .. FormatNo(C,2))
    --GraphVal = P


end


--Positive leaning is moving forward
function LeanForward()
    if RotorGone then return end
    local P = PointB[2] - PointF[2] - ForwardLeanOffset + ForwardLeanOffsetError
    LeanForwardAmount = P
    local D = GetBodyVelocityAtPos(Heli,PointB)[2] - GetBodyVelocityAtPos(Heli,PointF)[2]
    
    local I = LeanForwardI + P
    if math.abs(P)>0.03 then
        I = 0
    end
    LeanForwardI = I

    local PConst = 8000
    local IConst = 0.0024
    local DConst = 1.47
    local Range = 12000
    

    local C = math.clamp(-PConst*(P+IConst*I+DConst*D),-Range,Range)*MRotSpeedFraction*MRotorHealth*HeliMassRemainingFactor
    
    ApplyBodyImpulse(MRotorBody,PointF,Vec(0,-C,0))
    ApplyBodyImpulse(MRotorBody,PointB,Vec(0,C,0))
end

--Positive leaning is moving Right
function LeanSideways()
    if RotorGone then return end
    local P = PointL[2] - PointR[2]- RightLeanOffset + RightLeanOffsetError
    local D = GetBodyVelocityAtPos(Heli,PointL)[2] - GetBodyVelocityAtPos(Heli,PointR)[2]

    local I = LeanRightI + P
    if math.abs(P)>0.03 then
        I = 0
    end
    LeanRightI = I

    local PConst = 8000
    local IConst = 0.001
    local DConst = 0.63
    local Range = 12000

    local C = math.clamp(-PConst*(P+IConst*I+DConst*D),-Range,Range)*MRotSpeedFraction*MRotorHealth*HeliMassRemainingFactor
    
    ApplyBodyImpulse(MRotorBody,PointR,Vec(0,-C,0))
    ApplyBodyImpulse(MRotorBody,PointL,Vec(0,C,0))
end

--P is positive when turning right
function ManageYaw()
    local P = -VecFacingDifference(Axes[Forward],YawVector,Axes[Right],Axes[Upward])
    YawDifference = P
    local D = (P-YawLastP)*60
    YawLastP = P
    local I = YawI + P
    if math.abs(D)>0.3 then I = 0 end

    YawI = I
    
    local PConst = 4
    local IConst = 0.01
    local DConst = 1.2
    local Range = 3

--[[
        PConst = PConst * 10^Val[PFactor]
        IConst = IConst * 10^Val[IFactor]
        DConst = DConst * 10^Val[DFactor]
        Range = Range * 10^Val[RangeFactor]
]]
 
    local C = math.clamp(-PConst*(P+IConst*I+DConst*D),-Range,Range)

    if LostYawControl == false then
        YawForce = DefaultYawForce+C
        
    end

    if CurrentSetupMode == "Adjust Rotation Force" then return end

    SideRotorYawForceFactor = YawForce*SRotSpeedFraction*SRotorHealth

--[[
        DebugPrint(YawForce)
        GraphValP = P*PConst
        GraphValI = I*PConst*IConst
        GraphValD = D*PConst*DConst
        GraphValC = C
        GraphRn = nil
        DebugPrint("P:" .. FormatNo(GraphValP,2) .. " I:" .. FormatNo(GraphValI,2) .. " D:" .. FormatNo(GraphValD,2) .. " C:" .. FormatNo(GraphValC,2))
        ]]



end



--P is positive when going up
function ManageCollective()
    if RotorGone then return end
    local P = HeliVel[2]-CollectiveOffset+VerticalError
    local D = (P-CollectiveLastP)*60
    CollectiveLastP = P
    local I = CollectiveI + P
    if math.abs(P)>0.5 then
        I = 0
    end
    CollectiveI = I

    local PConst = 0.02
    local IConst = 0.001
    local DConst = 0.5
    local Range = 0.1
    local CollectiveRange = 1.8

    --[[
    PConst = PConst * 10^Val[PFactor]
    IConst = IConst * 10^Val[IFactor]
    DConst = DConst * 10^Val[DFactor]
    Range = Range * 10^Val[RangeFactor]
    ]]

    if IsSensorDamagedRPM  then
        if NoiseAmountNS1 == nil then NoiseAmountNS1 = 0 end
        P = P + NoiseAmountNS1*3
        PConst = PConst * 1.5
        Range = Range*0.8
    end

    if IsSensorDamagedAltitude then
        if NoiseAmountNS2 == nil then NoiseAmountNS2 = 0 end
        P = P + NoiseAmountNS2*3
        PConst = PConst * 1.5
        Range = Range*0.8
    end


    local C = math.clamp(-PConst*(P+IConst*I+DConst*D),-Range,Range)
    Collective = math.clamp(Collective+C,-CollectiveRange,CollectiveRange)

    --[[
    GraphValP = P*PConst
    GraphValI = I*PConst*IConst
    GraphValD = D*PConst*DConst
    GraphValC = C
    GraphRn = nil
        DebugPrint("P:" .. FormatNo(GraphValP,2) .. " I:" .. FormatNo(GraphValI,2) .. " D:" .. FormatNo(GraphValD,2) .. " C:" .. FormatNo(GraphValC,2))
    ]]

    ApplyBodyImpulse(MRotorBody,RotorPos,VecScale(Axes[Upward],RotorForce*Collective*MRotSpeedFraction*MRotorHealth*HeliMassRemainingFactor))


    CheckLanding(Collective,Range)
end
