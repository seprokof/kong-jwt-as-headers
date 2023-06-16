local JwtAsHeaders = {
  PRIORITY = 10,
  VERSION = "1.0.0",
}

local jwt_parser = require "kong.plugins.jwt.jwt_parser"

function JwtAsHeaders:access(plugin_conf)
  local header_value = kong.request.get_headers()[plugin_conf.token_header_name]
  if header_value then
    local token = header_value:gsub("^[Bb]earer ", "", 1)
    local jwt, err = jwt_parser:new(token)
    if err then
      kong.log.error(err)
      return
    end
    for c_key,c_value in pairs(jwt.claims) do
      write(plugin_conf.generated_header_prefix.."-"..capitalize_first(c_key), c_value)
    end
  end
end

function capitalize_first(str)
  return (str:gsub("^%l", string.upper))
end

function write(key, val)
  if type(val) == "table" then
    if is_array(val) then
      write(key, table.concat(val, ", "))
    else
      for k, v in pairs(val) do
        write(key.."-"..capitalize_first(k), v)
      end
    end
  else
    kong.service.request.set_header(key, val)
  end
end

function is_array(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then return false end
  end
  return true
end

return JwtAsHeaders