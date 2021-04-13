function Switch(unit, sw)
	print('\n\n\n\t\t\t\tSwitched', unit, sw, '!!!!!!!!!!!!!!!!!!!!!!!!!\n\n\n')
	gpio.write(pins[unit], sw)
	local state = sw == 0 and 'Off' or 'On'
	dat[unit] = state
end

function work()
	print('\n\nWork! node.heap() = '..node.heap())
	------------------ Forced ------------------
	if dat.ffan == 'On' or dat.fheat == 'On' then
		dat.dserror = nil
		dat.error = nil
		if dat.ffan  == 'On' and dat.fan  == "Off" then	Switch('fan', 1) end
		if dat.fheat == 'On' and dat.heat == "Off" then Switch('heat', 1) end

	elseif dat.ffan == 'Stop' or dat.fheat == 'Stop' then
		dat.dserror = nil		
		dat.error = nil
		if dat.ffan  == 'Stop' and dat.fan  == "On" then Switch('fan', 0) end
		if dat.fheat == 'Stop' and dat.heat == "On" then Switch('heat', 0) end
	end


	if not dat.dserror then
		print('\nNo dat.dserror!\n')
		dat.error = nil	
			-------------- Fan -------------
		if  dat.ffan ~= 'Off' then
		elseif	dat.tIn < dat.tg or dat.tIn < dat.tOut   or   dat.tOut > dat.maxOutTemp    or   dat.aHumOut >= dat.aHumIn then
			if dat.fan == "On" then	Switch('fan', 0) end
		elseif dat.tIn > (dat.tg + 1)  and   dat.tIn > dat.tOut and dat.fan == "Off" then  
			if (dat.aHumOut - 1) <= dat.aHumIn and dat.fan == "Off" then Switch('fan', 1) end
		else
			print('Loh!')
		end
		
		------------- heating ----------------
		if dat.fheat ~= 'Off' then
		elseif dat.tIn < (dat.tg - 0.75) then
			if dat.heat == "Off" then Switch('heat', 1) end
		elseif dat.tIn > dat.tg then
			if dat.heat == "On" then  Switch('heat', 0) end
		end
		--------------------------------------
	else
		print('Got dat.dserror!')
		dat.dserror = nil
		if not dat.error then 
			dat.error = 1
		else
			dat.error = dat.error + 1
		end
		if dat.error > 100 then 
			if dat.fan == "On" then	Switch('fan', 0) end
			if dat.heat == "On" then  Switch('heat', 0) end
		end
	end

		---------- printLCD() ------------------
	if not dat.error then
		print('OUT:', 't '..dat.tOut,'\t', 'Hum '.. dat.HumOut,'\t','AbsH '..dat.aHumOut)
		print('IN: ', 't '..dat.tIn, '\t', 'Hum '.. dat.HumIn,'\t','AbsH '..dat.aHumIn)
		local first  = string.char(0xd9)..string.format('t:%5.1f h:%2d/%2d', (dat.tOut or 99), (dat.HumOut or 99), (dat.aHumOut or 99))
		local second = string.char(0xda)..string.format('t:%5.1f h:%2d/%2d', (dat.tIn or 99), (dat.HumIn or 99), (dat.aHumIn or 99))
		hd44780.setCursor(0,0)
		hd44780.printString(first)
		hd44780.setCursor(0,1)
		hd44780.printString(second)
		first, second = nil, nil
	--else
		-- hd44780.setCursor(0,0)
		-- hd44780.printString(string.format(' Error No %4d  ', dat.error))
		-- hd44780.setCursor(0,1)
		-- hd44780.printString('                ')
	end
	return send()
end


