require('guts.set')
require('guts.maps')
require('guts.plugins')

function R(name)
    require("plenary.reload").reload_module(name)
end

if vim.fn.has('win32') then
    vim.opt.clipboard:prepend { 'unnamed', 'unnamedplus' }
else
    vim.opt.clipboard:append { 'unnamedplus' }
end
