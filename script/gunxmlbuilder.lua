attachmentXMLTable = {
	["gun-ak74"]={
		_header = [[
			<body tags="Loot=gun-ak74_Simonov-545_mag0-ak-545_6L23_30_30_5.45 interact=Simonov-545 unbreakable" pos="0 .3" dynamic="true">
		]],
		_basegun = [[
			<group name="Metal" prop0="color=.15 .15 .15" prop1="pbr=.02 .1" prop2="material=metal">
				<group name="barrel" pos="0.0 0.0 0.3">
					REPLACEbarrel
						<voxbox pos="-0.05 -0.05 -0.05" size="1 1 3">
							<voxbox pos="0.0 0.03 0.0" rot="0.0 0.0 0.0" size="1 1 2"/>
						</voxbox>
						<group pos="0.0 0.0 0.25">
							REPLACE(THIS DOES NOT WORK)muzzle
								<voxbox name="Barrel" tags="barrel range=30 magsize=30 damage=8 firerate=.17 gun=ak roundsize=2" pos="-0.05 -0.05 0.0" rot="0.0 0.0 0.0" size="1 1 1"/>
							EN(THIS DOES NOT WORK)D
						</group>
					END
				</group>
				<voxbox pos="-0.045 -0.05 -0.25" size="1 1 4"/>
				<voxbox pos="-0.055 -0.05 -0.25" size="1 1 4"/>
				<group name="dustcover" pos="0.0 0.05 -0.25">
					REPLACEdustcover
						<voxbox pos="-0.05 -0.05 0.05" rot="0.0 0.0 0.0" size="1 1 3">
							<voxbox pos="0.0 0.1" rot="135.0" size="1 1 1"/>
						</voxbox>
					END
				</group>
			</group>
			<group name="Magazine" pos="0.0 -0.05 -0.1" rot="-10.0" prop0="color=.42 .25 .07" prop1="material=metal">
				REPLACEmag
					<voxbox pos="-0.05 -0.1 0.0" rot="0.0 0.0 0.0" size="1 1 1">
						<voxbox pos="0 0 .03" size="1 1 1"/>
					</voxbox>
					<group pos="-0.05 -0.1 0.0" rot="-10.0 0.0 0.0">
						<voxbox pos="0 -.1" size="1 1 1">
							<voxbox pos="0 0 .03" size="1 1 1"/>
						</voxbox>
						<group pos="0 -.1" rot="-10.0">
							<voxbox pos="0 -.1" size="1 1 1">
								<voxbox pos="0 0 .03" size="1 1 1"/>
							</voxbox>
						</group>
					</group>
				END
			</group>
			<group name="Wood" prop0="color=.4 .19 .11" prop1="material=wood">
				<group name="Stock" pos="0 0 -.25">
					REPLACEstock
						<voxbox pos="-.05 -.05 -.4" size="1 1 2">
							<voxbox pos="0 -.05" size="1 1 2">
								<voxbox rot="68.0" size="1 4 1"/>
							</voxbox>
							<voxbox pos="0.0 0.0 0.15" rot="0.0 0.0 0.0" size="1 1 2"/>
						</voxbox>
						<voxbox pos="0.055 -0.05 0.0" rot="0.0 -177.1 0.0" size="1 1 1"/>
						<voxbox pos="-0.055 -0.05 0.0" rot="0.0 87.1 0.0" size="1 1 1"/>
					END
				</group>
				<group name="hand guard" pos="0.0 -0.06 0.1">
					<group>
						<group pos="0.0 0.0 0.1" rot="-100.0">
							<voxbox pos="-0.04 0.0 0.0" size="1 1 1"/>
							<voxbox pos="-0.06 0.0 0.0" size="1 1 1"/>
						</group>
						<voxbox pos="-0.04 0.0 0.0" rot="0.0 0.0 0.0" size="1 1 2">
							<voxbox pos="0.0 0.05 0.0" rot="0.0 0.0 0.0" size="1 1 2"/>
						</voxbox>
						<voxbox pos="-0.06 0.0 0.0" rot="0.0 0.0 0.0" size="1 1 2">
							<voxbox pos="0.0 0.05 0.0" rot="0.0 0.0 0.0" size="1 1 2"/>
						</voxbox>
					</group>
				</group>
			</group>
			<group name="Wood2" prop0="color=.25 .1 .15" prop1="material=wood">
				<voxbox name="Grip" tags="Grip" pos="-0.05 -0.05 -0.15" rot="-160" size="1 2 1">
					<light tags="handle" pos="0.05 0.1 0.05" scale="0" angle="0" penumbra="0" size="0.05" reach="0" unshadowed="0" fogscale="0" fogiter="0" glare="0"/>
				</voxbox>
			</group>
		]],
		mag={
			["mag0-ak-545"]=[[
				<group prop0="color=.42 .25 .07" prop1="material=metal">
					<voxbox pos="-0.05 -0.1 0.0" rot="0.0 0.0 0.0" size="1 1 1">
						<voxbox pos="0 0 .03" size="1 1 1"/>
					</voxbox>
					<group pos="-0.05 -0.1 0.0" rot="-10.0 0.0 0.0">
						<voxbox pos="0 -.1" size="1 1 1">
							<voxbox pos="0 0 .03" size="1 1 1"/>
						</voxbox>
						<group pos="0 -.1" rot="-10.0">
							<voxbox pos="0 -.1" size="1 1 1">
								<voxbox pos="0 0 .03" size="1 1 1"/>
							</voxbox>
						</group>
					</group>
				</group>
			]],
			["mag1-ak-545"]=[[
				<group prop0="color=.42 .25 .07" prop1="material=metal">
					<voxbox pos="-0.05 -0.1 0.0" rot="0.0 0.0 0.0" size="1 1 1">
						<voxbox pos="0 0 .03" size="1 1 1"/>
					</voxbox>
					<group pos="-0.05 -0.1 0.0" rot="-10.0 0.0 0.0">
						<voxbox pos="0 -.1" size="1 1 1">
							<voxbox pos="0 0 .03" size="1 1 1"/>
						</voxbox>
						<group pos="0 -.1" rot="-10.0">
							<voxbox pos="0 -.1" size="1 1 1">
								<voxbox pos="0 0 .03" size="1 1 1"/>
							</voxbox>
							<group pos="0 -.1" rot="-10.0">
								<voxbox pos="0 -.1" size="1 1 1">
									<voxbox pos="0 0 .03" size="1 1 1"/>
								</voxbox>
								<group pos="0 -.1" rot="-10.0">
									<voxbox pos="0 -.1" size="1 1 1">
										<voxbox pos="0 0 .03" size="1 1 1"/>
									</voxbox>
								</group>
							</group>
						</group>
					</group>
				</group>
			]],
			["mag2-ak-545"]=[[
				<group prop0="color=.2 .2 .2" prop1="material=metal">
					<voxbox pos="-0.05 -0.1 0.0" rot="0.0 0.0 0.0" size="1 1 1">
						<voxbox pos="0 0 .03" size="1 1 1"/>
					</voxbox>
					<group pos="-0.05 -0.1 0.0" rot="-10">
						<voxbox pos="0 -.1" size="1 1 1">
							<voxbox pos="0.0 -0.0 0.03" rot="0.0 0.0 0.0" size="1 1 1"/>
						</voxbox>
						<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
							<voxbox pos="0 -.1" size="1 1 1">
								<voxbox pos="0 0 .03" size="1 1 1"/>
							</voxbox>
							<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
								<voxbox pos="0 -.1" size="1 1 1">
									<voxbox pos="0 0 .03" size="1 1 1"/>
								</voxbox>
								<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
									<voxbox pos="0 -.1" size="1 1 1">
										<voxbox pos="0 0 .03" size="1 1 1"/>
									</voxbox>
									<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
										<voxbox pos="0.0 -0.2 0.0" rot="0.0 0.0 0.0" size="1 2 1">
											<voxbox pos="0 0 .03" size="1 2 1"/>
										</voxbox>
										<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
											<voxbox pos="0 -.1" size="1 1 1">
												<voxbox pos="0 0 .03" size="1 1 1"/>
											</voxbox>
											<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
												<voxbox pos="0 -.1" size="1 1 1">
													<voxbox pos="0 0 .03" size="1 1 1"/>
												</voxbox>
												<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
													<voxbox pos="0 -.1" size="1 1 1">
														<voxbox pos="0 0 .03" size="1 1 1"/>
													</voxbox>
												</group>
											</group>
										</group>
									</group>
								</group>
							</group>
						</group>
					</group>
				</group>
			]],
			["mag3-ak-545"]=[[
				<group prop0="color=.39 .39 .39" prop1="material=metal">
					<voxbox pos="-0.05 -0.1 0.0" rot="0.0 0.0 0.0" size="1 1 1">
						<voxbox pos="0 0 .03" size="1 1 1"/>
					</voxbox>
					<group pos="-0.05 -0.1 0.0" rot="-10">
						<voxbox pos="0 -.1" size="1 1 1">
							<voxbox pos="0.0 -0.0 0.03" rot="0.0 0.0 0.0" size="1 1 1"/>
						</voxbox>
						<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
							<voxbox pos="0 -.1" size="1 1 1">
								<voxbox pos="0 0 .03" size="1 1 1"/>
							</voxbox>
							<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
								<voxbox pos="0 -.1" size="1 1 1">
									<voxbox pos="0 0 .03" size="1 1 1"/>
								</voxbox>
								<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
									<voxbox pos="0 -.1" size="1 1 1">
										<voxbox pos="0 0 .03" size="1 1 1"/>
									</voxbox>
									<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
										<voxbox pos="0.0 -0.2 0.0" rot="0.0 0.0 0.0" size="1 2 1">
											<voxbox pos="0 0 .03" size="1 2 1"/>
										</voxbox>
										<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
											<voxbox pos="0 -.1" size="1 1 1">
												<voxbox pos="0 0 .03" size="1 1 1"/>
											</voxbox>
											<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
												<voxbox pos="0 -.1" size="1 1 1">
													<voxbox pos="0 0 .03" size="1 1 1"/>
												</voxbox>
												<group pos="0.1 0.0 0.0" rot="0.0 0.0 -45">
													<voxbox pos="0 -.1" size="1 1 1">
														<voxbox pos="0 0 .03" size="1 1 1"/>
													</voxbox>
												</group>
											</group>
										</group>
									</group>
								</group>
							</group>
						</group>
					</group>
				</group>
			]],
			["mag4-ak-545"]=[[
				<group prop0="color=.42 .25 .07" prop1="material=metal">
					<voxbox pos="-0.05 -0.1 0.0" rot="0.0 0.0 0.0" size="1 1 1">
						<voxbox pos="0 0 .03" size="1 1 1"/>
					</voxbox>
					<group pos="-0.075 -0.1 0.0" rot="-10.0 0.0 0.0">
						<voxbox pos="0 -.1" size="1 1 1">
							<voxbox pos="0 0 .03" size="1 1 1"/>
						</voxbox>
						<group pos="0 -.1" rot="-10.0">
							<voxbox pos="0 -.1" size="1 1 1">
								<voxbox pos="0 0 .03" size="1 1 1"/>
							</voxbox>
						</group>
					</group>
					<group pos="-0.025 -0.1 0.0" rot="-10.0 0.0 0.0">
						<voxbox pos="0 -.1" size="1 1 1">
							<voxbox pos="0 0 .03" size="1 1 1"/>
						</voxbox>
						<group pos="0 -.1" rot="-10.0">
							<voxbox pos="0 -.1" size="1 1 1">
								<voxbox pos="0 0 .03" size="1 1 1"/>
							</voxbox>
						</group>
					</group>
				</group>
			]],
		},

		["toprail"]={
		},
		["toprail2"]={
			["holo"]=[[
				<instance file="MOD/Loots/gun-ak74/toprail2/holo.xml"/>
			]],
		},
		["muzzle"]={
			["muzzle1"]=[[
				<voxbox name="Barrel" tags="barrel range=25 magsize=30 damage=7 firerate=0.1 gun=ak roundsize=2" pos="-0.05 -0.05 0.0" size="1 1 3" color=".1 .1 .1"/>
			]],
		},
		["stock"]={
			["removed"]="",
			["stock1"]=[[
				<group name="stock1" prop0="color=.2 .2 .2">
					<voxbox pos="-0.05 -0.05 -0.4" size="1 1 4">
						<voxbox pos="0.0 -0.05 0.0" size="1 1 1">
							<voxbox rot="68.0 0.0 0.0" size="1 1 1"/>
						</voxbox>
					</voxbox>
					<voxbox pos="0.055 -0.05 0.0" rot="0.0 -177.1 0.0" size="1 1 1"/>
					<voxbox pos="-0.055 -0.05 0.0" rot="0.0 87.1 0.0" size="1 1 1"/>
				</group>
			]],
			["stock2"]=[[
				<group name="stock2" prop0="color=.1 .1 .1">
					<voxbox pos="-0.055 -0.05 0.0" rot="0.0 87.1 0.0" size="1 1 1"/>
					<voxbox pos="-.05 -.05 -.4" size="1 1 2">
						<voxbox pos="0 -.05" size="1 1 2">
							<voxbox rot="68.0" size="1 4 1"/>
						</voxbox>
						<voxbox pos="0.0 0.0 0.15" rot="0.0 0.0 0.0" size="1 1 2"/>
					</voxbox>
					<voxbox pos="0.055 -0.05 0.0" rot="0.0 -177.1 0.0" size="1 1 1"/>
				</group>
			]],
		},
		["grip"]={
		},
		["barrel"]={
			["barrel1"]=[[
				<voxbox pos="-0.05 -0.05 -0.05" size="1 1 1">
					<voxbox pos="0.0 0.03 0.0" rot="0.0 0.0 0.0" size="1 1 1"/>
				</voxbox>
				<group pos="0.0 0.0 0.05">
					REPLACEmuzzle
						<voxbox name="Barrel" tags="barrel range=30 magsize=30 damage=8 firerate=.17 gun=ak roundsize=2" pos="-0.05 -0.05 0.0" rot="0.0 0.0 0.0" size="1 1 1"/>
					END
				</group>
			]],
			["barrel2"]=[[
				<voxbox pos="-0.05 -0.05 -0.05" size="1 1 5">
					<voxbox pos="0.0 0.03 0.0" rot="0.0 0.0 0.0" size="1 1 2"/>
				</voxbox>
				<group pos="0.0 0.0 0.45">
					REPLACEmuzzle
						<voxbox name="Barrel" tags="barrel range=30 magsize=30 damage=8 firerate=.17 gun=ak roundsize=2" pos="-0.05 -0.05 0.0" rot="0.0 0.0 0.0" size="1 1 1"/>
					END
				</group>
			]],
			
		},
		["side"]={
		},
		["modernguard"]={
		},
		["dustcover"]={
			["moderncover"]=[[
				<group prop2="color=.1 .1 .1">
					<voxbox pos="-0.05 -0.05 0.05" rot="0.0 0.0 0.0" size="1 1 3">
						<voxbox pos="0.0 0.1" rot="135.0" size="1 1 1"/>
						<group name="toprail2" pos="0.05 0.1 0.0">
							REPLACEtoprail2END
						</group>
					</voxbox>
				</group>
			]],
		},
		["camo"]={
		},
	},
}

