function DebugBoosedSidewaysMovement(diff,v,CorrectedDiff,AdjustingForce)
	BoosterPower = 10
	DebugWatch("diff ", diff)
	DebugWatch("v    ", v)
	DebugWatch("Corr ", CorrectedDiff)
	DebugWatch("Forc ", AdjustingForce)
	local t = target
	t[2] = HeliTr.pos[2]
	DebugCross(target)
end

function RopePositions()
	DebugCross(TransformToParentPoint(HeliTr,RopePosLoc[RopeNo]))
	DebugCross(TransformToParentPoint(HeliTr,RopeCamPosLoc[RopeNo]))
	DebugCross(TransformToParentPoint(HeliTr,RopeCamLookLoc))
end