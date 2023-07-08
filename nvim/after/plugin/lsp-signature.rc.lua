local status, lsp_signature = pcall(require, "lsp_signature")
if (not status) then return end

lsp_signature.setup({
    doc_lines = 0,
    handler_opts = {
        border = "none"
    },
})
