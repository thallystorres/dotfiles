local map = vim.keymap.set
local opts = { noremap = true, silent = true }
local utils = require("settings.utils")

-- Insert mode: jj = ESC
map("i", "jj", "<Esc>", opts)

-- Leader shortcuts
map("n", "<leader>w", ":w<CR>", opts)
map("n", "<leader>q", ":q<CR>", opts)
map("n", "<leader>h", ":noh<CR>", opts)

-- diagnostics (LSP)
map("n", "gl", vim.diagnostic.open_float, opts)

-- Toggle diagnostics on/off
map("n", "<leader>dt", function()
  if vim.diagnostic.is_enabled() then
    utils.notify("Diagnostic disabled")
    vim.diagnostic.enable(false)
  else
    utils.notify("Diagnostic enabled")
    vim.diagnostic.enable()
  end
end)

-- Conform format
map({ "n", "v" }, "<leader>f", function()
  utils.notify("Manually formatting with <leader>f...", vim.log.levels.INFO)
  require("conform").format({ async = false, lsp_fallback = true })
end, { desc = "Format file or range (conform)" })

-- Telescope
local builtin = require("telescope.builtin")
map("n", "<leader>fre", builtin.registers, { desc = "Find in registers" })
map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
map("n", "<leader>fg", function()
  builtin.live_grep({
    grep_open_files = true,
  })
end, { desc = "Live grep (Opened files)" })
map("n", "<leader>fb", builtin.buffers, { desc = "List open buffers" })
map("n", "<leader>fh", builtin.help_tags, { desc = "Search help tags" })
map("n", "<leader>fo", builtin.oldfiles, { desc = "Recently opened files" })
map(
  "n",
  "<leader>fc",
  builtin.current_buffer_fuzzy_find,
  { desc = "Fuzzy search in current buffer" }
)
map(
  "n",
  "<leader>fr",
  builtin.resume,
  { desc = "Resume last Telescope picker" }
)
map(
  "n",
  "<leader>fs",
  builtin.lsp_document_symbols,
  { desc = "Document symbols (LSP)" }
)
map(
  { "n" },
  "<leader>as",
  "<cmd>AutoSession search<cr>",
  { desc = "AutoSession Search" }
)
map(
  { "n" },
  "<leader>ass",
  "<cmd>AutoSession save<cr>",
  { desc = "AutoSession Save" }
)

-- Buffers
map("n", "<leader><tab>", "<C-^>", { desc = "Toggle last buffer" })
map("n", "<Tab>", ":bnext<CR>", opts)
map("n", "<S-Tab>", ":bprevious<CR>", opts)
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bu", "<C-^>", { desc = "Reopen last buffer" })

-- WrapIn
map(
  "v",
  "<leader>wp",
  "<Esc><Cmd>lua require('settings.utils').wrap_in_chars('(')<CR>",
  { desc = "Wrap parentheses - ( and )" }
)
map(
  "v",
  "<leader>wq",
  "<Esc><Cmd>lua require('settings.utils').wrap_in_chars('\\'')<CR>",
  { desc = "Wrap single quotes - ' and '" }
)
map(
  "v",
  "<leader>wQ",
  "<Esc><Cmd>lua require('settings.utils').wrap_in_chars('\"')<CR>",
  { desc = 'Wrap double quotes - " and "' }
)
map(
  "v",
  "<leader>ws",
  "<Esc><Cmd>lua require('settings.utils').wrap_in_chars('[')<CR>",
  { desc = "Wrap square brackets - [ and ]" }
)
map(
  "v",
  "<leader>wc",
  "<Esc><Cmd>lua require('settings.utils').wrap_in_chars('{')<CR>",
  { desc = "Wrap curly braces - { and }" }
)
map(
  "v",
  "<leader>wb",
  "<Esc><Cmd>lua require('settings.utils').wrap_in_chars('`')<CR>",
  { desc = "Wrap backtick - ` and `" }
)
map(
  "v",
  "<leader>wh",
  "<Esc><Cmd>lua require('settings.utils').wrap_in_chars('<')<CR>",
  { desc = "Wrap HTML - < and >" }
)
-- Copy text
vim.keymap.set("n", "<leader>cfp", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
  print("Full path copied to clipboard")
end, { noremap = true, silent = true, desc = "Copy full file path" })

vim.keymap.set("n", "<leader>cf", ":%y+<CR>", {
  desc = "Copy entire file to clipboard",
})

-- Word Wrap
vim.keymap.set("n", "<leader>ww", function()
  if vim.wo.wrap then
    vim.opt.wrap = false
    vim.opt.linebreak = false
    vim.opt.breakindent = false
    utils.notify("Softwrap disabled", vim.log.levels.INFO)
  else
    vim.opt.wrap = true
    vim.opt.linebreak = true
    vim.opt.breakindent = true
    utils.notify("Softwrap enabled", vim.log.levels.INFO)
  end
end, { desc = "Toggle Softwrap" })

-- Toggle Spell -- Toggle Spell Checker
vim.keymap.set("n", "<leader>ss", function()
  if vim.wo.spell then
    vim.opt.spell = false
    utils.notify("Spell checker disabled", vim.log.levels.INFO)
  else
    vim.opt.spell = true
    vim.opt.spelllang = { "pt_br", "en_us" }
    utils.notify("Spell checker enabled", vim.log.levels.INFO)
  end
end, { desc = "Toggle Spell Checker" })
