wifi.setmode(wifi.STATIONAP)

sv=nil

enduser_setup.start(
  function()
    print("Connected to wifi as:" .. wifi.sta.getip())
    --enduser_setup.stop()

    wifi.setmode(wifi.NULLMODE)

    wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, discon1)
    wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, connec1)
    wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, timeou1)
    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, gotip1)
    wifi.eventmon.register(wifi.eventmon.STA_AUTHMODE_CHANGE, authc1)

    tmr.create():alarm(15000, tmr.ALARM_SINGLE, function()
        wifi.setmode(wifi.STATION)
        wifi.sta.connect()
    end)
  end,
  function(err, str)
    print("enduser_setup: Err #" .. err .. ": " .. str)
  end,
  print -- Lua print function can serve as the debug callback
)

function discon1(T)
    print("\n\tSTA - DISCONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..T.BSSID.."\n\treason: "..T.reason.."\n")
end

function connec1(T)
    print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..T.BSSID.."\n\tChannel: "..T.channel)
end

function timeou1(T)
    print("\n\tSTA - DHCP TIMEOUT")
end

function authc1(T)
    print("\n\tSTA - AUTHMODE CHANGE".."\n\told_auth_mode: "..T.old_auth_mode.."\n\tnew_auth_mode: "..T.new_auth_mode)
end

function gotip1(T)
    print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..T.netmask.."\n\tGateway IP: "..T.gateway)

--    if (sv ~= nil) then
--        sv:close();
--        sv = nil;
--    end
    
    sv=net.createServer(net.TCP,60)
    sv:listen(80,listen1)
end

function listen1(c)
    c:on("receive", function(sck, req)

    local ht = {}
    table.insert(ht, "<html>")
    table.insert(ht, "<head><title>Temperatura</title></head>")
    table.insert(ht, "<body>")

    pin = 5
    status, temp, humi, temp_dec, humi_dec = dht.read11(pin)
    if status == dht.OK then
        table.insert(ht, "<h1>Temperatura</h1>")
        table.insert(ht, "<h2>"..temp.."</h2>")
        table.insert(ht, "<h1>Humidade</h1>")
        table.insert(ht, "<h2>"..humi.."</h2>")
    
    elseif status == dht.ERROR_CHECKSUM then
        table.insert(ht, "<h1>DHT Checksum error</h1>")
    elseif status == dht.ERROR_TIMEOUT then
        table.insert(ht, "<h1>DHT timed out</h1>")
    end
    
    table.insert(ht, "</body>")
    table.insert(ht, "</html>")
    local sht = 0
    for key, value in pairs(ht) do
        sht = sht + string.len(value) + 1
    end

    table.insert(ht, 1, "HTTP/1.0 200 OK")
    table.insert(ht, 2, "Server: ESP (nodeMCU)")
    table.insert(ht, 3, "Content-Type: text/html; charset=UTF-8")
    table.insert(ht, 4, "Content-Length: " .. sht .. "\n")

    local function sender (sck)
        if #ht>0 then 
            sck:send(table.remove(ht,1) .. "\n")
        else 
            sck:close()
        end
    end
    sck:on("sent", sender)
    sender(sck)
    end)
end