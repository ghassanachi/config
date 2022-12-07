--Reload all user config lua modules
---@return nil
return function()
    for name, _ in pairs(package.loaded) do
        if name:match('^guts') or name:match('^plugin') then
            package.loaded[name] = nil
        end
    end

    dofile(vim.env.MYVIMRC)
end
