local rootFolder = "MOD/prefabs/spawnables/enemies/"
local backupFolder = "MOD/prefabs/spawnables/enemies_backup/"


local folders = {
  civilian = {
    "civilian/Ragdollciv1.xml",
    "civilian/Ragdollciv2.xml",
    "civilian/Ragdollciv3.xml",
    "civilian/Ragdollciv4.xml",
    "civilian/Ragdollciv5.xml",
    "civilian/Ragdollciv6.xml",
    "civilian/Ragdollciv7.xml",
    "civilian/Ragdollciv8.xml",
    "civilian/Ragdollciv9.xml",
    "civilian/Ragdollciv10.xml",
    "civilian/Ragdollciv11.xml",
    "civilian/Ragdollciv12.xml",
    "civilian/Ragdollciv13.xml",
    "civilian/Ragdollciv14.xml",
    "civilian/Ragdollciv15.xml",
    "civilian/Ragdollciv16.xml",
    "civilian/RagdollcivDriver.xml",
    "civilian/RagdollcivDriver2.xml",
    "civilian/RagdollcivDriver3.xml",
    "civilian/RagdollcivDriver4.xml",
    "civilian/RagdollcivDriverDead.xml",
    "civilian/Ragdollcivspec1.xml",
  },
  cult = {
    "cult/Ragdollcult1.xml",
    "cult/Ragdollcult2.xml",
    "cult/Ragdollcult3.xml",
    "cult/Ragdollcult4.xml",
  },
  millitary = {
    "millitary/Ragdollmil1.xml",
    "millitary/Ragdollmil2.xml",
    "millitary/Ragdollmil3.xml",
    "millitary/Ragdollmil4.xml",
    "millitary/Ragdollmil5.xml",
    "millitary/Ragdollmil6.xml",
    "millitary/Ragdollmilnight1.xml",
    "millitary/Ragdollmilofficer1.xml",
    "millitary/Ragdollmilofficer2.xml",
    "millitary/Ragdollmilofficer3.xml",
    "millitary/Ragdollmilofficer4.xml",
    "millitary/Ragdollmilofficer5.xml",
    "millitary/Ragdollmilofficer6.xml",
    "millitary/Ragdollmilofficer7.xml",
    "millitary/Ragdollmilofficer8.xml",
    "millitary/Ragdollmilofficer9.xml",
    "millitary/Ragdollmilsand1.xml",
    "millitary/Ragdollmilsand2.xml",
    "millitary/Ragdollmilsand3.xml",
    "millitary/Ragdollmilsand4.xml",
    "millitary/Ragdollmilsand5.xml",
    "millitary/RagdollmilSpecOps.xml",
  },
  security = {
    "security/Ragdollsecurity1.xml",
    "security/Ragdollsecurity10.xml",
    "security/Ragdollsecurity11.xml",
    "security/Ragdollsecurity12.xml",
    "security/Ragdollsecurity13.xml",
    "security/Ragdollsecurity14.xml",
    "security/Ragdollsecurity2.xml",
    "security/Ragdollsecurity3.xml",
    "security/Ragdollsecurity4.xml",
    "security/Ragdollsecurity5.xml",
    "security/Ragdollsecurity6.xml",
    "security/Ragdollsecurity7.xml",
    "security/Ragdollsecurity8.xml",
    "security/Ragdollsecurity9.xml",
  },
  survior = {
    "survior/Ragdollsurvior1.xml",
  },
  um = {
    "um/Ragdollpur1.xml",
    "um/Ragdollpur2.xml",
    "um/Ragdollum1.xml",
    "um/Ragdollum2.xml",
    "um/Ragdollum3.xml",
    "um/Ragdollumofficer1.xml",
    "um/Ragdollumofficer2.xml",
    "um/Ragdollumofficer3.xml",
    "um/Ragdollumofficer4.xml",
  },
  vip = {
    "vip/RagdollVIP.xml",
    "vip/RagdollVIP2.xml",
    "vip/RagdollVIP3.xml",
  },
}




function print_npcs_xml(prefabs, group, col_x)

  print('\t\t<group name="' .. group .. '" layer="-npcs_' .. group .. '">')

  local cols = #prefabs
  local colWidth = 3
  local colHeight = 0

  local i = 1
  local j = 1
  local count = 1
  while count <= #prefabs do

      -- print('<instance pos="' .. i*colWidth .. ' 0 ' .. j*colHeight .. '" rot="0.0 0.0 0.0" file="' .. prefabs[count] .. '"/>')
      print('\t\t\t<instance pos="' .. col_x .. ' 0 ' .. i*colWidth .. '" rot="0 0 0" file="' .. prefabs[count] .. '"/>')

      if i > cols then
          i = 1
          j = j + 1
      else
        i = i + 1
      end

      count = count + 1

  end

  print('\t\t</group>')

end



function deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in next, orig, nil do
          copy[deepcopy(orig_key)] = deepcopy(orig_value)
      end
      setmetatable(copy, deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
      copy = orig
  end
  return copy
end


function GetTableKeys(tb)
  local keys = {}
  for key, value in pairs(tb) do
    table.insert(keys, key)
  end
  return keys
end


function printFolders(preppendPath, col_x)

  print('<group layer="-npcs">')

  -- add folder string before xml path
  local folders_modified = deepcopy(folders)
  for key, folder in pairs(folders_modified) do
    for index, item in ipairs(folder) do
      folder[index] = preppendPath .. item
    end
  end

  -- print npcs
  local col_x = col_x or 0
  local keys = GetTableKeys(folders)
  table.sort(keys)


  for index, key in ipairs(keys) do
    print_npcs_xml(folders_modified[key], key, col_x)
    col_x = col_x - 13
  end

  print('</group>')

end


printFolders(rootFolder, 0)
printFolders(backupFolder, 3)
