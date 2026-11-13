RED = {r=1,g=0,b=0,a=1}
GREEN = {r=0,g=1,b=0,a=1}
YELLOW = {r=1,g=1,b=0,a=1}
COLORS = {red=RED,green=GREEN,yellow=YELLOW}


PARTS_SCALE = 1.2

HEAD_SIZE = 30 * PARTS_SCALE
BODY_WIDTH = 38 * PARTS_SCALE
BODY_HEIGHT= 60 * PARTS_SCALE
ARM_WIDTH = 18 * PARTS_SCALE


HEALTHY = "healthy"
INJURED = "injured"
DEAD = "dead"

function Effect(title, color)
	return {text=title, color=color}
end

function BodyState(overall, head, body, leftArm, rightArm, leftLeg, rightLeg, effects)
	if effects == nil then effects = {} end
	return {overall=overall, head=head, body=body, leftArm=leftArm, rightArm=rightArm, leftLeg=leftLeg,rightLeg=rightLeg, effects=effects}
end

function BodyPart(color, effects)
	if effects == nil then effects = {} end
	return {color=color, effects=effects}
end

BROKEN_BODY_PART = BodyPart(RED, {Effect("Broken", RED)}) 
BROKEN_NECK = BodyPart(RED, {Effect("Broken Neck", RED)}) 

HEALTHY_BODY_STATE = BodyState(
		HEALTHY,
		BodyPart(GREEN, {}),
		BodyPart(GREEN, {}),	
		BodyPart(GREEN, {}),
		BodyPart(GREEN, {}),
		BodyPart(GREEN, {}),
		BodyPart(GREEN, {}),
		{}
	)

function UiDrawBodyState(state)

	local icon_size = 26

	UiTranslate(ARM_WIDTH+2+(BODY_WIDTH-HEAD_SIZE)/2,0)
	UiDrawHead(state.head, icon_size)

	UiTranslate(-(BODY_WIDTH-HEAD_SIZE)/2,HEAD_SIZE+2)
	UiDrawBody(state.body, icon_size)

	UiPush()
		UiTranslate(-ARM_WIDTH-2,0)
		UiDrawArm(state.leftArm, icon_size)
	UiPop()

	UiPush()
		UiTranslate(BODY_WIDTH+3,0)
		UiDrawArm(state.rightArm, icon_size)
	UiPop()

	UiTranslate(0,BODY_HEIGHT+2)
	UiDrawArm(state.leftLeg, icon_size)

	UiTranslate(BODY_WIDTH-ARM_WIDTH,0)
	UiDrawArm(state.rightLeg, icon_size)

end

function UiDrawHead(state, icon_size)

	drawRect(0,0,HEAD_SIZE,HEAD_SIZE,state.color.r,state.color.g,state.color.b,state.color.a)

	UiPush()
		UiTranslate(HEAD_SIZE/2, HEAD_SIZE/2) -- Center of ui body part
		UiDrawInjuries(state, icon_size)
	UiPop()

end

function UiDrawBody(state, icon_size)

	drawRect(0,0,BODY_WIDTH,BODY_HEIGHT,state.color.r,state.color.g,state.color.b,state.color.a)

	UiPush()
		UiTranslate(BODY_WIDTH/2, BODY_HEIGHT/2) -- Center of ui body part
		UiDrawInjuries(state, icon_size)
	UiPop()

end

function UiDrawArm(state, icon_size)

	drawRect(0,0,ARM_WIDTH,BODY_HEIGHT,state.color.r,state.color.g,state.color.b,state.color.a)

	UiPush()
		UiTranslate(ARM_WIDTH/2, BODY_HEIGHT/2) -- Center of ui body part
		UiDrawInjuries(state, icon_size)
	UiPop()

end

function UiDrawInjuries(state, icon_size)
	UiPush()

		local injuries_count = GetTableSize(state.effects)
		UiAlign("center middle")

		UiTranslate(0, -(injuries_count - 1) * (icon_size / 2))

		-- if #state.effects > 0 then
		-- 	PrintTable(state.effects)
		-- end

		for index, effect in ipairs(state.effects) do

			UiPush()

				if effect.text == "Bone Fracture" then

					UiColor(0,0,0, 1)
					UiImageBox("UI/icon_broken_bone.png", icon_size + 4,icon_size + 4, 0,0)
					UiColor(1,1,1, Oscillate(1)/2 + 1/2)
					UiImageBox("UI/icon_broken_bone.png", icon_size,icon_size, 0,0)

				elseif effect.text == "Bleeding" then

					UiColor(1,1,1, 1)
					UiImageBox("UI/icon_drop.png", icon_size + 4,icon_size + 4, 0,0)
					UiColor(1,0,0, Oscillate(1)/2 + 1/2)
					UiImageBox("UI/icon_drop.png", icon_size,icon_size, 0,0)

				end

			UiPop()

			UiTranslate(0, icon_size + 4)

		end

	UiPop()
end
