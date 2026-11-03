function Init_ShadowVolume()

	ReturnedFirst = false

	ReturnChunks_Forward = 1 -- How many chunks past 0,0,0 to trigger the return.
    ReturnMeters_Forward = ReturnChunks_Forward * ChunkLength -- How many meters past 0,0,0 to trigger the return.

	ReturnChunks_Backwards = 1 -- Chunks behing pos 0,0,0. -1 = 1 chunk backwards to account for shadow volume.
	ReturnMeters_Backwards = ReturnChunks_Backwards * ChunkLength -- Chunks behing pos 0,0,0. -1 = 1 chunk backwards to account for shadow volume.

	TotalReturnChunks = ReturnChunks_Forward + ReturnChunks_Backwards
	TotalReturnMeters = TotalReturnChunks * ChunkLength
	TotalReturnCells = TotalReturnChunks * Depth

    PlayerZStart = GetPlayerTransform().pos[3]
	PlayerZ = 0

	ReturnsCompleted = 0 -- Used for spawn pos offset.

end


function ReturnToShadowVolume()

	if GetPlayerTransform().pos[3] <= -ReturnMeters_Forward then -- Check if player is past trigger pos.

		ReturnedFirst = true

		CellsProgressedOffset = CellsProgressedOffset + TotalReturnCells -- Add how many chunks moved to offset.
		ReturnsCompleted = ReturnsCompleted + 1

		local addPos = Vec(0, 0, TotalReturnMeters)

		local bodies = FindBodies("", true)
		for i = 1, #bodies do

			local body = bodies[i]
			local bodyT = GetBodyTransform(body)
			bodyT.pos = VecAdd(bodyT.pos, addPos)
			SetBodyTransform(body, bodyT)

		end

		local triggers = FindTriggers("", true)
		for i = 1, #triggers do
			local trigger = triggers[i]
			local triggerT = GetTriggerTransform(trigger)
			triggerT.pos = Vec(triggerT.pos[1], triggerT.pos[2], triggerT.pos[3] + TotalReturnMeters)
			SetTriggerTransform(trigger, triggerT)
		end

		local playerT = GetPlayerTransform(true)
		playerT.pos = VecAdd(playerT.pos, addPos)
		SetPlayerTransform(playerT, true)

	end

end

function CalculateProgress()

	PlayerZ = (PlayerTr.pos[3] / -MeterScale) + CellsProgressedOffset
	PlayerZ = clamp(PlayerZ, 0, math.huge) * 10

end


function Draw_ShadowVolume()
	UiPush()

		UiTranslate(UiCenter(), 10)

		UiFont("bold.ttf", 32)
		UiColor(1,1,1, 1)
		UiTextOutline(0,0,0, 0.5, 0.2)

		local text = sfnCommas(tonumber(sfn(PlayerZ)), 0)
		UiSplitText("Distance", text .. " meters")

		UiTranslate(0, 32)
		UiSplitText("Territory", TerritoryDataY[CellsProgressedAdjusted])

	UiPop()
end
