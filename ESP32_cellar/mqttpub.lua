if not dat.broker or not m then return end
local count = 0
local pubnow
for _ in pairs(debug.getregistry()) do  count = count + 1 end
wth.reg = count
wth.heap = node.heap()

pubnow = function(top, dt)
	top, dt = next(wth, top)
	if top and dat.broker then
		m:publish(dat.clnt..'/'..top, dt, 2, 0, function() if pubnow then pubnow(top) end end)
	else
		print('Heap: '..wth.heap..'\nReg: '..wth.reg)
		top, dt, pubnow, count = nil, nil, nil, nil 
		--dat.publish = false
		if dat.boot then dofile('sendboot.lua') end
	end
end
pubnow()