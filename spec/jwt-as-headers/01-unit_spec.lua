local PLUGIN_NAME = "jwt-as-headers"


-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end


describe(PLUGIN_NAME .. ": (schema)", function() 
  it("accepts custom header name containing JWT token", function()
    local ok, err = validate({
      token_header_name = "X-Custom-Header"
    })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)


  it("does not accept invalid custom header name containing JWT token", function()
    local ok, err = validate({
      token_header_name = "Ф"
    })
    assert.is_same({
      ["config"] = {
        ["token_header_name"] = "bad header name 'Ф', allowed characters are A-Z, a-z, 0-9, '_', and '-'"
      }
    }, err)
    assert.is_falsy(ok)
  end)
 
 
  it("accepts non empty prefix for generated headers", function()
    local ok, err = validate({
      generated_header_prefix = "X-Pref"
    })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)

  
  it("does not accept empty prefix for generated headers", function()
    local ok, err = validate({
      generated_header_prefix = " 	"
    })
    assert.is_same({
      ["config"] = {
        ["generated_header_prefix"] = "invalid value:  	"
      }
    }, err)
    assert.is_falsy(ok)
  end)
end)