local isQB = GetResourceState('qb-core') == "started"

local User = {}
local stancer = {}
local Config = require "config".server

if isQB then
  local QBCore = exports['qb-core']:GetCoreObject()
  User.get = function (source)
      User.PlayerData = User.PlayerData or {}
      if not User.PlayerData[source] then
          User.PlayerData[source] = QBCore.Functions.GetPlayer(source)
      end
      return User.PlayerData[source]
  end
  User.removeItem = function (source, name, amount)
      local Player = User.get(source)
      return Player.Functions.RemoveItem(name, amount)
  end
  User.getItem = function (source, name)
      local Player = User.get(source)
      return Player.Functions.GetItemByName(name)
  end
  User.registerUsableItem = function (item, cb, ...)
      return QBCore.Functions.CreateUseableItem(item, cb)
  end
else
  local ESX = exports["es_extended"]:getSharedObject()
  User.get = function (source)
      User.PlayerData = User.PlayerData or {}
      if not User.PlayerData[source] then
          User.PlayerData[source] = ESX.GetPlayerFromId(source)
      end
      return User.PlayerData[source]
  end
  User.removeItem = function (source, name, amount)
      local Player = User.get(source)
      if Player.getInventoryItem(name).count >= amount then
          Player.removeInventoryItem(name, amount)
          return true
      end
      return false
  end
  User.getItem = function (source, name)
      local Player = User.get(source)
      if Player.getInventoryItem(name).count >= 1 then
        return true
      end
      return false
  end
  
  User.registerUsableItem = function (item, cb, ...)
      return ESX.RegisterUsableItem(item, cb)
  end
end

RegisterServerEvent("an-stancer:server:removestancer", function() 
  User.removeItem(source, "stancerkit", 1)
end)

Citizen.CreateThread(function()
  local ret = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM an_stancer', {})
  for k, v in pairs(ret) do
    if stancer[v.plate] == nil then stancer[v.plate] = {} end
    stancer[v.plate].plate = v.plate
    stancer[v.plate].stancer = json.decode(v.setting)
    stancer[v.plate].online = false
  end
  for k, v in ipairs(GetAllVehicles()) do
    local plate = GetVehicleNumberPlateText(v)
    if stancer[plate] and plate == stancer[plate].plate then
      if stancer[plate].stancer then
        local ent = Entity(v).state
        ent.stancer = stancer[plate].stancer
        ent.online = true
      end
    end
  end
end)

User.registerUsableItem('stancerkit', function (source)
    if User.getItem(source, "stancerkit") then
        TriggerClientEvent("an-stancer:addstancerkit", source)
        local veh = GetVehiclePedIsIn(GetPlayerPed(source), false)
        if veh ~= 0 then
          AddStancerKit(veh)
        end
    end
end)

function SaveStancer(ob)
    local plate = string.gsub(ob.plate, '^%s*(.-)%s*$', '%1')
    local result = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM an_stancer WHERE TRIM(plate) = @plate', {['@plate'] = plate})
    if result[1] == nil then
        SqlFunc(Config.Mysql,'execute','INSERT INTO an_stancer (plate, setting) VALUES (@plate, @stancer)', {
            ['@plate']   = ob.plate,
            ['@stancer']   = '[]',
        })
    elseif result[1] then
        SqlFunc(Config.Mysql,'execute','UPDATE an_stancer SET setting = @setting WHERE TRIM(plate) = @plate', {
          ['@plate']   = plate,
          ['@setting']   = json.encode(ob.setting),
        })
    end
    print('saved')
end

function firstToUpper(str)
  return (str:gsub("^%l", string.upper))
end

function AddStancerKit(veh)
  local veh = veh
  if veh == nil then veh = GetVehiclePedIsIn(GetPlayerPed(source),false) end
  plate = GetVehicleNumberPlateText(veh)
  if not stancer[plate] then
    stancer[plate] = {}
    local ent = Entity(veh).state
    if not ent.stancer then
      stancer[plate].stancer = {}
      stancer[plate].plate = plate
      stancer[plate].online = true
      ent.stancer = stancer[plate]
      SaveStancer({plate = plate, setting = {}})
    end
  end
end

exports('AddStancerKit', function(veh)
  return AddStancerKit(veh)
end)

AddEventHandler('entityCreated', function(entity)
  local entity = entity
  Wait(4000)
  if DoesEntityExist(entity) and GetEntityPopulationType(entity) == 7 and GetEntityType(entity) == 2 then
    local plate = GetVehicleNumberPlateText(entity)
    if stancer[plate] and stancer[plate].stancer then
      local ent = Entity(entity).state
      ent.stancer = stancer[plate].stancer
      stancer[plate].online = true
    end
  end
end)

AddEventHandler('entityRemoved', function(entity)
  local entity = entity
  if DoesEntityExist(entity) and GetEntityPopulationType(entity) == 7 and GetEntityType(entity) == 2 then
    local ent = Entity(entity).state
    if ent.stancer then
      local plate = GetVehicleNumberPlateText(entity)
      stancer[plate].online = false
      stancer[plate].stancer = ent.stancer
      SaveStancer({plate = plate, setting = stancer[plate].stancer})
    end
  end
end)

RegisterNetEvent("an-stancer:airsuspension")
AddEventHandler("an-stancer:airsuspension", function(entity,val,coords)
	TriggerClientEvent("an-stancer:airsuspension", -1, entity,val,coords)
end)

function SqlFunc(plugin,type,query,var)
	local wait = promise.new()
    if type == 'execute' and plugin == Config.Mysql then
        exports[Config.Mysql]:execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'fetchAll' and plugin == Config.Mysql then
		exports[Config.Mysql]:fetch(query, var, function(result)
			wait:resolve(result)
		end)
    end
	return Citizen.Await(wait)
end