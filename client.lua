local QBCore = exports['qb-core']:GetCoreObject()
customnitro = {}
busyplate = {}
nearstancer = {}
busyairsus = false
wheelsettings = {}
wheeledit = false
isbusy = false
carcontrol = false
local radialMenuItemId = nil
veh_stats = {}
local vehiclesinarea = {}


CreateThread(function()
if Config.One.Active then
	stancerOne = CircleZone:Create(Config.One.Stancer, 3.0, {
			name="StancerLS",
			heading=0.0,
		--	debugPoly=Config.One.DebugZone,
			useZ=true,
	})
	stancerOne:onPlayerInOut(function(isPointInside)
			if isPointInside then
					local playerPed	= PlayerPedId()
					local coords	= GetEntityCoords(playerPed)
					QBCore.Functions.GetPlayerData(function(PlayerData)
						if IsPedSittingInAnyVehicle(playerPed) then
						text = Config.One.StancerText..  '</br>Press [E]'
						exports['qb-drawtext']:DrawText(text)
						StartListeningForControl()
						else
							text = Config.One.StancerText..'</br>Vehicle is Required'
							exports['qb-drawtext']:DrawText(text)
						end
					end)			
			else
					exports['qb-drawtext']:HideText('hide')
					listen = false
			end
	end)
end
end)

--[[ CreateThread(function()  --------- -This can be a template to add more zones "just add (config.Two.Active....)""
	if Config.One.Active then
		stancerOne = CircleZone:Create(Config.One.Stancer, 3.0, {
				name="StancerLS",
				heading=0.0,
			--	debugPoly=Config.One.DebugZone,
				useZ=true,
		})
		stancerOne:onPlayerInOut(function(isPointInside)
				if isPointInside then
						local playerPed	= PlayerPedId()
						local coords	= GetEntityCoords(playerPed)
						QBCore.Functions.GetPlayerData(function(PlayerData)
							if IsPedSittingInAnyVehicle(playerPed) then
							text = Config.One.StancerText..  '</br>Press [E]'
							exports['qb-drawtext']:DrawText(text)
							StartListeningForControl()
							else
								text = Config.One.StancerText..'</br>Vehicle is Required'
								exports['qb-drawtext']:DrawText(text)
							end
						end)			
				else
						exports['qb-drawtext']:HideText('hide')
						listen = false
				end
		end)
	end
	end) ]]

function StartListeningForControl()
	listen = true
	CreateThread(function()
			while listen do
					if IsControlJustReleased(0, 38) then -- E
							OpenStancer()
							listen = false
					end
					Wait(1)
			end
	end)
end


function SetupInteraction()
	local Player = PlayerPedId()
	if IsPedInAnyVehicle(Player) then
	MenuItemId = exports['qb-radialmenu']:AddOption({
			id = 'open_stancer_menu',
			title = 'Stancer',
			icon = 'mechanic',
			type = 'client',
			event = 'an-stancer:openstancer',
			shouldClose = true,
	}, MenuItemId)
	end
end

RegisterNetEvent("an-stancer:openstancer")
AddEventHandler("an-stancer:openstancer", function(vehicle,val,coords)
		OpenStancer()
end)


RegisterNetEvent("an-stancer:airsuspension")
AddEventHandler("an-stancer:airsuspension", function(vehicle,val,coords)
	local v = NetToVeh(vehicle)
	CreateThread(function()
		Wait(math.random(1,500))
		if v ~= 0 and #(coords - GetEntityCoords(PlayerPedId())) < 50 and not busyplate[plate] then
			local plate = string.gsub(GetVehicleNumberPlateText(v), '^%s*(.-)%s*$', '%1')
			busyplate[plate] = true
			if vehiclesinarea[plate] ~= nil then
				vehiclesinarea[plate].wheeledit = true
			end
			playsound(GetEntityCoords(v),20,'suspension',1.0)
			local max = 0
			local data = {}
			local min = GetVehicleSuspensionHeight(v)
			local count = 0
			data.val = val
			local ent = Entity(v).state
			plate2 = tostring(GetVehicleNumberPlateText(v))
			plate2 = string.gsub(plate2, '^%s*(.-)%s*$', '%1')
			veh_stats[plate2] = ent.stancer
			veh_stats[plate2].wheeledit = true
			veh_stats[plate2].heightdata = data.val
			ent:set('stancer', veh_stats[plate2], true)
			if (data.val * 100) < 15 then
				val = min
				data.val = data.val - 0.1
				local good = false
				count = 0
				while min > data.val and busyplate[plate] and count < 50 do
					SetVehicleSuspensionHeight(v,GetVehicleSuspensionHeight(v) - (1.0 * 0.01))
					min = GetVehicleSuspensionHeight(v)
					count = count + 1
					Citizen.Wait(100)
					good = true
				end
				count = 0
				while not good and min < data.val and busyplate[plate] and count < 50 do
					SetVehicleSuspensionHeight(v,GetVehicleSuspensionHeight(v) + (1.0 * 0.01))
					min = GetVehicleSuspensionHeight(v)
					count = count + 1
					Citizen.Wait(100)
				end
				SetVehicleSuspensionHeight(v,data.val)
			else
				val = min
				local good = false
				count = 0
				while min < data.val and busyplate[plate] and count < 50 do
					SetVehicleSuspensionHeight(v,GetVehicleSuspensionHeight(v) + (1.0 * 0.01))
					min = GetVehicleSuspensionHeight(v)
					count = count + 1
					Citizen.Wait(100)
					good = true
				end
				count = 0
				while not good and min > data.val and busyplate[plate] and count < 50 do
					SetVehicleSuspensionHeight(v,GetVehicleSuspensionHeight(v) - (1.0 * 0.01))
					count = count + 1
					min = GetVehicleSuspensionHeight(v)
					Citizen.Wait(100)
				end
				SetVehicleSuspensionHeight(v,data.val)
			end
			busyplate[plate] = false
			busyairsus = false
		end
		return
	end)
end)

