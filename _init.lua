dat = {}
pins = {}
--dofile'wifi32Start.lua' 
--dofile'_searchDS.lua' 
dofile'__testDS.lua' 
dofile'_hd44780.lua'
timezone = 'EST-3'
dofile'_setuser.lua'

local runfile = "setglobals.lua"
print("Try Run ", runfile)
tmr.create():alarm(5000, 0, function()
  if runfile and file.exists(runfile) then
    dofile(runfile)
  else
    print('Stop, No RunFile!')
  end
end)