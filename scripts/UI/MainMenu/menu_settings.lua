function draw_setting(object, bg_alpha)

	local w = UiWidth() - 40
	local h = 60
	local pad = 20

	if bg_alpha then
		UiColor(0,0,0, bg_alpha)
		UiRect(w, h)
	end

	_G["draw_settings_" .. object.type](object, 24, w, h, pad, 0)


	return h
end

function draw_settings_range(setting, font_size, w, h, padW,padH)
	font_size = font_size or 30

	min = setting.min
	max = setting.max
	set = setting.value
	lockincrement = setting.increment
	paddingwidth = padW or 0
	paddingheight = padH or 0
	spreadpad = AutoDefault(spreadpad, true)

	local width = w - (paddingwidth*2)
	local dotwidth, dotheight = UiGetImageSize("ui/common/dot.png")

	local screen = AutoMap(set, min, max, 0, width)

	UiPush()
		UiWindow(w, h)
		UiTranslate(paddingwidth, paddingheight)
		UiColor(1,1,1, 1)

		UiTranslate(0,(h-font_size-6-dotheight)/2)
		UiFont("regular.ttf", font_size)

		UiTranslate(0, font_size)
		-- Title
		UiPush()
			UiAlign("left")
			UiText(setting.title)
		UiPop()

		-- Value
		UiPush()
			UiAlign("right")
			UiTranslate(width)
			UiText(sfn(set))
		UiPop()

		UiTranslate(0, 6)
		UiPush()
			UiAlign("left middle")
			UiTranslate(0, dotheight / 2)
			UiRect(width, 2)
		UiPop()

		screen, released = UiSlider('ui/common/dot.png', "x", screen, 0, width)
		screen = AutoMap(screen, 0, width, min, max)
		screen = AutoRound(screen, lockincrement)
		screen = AutoClamp(screen, min, max)
		set = screen

	UiPop()

	setting.value = set

	return set, data

end

function draw_settings_checkbox(setting, font_size, w,h, padW,padH)

	padW = AutoDefault(padW, 0)
	padH = AutoDefault(padH, 0)

	local width = w - (padW*2)
	local height = h - (padH*2)

	UiPush()
		UiTranslate(paddingwidth, paddingheight)
		UiColor(1,1,1, 1)

        local buttonW = height * 0.75
        local buttonH = height * 0.75


        -- Title
        UiPush()
            UiTranslate(0, height/2)
            UiAlign("left middle")
            UiFont("regular.ttf", font_size or 30)
            UiText(setting.title)
        UiPop()

        UiTranslate(500, 0)

		-- Multi-Options
		UiPush()


            UiTranslate(height * 0.25/2, height * 0.25/2)

            local checkbox_label_width = buttonW*4

            if setting.value then
                if UiBlankButton(buttonH,buttonH) then
                    setting.value = not setting.value
                end
                UiImageBox("MOD/img/icon_checkmark.png",buttonH,buttonH,0,0)

                UiTranslate(buttonW + 10, 0)
                UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Dark,Grey_Dark,Grey_Dark, 3/4)
                if UiTextButton("SELECTED", checkbox_label_width, buttonH) then
                	setting.value = not setting.value
                end
            else
                if UiBlankButton(buttonH,buttonH) then
                    setting.value = not setting.value
                end
                UiImageBox("MOD/img/icon_cross.png",buttonH,buttonH,0,0)

                UiTranslate(buttonW + 10, 0)
                UiButtonImageBox("ui/common/box-solid-6.png", 6,6, 0,0,0, .2)
                if UiTextButton("NOT SELECTED", checkbox_label_width, buttonH) then
                	setting.value = not setting.value
                end
            end
        UiPop()


	UiPop()

	return setting.value
end

