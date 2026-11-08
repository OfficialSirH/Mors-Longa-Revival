function init()
  --constant inits
  --find parts
  bikeVhcl = FindVehicle("bike")
  bikeBody = FindBody("bikeBod")
  hedJoint = FindJoint("bikeHeadJoint")
  bikStand = FindJoints("bikeStand")
  --head tuning
  maxHdAng = 25
  hdTrnSpd = 1
  --lean tuning
  maxLnAng = 60
  maxLnVel = 5
  inpLnFac = 0.5
  velLnFac = 0.03
  --turn tuning
  maxTnYaw = 4
  tnAtnTrg = 100
  --variable inits
  curLnAng = 0
  vehicle = FindVehicle("")
end

function tick(delta)
  --if GetPlayerVehicle() == bikeVhcl then
  bodyparts = FindShapes("TORSO")
  if #bodyparts > 0 or bikeVhcl == GetPlayerVehicle() then 
    bTra = GetBodyTransform(bikeBody)
    bRot = bTra.rot
    _, _, rollAng = GetQuatEuler(bRot)
    locLinVel = TransformToLocalVec(bTra, GetBodyVelocity(bikeBody))
    locAngVel = TransformToLocalVec(bTra, GetBodyAngularVelocity(bikeBody))
    steerInp = (InputValue("left") - InputValue("right"))
    SetJointMotorTarget(hedJoint, steerInp * maxHdAng, 1)
    for _,stand in pairs(bikStand) do
      SetJointMotorTarget(stand, 0, 2)
    end
    newLnVel = getNewLeanVelocity(steerInp, locLinVel[1], rollAng, delta)
    newTnVel = getNewTurnVelocity(math.abs(locLinVel[3]), locAngVel[2])
    DampedAngVel = Vec(locAngVel[1], newTnVel, newLnVel)
    lnAngVel = QuatRotateVec(bRot, DampedAngVel)
    SetBodyAngularVelocity(bikeBody, lnAngVel)
  end
end

function getNewLeanVelocity(steerInp, sliVel, rollAng, delta)
  curLnTar = math.tanh((steerInp * inpLnFac)+(sliVel * velLnFac))* maxLnAng
  curLnAng = lerp(curLnAng, curLnTar, delta * 2)
  return smoothClamp((curLnAng - rollAng), maxLnVel)
end

function getNewTurnVelocity(linVel, yawVel)
  yawCurve = smoothClamp(yawVel, maxTnYaw)
  scLinVel = smoothClamp(linVel, tnAtnTrg)
  baseComp = (tnAtnTrg - scLinVel) * yawCurve
  fSpdComp = (scLinVel * yawVel)
  pasvComp = (baseComp + fSpdComp) / tnAtnTrg
  return pasvComp
end

function smoothClamp(value, max)
  return math.tanh(value / max) * max
end

function lerp(current, target, factor)
  return current + ((target - current) * factor)
end