function gunXMLBuilder(item)
	local itemInfos = Split(item, "_")
	local id = itemInfos[1]
	local displayName = itemInfos[2]
	local customXML = false
	local gunXMLString = "MOD/Loots/"..id..".xml"

	local attlist = attList(item)

	if attachmentXMLTable[id] then
		customXML = true
		gunXMLString = attachmentXMLTable[id]._basegun
		if attlist ~= nil then
			for slot,attachment in pairs(attlist) do
				if attachmentXMLTable[id][slot] then
					if attachmentXMLTable[id][slot][attachment] then
						local attachmentXMLString = attachmentXMLTable[id][slot][attachment]
						--[[ for tempSlot,tempAttachments in pairs(attachmentXMLTable[id]) do
							local attachmentXMLString = attachmentXMLTable[id][slot][attachment]
							gunXMLString = ReplaceContent(gunXMLString, attachmentXMLString, slot)
						end ]]
						gunXMLString = ReplaceContent(gunXMLString, attachmentXMLString, slot)
					end
				end
			end
		end

		if itemInfos[3] == "none" then
			gunXMLString = ReplaceContent(gunXMLString, "", "mag")
		else
			if attachmentXMLTable[id].mag then
				if attachmentXMLTable[id].mag[itemInfos[3]] then
					local attachmentXMLString = attachmentXMLTable[id].mag[itemInfos[3]]
			
					if id ~= "gun-rpg" or itemInfos[5] == "1" then
						gunXMLString = ReplaceContent(gunXMLString, attachmentXMLString, "mag")
					else
						gunXMLString = ReplaceContent(gunXMLString, "", "mag")
					end
				end
			end
		end
		gunXMLString = attachmentXMLTable[id]._header..gunXMLString..'</body>'
	end

	return customXML, gunXMLString
