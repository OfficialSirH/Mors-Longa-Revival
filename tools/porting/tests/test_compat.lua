local R = {}
function HasKey(k) return R[k] ~= nil end
function SetFloat(k,v) R[k]=tonumber(v) end function GetFloat(k) return tonumber(R[k]) or 0 end
function SetInt(k,v) R[k]=math.floor(v) end function GetInt(k) return tonumber(R[k]) or 0 end
function SetBool(k,v) R[k]=v and true or false end function GetBool(k) return R[k]==true end
function SetString(k,v) R[k]=tostring(v) end function GetString(k) return R[k] and tostring(R[k]) or "" end
function GetPlayerVehicle(p) return p==7 and 42 or 0 end
dofile("scripts/TDSU/compat.lua")
local t = util.structured_table("savegame.mod.config", { db={"boolean",false}, map={ spawn={"boolean",true}, n={"number",2.5} }, name="string", inv={"table",{}} })
assert(t.db==false and t.map.spawn==true and t.map.n==2.5, "defaults")
t.db=true; t.map.n=7; t.name="x"; t.inv={a=1,{2,3}}
assert(R["savegame.mod.config.db"]==true and t.db==true)
assert(t.map.n==7 and R["savegame.mod.config.map.n"]==7)
assert(t.name=="x"); assert(t.inv.a==1 and t.inv[1][2]==3)
local s = util.serialize({x=1,y={"a",true}}, 5); local a,b = util.unserialize(s); assert(a.x==1 and a.y[1]=="a" and a.y[2]==true and b==5)
assert(IsPlayerInVehicle(7) and not IsPlayerInVehicle())
print("compat tests passed")
