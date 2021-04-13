-- https://github.com/devgiants/esp8266_hd44780_i2c
do
    local constants = {
	    MODULE_NAME = 'HD44780 I2C',
	    LCD_CLEARDISPLAY = 0x01,
	    LCD_RETURNHOME = 0x02,
	    LCD_ENTRYMODESET = 0x04,
	    LCD_DISPLAYCONTROL = 0x08,
	    LCD_FUNCTIONSET = 0x20,
	    LCD_SETDDRAMADDR = 0x80,
	    LCD_ENTRYLEFT = 0x02,
	    LCD_ENTRYSHIFTDECREMENT = 0x00,
	    LCD_DISPLAYON = 0x04,
	    LCD_CURSOROFF = 0x00,
	    LCD_BLINKOFF = 0x00,
	    LCD_4BITMODE = 0x00,
	    LCD_2LINE = 0x08,
	    LCD_1LINE = 0x00,
	    LCD_5x8DOTS = 0x00,
	    LCD_BACKLIGHT = 0x08,
	    LCD_NOBACKLIGHT = 0x00,
	    EN = 0x04,  -- Enable bit
	    RW = 0x02,  -- Read/Write bit
	    RS = 0x01,  -- Register select bit
	}
    local sda, scl, id, address, backlight, displayFunction, displayControl, displayMode,numLines
    local function expanderWrite(data, backlight)
        if(backlight == nil) then
            backlight = constants.LCD_BACKLIGHT
        end
        i2c.start(id)
        i2c.address(id, address ,i2c.TRANSMITTER)              
        i2c.write(id, bit.bor(data, backlight))
        i2c.stop(id)
    end
    local function pulseEnable(data)
        expanderWrite(bit.bor(data, constants.EN))
        --tmr.delay(1)
        expanderWrite(bit.band(data, bit.bnot(constants.EN)))
        --tmr.delay(50)
    end                
    local function write4bits(value)
        expanderWrite(value)
        pulseEnable(value)
    end   
    local function send(value, mode)            
        local highNib = bit.band(value, 0xF0)
        local lowNib = bit.band(bit.lshift(value, 4), 0xF0)

        write4bits(bit.bor(highNib, mode))
        write4bits(bit.bor(lowNib, mode))
    end
    local function command(value)
        send(value, 0)
    end
    local function write(value)
        send(value, constants.RS)
        return 1
    end      
    local function display()
        displayControl =  bit.bor(displayControl, constants.LCD_DISPLAYON)
        command(bit.bor(constants.LCD_DISPLAYCONTROL, displayControl))
    end
    ---[[
    local function clear()
        command(constants.LCD_CLEARDISPLAY)
        --tmr.delay(2000)
    end
    local function home()
        command(constants.LCD_RETURNHOME)
        --tmr.delay(2000)
    end
    --]]
    local function setCursor(col, row)
        row = row + 1
        rowOffsets = { 0x00, 0x40, 0x14, 0x54 }
        command(bit.bor(constants.LCD_SETDDRAMADDR, (col + rowOffsets[row])))
    end

    local function printString(str)
        for i = 1, #str do
         local char = string.byte(string.sub(str, i, i))
         write(char)             
        end
    end

    local function noBacklight()
        expanderWrite(0, constants.LCD_NOBACKLIGHT)
    end
    local function setBacklight(value)
        if value ~= 0 then value = constants.LCD_BACKLIGHT else value = constants.LCD_NOBACKLIGHT end     
        expanderWrite(0, value)
    end
    local tbcom = {}
    tbcom[1] = function()
        local speed = i2c.setup(id, sda, scl, i2c.SLOW)
    end

    tbcom[2] =  function()
        write4bits(bit.lshift(0x03, 4))
    end

    tbcom[3] =  function() 
        write4bits(bit.lshift(0x02, 4))
        command(bit.bor(constants.LCD_FUNCTIONSET, displayFunction))           
        displayControl = bit.bor(constants.LCD_DISPLAYON, constants.LCD_CURSOROFF, constants.LCD_BLINKOFF)
        display()
        clear()
        displayMode = bit.bor(constants.LCD_ENTRYLEFT, constants.LCD_ENTRYSHIFTDECREMENT)
        command(bit.bor(constants.LCD_ENTRYMODESET, displayMode))
        --home()
    end

    local counter = 0
    local pointer = 1
    local pause = 50
    local comtmr 
    comtmr = tmr.create()
    comtmr:register(pause, 1, function(t)
          counter = counter + 1
          if counter > 1 and counter < 5 then
                pointer = 2
                pause = 5
          elseif counter == 5 then
                pointer = 3
          elseif counter == 6 then
                t:stop()
                t:unregister()
                t,comtmr = nil, nil 
                print('i2c started!')
                return
          end
          tbcom[pointer]()
    end)

local function init(gsda, gscl, gaddress, cols, rows, givenId)
      sda, scl, address = gsda, gscl, gaddress
      if rows > 4 then rows = 4 end
      id = givenId or 0
      displayFunction = bit.bor(constants.LCD_4BITMODE, constants.LCD_1LINE, constants.LCD_5x8DOTS)                      
      if rows > 1 then displayFunction = bit.bor(displayFunction, constants.LCD_2LINE) end
      numLines = rows
      comtmr:start()
end
    hd44780 = {
        BACKLIGHT_ON = constants.LCD_BACKLIGHT,
        BACKLIGHT_OFF = constants.LCD_NOBACKLIGHT,
        init = init,
        setBacklight = setBacklight,
        setCursor = setCursor,
        clear = clear,
        printString = printString            
    }
end