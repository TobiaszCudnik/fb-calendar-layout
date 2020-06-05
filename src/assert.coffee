# Why? Because browserify ignores requires to assert with "--no-builtins"
# Not cool...

assert = (value, msg) ->
  throw new Error msg if not value

module.exports = assert
