fV = 1.5 -- Vertical recoil modifier
fH = 1   -- Horizontal recoil modifier
fW = 1   -- Wander recoil modifier

fM = 1   -- Max recoil modifier

fA = 1   -- Accuracy modifier

-- Vertical recoil: the angle (in degrees) that a gun will kick up every time it is fired
-- Horizontal recoil: the random angle (in degrees) that a gun will kick in any direction every time it is fired
-- Wander recoil: the random angle (in degrees) that a gun will wander every time it is fired

-- Max recoil: the angle limit for vertical recoil

-- Accuracy: an arbitrary unit (based on MOA; minute of angle) for accuracy where the higher the value, the less accuracte the weapon

-- Fire rate: the rate of fire in round/min


gunstats = {
	ak50={
		recoilVertical=		5*fV,
		recoilHorizontal=	10*fH,
		recoilWander=		3*fW,

		recoilMax=			10*fM,

		accuracy=			2.2*fA,

		fireRate=			150
	},
	ak74={
		recoilVertical=		0.9*fV,
		recoilHorizontal=	5*fH,
		recoilWander=		5*fW,

		recoilMax=			7*fM,

		accuracy=			1.8*fA,

		fireRate=			650
	},
	ak101={
		recoilVertical=		1.2*fV,
		recoilHorizontal=	3*fH,
		recoilWander=		7*fW,

		recoilMax=			7*fM,

		accuracy=			1.5*fA,

		fireRate=			600
	},
	ak74m={
		recoilVertical=		0.8*fV,
		recoilHorizontal=	4*fH,
		recoilWander=		4*fW,

		recoilMax=			7*fM,

		accuracy=			1.7*fA,

		fireRate=			650
	},
	akm={
		recoilVertical=		1.15*fV,
		recoilHorizontal=	6*fH,
		recoilWander=		5*fW,

		recoilMax=			7*fM,

		accuracy=			1.9*fA,

		fireRate=			600
	},
	ar15={
		recoilVertical=		0.95*fV,
		recoilHorizontal=	3*fH,
		recoilWander=		6*fW,

		recoilMax=			8*fM,

		accuracy=			1.9*fA,

		fireRate=			850
	},
	cz1012={
		recoilVertical=		4*fV,
		recoilHorizontal=	7*fH,
		recoilWander=		3*fW,

		recoilMax=			4*fM,

		accuracy=			20*fA,

		fireRate=			600
	},
	fiveseven={
		recoilVertical=		0.6*fV,
		recoilHorizontal=	1.3*fH,
		recoilWander=		2.5*fW,

		recoilMax=			5*fM,

		accuracy=			8*fA,

		fireRate=			1000
	},
	g3={
		recoilVertical=		1.85*fV,
		recoilHorizontal=	5*fH,
		recoilWander=		6*fW,

		recoilMax=			10*fM,

		accuracy=			1.6*fA,

		fireRate=			550
	},
	fal={
		recoilVertical=		1.1*fV,
		recoilHorizontal=	4*fH,
		recoilWander=		6*fW,

		recoilMax=			7*fM,

		accuracy=			1.3*fA,

		fireRate=			650
	},
	g17={
		recoilVertical=		0.8*fV,
		recoilHorizontal=	0.7*fH,
		recoilWander=		3.5*fW,

		recoilMax=			6*fM,

		accuracy=			11*fA,

		fireRate=			1200
	},
	deagle={
		recoilVertical=		8.8*fV,
		recoilHorizontal=	2.7*fH,
		recoilWander=		3.5*fW,

		recoilMax=			18*fM,

		accuracy=			17*fA,

		fireRate=			60
	},
	g18={
		recoilVertical=		0.8*fV,
		recoilHorizontal=	0.7*fH,
		recoilWander=		3.5*fW,

		recoilMax=			8*fM,

		accuracy=			11*fA,

		fireRate=			1200
	},
	g36k={
		recoilVertical=		1*fV,
		recoilHorizontal=	4*fH,
		recoilWander=		6*fW,

		recoilMax=			7*fM,

		accuracy=			1.9*fA,

		fireRate=			750
	},
	m16={
		recoilVertical=		1*fV,
		recoilHorizontal=	3*fH,
		recoilWander=		6*fW,

		recoilMax=			8*fM,

		accuracy=			1.6*fA,

		fireRate=			750
	},
	m107={
		recoilVertical=		13*fV,
		recoilHorizontal=	8*fH,
		recoilWander=		3*fW,

		recoilMax=			15*fM,

		accuracy=			1.5*fA,

		fireRate=			150
	},
	ks23={
		recoilVertical=		7*fV,
		recoilHorizontal=	14*fH,
		recoilWander=		10*fW,

		recoilMax=			8*fM,

		accuracy=			22*fA,

		fireRate=			20
	},
	m870={
		recoilVertical=		4*fV,
		recoilHorizontal=	11*fH,
		recoilWander=		7*fW,

		recoilMax=			5*fM,

		accuracy=			19*fA,

		fireRate=			60
	},
	--[[mosin={
		recoilVertical=*fV,
		recoilHorizontal=*fH,
		recoilWander=*fW,

		recoilMax=*fM,

		accuracy=*fA,
	},--]]
	mp5={
		recoilVertical=		0.5*fV,
		recoilHorizontal=	2*fH,
		recoilWander=		3*fW,

		recoilMax=			4*fM,

		accuracy=			7*fA,

		fireRate=			800
	},
	mp43={
		recoilVertical=		4*fV,
		recoilHorizontal=	7*fH,
		recoilWander=		3*fW,

		recoilMax=			6*fM,

		accuracy=			13*fA,

		fireRate=			150
	},
	p90={
		recoilVertical=		0.2*fV,
		recoilHorizontal=	2*fH,
		recoilWander=		4*fW,

		recoilMax=			4*fM,

		accuracy=			4*fA,

		fireRate=			900
	},
	pp19={
		recoilVertical=		0.4*fV,
		recoilHorizontal=	3*fH,
		recoilWander=		4*fW,

		recoilMax=			5*fM,

		accuracy=			4.5*fA,

		fireRate=			750
	},
	ppsh41={
		recoilVertical=		0.4*fV,
		recoilHorizontal=	2*fH,
		recoilWander=		6*fW,

		recoilMax=			4*fM,

		accuracy=			7*fA,

		fireRate=			1000
	},
	sawedoff={
		recoilVertical=		4*fV,
		recoilHorizontal=	7*fH,
		recoilWander=		3*fW,

		recoilMax=			4*fM,

		accuracy=			20*fA,

		fireRate=			150
	},
	scarh={
		recoilVertical=		1.4*fV,
		recoilHorizontal=	3*fH,
		recoilWander=		5*fW,

		recoilMax=			8*fM,

		accuracy=			1.6*fA,

		fireRate=			600
	},
	scarl={
		recoilVertical=		1*fV,
		recoilHorizontal=	4*fH,
		recoilWander=		3*fW,

		recoilMax=			6*fM,

		accuracy=			1.8*fA,

		fireRate=			650
	},
	sks={
		recoilVertical=		1.1*fV,
		recoilHorizontal=	5*fH,
		recoilWander=		3*fW,

		recoilMax=			6*fM,

		accuracy=			2.4*fA,

		fireRate=			150
	},
	--[[sv98={
		recoilVertical=*fV,
		recoilHorizontal=*fH,
		recoilWander=*fW,

		recoilMax=*fM,

		accuracy=*fA,
	},--]]
	svd={
		recoilVertical=		3*fV,
		recoilHorizontal=	7*fH,
		recoilWander=		3*fW,

		recoilMax=			10*fM,

		accuracy=			1*fA,

		fireRate=			700
	},
	tt33={
		recoilVertical=		0.8*fV,
		recoilHorizontal=	2*fH,
		recoilWander=		5*fW,

		recoilMax=			10*fM,

		accuracy=			12*fA,

		fireRate=			1000
	},
	m9={
		recoilVertical=		0.3*fV,
		recoilHorizontal=	2*fH,
		recoilWander=		5*fW,

		recoilMax=			8*fM,

		accuracy=			9*fA,

		fireRate=			1000
	},
	vector={
		recoilVertical=		0.4*fV,
		recoilHorizontal=	2*fH,
		recoilWander=		5*fW,

		recoilMax=			10*fM,

		accuracy=			6.5*fA,

		fireRate=			1100
	},
}