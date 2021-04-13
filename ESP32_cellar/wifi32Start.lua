if not dat then dat = {} end
if dat.nowifi then return end
wifi.start()
wifi.sta.on("disconnected", function(ev, info)
  print("Lost WiFi!")
  dat.wifi = nil
  dat.ip = nil
end)
wifi.sta.on("got_ip", function(ev, info)
  dat.wifi = true
  dat.ip = info.ip
  print("NodeMCU Got IP:", info.ip)
end)