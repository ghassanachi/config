local status, zen_mode = pcall(require, "zen-mode")
if (not status) then return end

zen_mode.setup {
    window = {
        width = 80,
        options = {
            number = true,
            relativenumber = true,
        }
    },
}

vim.keymap.set("n", "<leader>zz", function()
    zen_mode.toggle()
    vim.wo.wrap = false
end)


