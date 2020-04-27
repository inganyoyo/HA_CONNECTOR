--[[
HA_CONNECTOR by SuSuDaddy
Latest : 2020.03.30
[TYPE]
- ON_OFF: 일반 스위치 타입
- FAN_SPEED: SPEED를 가진 FAN_RS485 
- COVER_POSISION: 블라인드, 커튼
- AIR_CONDITIONER: 에어컨
]]
_APP = {version = "v0.1", name = "HA_CONNECTOR", logLevel = "debug"}
_DEVICE = {
  {DEVICE_ID = 107, ENTITY_ID = "light.kocom_livingroom_light1", TYPE = "ON_OFF"},
  {DEVICE_ID = 110, ENTITY_ID = "light.kocom_livingroom_light2", TYPE = "ON_OFF"},
  {DEVICE_ID = 111, ENTITY_ID = "light.kocom_livingroom_light3", TYPE = "ON_OFF"},
  {DEVICE_ID = 112, ENTITY_ID = "switch.kocom_wallpad_elevator", TYPE = "ON_OFF"},
  {DEVICE_ID = 114, ENTITY_ID = "fan.kocom_wallpad_fan", TYPE = "FAN_SPEED"},
  {DEVICE_ID = 116, ENTITY_ID = "cover.0x04cf8cdf3c73b9a7_cover", TYPE = "COVER_POSITION"},
  {DEVICE_ID = 127, ENTITY_ID = "switch.geosil_gonggiceongjeonggi", TYPE = "ON_OFF"},
  {DEVICE_ID = 129, ENTITY_ID = "binary_sensor.0x286d9700010a73b8_occupancy", TYPE = "ON_OFF"},
  {DEVICE_ID = 149, ENTITY_ID = "climate.seojae_eeokeon", TYPE = "CLIMATE"},
  {DEVICE_ID = 150, ENTITY_ID = "climate.anbang_eeokeon", TYPE = "CLIMATE"},
  {DEVICE_ID = 151, ENTITY_ID = "climate.geosil_eeokeon", TYPE = "CLIMATE"},
  {DEVICE_ID = 152, ENTITY_ID = "climate.nolibang_eeokeon", TYPE = "CLIMATE"},
  {DEVICE_ID = 153, ENTITY_ID = "climate.suminbang_eeokeon", TYPE = "CLIMATE"},
  {DEVICE_ID = 186, ENTITY_ID = "climate.kocom_room4_thermostat", TYPE = "CLIMATE"},
  {DEVICE_ID = 187, ENTITY_ID = "climate.kocom_livingroom_thermostat", TYPE = "CLIMATE"},
  {DEVICE_ID = 188, ENTITY_ID = "climate.kocom_room1_thermostat", TYPE = "CLIMATE"},
  {DEVICE_ID = 189, ENTITY_ID = "climate.kocom_room2_thermostat", TYPE = "CLIMATE"},
  {DEVICE_ID = 190, ENTITY_ID = "climate.kocom_room3_thermostat", TYPE = "CLIMATE"}
}

function QuickApp:setStateJson(entity_id, nJson, oJson)
  entity_id = nJson.entity_id
  for i = 1, #_DEVICE do
    if _DEVICE[i].ENTITY_ID == entity_id then
      if _DEVICE[i].TYPE == "FAN_SPEED" then
        self:setFanSpeed(_DEVICE[i].DEVICE_ID, nJson, oJson)
      elseif _DEVICE[i].TYPE == "ON_OFF" then
        self:setStateOnOff(_DEVICE[i].DEVICE_ID, nJson, oJson)
      elseif _DEVICE[i].TYPE == "COVER_POSITION" then
        self:setCoverPostion(_DEVICE[i].DEVICE_ID, nJson, oJson)
      elseif _DEVICE[i].TYPE == "CLIMATE" then
        self:setClimate(_DEVICE[i].DEVICE_ID, nJson, oJson)
      end
    end
  end
end

