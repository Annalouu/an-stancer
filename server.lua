local QBCore = exports['qb-core']:GetCoreObject()
RegisterUsableItem = nil
stancer = {}

RegisterServerEvent("an-stancer:server:removeItem", function() 
  local Player = QBCore.Functions.GetPlayer(source)
  Player.Functions.RemoveItem("stancerkit", 1, false)
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

QBCore.Functions.CreateUseableItem("stancerkit", function(source, item)   
  local Player = QBCore.Functions.GetPlayer(source)
  if Player.Functions.GetItemBySlot(item.slot) ~= nil then 
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