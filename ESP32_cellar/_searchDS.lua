local addrTb = {}
local pin = 4
local adr, as 
ow.setup(pin)
ow.reset_search(pin)
repeat
    adr = ow.search(pin)
    if(adr ~= nil) then
        table.insert(addrTb, adr)
    end
until (adr == nil)
ow.reset_search(pin)
print('\n\nDS2438 Units No:', #addrTb)
for i=1, #addrTb do
	as = "un"
	for ii = (#addrTb[i] - 1), #addrTb[i] do 
		as = as..string.format("%02X", (string.byte(addrTb[i], ii))) 
	end
    print('\t\t'..as)    
end
print'--------------------------\n'