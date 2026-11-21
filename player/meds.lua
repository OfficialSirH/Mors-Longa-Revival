#version 2
DL_LABEL = "meds"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../lib/DeleteLog.lua"
#include "script/include/player.lua"
#include "../weapons/guns/gunfunctions.lua"

function server.init()
	RegisterTool("ai2", "AI2", "MOD/assets/vox/ai2.vox")
	RegisterTool("cms", "CMS", "MOD/assets/vox/cms.vox")
end

-- (v2) client: animation only; the inventory does the healing.
function client.init()

	hidePos = Vec(0, -200, 0)
	hideTrans = Transform(hidePos,QuatEuler())

	ADSx = 0
	ADSy = 0
	ADSz = 0
	ADSrotx = 0
	ADSroty = 0
	ADSrotz = 0
	ADSx0 = 0
	ADSy0 = 0
	ADSz0 = 0
	ADSrotx0 = 0
	ADSroty0 = 0
	ADSrotz0 = 0
	ADSdelta = {0,0,0,0,0,0}
	ADSfov = 0
	RELx = 0
	RELy = 0
	RELz = 0
	RELrotx = 0
	RELroty = 0
	RELrotz = 0
	SELx = 0
	SELy = 0
	SELz = 0
	SELrotx = 0
	SELroty = 0
	SELrotz = 0
	INSx = 0
	INSy = 0
	INSz = 0
	INSrotx = 0
	INSroty = 0
	INSrotz = 0
	RECx = 0
	RECy = 0
	RECz = 0
	RECrotx = 0
	RECroty = 0
	RECrotz = 0
	RECx0 = 0
	RECy0 = 0
	RECz0 = 0
	RECrotx0 = 0
	RECroty0 = 0
	RECrotz0 = 0
	RECdelta = {0,0,0,0,0,0}
	crouchoffset = 0

	recoilTimer = 0
end

