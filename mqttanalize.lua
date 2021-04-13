if killtop and #killtop ~= 0 then
	local ide = function()
		if worktmr then worktmr:stop() end
		tiktmr:stop()
		if pintmr then pintmr:stop() end
		m:publish(dat.clnt..'/'..'ip', dat.ip, 0, 0)
		max7219.write7segment('1dE '..string.match(dat.ip, "\.(%d+)$"))
		dofile('ide.lua')
	end
	local com = table.remove(killtop)
	local top = com[1]
	local dt = com[2]
--[[
	if json['ffan'] == "On" then 
			dat.ffan = 'On'
			Switch('fan', 1)
		elseif json['ffan'] == "Off" or json['ffan'] == "Stop" then 
			dat.ffan = json['ffan']
			Switch('fan', 0)
		elseif json['fheat'] == 'On' then 
			dat.fheat = 'On'
			Switch('heat', 1)
		elseif json['fheat'] == 'Off' or json['fheat'] == 'Stop'  then 
			dat.fheat = json['fheat']
			Switch('heat', 0)
		else 
			print("Ask Me A Data!") 
			dat.countcheck = 1
			return
		end
--]]

	if top and com[2] then
		if top == "ide" and dt == 'ON' then 
			 return ide()
		end
		if top == 'clb' then 
			dofile('_mh-z19bclb.lua')(dt) 
		end
		if top == 'asktbl' then 
			dofile('senddata.lua')(dt)
		end
	end	
	dofile'mqttpub.lua'
	com, top, dt = nil, nil, nil
	dofile('mqttanalize.lua')
end