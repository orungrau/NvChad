local present, lspconfig = pcall(require, "lspconfig")

if not present then
  return
end

require("base46").load_highlight "lsp"
require "nvchad_ui.lsp"

local M = {}
local utils = require "core.utils"

-- export on_attach & capabilities for custom lspconfigs

M.on_attach = function(client, bufnr)
  if vim.g.vim_version > 7 then
    -- nightly
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  else
    -- stable
    client.resolved_capabilities.document_formatting = false
    client.resolved_capabilities.document_range_formatting = false
  end

  utils.load_mappings("lspconfig", { buffer = bufnr })

  if client.server_capabilities.signatureHelpProvider then
    require("nvchad_ui.signature").setup(client)
  end
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()

M.capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}

lspconfig.sumneko_lua.setup {
  on_attach = M.on_attach,
  capabilities = M.capabilities,

  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          [vim.fn.expand "$VIMRUNTIME/lua"] = true,
          [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
        },
        maxPreload = 100000,
        preloadFileSize = 10000,
      },
    },
  },
}

lspconfig.tsserver.setup {
  debug = false,
  disable_commands = false,
  enable_import_on_completion = true,

  -- import all
  import_all_timeout = 5000, -- ms
  import_all_priorities = {
    buffers = 4, -- loaded buffer names
    buffer_content = 3, -- loaded buffer content
    local_files = 2, -- git files or files with relative path markers
    same_file = 1, -- add to existing import statement
  },
  import_all_scan_buffers = 100,
  import_all_select_source = false,

  -- inlay hints
  auto_inlay_hints = true,
  inlay_hints_highlight = "Comment",

  -- update imports on file move
  update_imports_on_move = true,
  require_confirmation_on_move = false,
  watch_dir = nil,

  -- filter diagnostics
  filter_out_diagnostics_by_severity = {},
  filter_out_diagnostics_by_code = {},
  on_attach = function(client, bufnr)
    client.resolved_capabilities.document_formatting = false
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<space>fm", "<cmd>lua vim.lsp.buf.formatting()<CR>", {})
  end,
}

return M
