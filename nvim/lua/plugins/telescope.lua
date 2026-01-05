return {
  "nvim-telescope/telescope.nvim",
  tag = "v0.2.1",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "crispgm/telescope-heading.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        file_ignore_patterns = { "node_modules", ".git/", ".venv" },
        path_display = { "smart" },
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            preview_width = 0.5,
            preview_cutoff = 0,
          },
          width = 0.95,
          height = 0.95,
        },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
        buffers = {
          show_all_buffers = true,
          sort_mru = true,
        },
      },
      extensions = {
        heading = { treesitter = true },
      },
    })

    telescope.load_extension("fzf")
  end,
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      require("telescope").load_extension("ui-select")
    end,
  },
}
