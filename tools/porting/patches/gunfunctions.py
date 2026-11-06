import sys
p = sys.argv[1]
raw = open(p, 'rb').read().decode('latin-1')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
def rep(old, new, count=1):
    global s
    n = s.count(old)
    assert n == count, (old[:60], n)
    s = s.replace(old, new)

PROLOGUE = '''
	-- v2: this simulation runs on the server for world effects (doFx = false)
	-- and on clients for visuals/sound (doWorld = false); see gunnet.lua.
	-- v1 scripts leave both flags unset, so everything runs as before.
	local doWorld = projectile.doWorld ~= false
	local doFx = projectile.doFx ~= false
	local function noop() end
	local PlaySound = doFx and PlaySound or noop
	local SpawnParticle = doFx and SpawnParticle or noop
	local PointLight = doFx and PointLight or noop
	local DrawLine = doFx and DrawLine or noop
	local MakeHole = doWorld and MakeHole or noop
	local Explosion = doWorld and Explosion or noop
	local SpawnFire = doWorld and SpawnFire or noop
	local ApplyBodyImpulse = doWorld and ApplyBodyImpulse or noop
	local Blood_Pop = doWorld and Blood_Pop or noop
	local SetFloat = doWorld and SetFloat or noop
	local toolBody = projectile.owner and GetToolBody(projectile.owner) or GetToolBody()
'''

# ProjectileOperations
rep('''function ProjectileOperations(projectile)
	
	local lvl1armor''', 'function ProjectileOperations(projectile)\n' + PROLOGUE + '''
	local lvl1armor''')
rep('''	local factor = barrelFactordamage or 1
	local didHitNpc = false
	QueryRejectBody(GetToolBody())
	QueryRejectBody(BulletShape)''', '''	local factor = projectile.factor or barrelFactordamage or 1
	local didHitNpc = false
	if toolBody ~= 0 then QueryRejectBody(toolBody) end
	if BulletShape then QueryRejectBody(BulletShape) end''')
rep('''		if tracer then DrawLine(projectile.pos, point2, 0.9, 0.8, 0.7, 0.8) end
		SetBodyTransform(BulletShape, Transform(point2, GetBodyTransform(BulletShape).rot))''',
'''		if tracer then DrawLine(projectile.pos, point2, 0.9, 0.8, 0.7, 0.8) end
		if BulletShape then SetBodyTransform(BulletShape, Transform(point2, GetBodyTransform(BulletShape).rot)) end''')
rep('''	if not projectile.active then
		local allshapes = GetBodyShapes(BulletShape)
		for i=1,#allshapes do 
			Delete(allshapes[i])
		end	
		Delete(BulletShape)
	end''', '''	if not projectile.active and BulletShape then
		local allshapes = GetBodyShapes(BulletShape)
		for i=1,#allshapes do 
			Delete(allshapes[i])
		end	
		Delete(BulletShape)
	end''')

# GrenadeOperations
rep('''function GrenadeOperations(projectile)
	projectile.predictedBulletVelocity''', '''function GrenadeOperations(projectile)
	local doWorld = projectile.doWorld ~= false
	local doFx = projectile.doFx ~= false
	local toolBody = projectile.owner and GetToolBody(projectile.owner) or GetToolBody()
	projectile.predictedBulletVelocity''')
rep('''	QueryRejectBody(GetToolBody())
	local hit, dist, normal, shape = QueryRaycast(projectile.pos, dir, VecLength(VecSub(point2, projectile.pos)))
	if hit then
		hitPos = VecAdd(projectile.pos, VecScale(VecNormalize(VecSub(point2, projectile.pos)), dist))
		Explosion(hitPos, 1)
	else
		point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
		DrawLine(projectile.pos, point2)
	end''', '''	if toolBody ~= 0 then QueryRejectBody(toolBody) end
	local hit, dist, normal, shape = QueryRaycast(projectile.pos, dir, VecLength(VecSub(point2, projectile.pos)))
	if hit then
		hitPos = VecAdd(projectile.pos, VecScale(VecNormalize(VecSub(point2, projectile.pos)), dist))
		if doWorld then Explosion(hitPos, 1) end
	else
		point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
		if doFx then DrawLine(projectile.pos, point2) end
	end''')

out = s.replace('\n', '\r\n') if crlf else s
open(p, 'wb').write(out.encode('latin-1'))
print('patched', p)
