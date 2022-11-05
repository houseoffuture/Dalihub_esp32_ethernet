function protocolconf ()
  file.open("protocol.cfg", "r")
  pstr = file.readline()
  pstr = pstr:gsub("\n", "")
  pstr = pstr:gsub("\r", "")
  prot={}
  psep = ","
  for par in string.gmatch(pstr, "([^"..psep.."]+)") do
   table.insert(prot, par)
  end
  protocol = prot[1]
  if prot[5] == nil then prot[5] = '' end
  if prot[6] == nil then prot[6] = '' end
  file.close()
end

protocolconf ()

DALI = {
  x_on = {'addtype','address','1:','on',false}, --Legacy light on
  x_off = {'addtype','address','1:','off',false}, --Legacy light off
  x_up = {'addtype','address','1:','up',false}, --Legacy light up
  x_down = {'addtype','address','1:','down',false}, --Legacy light down
  setvalue = {'addtype','address','0','value',false},   --YAAA AAA0 XXXX XXXX
  getvalue = {'addtype','address','1','10100000',false}, --YAAA AAA1 1010 0000
  off = {'addtype','address','1','00000000',false}, --YAAA AAA1 0000 0000
  up = {'addtype','address','1','00000001',false},  --YAAA AAA1 0000 0001
  down = {'addtype','address','1','00000010',false},--YAAA AAA1 0000 0010
  stepup = {'addtype','address','1','00000011',false},--YAAA AAA1 0000 0011
  stepdown = {'addtype','address','1','00000100',false},--YAAA AAA1 0000 0100
  on = {'addtype','address','1','00000101',false},--YAAA AAA1 0000 0101
  min = {'addtype','address','1','00000110',false},--YAAA AAA1 0000 0110
  stepdownandoff = {'addtype','address','1','00000111',false},--YAAA AAA1 0000 0111
  setactuallevel = {'addtype','address','1','00100001',true},
  onandstepup = {'addtype','address','1','00001000',false},--YAAA AAA1 0000 1000
  setmaxlevel = {'addtype','address','1','00101010',true},--YAAA AAA1 0010 1010
  setminlevel = {'addtype','address','1','00101011',true},--YAAA AAA1 0010 1011
  setfadetime = {'addtype','address','1','00101110',true}, --YAAA AAA1 0010 1110
  setfaderate = {'addtype','address','1','00101111',true}, --YAAA AAA1 0010 1111
  getfade = {'addtype','address','1','10100101',false}, --YAAA AAA1 1010 0101
  geton = {'addtype','address','1','10010011',false},--YAAA AAA1 1001 0011
  addtogroup = {'addtype','address','10110','value',true},--YAAA AAA1 0110 XXXX
  removeofgroup = {'addtype','address','10111','value',true},--YAAA AAA1 0111 XXXX
  getgroup0_7 = {'addtype','address','1','11000000',false},--YAAA AAA1 1100 0000
  getgroup8_15 = {'addtype','address','1','11000001',false},--YAAA AAA1 1100 0001
  status = {'addtype','address','1','10010000',true}, --YAAA AAA1 1001 0000 --- bit status
  statusgear = {'addtype','address','1','10010001',true}, --YAAA AAA1 1001 0001
  statuslamp = {'addtype','address','1','10010010',true}, --YAAA AAA1 1001 0010
  reset = {'addtype','address','1','00100000',true} --YAAA AAA1 0010 0000
}

--Open serial port
function serialopen()
  uart.setup(2, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, {tx=17, rx=5})
  uart.start(2)
  --s = softuart.setup(115200, 2, 3)
  return
  1
end

-- write
function serial_write(w_msg)
  uart.write(2, w_msg)
  --s:write(w_msg)
end

