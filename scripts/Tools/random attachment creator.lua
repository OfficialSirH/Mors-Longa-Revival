function init()
done = false
	
	fiveseven = {
		{"holo", "ironsight", "ironsight"},
		{"muzzle1", "muzzle2", "none", "none"},
		{""},
		{"side1", "side2", "none", "none"},
		{"none", "grey"},
		}
	FiveSeven = false
	
	ak101 = {
		{"toprail1", "toprail2"},
		{"holo", "scope", "ironsight", "ironsight"},
		{"muzzle1", "muzzle2", "none", "none"},
		{"stock0", "stock0", "stock0", "stock0", "stock1", "stock2","stock3", "removed"},
		{"grip0", "grip1", "grip2","grip3"},
		{"barrel0", "barrel0", "barrel1", "barrel2"},
		{"side1", "side2", "side3", "none", "none", "none"},
		{"guard0", "guard0", "guard0", "guard1", "guard2", "guard3"},
		}
	AK101 = false	
	
	m16 = {
		{"scope", "holo", "ironsight", "ironsight"},
		{"muzzle1", "muzzle2", "none", "none"},
		{"grip0", "grip0", "grip0", "grip1", "grip2","grip3"},
		{"barre0", "barre0", "barre1", "barre2"},
		{"side1", "side2", "none", "none"},
		{"mag0", "mag0", "mag0", "mag0", "mag0", "mag1", "mag2", "mag3", "mag4", "mag5"}
		}
	M16 = false




end

function tick(dt)
	if InputPressed("u") then
		for i=1,40 do
			DebugPrint("")
		end
		done = false
	end
	
	if FiveSeven and not done then
		DebugPrint("---Attachments---")
		DebugPrint("Toprail = " .. fiveseven[1][math.random(1,#fiveseven[1])] .. "")
		DebugPrint("Muzzle = " .. fiveseven[2][math.random(1,#fiveseven[2])] .. "")
		DebugPrint("Stock = " .. fiveseven[3][math.random(1,#fiveseven[3])] .. "")
		DebugPrint("Side = " .. fiveseven[4][math.random(1,#fiveseven[4])] .. "")		
		DebugPrint("Camo = " .. fiveseven[5][math.random(1,#fiveseven[5])] .. "")
		DebugPrint("-------------")
	done = true	
	end
	if AK101 and not done then
		DebugPrint("---Attachments---")
		DebugPrint("WhichToprail = " .. ak101[1][math.random(1,#ak101[1])] .. "")
		DebugPrint("Toprail = " .. ak101[2][math.random(1,#ak101[2])] .. "")
		DebugPrint("Muzzle = " .. ak101[3][math.random(1,#ak101[3])] .. "")
		DebugPrint("Stock = " .. ak101[4][math.random(1,#ak101[4])] .. "")
		DebugPrint("Grip = " .. ak101[5][math.random(1,#ak101[5])] .. "")
		DebugPrint("Barrel = " .. ak101[6][math.random(1,#ak101[6])] .. "")
		DebugPrint("Side = " .. ak101[7][math.random(1,#ak101[7])] .. "")
		DebugPrint("Guard = " .. ak101[8][math.random(1,#ak101[8])] .. "")
		DebugPrint("-------------")
	done = true	
	end
	if M16 and not done then
		DebugPrint("---Attachments---")
		DebugPrint("Toprail = " .. m16[1][math.random(1,#m16[1])] .. "")
		DebugPrint("Muzzle = " .. m16[2][math.random(1,#m16[2])] .. "")
		DebugPrint("Grip = " .. m16[3][math.random(1,#m16[3])] .. "")
		DebugPrint("Side = " .. m16[4][math.random(1,#m16[4])] .. "")
		DebugPrint("---Mag---")
		DebugPrint("Mag = " .. m16[5][math.random(1,#m16[5])] .. "")
		DebugPrint("-------------")
	done = true	
	end
end
