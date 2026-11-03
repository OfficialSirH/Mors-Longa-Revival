function sfnPadZeroes(n, pad)
    local format = "%0" .. tostring(pad or 2) .. "d"
    return string.format(format, n)
end

function LoadFrames(path, frames_count)

    local frames = {}

    for i = 0, frames_count do
        local n = sfnPadZeroes(i, 3)
        local str = path .. "frame_" .. n .. ".png"
        table.insert(frames, str)
    end

    return frames

end


function PlayFrames(frames, player, w, h)

    UiImageBox(frames[player.index], w,h)

    if player.loop then
        PlayLoop(LoadLoop(player.loop), GetCameraTransform().pos, 100)
    end

    if player.last + player.speed < GetTime() then
        player.index = GetTableNextIndex(frames, player.index)
        player.last = GetTime()
    end

end


function CreatePlayer(speed, loop, index)
    return {
        last = 0,
        loop = loop,
        speed = speed or GetTimeStep(),
        index = index or 1
    }
end







function hsl_to_rgb(hue, saturation, lightness)
	-- https://en.wikipedia.org/wiki/HSL_and_HSV#To_RGB
	hue = hue % 360
	local chroma = (1-math.abs(2*lightness-1))*saturation
	hue = hue/60
	local x = chroma*(1-math.abs((hue % 2)-1))
	local red, green, blue
	if hue < 1 then
		red, green, blue = chroma, x, 0
	elseif hue < 2 then
		red, green, blue = x, chroma, 0
	elseif hue < 3 then
		red, green, blue = 0, chroma, x
	elseif hue < 4 then
		red, green, blue = 0, x, chroma
	elseif hue < 5 then
		red, green, blue = x, 0, chroma
	else
		red, green, blue = chroma, 0, x
	end
	local m = lightness-chroma/2
	return red+m, green+m, blue+m
end
