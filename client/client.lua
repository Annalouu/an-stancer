local busyplate = {}
local busyairsus = false
local wheelsettings = {}
local isbusy = false
local carcontrol = false
local veh_stats = {}
local vehiclesinarea = {}

local inZone = {}

local Config = require "config".client
local Utils = require "config".utils
local Progress = require "client.progressbar"

--- function

---@param num number
---@param numDecimalPlaces number
---@return integer
local function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5)
end

---@param vehicle string | integer
---@param max number
---@param file string
---@param maxvol number
local function playsound(vehicle,max,file,maxvol)
	local volume = maxvol
	local mycoord = vec(cache.coords)
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

---@param vehicle number
---@param val any
local function SetWheelOffsetRear(vehicle, val)
	local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')
	SetVehicleWheelXOffset(vehicle,2, tonumber("-0."..val..""))
	SetVehicleWheelXOffset(vehicle,3, tonumber("0."..val..""))
	if wheelsettings[plate]['wheeloffsetrear'] == nil then wheelsettings[plate]['wheeloffsetrear'] = {} end
	wheelsettings[plate]['wheeloffsetrear'].wheel2 = tonumber("-0."..val.."")
	wheelsettings[plate]['wheeloffsetrear'].wheel3 = tonumber("0."..val.."")
	if vehiclesinarea[plate] ~= nil then
		vehiclesinarea[plate].wheeledit = true
	end
end

---@param vehicle number
---@param val any
local function SetWheelOffsetFront(vehicle, val)
	local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')
	SetVehicleWheelXOffset(vehicle,0, tonumber("-0."..val..""))
	SetVehicleWheelXOffset(vehicle,1, tonumber("0."..val..""))
	if wheelsettings[plate]['wheeloffsetfront'] == nil then wheelsettings[plate]['wheeloffsetfront'] = {} end
	wheelsettings[plate]['wheeloffsetfront'].wheel0 = tonumber("-0."..val.."")
	wheelsettings[plate]['wheeloffsetfront'].wheel1 = tonumber("0."..val.."")
	if vehiclesinarea[plate] ~= nil then
		vehiclesinarea[plate].wheeledit = true
	end
end

---@param vehicle number
---@param val any
local function SetWheelRotationFront(vehicle, val)
	local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')
	SetVehicleWheelYRotation(vehicle, 0, tonumber(-val))
	SetVehicleWheelYRotation(vehicle, 1, tonumber(val))
	if wheelsettings[plate]['wheelrotationfront'] == nil then wheelsettings[plate]['wheelrotationfront'] = {} end
	wheelsettings[plate]['wheelrotationfront'].wheel0 = tonumber(-val)
	wheelsettings[plate]['wheelrotationfront'].wheel1 = tonumber(val)
	if vehiclesinarea[plate] ~= nil then
		vehiclesinarea[plate].wheeledit = true
	end
end

---@param vehicle number
---@param val any
local function SetWheelRotationRear(vehicle, val)
	local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')
	SetVehicleWheelYRotation(vehicle, 2, tonumber(-val))
	SetVehicleWheelYRotation(vehicle, 3, tonumber(val))
	if wheelsettings[plate]['wheelrotationrear'] == nil then wheelsettings[plate]['wheelrotationrear'] = {} end
	wheelsettings[plate]['wheelrotationrear'].wheel2 = tonumber(-val)
	wheelsettings[plate]['wheelrotationrear'].wheel3 = tonumber(val)
	if vehiclesinarea[plate] ~= nil then
		vehiclesinarea[plate].wheeledit = true
	end
end

local function whileinput()

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
	
	DisablePlayerFiring(cache.playerId, true)
end

