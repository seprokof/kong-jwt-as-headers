-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")

---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
---------------------------------------------------------------------------------------------

local jwt_as_headers = {
  PRIORITY = 10,
  VERSION = "0.0.1",
}

local jwt_parser = require "kong.plugins.jwt.jwt_parser"


-- do initialization here, any module level code runs in the 'init_by_lua_block',
-- before worker processes are forked. So anything you add here will run once,
-- but be available in all workers.



-- handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'
function jwt_as_headers:init_worker()

  -- your custom code here
  kong.log.info("saying hi from the 'init_worker' handler")

end --]]



--[[ runs in the 'ssl_certificate_by_lua_block'
-- IMPORTANT: during the `certificate` phase neither `route`, `service`, nor `consumer`
-- will have been identified, hence this handler will only be executed if the plugin is
-- configured as a global plugin!
function plugin:certificate(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'certificate' handler")

end --]]



--[[ runs in the 'rewrite_by_lua_block'
-- IMPORTANT: during the `rewrite` phase neither `route`, `service`, nor `consumer`
-- will have been identified, hence this handler will only be executed if the plugin is
-- configured as a global plugin!
function plugin:rewrite(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'rewrite' handler")

end --]]



-- runs in the 'access_by_lua_block'
function jwt_as_headers:access(plugin_conf)
  kong.log.info("1saying hi from the 'access' handler")

  -- your custom code here
  -- kong.log.inspect(plugin_conf)

  local token = kong.request.get_headers()["X-Access-Token"]
  kong.log.debug("token = "..token)
  local jwt, err = jwt_parser:new(token)
  if err then
    kong.log.error("Error on parsing JWT token")
  end
  
  for c_key,c_value in pairs(jwt.claims) do
    write("Claim-"..capitalize_first(c_key), c_value)
  end
end --]]

function capitalize_first(str)
    return (str:gsub("^%l", string.upper))
end


function write(key, val)
  kong.log.info("write# key=", key, " value=", val)
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


-- runs in the 'header_filter_by_lua_block'
function jwt_as_headers:header_filter(plugin_conf)

  -- your custom code here, for example;
  kong.response.set_header(plugin_conf.response_header, "this is on the response")

end --]]


--[[ runs in the 'body_filter_by_lua_block'
function plugin:body_filter(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'body_filter' handler")

end --]]


--[[ runs in the 'log_by_lua_block'
function plugin:log(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'log' handler")

end --]]


-- return our plugin object
return jwt_as_headers