function getveh()
	local v = GetVehiclePedIsIn(PlayerPedId(), false)
	lastveh = GetVehiclePedIsIn(PlayerPedId(), true)
	local dis = -1
	if v == 0 then
		if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(lastveh)) < 5 then
			v = lastveh
		end
		dis = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(lastveh))
	end
	if dis > 3 then
		v = 0
	end
	if v == 0 then
		local count = 5
		v = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 5.000, 0, 70)
		while #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(v)) > 5 and count >= 0 do
			v = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 5.000, 0, 70)
			count = count - 1
			Wait(400)
		end
	end
	return tonumber(v)
end

RegisterNUICallback('setvehicleheight', function(data, cb)
	vehicle = getveh()
    if vehicle ~= nil and vehicle ~= 0 and not busyairsus then
		busyairsus = true
		TriggerServerEvent("an-stancer:airsuspension",VehToNet(vehicle), data.val, GetEntityCoords(vehicle))
    end
	cb(true)
end)

function SetWheelOffsetFront(vehicle, val)
	plate = tostring(GetVehicleNumberPlateText(vehicle))
	plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')
	SetVehicleWheelXOffset(vehicle,0,tonumber("-0."..val..""))
	SetVehicleWheelXOffset(vehicle,1,tonumber("0."..val..""))
	if wheelsettings[plate]['wheeloffsetfront'] == nil then wheelsettings[plate]['wheeloffsetfront'] = {} end
	wheelsettings[plate]['wheeloffsetfront'].wheel0 = tonumber("-0."..val.."")
	wheelsettings[plate]['wheeloffsetfront'].wheel1 = tonumber("0."..val.."")
	wheeledit = true
	if vehiclesinarea[plate] ~= nil then
		vehiclesinarea[plate].wheeledit = true
	end
end

exports('SetWheelOffsetFront', function(vehicle, val)
	return SetWheelOffsetFront(vehicle, val)
end)

RegisterNetEvent('an-stancer:addstancerkit')
AddEventHandler("an-stancer:addstancerkit", function()
				QBCore.Functions.Progressbar("Installing The stancerkit", "Installing The stancerkit", 5000, false, true, {
						disableMovement = true,
						disableCarMovement = true,
						disableMouse = false,
						disableCombat = true,
				}, {
						animDict = "mini@repair",
						anim = "fixing_a_player",
						flags = 49,
				}, {}, {}, function()
						TriggerServerEvent("an-stancer:addstancer")
						TriggerServerEvent('QBCore:Server:RemoveItem', "stancerkit", 1)
						TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items["stancerkit"], "remove")
						QBCore.Functions.Notify("Stancer Installed", "success")
						ClearPedTasks(playerPed)
				end, function()
					QBCore.Functions.Notify("Failed..", "error")
				end)
end)

RegisterNUICallback('setvehiclewheeloffsetfront', function(data, cb)
	vehicle = getveh()
	plate = tostring(GetVehicleNumberPlateText(vehicle))
	plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')
    if vehicle ~= nil and vehicle ~= 0 then
		if wheelsettings[plate] == nil then wheelsettings[plate] = {} end
		local val = round(data.val * 100)
		SetWheelOffsetFront(vehicle, val)
    end
	cb(true)
end)

