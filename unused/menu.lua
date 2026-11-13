local debug = false

function init()
	print('menu loaded')
end

function draw()
  UiMakeInteractive()
  UiModalBegin()

	UiPush()
  UiTranslate(UiCenter(), UiMiddle())
	UiAlign("center middle")

  UiFont("bold.ttf", 52)

  UiButtonPressColor(1,1,0,0.5)
  UiButtonHoverColor(1,1,0)
   UiAlign("center middle")
  UiTranslate(-200, 0)
   UiColor(0,0,0)
  UiRect(240, 70)
  UiColor(1,0,0)
  UiImageBox("ui/common/box-outline-6.png", 240, 70, 12, 12)
  UiColor(1,0,0)
  if UiTextButton("CONVOY") then
    if debug ~= true then
      StartLevel("day","MOD/map.xml","")
    end
	end
  UiAlign("center middle")
  UiTranslate(400, 0)
   UiColor(0,0,0)
  UiRect(240, 70)
  UiColor(1,0,0)
  UiImageBox("ui/common/box-outline-6.png", 240, 70, 12, 12)
  UiColor(1,0,0)
  if UiTextButton("FPS") then
    if debug ~= true then
      StartLevel("day","MOD/fps.xml","")
    end
	end
	UiPop()

end

