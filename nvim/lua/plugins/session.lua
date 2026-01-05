return {
  "rmagatti/auto-session",
  lazy = false,
  config = function()
    require("auto-session").setup({
      git_use_branch_name = true,
      suppressed_dirs = { "~/", "/", "~/Downloads" },

      enabled = true,
      auto_save = true,
      auto_restore = true,
      auto_create = true,
      auto_restore_last_session = false,
      cwd_change_handling = false,
      single_session_mode = false,

      allowed_dirs = nil,
      bypass_save_filetypes = nil,
      close_filetypes_on_save = { "checkhealth" },
      close_unsupported_windows = true,
      preserve_buffer_on_restore = nil,

      git_auto_restore_on_branch_change = false,
      custom_session_tag = nil,

      auto_delete_empty_sessions = true,
      purge_after_minutes = nil,

      save_extra_data = nil,
      restore_extra_data = nil,

      args_allow_single_directory = true,
      args_allow_files_auto_save = false,

      log_level = "error",
      root_dir = vim.fn.stdpath("data") .. "/sessions/",
      show_auto_restore_notif = false,
      restore_error_handler = nil,
      continue_restore_on_error = true,
      lsp_stop_on_restore = false,
      lazy_support = true,
      legacy_cmds = true,

      session_lens = {
        picker = "telescope",
        load_on_setup = true,
        picker_opts = nil,
        previewer = "summary",

        mappings = {
          delete_session = { "i", "<C-d>" },
          alternate_session = { "i", "<C-s>" },
          copy_session = { "i", "<C-y>" },
        },

        session_control = {
          control_dir = vim.fn.stdpath("data") .. "/auto_session/",
          control_filename = "session_control.json",
        },
      },
    })
  end,
}
