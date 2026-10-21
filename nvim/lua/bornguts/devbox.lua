-- Dev-box ("lean") profile detection.
--
-- Teleport beams are ephemeral Debian boxes, so the heavy parts of the plugin
-- set are a bad trade there: mason downloads four language servers and six CLI
-- tools, treesitter compiles parsers, and both telescope-fzf-native and LuaSnip
-- need a C toolchain. That is minutes of setup and a build-essential install on
-- every fresh box, for tooling you often do not touch on a scratch machine.
--
-- Lean mode keeps everything that holds the muscle memory -- set.lua,
-- remap.lua, autocmds.lua, gruvbox, telescope, oil, harpoon, fugitive,
-- undotree, trouble, conform, cloak, zen-mode, autopairs -- and drops only the
-- specs that pull a compiler or download a server.
--
-- BEAM_ID is exported by the beam environment and is unset on macOS, so this
-- self-activates on a dev box and is inert everywhere else. Set NVIM_FULL=1 to
-- opt back into the full stack on a beam.

local M = {}

M.lean = vim.env.BEAM_ID ~= nil and vim.env.NVIM_FULL ~= "1"

-- Convenience for plugin specs: `enabled = require("bornguts.devbox").full`
M.full = not M.lean

return M
