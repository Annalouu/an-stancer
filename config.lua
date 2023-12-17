return {
    utils = {
        drawtext = function (text, type)
            if type == "show" then
                lib.showTextUI(text)
            else
                lib.hideTextUI()
            end
        end,
        Notify = function (msg, type, duration)
            lib.notify({
                description = msg,
                type = type,
                duration = duration
            })
        end
    },
    client = {
        FixedCamera = true,
        StanceLocations = {
            {
                coords = vec3(1127.5533, 2648.6147, 37.9965),
                size = 3.0,
                debug = true,
                drawtext = {
                    inveh = "Press E for the Stancer",
                    outveh = "You need to be in a vehicle!"
                }

            }
        },
        progressbar = "ox" --- qb / ox / refine-radialbar
    },
    server = {
        Mysql = "oxmysql"
    }
}