function QuickApp:setStateOnOff(deviceId, nJson, oJson)
  if nJson.state == oJson.state then
    return
  end
  local value = nJson.state
  local state = nil
  if value == "on" then
    state = true
  else
    state = false
  end
  fibaro.call(deviceId, "setState", state)
end

function QuickApp:setClimate(deviceId, nJson, oJson)
  Log(LOG.ULOG, "DEVICE_ID %s", deviceId)
  fibaro.call(deviceId, "setState", nJson, oJson)
end

function QuickApp:setCoverPostion(deviceId, nJson, oJson)
  if nJson.attributes.position == nil and nJson.attributes.current_position ~= nil then
    if nJson.attributes.running == false then
      fibaro.call(deviceId, "setState", nJson.attributes.current_position)
    end
  else
    if nJson.attributes.position == 255 then
      return
    end
    --current_position
    self:debug("nJson.attributes.position" .. nJson.attributes.position)
    self:debug("oJson.attributes.position" .. oJson.attributes.position)
    if nJson.attributes.running == false then
      fibaro.call(deviceId, "setState", nJson.attributes.position)
    end
  end
end

function QuickApp:setFanSpeed(deviceId, nJson, oJson)
  if nJson.attributes.speed == oJson.attributes.speed then
    return
  end
  fibaro.call(deviceId, "setState", nJson.attributes.speed)
end

function QuickApp:turnOn()
  for i = 1, #_DEVICE do
    fibaro.call(_DEVICE[i].DEVICE_ID, "getState")
  end
  self:updateProperty("log", "" .. os.date("%m-%d %X"))
  self:updateProperty("value", true)
  fibaro.sleep(2000)
  self:turnOff()
end

function QuickApp:turnOff()
  self:updateProperty("value", false)
end

function QuickApp:onInit()
  Utilities(self)
  quickSelf = self
  Logging(LOG.sys, "VERSION: %s, APP: %s", _APP.version, _APP.name)
  for i = 1, #_DEVICE do
    Logging(LOG.sys, "device info %s", _DEVICE[i])
  end
  self:turnOff()
end

--[[
  Utilities 
]]
function Utilities()
  logLevel = {trace = 1, debug = 2, warning = 3, error = 4}
  LOG = {debug = "debug", warning = "warning", trace = "trace", error = "error", sys = "sys"}
  function Logging(tp, ...)
    if tp == "debug" then
      if logLevel[_APP.logLevel] <= logLevel.debug then
        quickSelf:debug(string.format(...))
      end
    elseif tp == "warning" then
      if logLevel[_APP.logLevel] <= logLevel.warning then
        quickSelf:warning(string.format(...))
      end
    elseif tp == "trace" then
      if logLevel[_APP.logLevel] <= logLevel.trace then
        quickSelf:trace(string.format(...))
      end
    elseif tp == "error" then
      if logLevel[_APP.logLevel] <= logLevel.error then
        quickSelf:error(string.format(...))
      end
    elseif tp == "sys" then
      quickSelf:debug("[SYS]" .. string.format(...))
    end
  end
  local oldtostring, oldformat = tostring, string.format -- redefine format and tostring
  tostring = function(o)
    if type(o) == "table" then
      if o.__tostring and type(o.__tostring) == "function" then
        return o.__tostring(o)
      else
        return json.encode(o)
      end
    else
      return oldtostring(o)
    end
  end
  string.format = function(...) -- New format that uses our tostring
    local args = {...}
    for i = 1, #args do
      if type(args[i]) == "table" then
        args[i] = tostring(args[i])
      end
    end
    return #args > 1 and oldformat(table.unpack(args)) or args[1]
  end
  format = string.format

  function split(s, sep)
    local fields = {}
    sep = sep or " "
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(
      s,
      pattern,
      function(c)
        fields[#fields + 1] = c
      end
    )
    return fields
  end
end

if dofile then
  hc3_emulator.start {
    --id = 249,
    name = "HA_CONNECTOR", -- Name of QA
    type = "com.fibaro.binarySwitch",
    proxy = true,
    poll = 2000 -- Poll HC3 for triggers every 2000ms
  }
  hc3_emulator.offline = true
end
