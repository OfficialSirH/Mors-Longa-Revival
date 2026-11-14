#include "./lib/ModConfig.lua"
#include "./lib/DevShortcuts.lua"

function tick()
  TickModConfig()
  if GetVersion() == "1.6.0" then RequestFirstPerson(true) end
  tick_dev_shortcuts()
end

function draw()
  draw_dev_shortcuts()
end
