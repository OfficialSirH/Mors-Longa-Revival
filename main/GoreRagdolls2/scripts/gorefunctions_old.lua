--[[
#include "../../../scripts/TDSU/tdsu.lua"
#include "../../../Automatic.lua"
]]



function init()
   SBPM = {};
   upspeed = 50
   bodyparts = FindBodies("bodypart")
   for i=1,#bodyparts do
      table.insert(SBPM, GetBodyMass(bodyparts[i]))
   end
   RRLEG = FindBody("RRLEG")
   LLLEG = FindBody("LLLEG")
   headvel = Vec(0,GetBodyMass(RRLEG)/upspeed,0)
   legvel = Vec(0,-GetBodyMass(LLLEG)/20,0)
   minlimbdmg = 0.4
   mintorsodmg = 0.55
   minheaddmg = 0.8
   Torso = FindBody("Torso")
   entirelystop = false
   HChecktim = 2
   HCheck = 0
   joints = FindJoints("")
   brange = 50
   srange = 50
   DrawHitmark = 0
   HS = LoadSound("MOD/snd/headshot.ogg")
   Eyes = FindBody("Head")
   jaw = FindShape("jaw")
end

function update(dt)

   if entirelystop and not finished then
      SetTag(Loot, "interact", enemyweapontag)
      finished = true
      end

   if not entirelystop and dead and showkill then
      if not hitmarkset then
      DrawHitmark = 1
      hitmarkset = true
      PlaySound(HS)
       srange = VecLength(VecSub(GetAimPosSplatter(), GetBodyTransform(head).pos))^1.9
       if srange < 60 then
          srange = 60
       end
       for i=1,190 do
       Paint(VecAdd(GetAimPosSplatter(),Vec(math.random(-srange,srange)/100,math.random(-srange,srange)/100,math.random(-srange,srange)/100)), math.random(10,30)/100, "explosion")
       end
      end
      draw()
      if DrawHitmark < 0 then
         entirelystop = true
      end
   end

    if not dead and not entirelystop then
       for i=1,#bodyparts do
          bodypart = bodyparts[i]
          HCheck = HCheck + dt
          if IsBodyBroken(bodypart) then
          CBPM = GetBodyMass(bodyparts[i])
          bodyparttransform = GetBodyTransform(bodypart)
          end
          if HasTag(bodypart, "RRLEG") or HasTag(bodypart, "RLEG") or HasTag(bodypart, "LLEG") or HasTag(bodypart, "LLLEG") or HasTag(bodypart, "RRARM") or HasTag(bodypart, "RARM") or HasTag(bodypart, "LARM") or HasTag(bodypart, "LLARM") then
             if IsBodyBroken(bodypart) and minlimbdmg > CBPM/SBPM[i] then
                dead = true
             end
          end
          if HasTag(bodypart, "Head") then
             if IsBodyBroken(bodypart) and minheaddmg > CBPM/SBPM[i] then
                dead = true
                showkill = true
             end
          end
          if HasTag(bodypart, "Torso") then
             if IsBodyBroken(bodypart) and mintorsodmg > CBPM/SBPM[i] then
                dead = true
             end
          end
          if HasTag(bodypart, "Head") then
             currentvel = GetBodyVelocity(bodypart)
             -- if ai.stun.duration > 0 then
                SetBodyVelocity(bodypart, VecAdd(currentvel, headvel))
             -- end
         end
          if HasTag(bodypart, "RRLEG") or HasTag(bodypart, "LLLEG") then
             currentvel = GetBodyVelocity(bodypart)
             -- if ai.stun.duration > 0 then
                SetBodyVelocity(bodypart, VecAdd(currentvel, legvel))
             -- end
          end
       end
       for i=1,#joints do
          if IsJointBroken(joints[i]) then
             dead = true
          end
       end
       if HasTag(Torso, "dead") then
          dead = true
       end
       if dead then
          PlaySound(LoadSound("MOD/main/GoreRagdolls2/snd/death"..math.random(2,5)..".ogg"), GetBodyTransform(head).pos)
          if IsBodyBroken(head) or IsShapeBroken(jaw) then
             showkill = true
          end
          SetTag(Torso, "dead")
          RemoveTag(Torso, "Torso")
          --DebugPrint("SET")
    end
 end
end
