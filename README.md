[![Unix build](https://img.shields.io/github/actions/workflow/status/seprokof/kong-jwt-as-headers/test.yml?branch=master&label=Test&logo=linux)](https://github.com/seprokof/kong-jwt-as-headers/actions/workflows/test.yml)
[![Luacheck](https://github.com/seprokof/kong-jwt-as-headers/workflows/Lint/badge.svg)](https://github.com/seprokof/kong-jwt-as-headers/actions/workflows/lint.yml)

# kong-plugin-jwt-as-headers

Exposes JWT claims as HTTP headers attached to request.

## Configuration

Parameter|Default|Description
---|---|---
`token_header_name`|`Authorization`|The name of request's HTTP header containing JWT token.
`generated_header_prefix`|`Claim`|Prefix for the names of generated headers.