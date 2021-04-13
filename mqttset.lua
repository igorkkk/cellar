if dat.nowifi then return end
do
    local brk = dat.brk
    dat.brk = nil
    local port = dat.port
    dat.port = nil
    local subscribe, merror, newm, mconnect
    
    function subscribe(con)
        print("Connected to "..brk..' as '..dat.clnt)
        dat.broker = true
        con:subscribe(dat.clnt.."/com/#", 0)
        con:publish(dat.clnt..'/state', "ON", 0, 1)
        print("Subscribed")
    end
    
    function merror(con, reason)
        con = nil
        reason = nil
        m = nil
        tmr.create():alarm(15000, tmr.ALARM_SINGLE, function() mconnect(newm()) end)
        collectgarbage()
    end
    
    function newm()
        m = mqtt.Client(dat.clnt, 25, dat.clnt, 'pass22')
        m:lwt(dat.clnt..'/state', "OFF", 0, 1)
        m:on("offline", function(con)
            con:close()
            dat.broker = false
            print("offline")
            merror(con)
        end)
        m:on("message", function(con, top, dt)
            if not killtop then killtop = {} end
            top = string.match(top, "/(%w+)$")
            print('Got', top, dt)
            if dt then
                table.insert(killtop, {top, dt})
                if not dat.analiz then
                    dofile("mqttanalize.lua")
                end
            end
        end)
        return m
    end
    
    function mconnect(con)
        con:connect(brk, port, 0, subscribe, merror)
    end
    mconnect(newm()) 
end