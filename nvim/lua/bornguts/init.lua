require("bornguts.set")
require("bornguts.remap")
require("bornguts.lazy_init")
require("bornguts.autocmds")

-- Global reload helper for fast plugin/module iteration from the command line,
-- e.g. `:lua R("bornguts.set")`.
function R(name)
    require("plenary.reload").reload_module(name)
end