--todo fix
function draw_settings_segment(setting, font_size, w,h, padW,padH)
	padW = AutoDefault(padW, 0)
	padH = AutoDefault(padH, 0)

	local width = w - (padW*2)
	local height = h - (padH*2)

	-- UiPush()
	-- 	UiTranslate(paddingwidth, paddingheight)
	-- 	UiColor(1,1,1, 1)

	-- 	-- Title
	-- 	UiPush()
	-- 		UiAlign("left top")
	-- 		UiFont("regular.ttf", h/2)
	-- 		UiText(setting.title)
	-- 	UiPop()
	-- 	UiTranslate(0, h/2)

	-- 	-- Multi-Options
	-- 	UiPush()
	-- 		local valCount = #setting.values
	-- 		local buttonW = width/valCount
	-- 		local buttonH = height/2
	-- 		UiPush()
	-- 			UiColor(0,0,0, .2)
	-- 			UiImageBox('ui/menu/white_32.png',width,buttonH,0,0)
	-- 		UiPop()
	-- 		--UiButtonImageBox('', 0,0)
	-- 		UiPush()
	-- 			UiButtonImageBox("ui/common/box-solid-6.png", 6,6, 0,0,0, 0)
	-- 			for i,curVal in ipairs(setting.values)do
	-- 				if setting.value == curVal then
	-- 					UiPush()
	-- 						UiColor(.6,.6,.6, .4)
	-- 						UiImageBox('ui/menu/white_32.png', buttonW, buttonH, 0,0)
	-- 					UiPop()
	-- 				end
	-- 				if UiIsMouseInRect(buttonW, buttonH) then
	-- 					UiPush()
	-- 						UiColor(1,1,1, .1)
	-- 						UiImageBox('ui/menu/white_32.png', buttonW, buttonH, 0,0)
	-- 					UiPop()
	-- 				end
	-- 				UiColor(1,1,1, 1)
	-- 				if UiTextButton(tostring(curVal):upper(), buttonW, buttonH) then
	-- 					setting.value = curVal
	-- 				end
	-- 				UiTranslate(buttonW)
	-- 			end
	-- 		UiPop()
	-- 	UiPop()
	-- UiPop()

	return setting.value
end

