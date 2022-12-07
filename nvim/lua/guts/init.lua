require('guts.core.base')
require('guts.core.highlights')
require('guts.core.maps')
require('guts.core.diagnostics')
require('guts.core.completions')
require('guts.plugins.plugins')
require('guts.plugins.bootstrap')

local has = vim.fn.has
local is_mac = has "macunix"
local is_unix = has "unix"
local is_win = has "win32"

if is_unix then
	require('guts.os.linux')
end
if is_mac then
	require('guts.os.macos')
end
if is_win then
	require('guts.os.windows')
end