function SetWheelOffsetRear(vehicle, val)
	plate = tostring(GetVehicleNumberPlateText(vehicle))
	plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')
	SetVehicleWheelXOffset(vehicle,2,tonumber("-0."..val..""))
	SetVehicleWheelXOffset(vehicle,3,tonumber("0."..val..""))
	if wheelsettings[plate]['wheeloffsetrear'] == nil then wheelsettings[plate]['wheeloffsetrear'] = {} end
	wheelsettings[plate]['wheeloffsetrear'].wheel2 = tonumber("-0."..val.."")
	wheelsettings[plate]['wheeloffsetrear'].wheel3 = tonumber("0."..val.."")
	wheeledit = true
	if vehiclesinarea[plate] ~= nil then
		vehiclesinarea[plate].wheeledit = true
	end
end

exports('SetWheelOffsetRear', function(vehicle, val)
	return SetWheelOffsetRear(vehicle, val)
end)

RegisterNUICallback('setvehiclewheeloffsetrear', function(data, cb)
	vehicle = getveh()
	plate = tostring(GetVehicleNumberPlateText(vehicle))
	plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')
    if vehicle ~= nil and vehicle ~= 0 then
		if wheelsettings[plate] == nil then wheelsettings[plate] = {} end
		local val = round(data.val * 100)
		SetWheelOffsetRear(vehicle,val)
    end
	cb(true)
end)




local cachedata = {}
local cache = {}
CreateThread(function()
	while true do
		local ped = PlayerPedId()
		local coord = GetEntityCoords(ped)
		local c = 0
		cachedata = {}
		for k,v in pairs(vehiclesinarea) do
			c = c + 1
			cachedata[c] = v
		end
		for k,v in ipairs(GetGamePool('CVehicle')) do
			local ent = Entity(v).state
			local dist = #(GetEntityCoords(v) - coord)
			local plate = string.gsub(tostring(GetVehicleNumberPlateText(v)), '^%s*(.-)%s*$', '%1')
			if DoesEntityExist(v) and dist < 100 and ent.stancer then
				if not ent.stancer.wheeledit then
					if vehiclesinarea[plate] == nil then vehiclesinarea[plate] = {} addtable = true vehiclesinarea[plate]['entity'] = v vehiclesinarea[plate]['plate'] = plate end
					vehiclesinarea[plate]['wheelsetting'] = ent.stancer['wheelsetting']
					vehiclesinarea[plate]['speed'] = GetEntitySpeed(v)
					vehiclesinarea[plate]['dist'] = dist
					vehiclesinarea[plate]['wheeledit'] = ent.stancer.wheeledit
					SetVehicleSuspensionHeight(v,ent.stancer.height)
				end
			elseif DoesEntityExist(v) and dist > 100 and ent.stancer and vehiclesinarea[plate] then
				vehiclesinarea[plate] = nil
			end
		end
		cache = cachedata
		Wait(2000)
	end
end)

CreateThread(function()
	Wait(1000)
	while true do
		local sleep = 2000
		for i = 1, #cache do
			local v = cache[i]
			local activate = v and not v.wheeledit and v.dist < 100 and v['wheelsetting']
			local exist = DoesEntityExist(v.entity)
			if activate and exist then
				sleep = 1
				SetVehicleWheelXOffset(v.entity,0,tonumber(v['wheelsetting']['wheeloffsetfront'].wheel0))
				SetVehicleWheelXOffset(v.entity,1,tonumber(v['wheelsetting']['wheeloffsetfront'].wheel1))
				SetVehicleWheelXOffset(v.entity,2,tonumber(v['wheelsetting']['wheeloffsetrear'].wheel2))
				SetVehicleWheelXOffset(v.entity,3,tonumber(v['wheelsetting']['wheeloffsetrear'].wheel3))
			end
			if not exist then
				if vehiclesinarea[v.plate] then vehiclesinarea[v.plate] = nil end
				if cachedata[i] then cachedata[i] = nil end
			end
		end
		Wait(sleep)
	end
	return
end)

