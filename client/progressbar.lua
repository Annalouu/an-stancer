local Progress = {}
local ProgressActive = false
local ProgressType = require "config".client.progressbar

---@param pData table
function Progress.Start ( pData )

    local success = promise.new()
    ProgressActive = true
    
    if ProgressType == "ox" then
        local oxProp = {}
        if pData.prop and pData.prop.one then
            oxProp[#oxProp+1] = {
                model = pData.prop.one?.model,
                bone = pData.prop.one?.bone,
                pos = pData.prop.one?.coords,
                rot = pData.prop.one?.rotation
            }
        end

        if pData.prop and pData.prop.two then
            oxProp[#oxProp+1] = {
                model = pData.prop.two?.model,
                bone = pData.prop.two?.bone,
                pos = pData.prop.two?.coords,
                rot = pData.prop.two?.rotation
            }
        end

        if lib.progressBar({
            duration = pData.duration,
            label = pData.label,
            useWhileDead = pData.useWhileDead,
            canCancel = pData.canCancel,
            disable = pData.disable,
            anim = pData.anim,
            prop = oxProp,
        }) then
            success:resolve(true) ProgressActive = false
        else
            success:resolve(false) ProgressActive = false
        end
    elseif ProgressType == "qb" then
        local QBCore = exports['qb-core']:GetCoreObject()

        local Action = {
            name = "rhd_lib:qb_progressbar",
            duration = pData.duration,
            label = pData.label,
            useWhileDead = pData.useWhileDead,
            canCancel = pData.useWhileDead,
            controlDisables = {
                disableMovement = pData.disable?.move,
                disableCarMovement = pData.disable?.car,
                disableMouse = pData.disable?.mouse,
                disableCombat = pData.disable?.combat,
            },
            animation = {
                animDict = pData.anim?.dict,
                anim = pData.anim?.clip,
                flags = pData.anim?.flag,
            },
            prop = {
                model = pData.prop and pData.prop.one?.model,
                bone = pData.prop and pData.prop.one?.bone,
                coords = pData.prop and pData.prop.one?.coords,
                rotation = pData.prop and pData.prop.one?.rotation,
            },
            propTwo = {
                model = pData.prop and pData.prop.two?.model,
                bone = pData.prop and pData.prop.two?.bone,
                coords = pData.prop and pData.prop.two?.coords,
                rotation = pData.prop and pData.prop.two?.rotation,
            },
        }
        
        QBCore.Functions.Progressbar(Action.name, Action.label, Action.duration, Action.useWhileDead, Action.canCancel, Action.controlDisables, Action.animation, Action.prop, Action.propTwo, function()
            success:resolve(true) ProgressActive = false
            end, function()
            success:resolve(false) ProgressActive = false
        end)
    elseif ProgressType == "refine-radialbar" then
        exports['refine-radialbar']:Custom({
            canCancel = pData.canCancel,
            deadCancel = pData.useWhileDead,
            Duration = pData.duration,
            Label = pData.label,
            Animation = {
                animDict = pData.anim?.dict,
                anim = pData.anim?.clip,
                flags = pData.anim?.flag,
            },
            PropAttach = {
                model = pData.prop and pData.prop.one?.model,
                bone = pData.prop and pData.prop.one?.bone,
                coords = pData.prop and pData.prop.one?.coords,
                rotation = pData.prop and pData.prop.one?.rotation,
                modeltwo = pData.prop and pData.prop.two?.model,
                bonetwo = pData.prop and pData.prop.two?.bone,
                coordstwo = pData.prop and pData.prop.two?.coords,
                rotationtwo = pData.prop and pData.prop.two?.rotation,
            },
            DisableControls = {
                disableMovement = pData.disable?.move,
                disableCarMovement = pData.disable?.car,
                disableMouse = pData.disable?.mouse,
                disableCombat = pData.disable?.combat,
            },
            onComplete = function(cancelled)
                success:resolve(not cancelled) ProgressActive = false
            end
        })
    end

    return Citizen.Await(success)
end

Progress.IsActive = function ()
    return ProgressActive
end

return Progress
