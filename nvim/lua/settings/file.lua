vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

vim.filetype.add({
  pattern = {
    ["/Users/thallys/dotfiles/zsh/config/*"] = "sh",
    ["/Users/thallys/dotfiles/zsh/ghostty/*"] = "sh",
  },
})
