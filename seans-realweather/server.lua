local QBCore = exports['qb-core']:GetCoreObject()
local apiKey = Config.ApiKey
local isRealWeatherEnabled = Config.RealWeather
local useFahrenheit = Config.UseFahrenheit

local validWeathers = {
    clear = "Clear sky, sunny weather.",
    extrasunny = "Very clear and bright sunny weather.",
    clouds = "Partly cloudy skies.",
    overcast = "Cloudy and gray sky.",
    rain = "Rainy weather with wet roads.",
    clearing = "Rain clearing up, clouds breaking.",
    thunder = "Thunderstorms with heavy rain.",
    smog = "Low visibility due to smog.",
    foggy = "Fog reducing visibility.",
    snowlight = "Light snow falling.",
    snow = "Moderate snow weather.",
    blizzard = "Heavy snowstorm with blizzard conditions."
}

local function notifyPlayer(src, message, type, length)
    TriggerClientEvent('QBCore:Notify', src, message, type or 'primary', length or 10000)
end

local function mapOpenWeatherToFiveM(weatherMain, weatherDesc)
    weatherMain = weatherMain:lower()
    weatherDesc = weatherDesc:lower()

    if weatherMain:find("clear") then
        return "extrasunny"
    elseif weatherMain:find("cloud") then
        if weatherDesc:find("few") or weatherDesc:find("scattered") then
            return "clouds"
        else
            return "overcast"
        end
    elseif weatherMain:find("rain") then
        if weatherDesc:find("thunder") then
            return "thunder"
        elseif weatherDesc:find("light") or weatherDesc:find("drizzle") then
            return "clearing"
        else
            return "rain"
        end
    elseif weatherMain:find("thunder") then
        return "thunder"
    elseif weatherMain:find("fog") or weatherMain:find("mist") or weatherMain:find("haze") then
        return "foggy"
    elseif weatherMain:find("smoke") or weatherMain:find("smog") then
        return "smog"
    elseif weatherMain:find("snow") or weatherMain:find("sleet") then
        if weatherDesc:find("light") then
            return "snowlight"
        elseif weatherDesc:find("blizzard") then
            return "blizzard"
        else
            return "snow"
        end
    else
        return "clear"
    end
end

local function fetchWeather()
    if not isRealWeatherEnabled then return end

    local units = useFahrenheit and 'imperial' or 'metric'
    local url = string.format(
        'http://api.openweathermap.org/data/2.5/weather?q=%s,%s&appid=%s&units=%s',
        Config.City:gsub(' ', '%%20'),
        Config.CountryCode,
        apiKey,
        units
    )

    PerformHttpRequest(url, function(status, response)
        if status == 200 and response then
            local data = json.decode(response)
            if data and data.weather and data.main then
                local weatherDesc = data.weather[1].description
                local temperature = data.main.temp
                local gtaWeather = mapOpenWeatherToFiveM(data.weather[1].main, weatherDesc)

                TriggerClientEvent('rw:setWeather', -1, gtaWeather)
                TriggerClientEvent('rw:updateWeatherInfo', -1, {
                    temp = temperature,
                    desc = weatherDesc,
                    gta = gtaWeather,
                    unit = useFahrenheit and "F" or "C"
                })

                print(('[RealWeather] Updated: %s°%s | %s | GTA: %s'):format(
                    tostring(temperature), useFahrenheit and "F" or "C", weatherDesc, gtaWeather))
            else
                print("[RealWeather] Failed to parse API data.")
            end
        else
            print("[RealWeather] API request failed. Status: " .. tostring(status))
        end
    end, 'GET', '', { ['Content-Type'] = 'application/json' })
end

Citizen.CreateThread(function()
    while true do
        fetchWeather()
        Citizen.Wait(Config.UpdateInterval * 1000)
    end
end)

RegisterCommand('realweather', function(source, args)
    local src, sub = source, args[1]
    if not sub then
        notifyPlayer(src, '/realweather [on/off]', 'primary')
        return
    end
    if sub == 'on' then
        isRealWeatherEnabled = true
        TriggerClientEvent('rw:disableManualWeather', -1)
        notifyPlayer(src, 'Real-world weather enabled.', 'success')
        fetchWeather()
    elseif sub == 'off' then
        isRealWeatherEnabled = false
        notifyPlayer(src, 'Real-world weather disabled. Use /weather to set manually.', 'success')
    else
        notifyPlayer(src, '/realweather [on/off]', 'primary')
    end
end, true)

RegisterCommand('weather', function(source, args)
    local src, sub = source, args[1]
    if not sub then
        notifyPlayer(src, 'Usage: /weather [option] or /weather help', 'primary')
        return
    end
    sub = sub:lower()
    if sub == "help" then
        notifyPlayer(src, "Available weather types:", 'primary', 15000)
        for k,v in pairs(validWeathers) do
            notifyPlayer(src, string.format("- %s: %s", k, v), 'primary', 15000)
            Citizen.Wait(50)
        end
        return
    end
    if not validWeathers[sub] then
        notifyPlayer(src, 'The weather option you selected does not exist! Use /weather help.', 'error')
        return
    end
    isRealWeatherEnabled = false
    TriggerClientEvent('rw:enableManualWeather', -1, sub:upper())
    notifyPlayer(src, 'Weather manually set to: '..sub, 'success')
end, true)

RegisterNetEvent('rw:toggleUnit')
AddEventHandler('rw:toggleUnit', function()
    local src = source
    useFahrenheit = not useFahrenheit
    notifyPlayer(src, 'Unit now: ' .. (useFahrenheit and "Fahrenheit" or "Celsius"), 'success')
    fetchWeather()
end)