afterds = function()
	--package.loaded['_ds2438_HIH'] = nil
	---[[
	print('\nAfter DS!')
	if debbug then
		local inn = 'un007E'
		local oot = 'un0019' 
		dat.dserror = nil
		units[inn] = {}
		units[oot] = {}
		units[inn][1] = 9   -- 10 - math.floor(math.random()*10)
		units[inn][2] = 95--  math.floor(math.random()*100)
		units[inn] [3] = 20 -- math.floor(math.random()*10)
		units[inn] [4] = 3.3
		units[oot][1] = 10 - math.floor(math.random()*20)
		units[oot][2] = math.floor(math.random()*100)
		units[oot][3] = math.floor(math.random()*10)
		units[oot][4] = 3.3
	end

	if not dat.dserror then --!!!
		for k,v in pairs(units) do
			if k == dat.insensor then
				print('\nIn  Sensor: '..k)
				
				if type(units[k][1]) == 'number' and units[k][1] > - 10 and units[k][1] < 30  then	
					dat.tIn = units[k][1] 
					print('dat.tIn',dat.tIn, '108')
				end
				
				if type(units[k][2]) == 'number' and units[k][2] > 10 and units[k][2] < 115 then 
					dat.HumIn = units[k][2]
					print('dat.HumIn', dat.HumIn, '113') 
				end
				
				if type(units[k][3]) == 'number' and units[k][3] > 1 and units[k][3] < 30 then	
					dat.aHumIn = units[k][3]
					print('dat.aHumIn', dat.aHumIn, '118') 
				end
				
				dat.vBatIn = units[k][4] or 'lost'
			else
				print('\n\nOut Sensor:'..k)
				
				if type(units[k][1]) == 'number' and units[k][1] > - 40 and units[k][1] < 50 then 
					dat.tOut = units[k][1]
					print('dat.tOut', dat.tOut, 127)
				end
				
				if type(units[k][2]) == 'number' and units[k][2] > 10 and units[k][2] < 115 then 
					dat.HumOut = units[k][2] 
					print('dat.HumOut', dat.HumOut, '131')
				end
				
				if type(units[k][3]) == 'number' and units[k][3] > 1 and units[k][3] < 30 then 
					dat.aHumOut = units[k][3] 
					print('dat.aHumOut', dat.aHumOut, 137, '\n\n')
				
				end
				
				dat.vBatOut = units[k][4] or 'lost'
			end
		end
	  	
		if not debbug then
	  		dat.aHumIn = av.update('aHumIn', dat.aHumIn)
	  		dat.aHumOut = av.update('aHumOut',dat.aHumOut)
	  	end
		--]]
	 print('\n\nin  TIn:  '..dat.tIn..' AHIn:  '..dat.aHumIn, '\nout TOut: '..dat.tOut..' AHOut: ' ..dat.aHumOut)
	end
	--if #units ~= 2 then dat.dserror = true; print('Lost Unit')  end
	ds, units  = nil, nil
	work()
end 

send = function()
	local list = {"heat","fan","tOut","HumOut","aHumOut","tIn","HumIn","aHumIn","unt","ffan","fheat","vBatIn","vBatOut", "units"}
	local send = {} 
	local raw, ok, json
	if dat.error then list[#list+1] = 'error' end 

	for _,v in pairs(list) do 
		local ndat = dat[v]
	
		if ndat then 
			if type(ndat) == 'number' and v ~= 'error' and v ~= 'units' then ndat = string.format('%.1f', ndat) end 
			send[v] = ndat 
		end

	end 
	ok, json = pcall(sjson.encode, send)
	if ok then
		wth.jsonerror = nil
		if dat.broker and m then 
			print('\nSend to Broker:\n'..json)
			wth.data = json
			--[[
			if rawdat and rawdat ~= '' then 
				wth.raw = '{"rawdat":"'..rawdat..'"}' 
				print(wth.raw)
				rawdat = ''
			end
			--]]
			dofile'mqttpub.lua'
		
		else
			crc = require "_crc8"
			json = crc.encode(json)..';'
			print('\nSend to HC-12:\n'..json)
			uart.write(2, json)
		end
	else
		if dat.broker and m then 
			wth.jsonerror = 'Json Error!'
			dofile'mqttpub.lua'
		end
		print("failed to encode!")
	end
	package.loaded['_crc8'] = nil
	crc, ok, json, list, send, raw = nil, nil, nil, nil, nil, nil
end

asksens = function()
	units = {}
	ds = require('_ds2438_HIH')
	ds.askds(units, afterds, pins.ds, 2)
	--ds.askds(units, afterds)
end
tmr.create():alarm(30000, 1, asksens)
asksens()