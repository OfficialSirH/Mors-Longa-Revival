function InitTesting()

    BombCount = 9
    BombTypes = {}

    BombTypes[1] = "RG42"
    BombTypes[2] = "Stielhandgranate"
    BombTypes[3] = "PMN4"
    BombTypes[4] = "NailBomb"
    BombTypes[5] = "IEDa"
    BombTypes[6] = "FuelBomb"
    BombTypes[7] = "GBU12"
    BombTypes[8] = "JDAM"
    BombTypes[9] = "crockett"

    CBomb = 4

    SwitchShowCounter = 0
    SwitchShowCounterMax = 2
    ShowOptions = false
end

function BombSpawningInputs(dt)
    --[[if InputPressed("o") then
        CBomb = CBomb - 1 
        if CBomb<1 then CBomb = BombCount end 
        SwitchShowCounter = SwitchShowCounterMax
    end--]]
    if InputPressed("p") then
        CBomb = CBomb + 1 
        if CBomb>BombCount then CBomb = 1 end 
        SwitchShowCounter = SwitchShowCounterMax
    end
    
    DisplaySelection(dt)

    if InputPressed("t") then
        SpawnBomb()
    end
end

function DisplaySelection(dt)
    if SwitchShowCounter<=0 then return end
    SwitchShowCounter = SwitchShowCounter - dt

    UiTranslate(100,100)
    UiFont("bold.ttf", 40)
    UiText(Devices[BombTypes[CBomb]].Name)
end


function TestingUi(dt)
    BombSpawningInputs(dt)

    if InputPressed("m") then
        ShowOptions =not ShowOptions
    end

    if ShowOptions then
        UiMakeInteractive()
        DrawOptions("side","",SBombSettingStart, SBombSettingEnd)
    end
end


function SpawnBomb()
    local p,d = GetAim(1)
    p = VecAdd(p,VecScale(d,1.2))
    local s = [[
    <body tags="Splosion=#### interact=Arm " dynamic="true">
        <voxbox pos="-0.1 0.0 -0.1" size="2 1 2" material="metal" color="0.28 0.22 0.14" pbr="0.5 1"/>
    </body>
    ]]
    s = string.gsub(s, "####", BombTypes[CBomb])

    local b = Spawn(s, Transform(p), false, false)[1]
    SetBodyVelocity(b,VecScale(d,62))

    local Splosive = b
	local Species = GetTagValue(Splosive, "Splosion")
    if Devices[Species]["RequireArm"] then
        SetTag(Splosive, "interact", "!!!ARMED!!!")
        SetTag(Splosive, "Fuse", Devices[Species]["Fuse"])
    end

end

function GetAim(range)								
	local ct = GetCameraTransform()							
	local forwardPos = TransformToParentPoint(ct, Vec(0, 0, -1))							
	local direction = VecSub(forwardPos, ct.pos)								
	direction = VecNormalize(direction)							
	
	return ct.pos, direction							
end	