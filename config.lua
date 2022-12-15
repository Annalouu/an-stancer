Config = {}

Config.Mysql = 'oxmysql' -- mysql-async, ghmattisql, oxmysql
Config.FixedCamera = true

Config.DrawText = "qb-core" -- Define the export resource accordingly | qb-core, qb-drawtext

Config.StanceLocations = {
  ["customsMain"] = { -- THis name should be unique no duplicates
    ["coords"] = vector3(-325.6, -138.89, 39.02), -- The coords of the zone
    ["size"] = 3.0, -- How big is the zone?
    ["heading"] = 0.0, -- Heading
    ["debug"] = false, -- Should zone be debugged?
    ["inVehicle"] = "Press E for the Stancer", -- The name if a user is in a vehicle
    ["outVehicle"] = "You need to be in a vehicle!", -- Message if user is not in a vehicle
  },
  ["tunershop"] = { -- THis name should be unique no duplicates
    ["coords"] = vector3(125.23, -3040.95, 7.04), -- The coords of the zone
    ["size"] = 3.0, -- How big is the zone?
    ["heading"] = 0.0, -- Heading
    ["debug"] = false, -- Should zone be debugged?
    ["inVehicle"] = "Press E for the Stancer", -- The name if a user is in a vehicle
    ["outVehicle"] = "You need to be in a vehicle!", -- Message if user is not in a vehicle
  },
}