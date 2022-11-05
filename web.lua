function ethconf ()
  file.open("eth.cfg", "r")
  str = file.readline()
  t={}
  sep = ","
  for par in string.gmatch(str, "([^"..sep.."]+)") do
   table.insert(t, par)
  end
  file.close()
  ck = string.match(t[4], "dhc", 1)
  if ck then
  dhcp = 'checked'
  else 
  dhcp = ''
  end
end

function wificonf ()
  file.open("wifi.cfg", "r")
  wstr = file.readline()
  wt={}
  wsep = ","
  for par in string.gmatch(wstr, "([^"..wsep.."]+)") do
   table.insert(wt, par)
  end
  file.close()
  wck = string.match(wt[4], "dhc", 1)
  if wck then
  wifidhcp = 'checked'
  else 
  wifidhcp = ''
  end
end

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
  print("Protocol is : "..protocol)
  file.close()
end

ethconf ()
wificonf ()
protocolconf ()

--Create Server
sv=net.createServer(net.TCP)
function receiver(sck, data)
  -- Print received data
  -- print(data)
  s, e, get = string.find(data, "GET /??(.*) HTTP/1.1", 1)
  if get ~= nil then
    getparam = {}
    wgetparam = {}
    pgetparam = {}
    for param in get:gmatch('([^&]+)') do
      s, e, key = string.find(param,"(.*)=",1)
      s, e, val = string.find(param,"=(.*)",1)
      
      if key == 'protocol' then pgetparam[1] = val end
      if key == 'mqttip' then pgetparam[2] = val end
      if key == 'mqttport' then pgetparam[3] = val end
      if key == 'mqttid' then pgetparam[4] = val end
      if key == 'mqttlogin' then pgetparam[5] = val end
      if key == 'mqttpass' then pgetparam[6] = val end
      
      if key == 'ip' then getparam[1] = val end
      if key == 'netmask' then getparam[2] = val end
      if key == 'gw' then getparam[3] = val end
      if key == 'dhcp' then getparam[4] = 'dhcp' end

      if key == 'wifiip' then wgetparam[1] = val end
      if key == 'wifinetmask' then wgetparam[2] = val end
      if key == 'wifigw' then wgetparam[3] = val end
      if key == 'wifidhcp' then wgetparam[4] = 'dhcp' end
      if key == 'ssid' then wgetparam[5] = val end
      if key == 'pass' then wgetparam[6] = val end
    end
  
  if getparam[1] ~= nil then
  if getparam[4] == nil then getparam[4] = 'static' end
  cfgtowrite = getparam[1]..','..getparam[2]..','..getparam[3]..','..getparam[4]..'\r\n'
  file.open("eth.cfg","w+")   
  file.write(cfgtowrite)
  print("Set new ETH settings: "..cfgtowrite)
  file.close()
  end
  if wgetparam[1] ~= nil then
  if wgetparam[4] == nil then wgetparam[4] = 'static' end
  wcfgtowrite = wgetparam[1]..','..wgetparam[2]..','..wgetparam[3]..','..wgetparam[4]..','..wgetparam[5]..','..wgetparam[6]..'\r\n'
  file.open("wifi.cfg","w+")   
  file.write(wcfgtowrite)
  print("Set new WIFI settings: "..wcfgtowrite)
  file.close()
  end
  
  if pgetparam[1] ~= nil then
  if pgetparam[5] == nil then pgetparam[5] = '' end
  if pgetparam[6] == nil then pgetparam[6] = '' end
  pcfgtowrite = pgetparam[1]..','..pgetparam[2]..','..pgetparam[3]..','..pgetparam[4]..','..pgetparam[5]..','..pgetparam[6]..'\r\n'
  file.open("protocol.cfg","w+")   
  file.write(pcfgtowrite)
  print("Set new protocol settings: "..pcfgtowrite)
  file.close()
  end
  end  

if protocol == 'dalihub' then
  sl0 = 'selected'
  sl1 = ''
else 
  sl0 = ''
  sl1 = 'selected'