--DEC to BIN with offset
function byte2bin(n,range)
  if tonumber(n) then
    local t = {}
    for i=7,0,-1 do
      t[#t+1] = math.floor(n / 2^i)
      n = n % 2^i
    end
    if range == 16 then
      return table.concat(t,'',5,8)
    end
    if range == 64 then
      return table.concat(t,'',3,8)
    end
    if range == 255 then
      return table.concat(t)
    end
  else
    return '*'
  end
end

--Collect data to DALI format
function dalicmd(cmd, addtype, address, value)
  if DALI[cmd] == nil then
    --print(datetime()..DALI[cmd]..' - Command not found!')
    return
  else
    cmdtosend = ''
    CmdTable = {}
    table.insert(CmdTable,DALI[cmd][1])
    table.insert(CmdTable,DALI[cmd][2])
    table.insert(CmdTable,DALI[cmd][3])
    table.insert(CmdTable,DALI[cmd][4])
    if value ~= nil then 
      if tonumber(value) then 
        if CmdTable[4] == 'value' then --check value format command
          if cmd == 'addtogroup' or cmd == 'removeofgroup' then --set int size to bin convert
            CmdTable[4] = byte2bin(value,16)
            else
            CmdTable[4] = byte2bin(value,255)
          end
        end  
      end
    end
    if addtype == 'a' then CmdTable[1] = '0'    CmdTable[2] = byte2bin(address,64) else cmdtosend = '***' end
    if addtype == 'g' then CmdTable[1]  = '100' CmdTable[2] = byte2bin(address,16) else cmdtosend = '***' end
    if addtype == 'b' then CmdTable[1]  = '111' CmdTable[2] = '1111'               else cmdtosend = '***' end
  end
  local cmdtosend = table.concat(CmdTable,'',1,4)
  local issetup = DALI[cmd][5]

  
  if cmd == string.match(cmd, "x_%a+") then
    serial_write(cmdtosend)
  else
    if cmdtosend then
      if issetup then
        cmdtosend = 'service:'..cmdtosend
        serial_write(cmdtosend)
      else
      serial_write(cmdtosend)
      end
    end
  end
end

function main(tcpstr)
local tcpdata = {}
local dalitype = true
local cmd = tcpstr 


-- Serialize for string format      
      for tcpparam in tcpstr:gmatch('([^%s]+)') do
        local key = string.match(tcpparam,"(.*)=")
        local val = string.match(tcpparam,"=(.*)")
        if key ~= nil and val ~= nil then tcpdata[key] = val end
        if key == 'DTR' then
          dalitype = false
          serial_write('10100011'..byte2bin(val,255))
        end
      end
-- Check special commands
    if cmd == 'ini' or cmd == 'scan' or cmd == 'reset' or cmd == 'buslevel' then
      dalitype = false
      serial_write(cmd)   
    end  
    
-- Send and recieve DALI message 
     if dalitype then
      if (tcpdata['cmd'] ~= nil or
          tcpdata['addtype'] ~= nil or
          tcpdata['address'] ~= nil) then
      toResp = tcpdata['addtype']..tcpdata['address']..'/'..tcpdata['cmd']
      dalicmd(tcpdata['cmd'],tcpdata['addtype'],tcpdata['address'],tcpdata['value'])  
      end
     end     
     return dalitype
end
      
-- MAIN LOOP
local serialstatus = serialopen()
print ('serial port ready status: '..serialstatus)

mqttip = prot[2]
mqttport = prot[3]
mqttid = prot[4]
mqttlogin = prot[5]
mqttpass = prot[6]

m = mqtt.Client(mqttid, 120, mqttlogin, mqttpass)
m:connect(mqttip, mqttport, 0, function(client)

function subsctopic(top)
  client:subscribe(top, 0)
end

function senttopic(top,topdata)
  client:publish(top, topdata, 0, 0)
end

print(mqttid)

m:on("connect", function(client) print ("Connected to broker") end)
m:on("connect", subsctopic(mqttid.."/DTR") )
m:on("connect", subsctopic(mqttid.."/CMD") )
m:on("connect", senttopic(mqttid.."/status", "Online") )

m:on("message", function(client, topic, mqttdata) 
  print(topic .. " >>> data is: "..mqttdata )
if topic == mqttid..'/DTR' then 
    main("DTR="..mqttdata)
end   
if topic == mqttid..'/CMD' then 
  dalitype = main(mqttdata)
  gpio.write(4, 0)
  sep = "\r" 
  if dalitype == false then 
  uart.on(2,"data", sep,
     function(data)
        if mqttdata == 'scan' or mqttdata == 'ini' or mqttdata == 'buslevel' then
         if mqttdata == 'scan' then
           s, e, devID = string.find(data, "(%d+) OK", 1)
           if devID ~= nil then
             senttopic(mqttid..'/a'..devID..'/scan', '1')
             print('Finded device '..devID)
           end
         else
         senttopic(mqttid..'/'..mqttdata, data)
         end
         gpio.write(4, 1)
        end
  end , 1)
  else 
  uart.on(2,"data", sep,
       function(data)
         dali_rx = string.match(data, '[+-]?%d+')
         senttopic(mqttid..'/'..toResp, dali_rx)
          gpio.write(4, 1)  
  end , 1)

  end
  end 
end)
end,
function(client, reason)
  print("failed reason: " .. reason)
end)