end

-- borrowed functions from Yulun
function ReplaceContent(sourceStr, newContents, replaceStr, endStr)
	local protectCount = 0
	replaceStr = "REPLACE"..replaceStr
	local endStr = endStr or "END"
	local newStr = sourceStr
	--print(sourceStr)
	print(newContents)
	print(replaceStr)
	print(endStr)
	--[[ local newStr = sourceStr:gsub("(%d*) ()", function(index, s)
		return newContents[1 + (tonumber(index)or 0)]
	end) ]]
	if type(newContents) == "table" then
		while protectCount < 1000 do
			local startPos, endPos = newStr:find(replaceStr)
			if startPos then
				local beginPos, finalPos = string.find(newStr, endStr, endPos+1)
				if beginPos then
					local contentIndex = tonumber(string.sub(newStr, endPos+1, endPos+2))+1
					local newContent = newContents[contentIndex] or ""
					newStr = string.sub(newStr, 1, startPos-1)..newContent..string.sub(newStr, finalPos+1, string.len(newStr))
				end
			end
			protectCount = protectCount + 1
		end
	else
		newStr = sourceStr:gsub(replaceStr..".-"..endStr, newContents)
		--[[ while protectCount < 1000 do
			local startPos, endPos = string.find(newStr, replaceStr)
			if startPos then
				local beginPos, finalPos = string.find(newStr, endStr, endPos+1)
				if beginPos then
					newStr = string.sub(newStr, 1, startPos-1)..newContents..string.sub(newStr, finalPos+1, string.len(newStr))
				end
			end
			protectCount = protectCount + 1
		end ]]
	end
	return newStr
end