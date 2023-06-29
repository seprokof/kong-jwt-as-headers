local typedefs = require "kong.db.schema.typedefs"


return {
  name = "jwt-as-headers",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { token_header_name = typedefs.header_name { required = true, default = "Authorization" } },
          { generated_header_prefix = { type = "string", required = true, default = "Claim", not_match = "%s+" } }, 
        },
      },
    },
  },
}
