#version 2
#include "script/include/player.lua"
-- (v2) server: crate loot types; any player interacting with a crate removes its prompt.




function server.init()
Med1x1 = {
"meds-bleed-bandage_Bandage_1_1",
"meds-bleed-general-ifak_IFAK_300_300",
"meds-fracture-splint_Splint_1_1",
"meds-general-ai2_AI-2_100_100",
"meds-stim-adrenaline_Adrenaline_1_1",
"meds-stim-morphine_Morphine_1_1",
"meds-stim-pz1_PZ1_1_1",
"",
"",
"",
"",
}
AmountMed1x1 = #Med1x1
Med1x2 = {
"meds-bleed-general-car_CAR_220_220",
"meds-bleed-general-car_CAR_158_220",
"meds-bleed-general-car_CAR_123_220",
"meds-bleed-general-car_CAR_93_220",
"meds-bleed-general-car_CAR_170_220",
"meds-surgery-cms_CMS_5_5",
"meds-surgery-cms_CMS_4_5",
"meds-surgery-cms_CMS_3_5",
"meds-surgery-cms_CMS_2_5",
"meds-surgery-cms_CMS_1_5",
"",
"",
"",
"",
}
AmountMed1x2 = #Med1x2
Med1x3 = {
"meds-fracture-surgery-surv12_Surv12_12_12",
"meds-fracture-surgery-surv12_Surv12_11_12",
"meds-fracture-surgery-surv12_Surv12_10_12",
"meds-fracture-surgery-surv12_Surv12_9_12",
"meds-fracture-surgery-surv12_Surv12_8_12",
"meds-fracture-surgery-surv12_Surv12_7_12",
"meds-fracture-surgery-surv12_Surv12_6_12",
"meds-fracture-surgery-surv12_Surv12_5_12",
"meds-fracture-surgery-surv12_Surv12_4_12",
"meds-fracture-surgery-surv12_Surv12_3_12",
"meds-fracture-surgery-surv12_Surv12_2_12",
"meds-fracture-surgery-surv12_Surv12_1_12",
"",
"",
"",
"",
}
AmountMed1x3 = #Med1x3




end
function server.tick(dt)
--	DebugPrint(#Med1x1)
	MaybeCrate = FindBodies("MaybeCrate", true)
		for i=1,#MaybeCrate do
			if	not HasTag(MaybeCrate[i], "dont") then
					local Chance = tonumber(GetTagValue(MaybeCrate[i], "chance"))
					local probability = math.random(1,100)
					if probability <= Chance then 
						SetTag(MaybeCrate[i], "Crate")
						SetTag(MaybeCrate[i], "dont")
						SetTag(MaybeCrate[i], "interact", "Crate")
					end
				end
			end
		
		
		
		
		
    Crates = FindBodies("Crate", true)
		
				
				
		for i=1,#Crates do
			if not HasTag(Crates[i], "small") and not HasTag(Crates[i], "mid") and not HasTag(Crates[i], "large") then
				local newrandomy = math.random(1,3)
				if newrandomy == 1 then
					SetTag(Crates[i], "small")		
				elseif newrandomy == 2 then
					SetTag(Crates[i], "mid")	
				elseif newrandomy == 3 then
					SetTag(Crates[i], "large")	
				end
			end
		end
		for p in Players() do
			if GetPlayerInteractBody(p) == Crates[i] and InputPressed("interact", p) then
				RemoveTag(Crates[i], "interact")
			end
		end
			
		if not HasTag(Crates[i], "IsDone") then
			if not HasTag(Crates[i], "med") and not HasTag(Crates[i], "weapon") and not HasTag(Crates[i], "food") and not HasTag(Crates[i], "general") then
				local randomly = math.random(1,4)
				if randomly == 1 then 
					SetTag(Crates[i], "med")				
				elseif randomly == 2 then 
					SetTag(Crates[i], "weapon")
				elseif randomly == 3 then 
					SetTag(Crates[i], "food")
				elseif randomly == 4 then 
					SetTag(Crates[i], "general")
				end
			end
		end

				
				if HasTag(Crates[i], "med") and HasTag(Crates[i], "small") then
					local whatcrate = math.random(1,1)
					if whatcrate == 1 then

						SetTag(Crates[i], "Width", "3")
						SetTag(Crates[i], "Height", "2")
						-----------------------------------------------------
						SetTag(Crates[i], "1_1", "" .. Med1x1[math.random(1,AmountMed1x1)] .. "")
						SetTag(Crates[i], "2_1", "" .. Med1x1[math.random(1,AmountMed1x1)] .. "")
						SetTag(Crates[i], "3_1", "" .. Med1x1[math.random(1,AmountMed1x1)] .. "")
						-----------------------------------------------------
						SetTag(Crates[i], "1_2", "" .. Med1x2[math.random(1,AmountMed1x2)] .. "")
						SetTag(Crates[i], "3_2", "" .. Med1x1[math.random(1,AmountMed1x1)] .. "")
						SetTag(Crates[i], "IsDone")
				elseif HasTag(Crates[i], "med") and HasTag(Crates[i], "mid") then
					local whatcrate = math.random(1,1)
					if whatcrate == 1 then
					
						SetTag(Crates[i], "IsDone")
					end
				elseif HasTag(Crates[i], "med") and HasTag(Crates[i], "large") then
					local whatcrate = math.random(1,1)
					if whatcrate == 1 then
						
						SetTag(Crates[i], "IsDone")

					end
				end
			end
end

		



