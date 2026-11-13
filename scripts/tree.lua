function clamp(a, mi, ma)
	if a < mi then return mi
	elseif a > ma then return ma
	else return a
	end
end

pRandom = GetInt("randomseed", 1)
pMaxIter = clamp(GetInt("iterations", 12), 5, 15)
pTrunkBrush = GetString("trunkbrush", "MOD/brush/tree/trunk-oak.vox")
pLeafBrush = GetString("leafbrush", "MOD/brush/tree/leaf.vox")
pSize = clamp(GetFloat("size", 1), 0.1, 3.0)
pTrunkSize = clamp(GetFloat("trunksize", 1), 0.1, 3)
pWide = clamp(GetFloat("wide", 0.5), 0.0, 1.0)
pSpread = clamp(GetFloat("spread", 0.5), 0.0, 1.0)
pTwisted = clamp(GetFloat("twisted", 0.5), 0.0, 1.0)
pLeaves = clamp(GetFloat("leaves", 1), 0.0, 3.0)
pGravity = clamp(GetFloat("gravity", 0), -1.0, 1.0)

local size = 150*pSize/pMaxIter
gTrunkSize = pTrunkSize * pSize * 6
gBranchLength0 = size*(1-pWide)
gBranchLength1 = size*pWide
gTrunk = true
gLeaves = {}

function normalize(x,y,z)
	local l = math.sqrt(x*x + y*y + z*z);
	return x/l, y/l, z/l
end


function init()
	if pRandom ~= 0 then
		Randomize(pRandom)
	end

	matWood = CreateBrush(pTrunkBrush)
	matLeaf = CreateBrush(pLeafBrush)

	Vox()
	generateBranches(0, 0, 0, 0, 1, 0, 1)
	generateLeaves()
end


function getBranchSize(iter)
	local t = (iter-1)/pMaxIter
	t = math.sqrt(t)
	return (1-t)*gTrunkSize
end

function getBranchLength(iter)
	local t = (iter-1)/pMaxIter
	t = math.sqrt(t)
	return gBranchLength0 + t*(gBranchLength1-gBranchLength0)
end

function getBranchAngle(iter)
	local t = (iter-1)/pMaxIter
	t = math.sqrt(t)
	return 2.0*pSpread * t
end

function getBranchProbability(iter)
	local t = (iter-1)/pMaxIter
	t = math.sqrt(t)
	return t
end

function generateBranches(x, y, z, dx, dy, dz, iter)
	Material(matWood)
	local l= getBranchLength(iter)
	local s0 = getBranchSize(iter)
	local s1 = getBranchSize(iter+1)

	x1 = x + dx*l
	y1 = y + dy*l
	z1 = z + dz*l
	Line(x, y, z, x1, y1, z1, s0, s1)

	if iter == 1 then
		Material(0)
		Box(-gTrunkSize, -gTrunkSize, -gTrunkSize, gTrunkSize, 0, gTrunkSize)
	end
	
	if iter < pMaxIter then
		local b = 1
		local var = iter*0.2*pTwisted
		if RandomFloat(0.0, 1.0) < getBranchProbability(iter) then
			b = 2
			var = getBranchAngle(iter)
			if gTrunk and y1 > 20 then
				Vox()
			end
			gTrunk = false
		end
		local x2 = x1
		local y2 = y1
		local z2 = z1
		for i=1, b do
			local dx2 = dx + RandomFloat(-var, var)
			local dy2 = dy + RandomFloat(-var, var)
			local dz2 = dz + RandomFloat(-var, var)
			dx2,dy2,dz2 = normalize(dx2, dy2, dz2)
			generateBranches(x2, y2, z2, dx2, dy2, dz2, iter+1)
		end
	else
		gLeaves[#gLeaves+1] = {x1, y1, z1}
		gLeaves[#gLeaves+1] = {(x+x1)/2, (y+y1)/2, (z+z1)/2}
	end
end

function generateLeaves()
	Material(matLeaf)
	local chunks = math.ceil(5*pLeaves)
	local leavesPerChunk = math.ceil(50*pLeaves)
	for j=1, #gLeaves do
		local x1 = gLeaves[j][1]
		local y1 = gLeaves[j][2]
		local z1 = gLeaves[j][3]
		for i=1, chunks do
			local x2 = x1
			local y2 = y1
			local z2 = z1
			for j=1, leavesPerChunk do
				if Get(x2, y2, z2) == 0 then
					Set(x2, y2, z2)
				end
				local d = RandomInt(1,6)
				if d == 1 then
					x2 = x2 - 1
				elseif d == 2 then
					x2 = x2 + 1
				elseif d == 3 or d == 4 then
					if RandomFloat(-1.0, 1.0) > pGravity then
						y2 = y2 - 1
					else
						y2 = y2 + 1
					end
				elseif d == 5 then
					z2 = z2 - 1
				else
					z2 = z2 + 1
				end
			end
		end
	
	end
end
