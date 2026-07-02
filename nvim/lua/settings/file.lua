vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

vim.filetype.add({
  pattern = {
    [vim.fn.expand("~/dotfiles/zsh/config/") .. "*"] = "sh",
    [vim.fn.expand("~/dotfiles/zsh/ghostty/") .. "*"] = "sh",
  },
})