function client.tick(dt)

    unlimitedammo = GetBool("savegame.mod.unlimitedammo")

	-- AI2 animations
	if GetPlayerTool() == "ai2" and IsToolEnabled("ai2") then

		local medtimer = GetFloat("inventory.medtimer")
		local medtimermax = GetFloat("inventory.medtimermax")

		local b = GetToolBody()

		if b~=0 then

			------MEDKIT ANIMATIONS----

			local x, y, z, rotx, roty, rotz = 0, -0.6, -1, 20, 0, 0
			if medtimermax-medtimer < 0.5 then
				local t = (0.5-medtimermax+medtimer)/0.5
				x, y, z, rotx, roty, rotz = 0, -0.6-0.5*t, -1, 10*t, 0, 0
			end

			offset = ADS(true, 0, 1, x, y, z, rotx, roty, rotz)

			SetToolTransform(offset, 0.2)


			if body ~= b then
				body = b
				local shapes = GetBodyShapes(b)
				ai2lid = shapes[2]
				ai2injector = shapes[3]

				ai2lidTrans = GetShapeLocalTransform(ai2lid)
				ai2injectorTrans = GetShapeLocalTransform(ai2injector)
			end

			ai2ldt = TransformCopy(ai2lidTrans)
			ai2int = TransformCopy(ai2injectorTrans)

			ai2ldt.pos = VecAdd(ai2ldt.pos, Vec(0.45, 0, -0.5))
			if medtimermax-medtimer < 0.5 then
				local t = (medtimermax-medtimer)/0.5
				ai2ldt.rot = QuatRotateQuat(ai2ldt.rot, QuatEuler(90*t,0,180))
			elseif medtimer > 0.5 then
				ai2ldt.rot = QuatRotateQuat(ai2ldt.rot, QuatEuler(90,0,180))
				if medtimermax-medtimer > 0.7 and medtimermax-medtimer < 1.2 then
					local t = (medtimermax-medtimer-0.7)/0.5
					ai2int.pos = VecAdd(ai2int.pos, Vec(-0.2*t, 0.1*t, 0.7*t))
				elseif medtimer < 1.2 and medtimer > 0.7 then
					local t = (medtimer-0.7)/0.5
					ai2int.pos = VecAdd(ai2int.pos, Vec(-0.2*t, 0.1*t, 0.7*t))
				elseif medtimermax-medtimer > 0.7 and medtimer > 0.7 then
					ai2int.pos = VecAdd(ai2int.pos, Vec(-0.2, 0.1, 0.7))
				end
			elseif  medtimer <= 0.5 then
				local t = medtimer/0.5
				ai2ldt.rot = QuatRotateQuat(ai2ldt.rot, QuatEuler(90*t,0,180))
			end

			SetShapeLocalTransform(ai2lid, ai2ldt)
			SetShapeLocalTransform(ai2injector, ai2int)

			if medtimer > 0 then

			end

			------ARM ANIMATIONS------

			-- Defining arm shapes and which clothing type is used
			local clothingtype = GetString("savegame.mod.difficulty")
			local bs = GetBodyShapes(GetToolBody())
			for i = 4, 15 do
				SetShapeLocalTransform(bs[i], hideTrans)
			end
			local hand1 = bs[4]
			local arm1 = bs[6]
			local hand2 = bs[5]
			if clothingtype == "peaceful" then
				hand1 = bs[7]
				arm1 = bs[9]
				hand2 = bs[8]
			elseif clothingtype == "normal" then
				hand1 = bs[10]
				arm1 = bs[12]
				hand2 = bs[11]
			elseif clothingtype == "hardcore" then
				hand1 = bs[13]
				arm1 = bs[15]
				hand2 = bs[14]
			else
				hand1 = bs[4]
				arm1 = bs[6]
				hand2 = bs[5]
			end

			local btrans = GetBodyTransform(b)

			-- Setting locations for the hands
			local x2, y2, z2, rotx2, roty2, rotz2 = 0, 0, 0, 0, 0, 0
			local lt = TransformToParentPoint(Transform(ai2ldt.pos, QuatRotateQuat(ai2ldt.rot, QuatEuler(90, 0, 0))), Vec(0.2, 0, -0.4))
			local it = ai2int.pos
			if medtimermax-medtimer < 0.5 or medtimer < 0.5 then
				x2, y2, z2, rotx2, roty2, rotz2 = 0+lt[1], 0+lt[2], 0+lt[3], 0, 0, 0
			elseif medtimer > 0 then
				x2, y2, z2, rotx2, roty2, rotz2 = 0+it[1], 0+it[2], -0.1+it[3], 0, 0, 0
			end

			local h1p1l = INS(true, x2, y2, z2, rotx2, roty2, rotz2).pos

			local pcrx,pcry,pcrz=GetQuatEuler(GetPlayerCameraTransform().rot)
			local pitch=pcrx*0.0174532925199
			local lookoffset=math.sin(pitch)

			-- h1p1l = Vec(0.225, -0.85, -1.9)
			local h1p2l = TransformToLocalPoint(btrans, TransformToParentPoint(GetPlayerTransform(), Vec(-0.6, 0.7-crouchoffset, 0.2-lookoffset)))
			local hnd1 = Transform(h1p1l, QuatRotateQuat(QuatLookAt(h1p2l, h1p1l), QuatEuler(0,90,90)))
			local a1p1l = VecAdd(h1p1l, TransformToParentVec(hnd1, Vec(0, 1, 0)))
			local a1p2l = TransformToLocalPoint(btrans, TransformToParentPoint(GetPlayerTransform(), Vec(-0.45, 1.5-crouchoffset-lookoffset*0.5, 0.5-lookoffset)))
			local amt1 = Transform(a1p1l, QuatRotateQuat(QuatLookAt(a1p2l, a1p1l), QuatEuler(0,90,90)))
			SetShapeLocalTransform(hand1, hnd1)
			SetShapeLocalTransform(arm1, amt1)

			local x3, y3, z3, rotx3, roty3, rotz3 = 0, -0.1, 0.15, 0, 0, 0
			-- if reloading and (reloadTimer > 1.1 or reloadTimer < 0.35) and maginTimer <= 0 and magoutTimer <= 0 then
			-- 	x3, y3, z3, rotx3, roty3, rotz3 = 0.3, -0.6, -0.3+bt.pos[3], 0, 0, 0
			-- elseif selectfireTimer > 0 then
			-- 	x3, y3, z3, rotx3, roty3, rotz3 = 0.3, -0.85, -0.9, 0, 0, 0
			-- end

			local h2p1l = SEL(true, x3, y3, z3, rotx3, roty3, rotz3).pos

			--h2p1l = Vec(0.275, -0.95, -0.85)
			local h2p2l = TransformToLocalPoint(btrans, TransformToParentPoint(GetPlayerTransform(), Vec(0.55, 1.1-crouchoffset-lookoffset, 0.9)))
			local hnd2 = Transform(h2p1l, QuatRotateQuat(QuatLookAt(h2p2l, h2p1l), QuatEuler(0,90,90)))
			SetShapeLocalTransform(hand2, hnd2)
		end
	end
	-- CMS animations
	if GetPlayerTool() == "cms" and IsToolEnabled("cms") then

		local medtimer = GetFloat("inventory.medtimer")
		local medtimermax = GetFloat("inventory.medtimermax")

		local b = GetToolBody()

		if b~=0 then

			------MEDKIT ANIMATIONS----

			local x, y, z, rotx, roty, rotz = -0.3, -0.45, -1, -40, -90, -70
			if medtimermax-medtimer < 0.5 then
				local t = (0.5-medtimermax+medtimer)/0.5
				local t2 = (medtimermax-medtimer)/0.5
				x, y, z, rotx, roty, rotz = -0.3, -0.4-0.5*t, -0.8, -30*t2, -90, -60*t2
			elseif medtimermax-medtimer > 0.6 and medtimermax-medtimer < 1 then
				x, y, z, rotx, roty, rotz = -0.2, -0.35, -1, -20, -50, -50
			elseif medtimermax-medtimer > 2.8 and medtimermax-medtimer < 3.3 then
				x, y, z, rotx, roty, rotz = -0.25, -0.35, -1.05, -30, -70, -80
			elseif medtimermax-medtimer > 3.9 and medtimermax-medtimer < 5.8 then
				x, y, z, rotx, roty, rotz = -0.3, -0.7, -0.95, -30, -70, -80
			elseif medtimermax-medtimer > 6.6 and medtimermax-medtimer < 8.8 then
				x, y, z, rotx, roty, rotz = -0.3, -1, -0.95, -30, -70, -80
			elseif medtimer < 0.2 then
				local t = (0.2-medtimer)/0.2
				local t2 = medtimer/0.2
				x, y, z, rotx, roty, rotz = -0.3, -0.4-0.5*t, -0.8, -40*t2, -90+50*t, -70+30*t
			end

			offset = ADS(true, 0, 1.5, x, y, z, rotx, roty, rotz)

			SetToolTransform(offset, 0.2)


			if body ~= b then
				body = b
				local shapes = GetBodyShapes(b)
				cmslid1 = shapes[2]
				cmslid2 = shapes[3]
				cmstool1 = shapes[4]
				cmstool2 = shapes[5]
				cmstool3 = shapes[6]

				cmslid1Trans = GetShapeLocalTransform(cmslid1)
				cmslid2Trans = GetShapeLocalTransform(cmslid2)
				cmstool1Trans = GetShapeLocalTransform(cmstool1)
				cmstool2Trans = GetShapeLocalTransform(cmstool2)
				cmstool3Trans = GetShapeLocalTransform(cmstool3)
			end

			cmsld1t = TransformCopy(cmslid1Trans)
			cmsld2t = Transform(Vec(0,0.15,0),QuatEuler(0,180,180))

			cmstl1t = TransformCopy(cmstool1Trans)
			cmstl2t = TransformCopy(cmstool2Trans)
			cmstl3t = TransformCopy(cmstool3Trans)

			cmsld1t.pos = VecAdd(cmsld1t.pos, Vec(0.75, 0, -0.15))
			-- cmsld2t.pos = VecAdd(cmsld2t.pos, Vec(0.75, 0, -0.15))
			if medtimermax-medtimer < 0.5 then
				local t = (medtimermax-medtimer)/0.5
				cmsld1t.rot = QuatRotateQuat(cmsld1t.rot, QuatEuler(100*t,0,180))
				cmsld2t.rot = QuatRotateQuat(cmsld2t.rot, QuatEuler(110*t,0,0))
			elseif medtimer > 0.5 then
				cmsld1t.rot = QuatRotateQuat(cmsld1t.rot, QuatEuler(100,0,180))
				cmsld2t.rot = QuatRotateQuat(cmsld2t.rot, QuatEuler(110,0,0))
				if medtimermax-medtimer > 0.9 and medtimermax-medtimer < 1.2 then
					local t = (medtimermax-medtimer-0.9)/0.3
					cmstl3t.pos = VecAdd(cmstl3t.pos, Vec(0, 0.45*t, 0))
				elseif medtimermax-medtimer > 3.1 and medtimermax-medtimer < 3.4 then
					local t = (medtimermax-medtimer-3.1)/0.3
					cmstl3t.pos = VecAdd(cmstl3t.pos, Vec(0, 0.45*(1-t), 0))
				elseif medtimermax-medtimer > 1.2 and medtimermax-medtimer < 3.4 then
					cmstl3t.pos = VecAdd(cmstl3t.pos, Vec(0, 0.45, 0))
				end
				if medtimermax-medtimer > 3.7 and medtimermax-medtimer < 4 then
					local t = (medtimermax-medtimer-3.7)/0.3
					cmstl2t.pos = VecAdd(cmstl2t.pos, Vec(0, 0.45*t, 0))
				elseif medtimermax-medtimer > 5.8 and medtimermax-medtimer < 6.1 then
					local t = (medtimermax-medtimer-5.8)/0.3
					cmstl2t.pos = VecAdd(cmstl2t.pos, Vec(0, 0.45*(1-t), 0))
				elseif medtimermax-medtimer > 3.7 and medtimermax-medtimer < 6.1 then
					cmstl2t.pos = VecAdd(cmstl2t.pos, Vec(0, 0.45, 0))
				end
				if medtimermax-medtimer > 6.4 and medtimermax-medtimer < 6.7 then
					local t = (medtimermax-medtimer-6.4)/0.3
					cmstl1t.pos = VecAdd(cmstl1t.pos, Vec(0, 0.55*t, 0))
				elseif medtimermax-medtimer > 8.8 and medtimermax-medtimer < 9.1 then
					local t = (medtimermax-medtimer-8.8)/0.3
					cmstl1t.pos = VecAdd(cmstl1t.pos, Vec(0, 0.55*(1-t), 0))
				elseif medtimermax-medtimer > 6.4 and medtimermax-medtimer < 9.1 then
					cmstl1t.pos = VecAdd(cmstl1t.pos, Vec(0, 0.55, 0))
				end
			elseif  medtimer <= 0.5 then
				local t = medtimer/0.5
				cmsld1t.rot = QuatRotateQuat(cmsld1t.rot, QuatEuler(100*t,0,180))
				cmsld2t.rot = QuatRotateQuat(cmsld2t.rot, QuatEuler(110*t,0,0))
			end

			cmsld2t = TransformToParentTransform(cmsld1t, cmsld2t)

			SetShapeLocalTransform(cmslid1, cmsld1t)
			SetShapeLocalTransform(cmslid2, cmsld2t)

			SetShapeLocalTransform(cmstool1, cmstl1t)
			SetShapeLocalTransform(cmstool2, cmstl2t)
			SetShapeLocalTransform(cmstool3, cmstl3t)

			if medtimer > 0 then

			end

			------ARM ANIMATIONS------

			-- Defining arm shapes and which clothing type is used
			local clothingtype = GetString("savegame.mod.difficulty")
			local bs = GetBodyShapes(GetToolBody())
			for i = 7, 18 do
				SetShapeLocalTransform(bs[i], hideTrans)
			end
			local hand1 = bs[7]
			local arm1 = bs[9]
			local hand2 = bs[8]
			if clothingtype == "peaceful" then
				hand1 = bs[10]
				arm1 = bs[12]
				hand2 = bs[11]
			elseif clothingtype == "normal" then
				hand1 = bs[13]
				arm1 = bs[15]
				hand2 = bs[14]
			elseif clothingtype == "hardcore" then
				hand1 = bs[16]
				arm1 = bs[18]
				hand2 = bs[17]
			else
				hand1 = bs[7]
				arm1 = bs[9]
				hand2 = bs[8]
			end

			local btrans = GetBodyTransform(b)

			-- Setting locations for the hands
			local x2, y2, z2, rotx2, roty2, rotz2 = -0.2, 0, 0.05, 0, 0, 0

			local h1p1l = INS(true, x2, y2, z2, rotx2, roty2, rotz2).pos

			local pcrx,pcry,pcrz=GetQuatEuler(GetPlayerCameraTransform().rot)
			local pitch=pcrx*0.0174532925199
			local lookoffset=math.sin(pitch)

			-- h1p1l = Vec(0.225, -0.85, -1.9)
			local h1p2l = TransformToLocalPoint(btrans, TransformToParentPoint(GetPlayerTransform(), Vec(-0.6, 0.7-crouchoffset, 0.2-lookoffset)))
			local hnd1 = Transform(h1p1l, QuatRotateQuat(QuatLookAt(h1p2l, h1p1l), QuatEuler(0,90,90)))
			local a1p1l = VecAdd(h1p1l, TransformToParentVec(hnd1, Vec(0, 1, 0)))
			local a1p2l = TransformToLocalPoint(btrans, TransformToParentPoint(GetPlayerTransform(), Vec(-0.45, 1.5-crouchoffset-lookoffset*0.5, 0.5-lookoffset)))
			local amt1 = Transform(a1p1l, QuatRotateQuat(QuatLookAt(a1p2l, a1p1l), QuatEuler(0,90,90)))
			SetShapeLocalTransform(hand1, hnd1)
			SetShapeLocalTransform(arm1, amt1)

			local x3, y3, z3, rotx3, roty3, rotz3 = 0, 0.3, 0.1, 0, 0, 0
			local lt = TransformToParentPoint(Transform(cmsld2t.pos, QuatRotateQuat(cmsld2t.rot, QuatEuler(180, 0, 0))), Vec(0.4, 0, -0.1))
			local t1t = TransformToParentPoint(Transform(cmstl1t.pos, QuatRotateQuat(cmstl1t.rot, QuatEuler(180, 0, 0))), Vec(0.05, 0, -0.25))
			local t2t = TransformToParentPoint(Transform(cmstl2t.pos, QuatRotateQuat(cmstl2t.rot, QuatEuler(180, 0, 0))), Vec(0.05, 0, -0.25))
			local t3t = TransformToParentPoint(Transform(cmstl3t.pos, QuatRotateQuat(cmstl3t.rot, QuatEuler(180, 0, 0))), Vec(0.05, 0, -0.1))
			if medtimermax-medtimer < 0.5 or medtimer < 0.7 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0+lt[1], 0+lt[2], 0+lt[3], 0, 0, 0
			elseif medtimermax-medtimer < 3.4 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0+t3t[1], 0+t3t[2], 0+t3t[3], 0, 0, 0
			elseif medtimermax-medtimer > 3.4 and medtimermax-medtimer < 6.2 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0+t2t[1], 0+t2t[2], 0+t2t[3], 0, 0, 0
			elseif medtimermax-medtimer > 6.2 and medtimermax-medtimer < 9.2 then
				x3, y3, z3, rotx3, roty3, rotz3 = 0+t1t[1], 0+t1t[2], 0+t1t[3], 0, 0, 0
			end

			local h2p1l = SEL(true, x3, y3, z3, rotx3, roty3, rotz3).pos

			--h2p1l = Vec(0.275, -0.95, -0.85)
			local h2p2l = TransformToLocalPoint(btrans, TransformToParentPoint(GetPlayerTransform(), Vec(0.55, 1.1-crouchoffset-lookoffset, 0.9)))
			local hnd2 = Transform(h2p1l, QuatRotateQuat(QuatLookAt(h2p2l, h2p1l), QuatEuler(0,90,90)))
			SetShapeLocalTransform(hand2, hnd2)
		end
	end
end