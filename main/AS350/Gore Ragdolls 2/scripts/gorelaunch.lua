function init()
	yeeeeeeeeted = false
	force = 5
end

function tick()
	if not yeeeeeeeeted then
		body = FindBody("gore")
		local pos = Vec(0,0,0)
		imp = Vec(math.random(-force,force),math.random(force/3,force),math.random(-force,force))
		SetBodyVelocity(body, imp)
		imp = Vec(math.random(-force,force),math.random(force/3,force),math.random(-force,force))
		SetBodyAngularVelocity(body, imp)
		yeeeeeeeeted = true
	end
	if InputPressed("L") then
		body = FindBody("gore")
		Delete(body)
	end
end