RegisterNUICallback('wheelsetting', function(data, cb)
	vehicle = getveh()
	wheeledit = false
	plate = tostring(GetVehicleNumberPlateText(vehicle))
	plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')
	if veh_stats[plate] == nil then veh_stats[plate] = {} end
	if veh_stats[plate]['wheelsetting'] == nil then
		veh_stats[plate]['wheelsetting'] = {}
	end
	local vehicle_height = GetVehicleSuspensionHeight(vehicle)
	if wheelsettings[plate] == nil then wheelsettings[plate] = {} end
	if wheelsettings[plate]['wheeloffsetfront'] == nil then
		wheelsettings[plate]['wheeloffsetfront'] = {}
	end
	if wheelsettings[plate]['wheeloffsetfront'].wheel0 == nil then
		wheelsettings[plate]['wheeloffsetfront'].wheel0 = GetVehicleWheelXOffset(vehicle,0)
	end
	if wheelsettings[plate]['wheeloffsetfront'].wheel1 == nil then
		wheelsettings[plate]['wheeloffsetfront'].wheel1 = GetVehicleWheelXOffset(vehicle,1)
	end

	if wheelsettings[plate]['wheeloffsetrear'] == nil then
		wheelsettings[plate]['wheeloffsetrear'] = {}
	end

	if wheelsettings[plate]['wheeloffsetrear'].wheel2 == nil then
		wheelsettings[plate]['wheeloffsetrear'].wheel2 = GetVehicleWheelXOffset(vehicle,2)
	end
	if wheelsettings[plate]['wheeloffsetrear'].wheel3 == nil then
		wheelsettings[plate]['wheeloffsetrear'].wheel3 = GetVehicleWheelXOffset(vehicle,3)
	end
	veh_stats[plate]['wheelsetting'] = wheelsettings[plate]
	--end
	veh_stats[plate].height = vehicle_height
    if vehicle ~= nil and vehicle ~= 0 then
		print("saving stance")
		local ent = Entity(vehicle).state
		veh_stats[plate].wheeledit = false
		veh_stats[plate].heightdata = ent.stancer.heightdata
		ent:set('stancer', veh_stats[plate], true)
		QBCore.Functions.Notify("Vehicle Wheel Data is Saved", "success")
	end
	cb(true)
end)


RegisterCommand(Config.commands, function()
	OpenStancer()
end, false)

CreateThread(function()
	RegisterKeyMapping(Config.commands, 'Open Car Control', 'keyboard', Config.keybinds)
	return
end)

RegisterNUICallback('closecarcontrol', function(data, cb)
	carcontrol = false
	SendNUIMessage({
		type = "show",
		content = {bool = false}
	})
	SetNuiFocus(false,false)
	cb(true)
end)

function OpenStancer()
	vehicle = getveh()
	local ent = Entity(vehicle).state
	if Config.yes == 'no' and not ent.stancer then
		TriggerServerEvent('an-stancer:addstancer')
		while not ent.stancer do
			Wait(200)
		end
	end
	if busy or not ent.stancer then
		QBCore.Functions.Notify("No stancer installed.", "error") return
	end
	local cache = ent.stancer
	isbusy = true
	vehicle  = getveh()
	if vehicle  ~= 0 and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle )) < 15 and GetVehicleDoorLockStatus(vehicle ) == 1 then
		carcontrol = not carcontrol
		cache.wheeledit = carcontrol
		ent:set('stancer', cache, true)
		local offset = {}
		local rotation = {}
		for i=0, 4 do
			offset[i] = GetVehicleWheelXOffset(vehicle,i)
			rotation[i] = GetVehicleWheelYRotation(vehicle,i)
		end
		SendNUIMessage({
			type = "show",
			content = {bool = carcontrol, offset = offset, height = ent.stancer.heightdata}
		})
		Wait(500)
		SetNuiFocus(carcontrol,carcontrol)
		SetNuiFocusKeepInput(true)
		isbusy = false
		CreateThread(function()
			while carcontrol do
				whileinput()
				Wait(5)
			end
			SetNuiFocusKeepInput(false)
			return
		end)
	else
		if GetVehicleDoorLockStatus(vehicle ) ~= 1 then
			QBCore.Functions.Notify("No unlocked vehicles nearby.", "error")
		else
			QBCore.Functions.Notify("No vehicles nearby", "error")
		end
	end
end

exports('OpenStancer', function()
	return OpenStancer()
end)

function whileinput()
	if Config.FixedCamera then
		DisableControlAction(1, 1, true)
		DisableControlAction(1, 2, true)
	end
	DisableControlAction(1, 18, true)
	DisableControlAction(1, 68, true)
	DisableControlAction(1, 69, true)
	DisableControlAction(1, 70, true)
	DisableControlAction(1, 91, true)
	DisableControlAction(1, 92, true)
	DisableControlAction(1, 24, true)
	DisableControlAction(1, 25, true)
	DisableControlAction(1, 14, true)
	DisableControlAction(1, 15, true)
	DisableControlAction(1, 16, true)
	DisableControlAction(1, 17, true)
	DisablePlayerFiring(PlayerId(), true)
end

function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5)
end

function playsound(vehicle,max,file,maxvol)
	local volume = maxvol
	local mycoord = GetEntityCoords(PlayerPedId())
	local distIs  = tonumber(string.format("%.1f", #(mycoord - vehicle)))
	if (distIs <= max) then
		distPerc = distIs / max
		volume = (1-distPerc) * maxvol
		local table = {
			['file'] = file,
			['volume'] = volume
		}
		SendNUIMessage({
			type = "playsound",
			content = table
		})
	end
end

function CheckForKeypress()
					if IsControlJustReleased(0, 38) then
						OpenStancer()
					end
end