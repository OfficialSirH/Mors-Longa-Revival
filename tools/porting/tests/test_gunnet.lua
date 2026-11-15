-- Minimal engine mock
local calls = {}
local function rec(name) return function(...) calls[name] = (calls[name] or 0) + 1 end end
for _, n in ipairs{"PlaySound","SpawnParticle","PointLight","DrawLine","MakeHole","Explosion","SpawnFire","ApplyBodyImpulse","PaintRGBA","ParticleReset","ParticleType","ParticleTile","ParticleSticky","ParticleRadius","ParticleAlpha","ParticleEmissive","ParticleColor","ParticleGravity","ParticleCollide","ParticleDrag","QueryRejectBody","QueryRejectShapes","Delete","SetBodyTransform","SetBodyVelocity","Spawn","SetPlayerTool"} do _G[n] = rec(n) end
local R = {}
function SetFloat(k,v) calls.SetFloat=(calls.SetFloat or 0)+1 R[k]=v end
function SetBool(k,v) R[k]=v end -- (2026-11-15) damage writers raise level.goreai.damage_pending
function GetFloat(k) return R[k] or 0 end
function SetInt(k,v) R[k]=v end
function GetInt(k) return R[k] or 0 end
function Vec(x,y,z) return {x or 0,y or 0,z or 0} end
function VecCopy(v) return {v[1],v[2],v[3]} end
function VecAdd(a,b) return {a[1]+b[1],a[2]+b[2],a[3]+b[3]} end
function VecSub(a,b) return {a[1]-b[1],a[2]-b[2],a[3]-b[3]} end
function VecScale(a,s) return {a[1]*s,a[2]*s,a[3]*s} end
function VecLength(a) return math.sqrt(a[1]^2+a[2]^2+a[3]^2) end
function VecNormalize(a) local l=VecLength(a) return l>0 and VecScale(a,1/l) or a end
function VecDot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
function VecLerp(a,b,t) return VecAdd(a,VecScale(VecSub(b,a),t)) end
function GetTimeStep() return 1/60 end
function GetToolBody(p) return 0 end
function HasTag(h,t) return h==5 and t=="gore_id" end
function GetShapeBody(s) return 5 end
function GetTagValue() return 0 end
function GetShapeMaterialAtPosition() return "wood",1,1,1,1 end
function LoadSound(p) return p end
function Transform(p,r) return {pos=p,rot=r} end
local raycasts = 0
function QueryRaycast(o,d,dist) raycasts = raycasts + 1 if raycasts == 3 then return true, 0.5, Vec(0,0,1), 9 end return false end
function RandomSpreadPercent25(x) return x end
Settings = {game={blood_and_gore={value=true}}}
gravity = Vec(0,-10,0)
function Blood_Pop() PaintRGBA() end
function GunFunctions_LoadSounds() end
function InputDown() return false end
function InputPressed() return false end
function GetTime() return os.clock() end
function GetEntityType() return "body" end
-- network mock: host is both server and client
server, client = {}, {}
local outbox = {}
function ServerCall(fn, ...) outbox[#outbox+1] = {fn, {...}} end
function ClientCall(p, fn, ...) outbox[#outbox+1] = {fn, {...}} end
function GetLocalPlayer() return 1 end
function IsPlayerLocal(p) return p == 1 end
local function pump() while #outbox > 0 do local m = table.remove(outbox,1); local f = assert(loadstring("return "..m[1]))(); f(unpack(m[2])) end end
-- load the code under test (only the functions we need from gunfunctions.lua)
local src = io.open("weapons/guns/gunfunctions.lua","rb"):read("*a"):gsub("\r","")
local a = src:find("function GunRaycast"); local b = src:find("\nfunction ShootNewDontCallYet")
assert(loadstring(src:sub(a,b)))()
local g1 = src:find("function GrenadeOperations"); local g2 = src:find("\nfunction ADS")
assert(loadstring(src:sub(g1,g2)))()
dofile("weapons/guns/gunnet.lua")

GunNet_ServerInit()
local shell = {armor={1,1,1,1,1}, damage=0.2, pdamage=1, tracer=true, velocity=880, maxmomentum=2.5, momentum=2.5,
  pos=Vec(0,1,0), predictedBulletVelocity=Vec(0,0,-880), factor=1, active=false}
GunNet_Fire(shell, "MOD/assets/snd/Weapons/ak/ak_0.ogg", 0.7)
assert(#client.gunShells == 1 and client.gunShells[1].doWorld == false)
pump() -- server.gunFire -> ClientCall(client.gunRemoteFire) -> local, ignored
assert(#server.gunShells == 1 and server.gunShells[1].doFx == false and server.gunShells[1].owner == 1)
-- step server only
calls = {}
raycasts = 0
for i=1,5 do GunNet_ServerTick(1/60) end
assert((calls.MakeHole or 0) >= 1, "server must make holes")
assert((calls.SetFloat or 0) >= 1, "server must write NPC damage")
assert(R["level.goreai.body_damage_player_owner"] == 1, "server must record the shooter (hitmarkers)")
assert(not calls.PlaySound and not calls.SpawnParticle and not calls.DrawLine, "server must not do fx")
-- step client only
calls = {}
raycasts = 0
for i=1,5 do GunNet_ClientTick(1/60) end
assert(not calls.MakeHole and not calls.SetFloat and not calls.ApplyBodyImpulse and not calls.PaintRGBA, "client must not touch world")
assert((calls.PlaySound or 0) >= 1 and (calls.SpawnParticle or 0) >= 1, "client must do fx")
-- remote player's shot reaches this client with sound
calls = {}
client.gunRemoteFire(2, {pos=Vec(0,1,0), predictedBulletVelocity=Vec(0,0,-880), momentum=1, maxmomentum=1, armor={}}, "MOD/assets/snd/x.ogg", 0.7)
assert(calls.PlaySound == 1 and #client.gunShells >= 1)
-- grenade: explosion only on server
GunNet_FireGrenade({pos=Vec(0,1,0), predictedBulletVelocity=Vec(0,0,-10)})
pump()
calls = {} client.gunShells = {} raycasts = 2
GunNet_ClientTick(1/60) assert(not calls.Explosion)
server.gunShells = {} raycasts = 2 GunNet_ServerTick(1/60) assert(calls.Explosion == 1)
-- tool parts are skipped by GunRaycast
local n = 0
local savedQR, savedHT = QueryRaycast, HasTag
QueryRaycast = function() n = n + 1 if n == 1 then return true, 0.1, Vec(0,0,1), 77 end return true, 5, Vec(0,0,1), 9 end
HasTag = function(h, t) return h == 77 and t == "ml_toolpart" end
local hit, dist, _, shape = GunRaycast(Vec(), Vec(0,0,-1), 10, 0)
assert(hit and shape == 9 and dist == 5 and n == 2, "tool part must be skipped")
QueryRaycast, HasTag = savedQR, savedHT
print("gunnet split tests passed")
-- GunNet_FixToolParts: per part, only parts still in their lane; idempotent
do
  local T = {}
  function GetShapeLocalTransform(h) return {pos = {T[h][1], T[h][2], T[h][3]}, rot = {0,0,0,1}} end
  function SetShapeLocalTransform(h, t) T[h] = t.pos end
  local orig, shapes = {}, {}
  local function lane(i) return ((i - 1) % 10 + 1) * 24, math.floor((i - 1) / 10) * 24 end
  local origy = {}
  for i = 1, 91 do orig[i] = ((i * 7) % 230) / 10 - 11.5; origy[i] = -1 - (i % 3); local lx, ly = lane(i); T[i] = {orig[i] + lx, origy[i] + ly, -1}; shapes[i] = i end
  T[91] = {0, -200, 0}          -- hidden by the gun script before the fix (TT-33 case)
  T[5] = {orig[5], -1, -1}      -- already moved by the gun script (must stay)
  GunNet_FixToolParts(shapes)
  for i = 1, 90 do if i ~= 5 then assert(math.abs(T[i][1] - orig[i]) < 1e-6 and math.abs(T[i][2] - origy[i]) < 1e-6, "part " .. i .. " not at its real place") end end
  assert(T[91][1] == 0 and T[91][2] == -200, "hidden part must be left alone")
  GunNet_FixToolParts(shapes)
  for i = 1, 90 do assert(math.abs(T[i][1] - orig[i]) < 1e-6, "part " .. i .. " moved twice") end
  assert(T[5][2] == -1, "part moved by the gun script must be left alone")
  print("tool part fix-up tests passed")
end
-- (2026-11-15) spent casings: only the newest CASING_CAP stay, shared by every gun (tag), rockets never counted
do
  local live, tags, nextH, now = {}, {}, 100, 0
  function Spawn(xml) nextH = nextH + 1 live[nextH] = xml return { nextH, nextH + 1000 } end -- a body and a shape
  function GetEntityType(e) return e < 1000 and "body" or "shape" end
  function SetBodyVelocity() end
  function GetTime() return now end
  function SetTag(h, t, v) tags[h] = tags[h] or {} tags[h][t] = v end
  function GetTagValue(h, t) return tags[h] and tags[h][t] or "" end
  function FindBodies(t) local out = {} for h in pairs(live) do if tags[h] and tags[h][t] then out[#out + 1] = h end end return out end
  function Delete(h) live[h] = nil end
  local first
  for i = 1, 70 do
    now = i * 0.1
    server.gunSpawnCasing(i % 2 == 0 and "MOD/assets/vox/riflecasing.xml" or "MOD/assets/vox/pistolcasing.xml", {}, Vec())
    first = first or nextH
  end
  local count = 0 for _ in pairs(live) do count = count + 1 end
  assert(count == CASING_CAP and CASING_CAP == 60, "70 casings: the newest 60 stay")
  assert(live[first] == nil and live[first + 9] == nil and live[first + 10] ~= nil, "the 10 oldest were deleted")
  server.gunSpawnCasing("MOD/prefabs/rpg_rocket.xml", {}, Vec())
  local rocket = nextH
  for i = 1, 5 do now = 100 + i server.gunSpawnCasing("MOD/assets/vox/shotguncasing.xml", {}, Vec()) end
  assert(live[rocket] and not (tags[rocket] and tags[rocket].ml_casing), "a rocket is neither tagged nor deleted")
  count = 0 for h in pairs(live) do if h ~= rocket then count = count + 1 end end
  assert(count == 60, "still 60 casings after more shots")
  print("casing cap tests passed")
end
