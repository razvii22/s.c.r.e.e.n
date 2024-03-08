local ratu = require("ratu")
local spk = peripheral.find("speaker")
local mon = peripheral.find("monitor")
local oauthToken = settings.get("oauthToken")
local refreshToken = settings.get("refreshToken", nil)
local clientID = settings.get("clientID", nil)
local clientSecret = settings.get("clientSecret", nil)
local redirectURI = settings.get("redirectURI", nil)
local applicationCode = settings.get("applicationCode", nil)

if (not clientID) then
  ratu.lenghtwisePrint("&e> No client ID provided, please set using &0\"set clientID\"", nil, 10, spk, true)
  error()
end

if (not clientSecret) then
  ratu.lenghtwisePrint("&e> No client secret provided, please set using &0\"set clientSecret\"", nil, 10, spk, true)
  error()
end

if (not redirectURI) then
  ratu.lenghtwisePrint("&e> No redirect URI provided, please set using &0\"set redirectURI\"", nil, 10, spk, true)
  error()
end
if (not oauthToken) and (not applicationCode) then
  ratu.lenghtwisePrint("&e> No oauth token token, either provide one, or provide the &0application code&e below:", nil,
    10, spk, true)
  ratu.lenghtwisePrint("&d>&0 ", nil, 10, nil, false)
  applicationCode = read()
end

if (not oauthToken) and applicationCode then
  local request = {}
  request.url = "https://id.twitch.tv/oauth2/token"
  request.body = "client_id=" .. clientID ..
      "&client_secret=" .. clientSecret ..
      "&code=" .. applicationCode ..
      "&grant_type=authorization_code" ..
      "&redirect_uri=" .. redirectURI

  local response = { http.post(request) }

  if not response[1] then
    local reply = textutils.unserialiseJSON(response[3].readAll()) or {}
    ratu.lenghtwisePrint("&e> Server replied with " .. response[2], nil, 10, spk, true)
    ratu.lenghtwisePrint(reply.message, nil, 10, nil, true)
    ratu.lenghtwisePrint(reply.status, nil, 10, nil, true)
    error()
  end

  if response[1] then
    print("success")
    local reply = textutils.unserialiseJSON(response[1].readAll() or "") or {}
    settings.set("oauthToken", reply.access_token)
    print(reply.access_token)
    settings.set("refreshToken", reply.refresh_token)
    print(reply.refresh_token)
    settings.save()
  end
end

local function queryTwitch()
  local width, height = term.getSize()
  local request = {}
  request.url = "https://api.twitch.tv/helix/channels/followers?broadcaster_id=178331774&first=1"
  request.headers = {
    ["Authorization"] = "Bearer " .. oauthToken,
    ["Client-Id"] = clientID
  }
  local reply = { http.get(request) }

  if reply[1] then
    local reply = textutils.unserialiseJSON(reply[1].readAll()) or {}
    ratu.printCentered("&aFollowers:", width/2, 1, nil)
    ratu.printCentered("&0"..reply.total, width/2 ,2, true)
    ratu.printCentered("&a".."Latest:", width/2, 3, nil)
    ratu.printCentered("&0"..reply.data[1].user_name, width/2, 4, true)

    ratu.printCentered("&eSubscribers:", width/2, 6, nil)
    ratu.printCentered("&0"..reply.total, width/2 ,7, nil)
  end

  if reply[3] then
    local reply = textutils.unserialiseJSON(reply[3].readAll()) or {}
    if not reply.status then return end
    if reply.status ~= 401 then return end
    print("Trying to refresh token...")
    local request = {}
    request.url = "https://id.twitch.tv/oauth2/token"
    request.body = "client_id=" .. clientID ..
        "&client_secret=" .. clientSecret ..
        "&grant_type=refresh_token"..
        "&refresh_token="..textutils.urlEncode(refreshToken)
    
    local response = {http.post(request)}
    if response[1] then
        local info = response[1].readAll()
        local info, error = textutils.unserialiseJSON(info)

        if info and info.access_token then
          settings.set("oauthToken", info.access_token)
          settings.set("refreshToken", info.refresh_token)
          settings.save()
        end
    end
  end
end

term.redirect(mon)
term.clear()

while true do
  mon.setTextScale(5)
  queryTwitch()

  sleep(30)
end
