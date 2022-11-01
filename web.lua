  file.open("cfg.lua", "r")
  str = file.readline()
  local t={}
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


--Create Server
sv=net.createServer(net.TCP)
function receiver(sck, data)
  -- Print received data
  -- print(data)
  s, e, get = string.find(data, "GET /??(.*) HTTP/1.1", 1)
  if get ~= nil then
    getparam = {}
    for param in get:gmatch('([^&]+)') do
      s, e, key = string.find(param,"(.*)=",1)
      s, e, val = string.find(param,"=(.*)",1)
      if key == 'ip' then getparam[1] = val end
      if key == 'netmask' then getparam[2] = val end
      if key == 'gw' then getparam[3] = val end
      if key == 'dhcp' then getparam[4] = key else getparam[4] = 'static' end
    end
  cfgtowrite = getparam[1]..','..getparam[2]..','..getparam[3]..','..getparam[4]..'\r\n'
  print("set parameters: "..cfgtowrite)
  file.open("cfg.lua","w+")   
  file.write(cfgtowrite)
  file.close()
  end  

  
  
  -- Send response  
  sck:on("sent", function(sck) sck:close() end)
  sck:send("HTTP/1.0 200 OK\r\nServer: NodeMCU\r\nContent-Type: text/html\r\n\r\n"..
     "<html><title>Dalihub</title><body>"..
     "<h1>Dalihub32_Ethernet</h1>"..
     
     "<style>"..
     [[label,
     input[type=text] {
     display: inline-block;
     vertical-align: middle;
     }
     label {
     width: 8%;
     }
     input[type=text] {
     width: 49%;
     }]]..
     "</style>"..
     "<hr>"..
     "<p>Uptime: "..node.uptime().."</p>"..
     "<p>Last Reboot: "..node.bootreason().."</p>"..
     "<p>Chip ID: "..node.chipid().."</p>"..
     "<p>Heap: "..node.heap().."</p>"..
     '<form action="/" method="get">'..
     '<div>'..
        '<label for="ip"> IP ADDRESS- </label>'..
        '<input name="ip" id="ip" value='..t[1]..'>'..
     '</div>'..
     '<div>'..
        '<label for="netmask"> NETMASK - </label>'..
        '<input name="netmask" id="netmask" value='..t[2]..'>'..
     '</div>'..
     '<div>'..
        '<label for="gw"> GATEWAY - </label>'..
        '<input name="gw" id="gw" value='..t[3]..'>'..
     '</div>'..
     '<div>'..
      '<input type="checkbox" id="dhcp" name="dhcp"'..dhcp..'>'..
      '<label for="dhcp">DHCP</label>'..
     '</div>'..
        '<button>Save</button>'..
     '</form>'..
     "</body></html>")
end

if sv then
  sv:listen(80, function(conn)
    conn:on("receive", receiver)
  end)
 end

dofile('dali.lua')
