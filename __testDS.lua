local dat = {}
dat.dserror = nil
local M = {}
M.pin = 4
M.addrTb = {}
M.result = {} 
M.dat = ""
M.error = 0
M.dsNo = 1
M.att = 1

local vbat = 0
local step = 1
local countDS = 1
local v, t, hum, ahum, as, adr, mb, raw

local disptmr
disptmr = tmr.create()

M.exit = function(t)
    t:stop()
    t:unregister()
    t, disptmr = nil, nil
    if M.error ~= 0 then
        if not dat then dat ={} end
        dat.dserror = 1
    else
        if dat.start then dat.start = nil end
    end
    package.loaded[mod] = nil
    if M.call then M.call() end
end

M.writeDS = function(tb, addrNo)
	ow.reset(M.pin)
	ow.select(M.pin,  M.addrTb[addrNo])
	for _, v in pairs(tb) do
		ow.write(M.pin, v, 1)
	end
	if tb[1] == 0xBE then M.dat = ow.read_bytes(M.pin, 9) end
	ow.reset(M.pin)
end

M.ncom = {
    {0x44}, -- starttemp
    {0xb4}, --startVolt
    {0xb8, 0x00}, -- recallMem
    {0xBE, 0x00}, -- readPage
	{0x4e, 0x00, 0x00}, -- setVAD,
    {0x4e, 0x00, 0x08}, -- setVVD
    {0x48, 0x00} -- copySP
}
M.psteps = {6,1,2,3,4,'calc1',5,2,3,4,'calc2'}

M.search = function(t)
    ow.setup(M.pin)
    ow.reset_search(M.pin)
    repeat
        adr = ow.search(M.pin)
        if(adr ~= nil) then
            table.insert(M.addrTb, adr)
        end
    until (adr == nil)
    ow.reset_search(M.pin)
    dsunt = #M.addrTb 
    print('Units No:', #M.addrTb)
    dat.units = #M.addrTb
    M.addr = M.addrTb[1]
     
    if #M.addrTb >= M.dsNo  then 
        M.att = 1
        M.dsNo = #M.addrTb
        disptmr:start()      
    else
        if M.att < 8 then 
            M.att = M.att + 1
            M.search(t)
        else
            print('Error! Lost '..(M.dsNo - #M.addrTb).. ' DS2438!')
            M.error = M.error + 1
            M.exit(t)
        end
    end
end

M.checkCRC = function()
    if M.dat:byte(9) == ow.crc8(string.sub(M.dat,1,8)) then
    --if (math.random() < 0.5) then   
        M.att = 1
        return true
    else
        M.att = M.att + 1
        return false
    end
end

M.calc = function(arg, t)
	local noerr = M.checkCRC()
    if noerr then  
    	v = ((M.dat:byte(5) * 256) + M.dat:byte(4)) / 100
		
        if dat.debug then
            print('\n\t\t\t'..arg..' v: '..v)
        end

        if arg == 'calc1' then
			vbat = v
			return
		else
			mb = M.dat:byte(3)
    		raw = (mb > 127) and (-256 + mb) or mb
		


            t = (raw + (bit.rshift(M.dat:byte(2), 3)) * 0.03125)
			t = (math.floor(t*10))/10
            hum = (((v/vbat) - 0.1515)/0.00636)/(1.0546 - 0.00216 * t)
			hum = (math.floor(hum*10))/10
            
            as = "un"
            for ii = (#M.addrTb[countDS] - 1), #M.addrTb[countDS] do as = as..string.format("%02X", (string.byte(M.addrTb[countDS], ii))) end
            M.result[as] = {}
            M.result[as][1] = t
			M.result[as][2] = hum
            ahum = ((6.112*(math.pow(2.718281828,(17.67*t)/(t+243.5)))*hum*2.1674)/(273.15+t)) 
            ahum = (math.floor(ahum*10))/10
            M.result[as][3] = ahum
            M.result[as][4] = vbat
            --if dat.debug then
                print('\n\taddr \t= '..as)
                print('\tt \t\t= '..t) 
                print('\tvbat \t= '..vbat) 
                print('\thum \t= '..hum)
                print('\tahum \t= '..ahum..'\n')
		    --end
            t = t or 'er'; vbat = vbat or 'er'; hum  = hum or 'er'; ahum = ahum or 'er'
            if dat.debug then
                rawdat = rawdat..'t$'..t..' &vbat$'..vbat..' &vnow$'..v..' &hum$'..hum..' &ahum$'..ahum..' &'
            end
        end
	
    elseif M.att < 8 then
        disptmr:stop()
        
        if arg == 'calc1' then
            step = 1
        else
            step = 6
        end
        if dat.debug then
            print('Try ask DS:'..M.att)
        end
        tmr.create():alarm(1000, 0, function(t)
            t:unregister()
            t = nil
            disptmr:start()
        end)
    else
        M.error = M.error + 1
		print('Error! Alarm CRC!')
        M.exit(t)
	end
end

disptmr:register(80, tmr.ALARM_AUTO, function(t)
    if type(M.psteps[step]) == 'number' then
    	M.writeDS(M.ncom[M.psteps[step]], countDS, read)
    else
    	M.calc(M.psteps[step], t)
    end
    step = step + 1
    if step == 12 then
        if countDS  ~= #M.addrTb then
            countDS = countDS + 1
            M.addr = M.addrTb[countDS]
            step = 1
            -- print('\t\t\tstep '..countDS..' at long'.. #M.addrTb)
        else 
            t:stop()
            t:unregister()
            t = nil
            disptmr = nil
            --table.foreach(M.result,print)
            if M.call then M.call() end
        end
    end
end)

M.askds = function(tbl, call, pin, dsNo)
    rawdat = ''
    if dsNo then M.dsNo = dsNo end
    if pin then M.pin = pin end
	if tbl then M.result = tbl end
	if call then M.call = call end
    M.att = 1
	M.search(disptmr)
end


M.askds()