-- works
-- add function move
-- parce unit

crc8 = require 'crc8'

Broker="ВАШ_САЙТ"
port=ВАШ_ПОРТ
myClient="master433"
pass="pass"
publish = false

asked = {
    '"cel"',
    --'"bel"',
    --'"gal"'  
}

m = mqtt.Client(myClient, 180, myClient, pass)
m:lwt("/lwt", myClient, 0, 0)

function connecting()
     print('(Re)Connecting')
    function getConnect()
       if wifi.sta.status() == 5 and wifi.sta.getip() ~= nil then
            print("Got WiFi!")
            m:connect(Broker, port, 0, 0,
                function(conn)
                    tmr.stop(6)
                     print("Connected")
                    publish = true
                    m:subscribe(myClient.."/#",0, function(conn)
                         print("Subscribed")
                    end)
            end)
        end
    end
    getConnect()
    tmr.alarm(6, 90000, 1, function()
        getConnect()
    end)
end

m:on("offline", function(con)
    publish = false
    connecting()
end)

function publ(dt) -- здесь разбираем данные от HC-12
    print('Now: '..dt)
    dt = string.gsub(dt, "%c","") -- удаляем все незнаки
     
    local data = crc8.decode(dt) -- проверяем crc8
    print("Got "..data)
    
    if data == 'NoCRC' then
        return
    end
    local topic = "/" -- формируем топик
    if string.find(data, "{") and string.find(data, "}") then
        print('Got JSON')
        local tp = cjson.decode(data)
        local top = tp.unt
        if top then
            topic = topic..top -- из названия оконечного устройства.
        else
            print("No topic")
            return
        end
        if publish == true then
          print("Publish!: ".. data)
          m:publish(myClient..topic,data,0,0)
        
        end
    end
    collectgarbage() 
 end

uart.on("data",';',
    function(data)
        if string.find(data, ";") then 
            print('ask: '..data)
            data = string.gsub(data, ";","")
            data = string.gsub(data, "\n","")
            if string.find(data, "999") then
                node.restart()
            end  
            publ(data)
        end
end, 0)

 m:on("message", function(conn, topic, data)
    if (string.find(topic, "state")) == nil then 
        local top = string.gsub(topic, myClient.."/","")
        if top == "command" then
            local dt = crc8.encode(data)
            print(dt..";")
        end 
        if top == "insert" then move(data, 1) end
        if top == "remove" then move(data, 0) end
    end
    collectgarbage() 
end)

function move(ask, muv) -- функция вставляет и удаляет названия устройств в таблицу запроса
    local place = 0
    muv = muv or 0
    print(cjson.encode(asked))
    for n, d in pairs(asked) do
        if d == ask then place = n end
    end
    if place ~= 0 and muv == 0 and #asked > 1 then
       table.remove(asked, place) 
    end
    if place == 0 and muv == 1 then
       table.insert(asked, ask) 
    end
    print(cjson.encode(asked))
    m:publish(myClient.."/report",json,0,0) 
end

function AskUnits()  -- крутится для выдачи равномерных запросов конечным устройствам
    local count = 0
    local function AskNow()
        tmr.alarm(5, 30000, 1, function() -- через 30 сек следующий запросов
           if publish then  -- опрашиваем, если со Интернет все нормально
            count = count + 1
            if count > #asked then count = 1 end
            local ask = "{"..asked[count]..":0}"
            local send = crc8.encode(ask)
            print(send..';')
           end
            AskNow()
        end)
    end
    AskNow()
end
AskUnits()
connecting()
