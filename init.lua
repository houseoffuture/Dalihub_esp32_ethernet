gpio.config({ gpio=2, dir=gpio.IN, pull=gpio.PULL_UP }, { gpio=4, dir=gpio.OUT })
def_pin = gpio.read(2)
print('Default settings pin is '..def_pin)
if def_pin == 1 then
dofile('main.lua')
else
print("Write default IP 192.168.6.66... Open jumper and reboot device!")
file.open("cfg.lua","w+")
set = '192.168.6.66,255.255.255.0,192.168.6.1,static'    
file.write(set)
file.close()
end