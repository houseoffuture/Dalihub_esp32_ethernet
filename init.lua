gpio.config({ gpio=2, dir=gpio.IN, pull=gpio.PULL_UP }, {gpio=12, dir=gpio.IN, pull=gpio.PULL_UP }, { gpio=4, dir=gpio.OUT })
def_pin = gpio.read(2)
mode = gpio.read(12)
print('Default settings pin is '..def_pin)
print('Mode settings pin is '..mode)
if def_pin == 1 then
  if mode == 1 then
    print("Switch to Ethernet...")
    dofile('main.lua')
  else
    print("Switch to WIFI...")
    dofile('mainwifi.lua')
  end
else
print("Write default IP 192.168.6.66... Open jumper and reboot device!")
file.open("eth.cfg","w+")
set = '192.168.6.66,255.255.255.0,192.168.6.1,static'    
file.write(set)
file.close()
end