--todo fix
_mapCurInputBind = _mapCurInputBind or nil
_mapCurInputIndex = _mapCurInputIndex or nil
function draw_settings_keybind(setting, font_size, w,h, padW,padH)

	padW = AutoDefault(padW, 0)
	padH = AutoDefault(padH, 0)

	local width = w
	local height = h

	local mappingCurInputBind = _mapCurInputBind == setting

	UiPush()

		UiAlign("left top")
		UiTranslate(paddingwidth, paddingheight)
		UiColor(1,1,1, 1)

		--! Interferes with the keybind button highlights.
		-- UiPush()
		-- 	if UiIsMouseInRect(width, height) or mappingCurInputBind then
		-- 		UiColor(.6,.6,.6, .2)
		-- 		UiImageBox('ui/menu/white_32.png', width,height, 0,0)
		-- 	else
		-- 		UiColor(0,0,0, .2)
		-- 		UiImageBox('ui/menu/white_32.png', width,height, 0,0)
		-- 	end
		-- UiPop()

		-- Title
		UiPush()
			UiTranslate(0, h/2)
			UiAlign("left middle")
			UiFont("regular.ttf", font_size or 30)
			UiText(setting.title:upper())
		UiPop()

		UiTranslate(300)



		UiPush()

			local button_pad = 10
			local buttonW = height * 2 - button_pad
			local buttonH = height - button_pad

			UiPush()

				UiTranslate(0, button_pad/2)

                -- Magic tables are kinda confusing and I had to do this.
                local keys = {}

                for i = 1, 3 do
                    if setting.values["k" .. i] ~= "none" then
                        table.insert(keys, setting.values["k" .. i])
                    end
                end

				for index, value in ipairs(keys) do

                    local key = "k" .. index
                    local index = "k"..index

                    -- Key text field
					UiButtonImageBox("ui/common/box-solid-6.png", 6,6, 0.4,0.4,0.4, 3/4)
					local mappingCurInputIndex = _mapCurInputIndex == index
					UiPush()
						if UiIsMouseInRect(buttonW, buttonH) or (mappingCurInputBind and mappingCurInputIndex) then
							UiColor(1,1,1, .2)
							UiImageBox("ui/common/box-solid-6.png", buttonW, buttonH, 6,6)
						else
							UiColor(.5,.5,.5, .2)
							UiImageBox("ui/common/box-solid-6.png", buttonW, buttonH, 6,6)
						end
					UiPop()
                    -- Key text field - blinking caret
					UiColor(1,1,1, 1)
					local buttonText = tostring(value):upper()

                    if (mappingCurInputBind and mappingCurInputIndex) then
                        if GetTime() % 0.5 > 0.25 then
                            buttonText = "____"
                        else
                            buttonText = " "
                        end
                    end

                    -- Button overlay.
					if UiTextButton(buttonText, buttonW, buttonH) then
						_mapCurInputBind = setting
						_mapCurInputIndex = index
					end


                    -- Assign new value
                    if mappingCurInputBind and mappingCurInputIndex then
                        UiModalBegin()
							if InputPressed("esc") then
								_mapCurInputBind = nil
								_mapCurInputIndex = nil
							elseif InputPressed("any")then
                                local val
                                local LAGACY=true
                                if LAGACY then
                                    val=GetInputPressed()
                                else
                                    val=InputLastPressedKey()
                                end
                                if val~=""and --[[ val~="tab"and ]] val~="esc"and tonumber(val)==nil then
                                    _mapCurInputBind = nil
                                    _mapCurInputIndex = nil
                                    setting.values[key] = val
                                end
                            end
                        UiModalEnd()
                    end
                    UiTranslate(buttonW)

					-- Delete keybind
                    if (#keys >= 2 and key ~= "k1") then
                        UiButtonImageBox("ui/common/box-solid-6.png", 6,6, .8,.2,.2, .6)
                        if UiTextButton("-", buttonH, buttonH) then

                            setting.values[key] = nil

							local newKeys = {}
							local nilCheck = false
							for i = 1, 3 do

								local keyCopy = setting.values["k" .. i]

								keyCopy = ternary(keyCopy == " " or keyCopy == nil, "none", keyCopy)

								table.insert(newKeys, keyCopy)

								print(keyCopy)

							end

							PrintTable(newKeys)

							setting.values = MakeKeybind(unpack(newKeys))

                            -- -- Yes this is terrible I am tired lol. --todo
                            -- if setting.values["k" .. 3] and not setting.values["k" .. 2] then

                            --     setting.values["k" .. 2] = setting.values["k" .. 3]
                            --     setting.values["k" .. 3] = nil

							-- 	local k1 = setting.values["k" .. 1]
							-- 	local k3 = setting.values["k" .. 1]

							-- 	setting.values = MakeKeybind(k1, k3)

                            -- end

                            UiTranslate(-buttonH * 2 - 10)

                        end
                        UiTranslate(buttonH + 10)
                    else
                        UiTranslate(buttonH/2 - 10)
                    end

				end

				if #keys < 3 then
					UiColor(1,1,1, 1)
					UiButtonImageBox("ui/common/box-solid-6.png", 6,6, .2,.2,.8, .6)
					if UiTextButton("+", buttonH, buttonH) then

						-- _mapCurInputBind = setting
						-- _mapCurInputIndex = #keys + 1

                        table.insert(keys, " ")

                        --todo sort by letters first, shift and ctrl last.
                        local kb = {}
                        for i = 1, #keys do
                            kb[i] = keys[i]
                        end

                        setting.values = MakeKeybind(unpack(kb)) -- Explode that bih.

					end
				end

			UiPop()
		UiPop()
	UiPop()

	return setting.value

end
