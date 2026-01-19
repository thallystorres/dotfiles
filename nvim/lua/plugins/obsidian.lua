return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  keys = {
    { "<leader>ot", "<cmd>ObsidianTemplate<cr>", desc = "[O]bsidian [T]emplate" },
    { "<leader>on", "<cmd>ObsidianNewFromTemplate<cr>",      desc = "[O]bsidian [N]ew" },
  },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "~/Notes",
      },
    },
    disable_frontmatter = true,
    templates = {
      subdir = "Templates",
      date_format = "%d-%m-%Y",
      time_format = "%H:%M",
      substitutions = {
        yesterday = function()
          return os.date("%d-%m-%Y", os.time() - 86400)
        end,
      }
    },
    mappings = {
      ["gf"] = {
        action = function()
          local path = vim.fn.expand("<cfile>")
          if path:match("^https?://") then
            return vim.ui.open(path)
          end
          return vim.cmd("ObsidianFollowLink")
        end,
        opts = { noremap = false, expr = false, buffer = true },
      },
    },
    ui = {
      enable = true,
    }
  },
  config = function(_, opts)
    require("obsidian").setup(opts)
    vim.opt.conceallevel = 2
  end,
}
