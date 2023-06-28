local helpers = require "spec.helpers"


local PLUGIN_NAME = "jwt-as-headers"


for _, strategy in helpers.all_strategies() do if strategy ~= "cassandra" then
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy == "off" and "postgres" or strategy, nil, { PLUGIN_NAME })
	  
      -- Creating test routes for default service which will echo the requests
      -- Route with default plugin configuration
      local route1 = bp.routes:insert({
        hosts = { "test1.com" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {},
      }
	  
      -- Route with custom header name containing JWT token
      local route2 = bp.routes:insert({
        hosts = { "test2.com" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route2.id },
        config = { token_header_name = "X-Token" },
      }
	  
      -- Route with custom prefix used to generate headers 
      local route3 = bp.routes:insert({
        hosts = { "test3.com" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route3.id },
        config = { generated_header_prefix = "X-JWT" },
      }
	  
      -- Route with custom header name containing JWT token and custom prefix used to generate headers
      local route4 = bp.routes:insert({
        hosts = { "test4.com" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route4.id },
        config = { token_header_name = "X-Token", generated_header_prefix = "X-JWT" },
      }

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,
        -- write & load declarative config, only if 'strategy=off'
        declarative_config = strategy == "off" and helpers.make_yaml_file() or nil,
      }))
    end)


    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)


    before_each(function()
      client = helpers.proxy_client()
    end)


    after_each(function()
      if client then client:close() end
    end)


    describe("generated headers added only to the request", function()
      it("when default configuration used", function()
        local r = client:get("/request", {
          headers = {
            host = "test1.com",
            Authorization = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2ODMzMzA0NjQsImlhdCI6MTY4MzMzMDE2NCwiYXV0aF90aW1lIjoxNjgzMzMwMTY0LCJqdGkiOiJiZmEyMjE4OC01NzhiLTRiMzYtYjRlYi1hZTY1NjVmZmRlYjYiLCJpc3MiOiJodHRwczovL2F1dGguY29tcGFueS5jb20vcmVhbG1zL2NvbXBhbnkiLCJhdWQiOiJhY2NvdW50Iiwic3ViIjoiNmI5Mzg4NWYtMmNmOS00OWYzLWE2Y2UtODBiYTlkZTgzNDQ1IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoia29uZyIsIm5vbmNlIjoiYWFyMjJ5cWI4MjJiM2UxODRmZGU0MXQzMjYzMGQ0MzUiLCJzZXNzaW9uX3N0YXRlIjoiNmVkZjAyODAtMTYyNC00OWI4LWI5MDItYTRjNThiYzg3OGY4MiIsImFjciI6IjEiLCJhbGxvd2VkLW9yaWdpbnMiOlsiIl0sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJkZWZhdWx0LXJvbGVzLWNvbXBhbnkiLCJvZmZsaW5lX2FjY2VzcyIsInVtYV9hdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJvcGVuaWQgcHJvZmlsZSBlbWFpbCIsInNpZCI6IjZlZGYwMjgwLTE2MjQtNDliOC1iOTAyLWE0YzU4YmM4NzhmODIiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwibmFtZSI6IkpvaG4gRG9lIiwicHJlZmVycmVkX3VzZXJuYW1lIjoiamRvZSIsImdpdmVuX25hbWUiOiJKb2huIiwiZmFtaWx5X25hbWUiOiJEb2UiLCJlbWFpbCI6ImpvaG4uZG9lQGNvbXBhbnkuY29tIn0.SMx4XSHguenlEu1Ew1WkaJZoJ04pWG1-laB5Yj0XMGs",
          }
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
        -- validate that the generated headers added to the request
        assert.equal("1683330464", assert.request(r).has.header("Claim-Exp"))
        assert.equal("1683330164", assert.request(r).has.header("Claim-Iat"))
        assert.equal("1683330164", assert.request(r).has.header("Claim-Auth_time"))
        assert.equal("bfa22188-578b-4b36-b4eb-ae6565ffdeb6", assert.request(r).has.header("Claim-Jti"))
        assert.equal("https://auth.company.com/realms/company", assert.request(r).has.header("Claim-Iss"))
        assert.equal("account", assert.request(r).has.header("Claim-Aud"))
        assert.equal("6b93885f-2cf9-49f3-a6ce-80ba9de83445", assert.request(r).has.header("Claim-Sub"))
        assert.equal("Bearer", assert.request(r).has.header("Claim-Typ"))
        assert.equal("kong", assert.request(r).has.header("Claim-Azp"))
        assert.equal("aar22yqb822b3e184fde41t32630d435", assert.request(r).has.header("Claim-Nonce"))
        assert.equal("6edf0280-1624-49b8-b902-a4c58bc878f82", assert.request(r).has.header("Claim-Session_state"))
        assert.equal("1", assert.request(r).has.header("Claim-Acr"))
        assert.equal("", assert.request(r).has.header("Claim-Allowed-origins"))
        assert.equal("default-roles-company, offline_access, uma_authorization", assert.request(r).has.header("Claim-Realm_access-Roles"))
        assert.equal("manage-account, manage-account-links, view-profile", assert.request(r).has.header("Claim-Resource_access-Account-Roles"))		
        assert.equal("openid profile email", assert.request(r).has.header("Claim-Scope"))
        assert.equal("6edf0280-1624-49b8-b902-a4c58bc878f82", assert.request(r).has.header("Claim-Sid"))
        assert.equal("true", assert.request(r).has.header("Claim-Email_verified"))
        assert.equal("John Doe", assert.request(r).has.header("Claim-Name"))
        assert.equal("jdoe", assert.request(r).has.header("Claim-Preferred_username"))		
        assert.equal("John", assert.request(r).has.header("Claim-Given_name"))
        assert.equal("Doe", assert.request(r).has.header("Claim-Family_name"))
        assert.equal("john.doe@company.com", assert.request(r).has.header("Claim-Email"))
        -- validate that the response does not contain generated headers
        assert.response(r).has_not.header("Claim-Exp")
        assert.response(r).has_not.header("Claim-Iat")
        assert.response(r).has_not.header("Claim-Auth_time")
        assert.response(r).has_not.header("Claim-Jti")
        assert.response(r).has_not.header("Claim-Iss")
        assert.response(r).has_not.header("Claim-Aud")
        assert.response(r).has_not.header("Claim-Sub")
        assert.response(r).has_not.header("Claim-Typ")
        assert.response(r).has_not.header("Claim-Azp")
        assert.response(r).has_not.header("Claim-Nonce")
        assert.response(r).has_not.header("Claim-Session_state")
        assert.response(r).has_not.header("Claim-Acr")
        assert.response(r).has_not.header("Claim-Allowed-origins")
        assert.response(r).has_not.header("Claim-Realm_access-Roles")
        assert.response(r).has_not.header("Claim-Resource_access-Account-Roles")
        assert.response(r).has_not.header("Claim-Scope")
        assert.response(r).has_not.header("Claim-Sid")
        assert.response(r).has_not.header("Claim-Email_verified")
        assert.response(r).has_not.header("Claim-Name")
        assert.response(r).has_not.header("Claim-Preferred_username")
        assert.response(r).has_not.header("Claim-Given_name")
        assert.response(r).has_not.header("Claim-Family_name")
        assert.response(r).has_not.header("Claim-Email")
      end)


      it("when default configuration used without Bearer", function()
        local r = client:get("/request", {
          headers = {
            host = "test1.com",
            Authorization = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
          }
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
        -- validate that the generated headers added to the request
        assert.equal("1234567890", assert.request(r).has.header("Claim-Sub"))
        assert.equal("John Doe", assert.request(r).has.header("Claim-Name"))
        assert.equal("1516239022", assert.request(r).has.header("Claim-Iat"))
        -- validate that the response does not contain generated headers
        assert.response(r).has_not.header("Claim-Sub")
        assert.response(r).has_not.header("Claim-Name")
        assert.response(r).has_not.header("Claim-Iat")
      end)


      it("when custom header contains JWT token", function()
        local r = client:get("/request", {
          headers = {
            host = "test2.com",
            ["X-Token"] = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiZnVsbF9uYW1lIjoiSm9obiBEb2UiLCJyZWFsbSI6ImNvbXBhbnkifQ.z_ykGw27WZyw7SxtUfnqNB9Z9EqU7zlAKdgv5bpzYWU",
          }
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
        -- validate that the generated headers added to the request
        assert.equal("1234567890", assert.request(r).has.header("Claim-Sub"))
        assert.equal("John Doe", assert.request(r).has.header("Claim-Full_name"))
        assert.equal("company", assert.request(r).has.header("Claim-Realm"))
        -- validate that the response does not contain generated headers
        assert.response(r).has_not.header("Claim-Sub")
        assert.response(r).has_not.header("Claim-Full_name")
        assert.response(r).has_not.header("Claim-Realm")
      end)


      it("when custom prefix used for generated headers", function()
        local r = client:get("/request", {
          headers = {
            host = "test3.com",
            Authorization = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjMzMzMzMyIsIm5hbWUiOiJKb2huIERvZSIsImFkbWluIjp0cnVlfQ.YRBmS2GIC5dRuJt_D64UKozfrQGN4hyU6mwVj7VeioU",
          }
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
        -- validate that the generated headers with custom prefix added to the request
        assert.equal("12333333", assert.request(r).has.header("X-JWT-Sub"))
        assert.equal("John Doe", assert.request(r).has.header("X-JWT-Name"))
        assert.equal("true", assert.request(r).has.header("X-JWT-Admin"))
        -- validate that the generated headers with default prefix were not added to the request
        assert.request(r).has_not.header("Claim-Sub")
        assert.request(r).has_not.header("Claim-Name")
        assert.request(r).has_not.header("Claim-Admin")
        -- validate that the response does not contain generated headers with custom prefix
        assert.response(r).has_not.header("X-JWT-Sub")
        assert.response(r).has_not.header("X-JWT-Name")
        assert.response(r).has_not.header("X-JWT-Admin")
        -- validate that the response does not contain generated headers with default prefix
        assert.response(r).has_not.header("Claim-Sub")
        assert.response(r).has_not.header("Claim-Name")
        assert.response(r).has_not.header("Claim-Admin")
      end)


      it("when custom header contains JWT token and custom prefix used for generated headers", function()
        local r = client:get("/request", {
          headers = {
            host = "test4.com",
            ["X-Token"] = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
          }
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
        -- validate that the generated headers with custom prefix added to the request
        assert.equal("1234567890", assert.request(r).has.header("X-JWT-Sub"))
        assert.equal("John Doe", assert.request(r).has.header("X-JWT-Name"))
        assert.equal("1516239022", assert.request(r).has.header("X-JWT-Iat"))
        -- validate that the generated headers with default prefix were not added to the request
        assert.request(r).has_not.header("Claim-Sub")
        assert.request(r).has_not.header("Claim-Name")
        assert.request(r).has_not.header("Claim-Iat")
        -- validate that the response does not contain generated headers with custom prefix
        assert.response(r).has_not.header("X-JWT-Sub")
        assert.response(r).has_not.header("X-JWT-Name")
        assert.response(r).has_not.header("X-JWT-Iat")
        -- validate that the response does not contain generated headers with default prefix
        assert.response(r).has_not.header("Claim-Sub")
        assert.response(r).has_not.header("Claim-Name")
        assert.response(r).has_not.header("Claim-Iat")
      end)
    end)
  end)
end end