function init()
	Shrine = FindShape("Shrine")
	AUGH = LoadSound("MOD/snd/Enemies/Boss/Binge.ogg")
	Gurenya = LoadSound("MOD/snd/Enemies/Boss/NecoArc.ogg")
	timer = 0
	prayed = false
end
function tick(dt)
	if IsShapeBroken(Shrine) then
		if not played then
			PlaySound(AUGH)
			played = true
			prayed = true
		end
		timer = timer + dt
		if timer > 10 then
			ShrineTrans = GetShapeWorldTransform(Shrine)
			if not spawned then
			Spawn("MOD/prefabs/other/BossBingus.xml",Transform(VecAdd(ShrineTrans.pos,Vec(0,2,0))))
			spawned = true
			end
		end
	end
	if InputPressed("Interact") and GetPlayerInteractShape() == Shrine and not prayed then
		PlaySound(Gurenya)
		prayed = true
		ShrineTrans = GetShapeWorldTransform(Shrine)
		Spawn("MOD/prefabs/spawns/loots/GiftFromGod.xml",Transform(VecAdd(ShrineTrans.pos,Vec(0,2,0))))
	end
end
