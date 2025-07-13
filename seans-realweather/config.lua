Config = {}

Config.ApiKey = 'YOUR API KEY HERE'
Config.City = 'Los Angeles'
Config.CountryCode = 'US'
Config.UpdateInterval = 60    -- 1 minute
Config.RealWeather = true      -- start enabled
Config.UseFahrenheit = true   -- default unit
Config.RestartTimesLocal = {
    { hour = 11, minute = 30},
    { hour = 18, minute = 0},
    { hour = 22, minute = 30},
}
Config.DisableWeatherBeforeStormMinutes = 10