local function OpenStancer()
	if not cache.vehicle then return
	
	end

	local ent = Entity(cache.vehicle).state
	
	if isbusy or not ent.stancer then
		Utils.Notify("No stancer installed.", "error") return
	end

	local cachestancer = ent.stancer
	isbusy = true
	
	carcontrol = not carcontrol
	cachestancer.wheeledit = carcontrol
	ent:set('stancer', cachestancer, true)

	local offset = {}
	local rotation = {}

	for i=0, 4 do
		offset[i] = GetVehicleWheelXOffset(cache.vehicle, i)
		rotation[i] = GetVehicleWheelYRotation(cache.vehicle, i)
	end

	SendNUIMessage({
		type = "show",
		content = {bool = carcontrol, offset = offset, rotation = rotation, height = ent.stancer.heightdata}
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
	end)
end

--- NUI CALLBACK
RegisterNUICallback('setvehicleheight', function(data, cb)
    if cache.vehicle and not busyairsus then
		busyairsus = true
		TriggerServerEvent("an-stancer:airsuspension", VehToNet(cache.vehicle), data.val, GetEntityCoords(cache.vehicle))
    end
	cb(true)
end)


RegisterNUICallback('setvehiclewheeloffsetfront', function(data, cb)
    if cache.vehicle then
		local plate = string.gsub(GetVehicleNumberPlateText(cache.vehicle), '^%s*(.-)%s*$', '%1')
		if wheelsettings[plate] == nil then wheelsettings[plate] = {} end
		local val = round(data.val * 100)
		SetWheelOffsetFront(cache.vehicle, val)
    end
	cb(true)
end)

RegisterNUICallback('setvehiclewheeloffsetrear', function(data, cb)
    if cache.vehicle then
		local plate = string.gsub(GetVehicleNumberPlateText(cache.vehicle), '^%s*(.-)%s*$', '%1')
		if wheelsettings[plate] == nil then wheelsettings[plate] = {} end
		local val = round(data.val * 100)
		SetWheelOffsetRear(cache.vehicle, val)
    end
	cb(true)
end)

RegisterNuiCallback("setvehiclewheelrotationfront", function (data, cb)
	if cache.vehicle then
		local plate = string.gsub(GetVehicleNumberPlateText(cache.vehicle), '^%s*(.-)%s*$', '%1')
		if wheelsettings[plate] == nil then wheelsettings[plate] = {} end
		SetWheelRotationFront(cache.vehicle, data.val)
    end
	cb(true)
end)

RegisterNuiCallback("setvehiclewheelrotationrear", function (data, cb)
	if cache.vehicle then
		local plate = string.gsub(GetVehicleNumberPlateText(cache.vehicle), '^%s*(.-)%s*$', '%1')
		if wheelsettings[plate] == nil then wheelsettings[plate] = {} end
		SetWheelRotationRear(cache.vehicle, data.val)
    end
	cb(true)
end)

RegisterNUICallback('wheelsetting', function(data, cb)
	if cache.vehicle then
		local plate = string.gsub(GetVehicleNumberPlateText(cache.vehicle), '^%s*(.-)%s*$', '%1')
		
		if veh_stats[plate] == nil then veh_stats[plate] = {} end
	
		if veh_stats[plate]['wheelsetting'] == nil then
			veh_stats[plate]['wheelsetting'] = {}
		end
	
		local vehicle_height = GetVehicleSuspensionHeight(cache.vehicle)
		if wheelsettings[plate] == nil then wheelsettings[plate] = {} end
	
		if wheelsettings[plate]['wheeloffsetfront'] == nil then
			wheelsettings[plate]['wheeloffsetfront'] = {}
		end
		if wheelsettings[plate]['wheeloffsetfront'].wheel0 == nil then
			wheelsettings[plate]['wheeloffsetfront'].wheel0 = GetVehicleWheelXOffset(cache.vehicle, 0)
		end
		if wheelsettings[plate]['wheeloffsetfront'].wheel1 == nil then
			wheelsettings[plate]['wheeloffsetfront'].wheel1 = GetVehicleWheelXOffset(cache.vehicle, 1)
		end
	
		if wheelsettings[plate]['wheeloffsetrear'] == nil then
			wheelsettings[plate]['wheeloffsetrear'] = {}
		end
	
		if wheelsettings[plate]['wheeloffsetrear'].wheel2 == nil then
			wheelsettings[plate]['wheeloffsetrear'].wheel2 = GetVehicleWheelXOffset(cache.vehicle, 2)
		end
		if wheelsettings[plate]['wheeloffsetrear'].wheel3 == nil then
			wheelsettings[plate]['wheeloffsetrear'].wheel3 = GetVehicleWheelXOffset(cache.vehicle, 3)
		end
	
		--- camber
		if wheelsettings[plate]['wheelrotationfront'] == nil then
			wheelsettings[plate]['wheelrotationfront'] = {}
		end
		if wheelsettings[plate]['wheelrotationfront'].wheel0 == nil then
			wheelsettings[plate]['wheelrotationfront'].wheel0 = GetVehicleWheelYRotation(cache.vehicle, 0)
		end
		if wheelsettings[plate]['wheelrotationfront'].wheel1 == nil then
			wheelsettings[plate]['wheelrotationfront'].wheel1 = GetVehicleWheelYRotation(cache.vehicle, 1)
		end
	
		if wheelsettings[plate]['wheelrotationrear'] == nil then
			wheelsettings[plate]['wheelrotationrear'] = {}
		end
	
		if wheelsettings[plate]['wheelrotationrear'].wheel2 == nil then
			wheelsettings[plate]['wheelrotationrear'].wheel2 = GetVehicleWheelYRotation(cache.vehicle, 2)
		end
		if wheelsettings[plate]['wheelrotationrear'].wheel3 == nil then
			wheelsettings[plate]['wheelrotationrear'].wheel3 = GetVehicleWheelYRotation(cache.vehicle, 3)
		end
	
		veh_stats[plate]['wheelsetting'] = wheelsettings[plate]
		veh_stats[plate].height = vehicle_height
	
		local ent = Entity(cache.vehicle).state
		veh_stats[plate].wheeledit = false
		veh_stats[plate].heightdata = ent.stancer.heightdata
		ent:set('stancer', veh_stats[plate], true)
		TriggerServerEvent('an-stancer:server:save',veh_stats[plate])
		Utils.Notify("Vehicle Wheel Data is Saved", "success")
	end
	cb(true)
end)

RegisterNUICallback('closecarcontrol', function(data, cb)
	carcontrol = false
	InputDisabled = false

	SendNUIMessage({
		type = "show",
		content = {bool = false}
	})

	SetNuiFocus(false,false)
	cb(true)
end)

--- Thread
CreateThread(function()
	for k, v in pairs(Config.StanceLocations) do -- For every unique name get it's values
		lib.zones.sphere({
			coords = v.coords,
			radius = v.size,
			debug = v.debug,
			inside = function ()
				if IsControlJustPressed(0, 38) then
					OpenStancer()

				end
			end,
			onEnter = function ()
				inZone.status = true
				inZone.index = k

				if cache.vehicle then
					Utils.drawtext(v.drawtext.inveh, "show")
					return
				end

				Utils.drawtext(v.drawtext.outveh, "show")
			end,
			onExit = function ()
				inZone.status = false
				inZone.index = nil
				
				Utils.drawtext(nil, "hide")
			end
		})
	end
end)

local cachedata = {}
local cachestancer = {}
CreateThread(function()
	while true do
		local coord = vec(cache.coords)
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

					if vehiclesinarea[plate] == nil then vehiclesinarea[plate] = {}
						vehiclesinarea[plate]['entity'] = v
						vehiclesinarea[plate]['plate'] = plate
					end

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

		cachestancer = cachedata
		Wait(2000)
	end
end)

CreateThread(function()
	Wait(1000)
	while true do
		local sleep = 2000
		for i = 1, #cachestancer do
			local v = cachestancer[i]
			local activate = v and not v.wheeledit and v.dist < 100 and v['wheelsetting']
			local exist = DoesEntityExist(v.entity)
			if activate and exist then
				sleep = 1
				SetVehicleWheelXOffset(v.entity,0,tonumber(v['wheelsetting']['wheeloffsetfront'].wheel0))
				SetVehicleWheelXOffset(v.entity,1,tonumber(v['wheelsetting']['wheeloffsetfront'].wheel1))
				SetVehicleWheelXOffset(v.entity,2,tonumber(v['wheelsetting']['wheeloffsetrear'].wheel2))
				SetVehicleWheelXOffset(v.entity,3,tonumber(v['wheelsetting']['wheeloffsetrear'].wheel3))
				
				--- camber
				SetVehicleWheelYRotation(v.entity,0,tonumber(v['wheelsetting']['wheelrotationfront'].wheel0))
				SetVehicleWheelYRotation(v.entity,1,tonumber(v['wheelsetting']['wheelrotationfront'].wheel1))
				SetVehicleWheelYRotation(v.entity,2,tonumber(v['wheelsetting']['wheelrotationrear'].wheel2))
				SetVehicleWheelYRotation(v.entity,3,tonumber(v['wheelsetting']['wheelrotationrear'].wheel3))
			end
			if not exist then
				if vehiclesinarea[v.plate] then vehiclesinarea[v.plate] = nil end
				if cachedata[i] then cachedata[i] = nil end
			end
		end
		Wait(sleep)
	end
end)

--- Cache
lib.onCache('vehicle', function(value)
    if inZone.status then
		local drawtext = Config.StanceLocations[inZone.index].drawtext
        local text = value and drawtext.inveh or drawtext.outveh
        Utils.drawtext("show", text)
    end
end)

--- Export
exports('OpenStancer', function()
	return OpenStancer()
end)

exports('SetWheelOffsetRear', function(vehicle, val)
	return SetWheelOffsetRear(vehicle, val)
end)

exports('SetWheelOffsetFront', function(vehicle, val)
	return SetWheelOffsetFront(vehicle, val)
end)

--- Event
RegisterNetEvent("an-stancer:airsuspension")
AddEventHandler("an-stancer:airsuspension", function(vehicle, val, coords)
	local v = NetToVeh(vehicle)
	CreateThread(function()
		Wait(math.random(1,500))
		if v ~= 0 and #(coords - GetEntityCoords(cache.ped)) < 50 and not busyplate[plate] then
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
			local plate2 = string.gsub(GetVehicleNumberPlateText(v), '^%s*(.-)%s*$', '%1')

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
	end)
end)

RegisterNetEvent("an-stancer:addstancerkit", function()
	if cache.vehicle then
		if Progress.Start({
			label = "Installing The stancerkit",
			duration = 5000,
			disable = {
				move = true,
				car = true,
				combat = true
			},
			anim = {
				dict = "mini@repair",
				clip = "fixing_a_player",
				flag = 49
			}
		}) then
			TriggerServerEvent("an-stancer:server:removestancer")
			Utils.Notify("Stancer Installed", "success")
			ClearPedTasks(cache.ped)
		else
			Utils.Notify("Failed..", "error")
		end
	else
		Utils.Notify("You are not in a vehicle.", "error")
	end
end)