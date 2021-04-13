time.settimezone(timezone)
time.initntp()
wth = {}
uart.setup(2, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, {tx = 17, rx = 16})
uart.start(2)
--dat.boot = true

gpio.config( { gpio={pins.fan, pins.heat}, dir=gpio.OUT }, { gpio=22, dir=gpio.IN, pull=gpio.PULL_UP })
gpio.write(pins.fan, 0)
gpio.write(pins.heat,0)

--[[
dat.tIn = 9
dat.tOut = 10
dat.aHumOut = 1 
dat.aHumIn = 2
dat.HumOut = 53 
dat.HumIn = 75
--]]

dat.fan = "Off"
dat.ffan = "Off"
dat.heat = "Off"
dat.fheat = "Off"
dat.countcheck = 1
dat.units = 0
--dat.start = true

av = require("_kalman")
av.newkalm('aHumOut')
av.newkalm('aHumIn')

--max7219 = require('_max7219')
--max7219.setup()
hd44780.setCursor(0,0)
hd44780.printString(' Start Cellar!')
hd44780.setCursor(0,1)
print('dsunt at start:', dsunt)

dsunt = dsunt or 0
hd44780.printString(' Got Unit: '..dsunt)
dsunt = nil
--dofile'mqttset.lua'
dofile'main.lua'