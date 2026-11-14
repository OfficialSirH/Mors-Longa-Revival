function clamp(a, mi, ma)
	if a < mi then return mi
	elseif a > ma then return ma
	else return a
	end
end

pRandom = GetInt("random", 1)
pSize = clamp(GetFloat("size", 1), 0.1, 3)
pTrunkBrush = GetString("brush", "MOD/brush/tree/trunk-pine.vox")
pTwisted = clamp(GetFloat("twisted", 0.5), 0, 3)
pTrunkHeight = GetFloat("trunkheight", 2.0)*10
pDensity = clamp(GetFloat("branchdensity", 1), 0, 3)
pBranchLength = clamp(GetFloat("branchlength", 1), 0, 3)
pBranchDir = clamp(GetFloat("branchdir", -0.5), -5, 5)
pLeaves = clamp(GetFloat("leaves", 1), 0, 2)
pDarknessFactor = clamp(GetFloat("darkness", 0.65), 0.1, 2.0)
pBrightnessFactor = clamp(GetFloat("brightness", 0.8), 0.1, 2.0)

pTrunkWidth = pSize*3.5
pBranchLength = pBranchLength*pSize*20
pMaxIter = math.floor(100*pSize / 5)
pSize = 5
pTwisted = pTwisted/pMaxIter
pDensity =pDensity * 30

gLeaves = {}

function normalize(x,y,z)
	local l = math.sqrt(x*x + y*y + z*z);
	return x/l, y/l, z/l
end


function init()
	if pRandom ~= 0 then
		Randomize(pRandom)
	end

	wood = CreateBrush(pTrunkBrush)

	leaves = {}
	local rD = RandomFloat(0.30, 0.34)*pDarknessFactor
	local gD = RandomFloat(0.37, 0.42)*pDarknessFactor
	local bD = RandomFloat(0.28, 0.32)*pDarknessFactor
	local rB = (RandomFloat(0.41, 0.46)*pBrightnessFactor-rD)/8
	local gB = (RandomFloat(0.50, 0.56)*pBrightnessFactor-gD)/8
	local bB = (RandomFloat(0.39, 0.44)*pBrightnessFactor-bD)/8

	for i=1, 8 do
		--leaves[i] = CreateMaterial("foliage", t*0.9, t*RandomFloat(0.8, 1.3), t)
		leaves[i] = CreateMaterial("foliage", rD+rB*i, gD+gB*i, bD+bB*i)
		--leaves[i] = CreateMaterial("foliage", rB*8, gB*8, bB*8)
	end

	Vox()

	generateBranches(0, 0, 0, 0, 1, 0, 1)
	generateLeaves()
	Material(0)
	Box(-pTrunkWidth, -pTrunkWidth, -pTrunkWidth, pTrunkWidth, 0, pTrunkWidth)
end


function getBranchSize(iter)
	local t = (iter-1)/pMaxIter
	t = t * t
	return (1-t)*pTrunkWidth
end


function branch(x, y, z, dx, dy, dz, l)
	local steps = math.ceil(l/3)
	l = l / steps
	local var = 1 / steps
	for i=1, steps do
		local x1 = x + dx*l
		local y1 = y + dy*l
		local z1 = z + dz*l
		dx = dx + RandomFloat(-var, var)
		dy = dy + RandomFloat(-var, var) + 0.4/steps
		dz = dz + RandomFloat(-var, var)
		dx,dy,dz = normalize(dx, dy, dz)
		Line(x, y, z, x1, y1, z1, s0, s1)
		gLeaves[#gLeaves+1] = {x1, y1, z1}
		x = x1
		y = y1
		z = z1
	end	
end

function generateBranches(x, y, z, dx, dy, dz, iter)
	Material(wood)
	local l = pSize
	local s0 = getBranchSize(iter)
	local s1 = getBranchSize(iter+1)

	x1 = x + dx*l
	y1 = y + dy*l
	z1 = z + dz*l
	Line(x, y, z, x1, y1, z1, s0, s1)
	
	if y1 > pTrunkHeight then
		local b = (1.0-iter/pMaxIter)*pDensity + 1
		for i=1, b do
			local a = RandomFloat(0.0, 6.28)
			local dx = math.cos(a)
			local dy = RandomFloat(0.5, 1.0) * pBranchDir
			local dz = math.sin(a)
			dx,dy,dz = normalize(dx, dy, dz)
			local l = (1.0-iter/pMaxIter)*pBranchLength
			l = l*(RandomFloat(0.5, 1.5))
			local t = RandomFloat(0.0, 1.0)
			local x2 = x + (x1-x)*t
			local y2 = y + (y1-y)*t
			local z2 = z + (z1-z)*t
			branch(x2, y2, z2, dx, dy, dz, l+3)
		end
	end
	
	if iter < pMaxIter then
		local var = iter*0.1*pTwisted
		local x2 = x1
		local y2 = y1
		local z2 = z1
		local dx2 = dx + RandomFloat(-var, var)
		local dy2 = dy + RandomFloat(-var, var)
		local dz2 = dz + RandomFloat(-var, var)
		dx2,dy2,dz2 = normalize(dx2, dy2, dz2)
		generateBranches(x2, y2, z2, dx2, dy2, dz2, iter+1)
	else
		gLeaves[#gLeaves+1] = {x1, y1, z1}
		gLeaves[#gLeaves+1] = {(x+x1)/2, (y+y1)/2, (z+z1)/2}
	end
end

function generateLeaves()
	local chunks = math.ceil(3*pLeaves)
	local leavesPerChunk = math.ceil(3*pLeaves)
	for j=1, #gLeaves do
		local x1 = gLeaves[j][1]
		local y1 = gLeaves[j][2]
		local z1 = gLeaves[j][3]
		for i=1, chunks do
			local x2 = x1
			local y2 = y1
			local z2 = z1
			for k=1, leavesPerChunk do
				Material(leaves[RandomInt(1, 8)])
				Set(x2, y2, z2)
				local d = RandomInt(1,6)
				if d == 1 then
					x2 = x2 - 1
				elseif d == 2 then
					x2 = x2 + 1
				elseif d == 3 then
					y2 = y2 - 1
				elseif d == 4 then
					y2 = y2 - 1
				elseif d == 5 then
					z2 = z2 - 1
				else
					z2 = z2 + 1
				end
			end
		end
	end
end

