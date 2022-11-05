print("eth init")

eth.init({phy=eth.PHY_LAN8720,
addr=1,
power=16,
clock_mode=eth.CLOCK_GPIO0_IN,
mdc=23,
mdio=18})

file.open("eth.cfg", "r")
str = file.readline()
local t={}
sep = ","
for par in string.gmatch(str, "([^"..sep.."]+)") do
 table.insert(t, par)
end
file.close()
print('Boot IP settings is: '..str)

static = string.match(t[4], "stat", 1)
if static ~= nil then
  cfg={}
  cfg.ip=t[1]
  cfg.netmask=t[2]
  cfg.gateway=t[3]
  cfg.dns='8.8.8.8'
  eth.set_ip(cfg)
end

function ev(event, info)
    print("event", event)
    if event == "got_ip" then
        file.open("eth.cfg","w+")
        set = info.ip..','..info.netmask..','..info.gw..',dhcp'    
        file.write(set)
        file.close()
        print("ip:"..info.ip..", nm:"..info.netmask..", gw:"..info.gw)
        gpio.write(4, 1)
        dofile('web.lua')
    elseif event == "connected" then
        print("speed:", eth.get_speed())
        print("mac:", eth.get_mac())
        
    end
end

eth.on("connected", ev)
eth.on("disconnected", ev)
eth.on("start", ev)
eth.on("stop", ev)
eth.on("got_ip", ev)
