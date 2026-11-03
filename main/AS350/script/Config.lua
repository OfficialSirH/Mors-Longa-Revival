function MainSettingsConfig()
    SwitchOffPrompts = false --on screen text showing controls to be switched off
    QuickStartRide = false --start quickly where the heli is pilot controled (point and click X)
    QuickStartControl = false --start quickly with player control
    IsHostile = true --Enemy AI attacking player
    DisableWeapons = false --Weapons disabled for testing purposes works the same way as completely broken weapons
end

--configuration of things like power of the helicopter, speed etc
function PowerConfig()
    MaxMRotorRotationForce = 4000 --relating to the force spinning the main rotor, if too low it spins too slow
    MaxSRotorRotationForce = 200 --relating to the spinning force of the secondary rotor. Due to the smaller weight it's a smaller number.
    RotorForceConfig = 4000 --relating to how much upward force the main rotor creates (actual force depends on spinning and control too)
end

function SetupOptions()
    InitSetupOptions()
    -- 0 to n a number for choosing the type of debugging help for setting up new helicopters
    -- with 0 the debug setup is switched off, and each number is a different step that is best done in order
    local debugnumber = 0

    CurrentSetupMode = DebugSetupName[debugnumber]
    --1 Adjust Rotor CoM
    --The rotor center of mass needs to be lining up very accurately with the body center of the rotor
    --for reference the AS350 is only offset by 0.00024
    --This This is required to make sure it won't shake while rotating fast.
    --Small adjustments to center of mass can be achieved by very slighlyt adjusting position of individual blades

    --2 Adjust Heli CoM
    --The Heli center of mass should be adjusted to line up well with the position of the rotor
    --so that when the rotor force is applied upward, it doesn't cause leaning for reference AS350 is offset by 0.08
    --This can be adjusted either by changing the model or a lot simpler by adjusting densities of different components in the editor

    --3 Adjust Main Rotor power
    --Adjust the variable MaxMRotorRotationForce, this will determine how quickly the main rotor starts spinning
    --ideally it would reach full speed in like 15 seconds.

    --4 Adjust Tail Rotor power
    --Same as above for tail rotor. Use smaller numbers MaxSRotorRotationForce is the variable to update
    --it's fine if it doesn't get too close to 100%, it's more about how fast it starts spinning

    --5 Adjust RotorForceConfig
    --Adjusts the power of the main rotor in case it's too weak to lift the heli, I wouldn't make it too strong, but I don't have a specific method
    --If the main rotor is too light it may also be unable to lift the heli regardless of this value

    --6 Adjust PIDS
    --press n to show options to adjust the PID values (these are temporary adjustments in game, just to see the results and not saved anywhere)
    --The PIDs are under control.lua
    --Choose one of the PIDs to adjust at a time, for example ManageCollective, adjusts up and down motion
    --After the definition of variables like local PConst, there should be the below code added (no comments)

        --[[
    PConst = PConst * 10^Val[PFactor]
    IConst = IConst * 10^Val[IFactor]
    DConst = DConst * 10^Val[DFactor]
    Range = Range * 10^Val[RangeFactor]
    ]]

    --at the end of the function add the below code


        --[[
    GraphValP = P*PConst
    GraphValI = I*PConst*IConst
    GraphValD = D*PConst*DConst
    GraphValC = C
    GraphRn = nil
        DebugPrint("P:" .. FormatNo(GraphValP,2) .. " I:" .. FormatNo(GraphValI,2) .. " D:" .. FormatNo(GraphValD,2) .. " C:" .. FormatNo(GraphValC,2))
    ]]

    --if from adjusting PIDS you find for example a 2x as big P number is better, adjust the relevant line such as below, in the only one place
    --local PConst = 0.02
    --for the function you were working on (eg ManageCollective)
end


function InitSetupOptions()
    DebugSetupName = {}
    DebugSetupName[0] = ""
    DebugSetupName[1] = "Adjust Rotor CoM"
    DebugSetupName[2] = "Adjust Heli CoM"
    DebugSetupName[3] = "Adjust Main Rotor power"
    DebugSetupName[4] = "Adjust Tail Rotor power"
    DebugSetupName[5] = ""
    DebugSetupName[6] = "PID adjustment"

    DebugTimer = 0
end