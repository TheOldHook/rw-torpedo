# rw-torpedo
Torpedo job for QB-Core 

Call with the burnerphone and get a sms, press accept and you get a location where you can meet a ped that "owes" money. 
Once you have downed the ped you will get money, original you get `svartepenger`, but you can change this to whatever you like in `server.lua`.

Call again and repeat. There are multiple locations and peds in the config file (feel free to change).
There is also a line that makes some of the peds spawn with weapons.

You need to add a item for the phone itself in shared for this useable item `burnertelefon`.

Add this to your ps-dispatch client cl_events.lua
```local function Torpedo(message, pos)
    local locationInfo = getStreetandZone(pos)
    local gender = GetPedGender()
    TriggerServerEvent("dispatch:server:notify", {
        dispatchcodename = "susactivity",
        dispatchCode = "10-66",
        firstStreet = locationInfo,
        gender = gender,
        model = nil,
        plate = nil,
        priority = 2,
        firstColor = nil,
        automaticGunfire = false,
        origin = {
            x = pos.x,
            y = pos.y,
            z = pos.z
        },
        dispatchMessage = message,
        job = { "police" }
    })
end

exports('Torpedo', Torpedo)```


