require('guts.base')
require('guts.highlights')
require('guts.maps')
require('guts.plugins')
require('guts.bootstrap')
require('guts.diagnostics')
require('guts.completions')

local has = vim.fn.has
local is_mac = has "macunix"
local is_unix = has "unix"
local is_win = has "win32"

if is_unix then
  require('guts.unix')
end
if is_mac then
  require('guts.macos')
end
if is_win then
  require('guts.windows')
end