end  

  -- Send response  
  sck:on("sent", function(sck) sck:close() end)
  
     html = "HTTP/1.0 200 OK\r\nServer: NodeMCU\r\nContent-Type: text/html\r\n\r\n"
     html = html.."<html><title>Dalihub</title><body>"
     html = html.."<h1>Dalihub32_Ethernet</h1>"
     
     html = html.."<style>"..
     [[label,
     input[type=text] {
     display: inline-block;
     vertical-align: middle;
     }
     label {
     width: 10%;
     margin-bottom: 5px;
     }
     input[type=text] {
     width: 30%;
     margin-bottom: 5px;
     }
     select {
     margin-bottom: 5px;
     }]]
     html = html.."</style>"
     html = html.."<hr>"
     html = html.."<p>Last Reboot: "..node.bootreason().."</p>"
     html = html.."<p>Heap: "..node.heap().." byte</p>"

     html = html.."<b>Protocol settings: </b>"
     html = html..'<form action="/" method="get">'
     html = html..'<select size="1" name="protocol">'
     html = html..'<option '..sl0..' value="dalihub">Dalihub</option>'
     html = html..'<option '..sl1..' value="mqtt">MQTT</option>'
     html = html..'</select>'
     html = html..'<div>'
     html = html..'<label for="mqttip"> MQTT broker IP - </label>'
     html = html..'<input name="mqttip" id="mqttip" value='..prot[2]..'>'
     html = html..'</div>'
     html = html..'<div>'
     html = html..'<label for="mqttport"> MQTT broker port - </label>'
     html = html..'<input name="mqttport" id="mqttport" value='..prot[3]..'>'
     html = html..'</div>'
     html = html..'<div>'
     html = html..'<label for="mqttid"> MQTT device ID - </label>'
     html = html..'<input name="mqttid" id="mqttid" value='..prot[4]..'>'
     html = html..'</div>'
     html = html..'<label for="mqttlogin"> MQTT Login - </label>'
     html = html..'<input name="mqttlogin" id="mqttlogin" value='..prot[5]..'>'
     html = html..'</div>'
     html = html..'<div>'
     html = html..'<label for="mqttpass"> MQTT Password - </label>'
     html = html..'<input name="mqttpass" id="mqttpass" value='..prot[6]..'>'
     html = html..'</div>'
     html = html..'<button type="submit">Save settings</button>'
     html = html..'</form>'
     
     html = html.."<b>Ethernet settings: </b>"
     html = html..'<form action="/" method="get">'
     html = html..'<div>'
     html = html..'<label for="ip"> IP ADDRESS- </label>'
     html = html..'<input name="ip" id="ip" value='..t[1]..'>'
     html = html..'</div>'
     html = html..'<div>'
     html = html..'<label for="netmask"> NETMASK - </label>'
     html = html..'<input name="netmask" id="netmask" value='..t[2]..'>'
     html = html..'</div>'
     html = html..'<div>'
     html = html..'<label for="gw"> GATEWAY - </label>'
     html = html..'<input name="gw" id="gw" value='..t[3]..'>'
     html = html..'</div>'
     html = html..'<div>'
     html = html..'<input type="checkbox" id="dhcp" name="dhcp"'..dhcp..'>'
     html = html..'<label for="dhcp">DHCP</label>'
     html = html..'</div>'
     html = html..'<button>Save ETH settings</button>'
     html = html..'</form>'

     html = html.."<b>WIFI settings: </b>"
     html = html..'<form action="/" method="get">'
     html = html..'<div>'
     html = html..'<label for="wifiip"> IP ADDRESS- </label>'
     html = html..'<input name="wifiip" id="wifiip" value='..wt[1]..'>'
     html = html..'</div>'
     html = html..'<div>'
     html = html..'<label for="wifinetmask"> NETMASK - </label>'
     html = html..'<input name="wifinetmask" id="wifinetmask" value='..wt[2]..'>'
     html = html..'</div>'
     html = html..'<div>'
     html = html..'<label for="wifigw"> GATEWAY - </label>'
     html = html..'<input name="wifigw" id="wifigw" value='..wt[3]..'>'
     html = html..'</div>'
     html = html..'<div>'
     html = html..'<input type="checkbox" id="wifidhcp" name="wifidhcp"'..wifidhcp..'>'
     html = html..'<label for="wifidhcp">DHCP</label>'
     html = html..'</div>'
     html = html..'<div>'
     html = html..'<label for="ssid"> SSID - </label>'
     html = html..'<input name="ssid" id="ssid" value='..wt[5]..'>'
     html = html..'</div>'
     html = html..'<div>'
     html = html..'<label for="pass"> PASSWORD - </label>'
     html = html..'<input name="pass" id="pass" value='..wt[6]..'>'
     html = html..'</div>'
     html = html..'<button>Save WIFI settings</button>'
     html = html..'</form>'
     
     html = html.."</body></html>"
     sck:send(html)
end

if sv then
  sv:listen(80, function(conn)
    conn:on("receive", receiver)
  end)
 end

if protocol == 'dalihub' then dofile('dali.lua') end

if protocol == 'mqtt' then dofile('dalimqtt.lua') end

