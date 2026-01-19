local U = {}

-- Notifications
function U.notify(msg, level, timeout)
  vim.notify(
    msg,
    level or vim.log.levels.INFO,
    { title = "nvim", timeout = timeout or 2000 }
  )
end

vim.api.nvim_create_user_command("Notify", function(opts)
  local msg = opts.fargs[1] or "NO MESSAGE"
  local level = opts.fargs[2] or vim.log.levels.INFO
  local timeout = tonumber(opts.fargs[3]) or 2000

  U.notify(msg, level, timeout)
end, {
  nargs = "*",
})

-- Word count
function U.count_words()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, " ")
  local _, count = content:gsub("%S+", "")
  U.notify("Words: " .. count)
end

vim.api.nvim_create_user_command("CountWords", function()
  U.count_words()
end, {})

-- Wrap visual selection
function U.wrap_in_chars(left, right)
  local pairs = {
    ["("] = ")",
    ["["] = "]",
    ["{"] = "}",
    ["<"] = ">",
    ["'"] = "'",
    ['"'] = '"',
    ["`"] = "`",
    ["«"] = "»",
    ["“"] = "”",
    ["‘"] = "’",
    ["‹"] = "›",
    ["「"] = "」",
    ["『"] = "』",
    ["【"] = "】",
    ["《"] = "》",
  }

  left = left and vim.trim(left) or ""
  right = right and vim.trim(right) or ""

  if left == "" then
    U.notify("Missing wrapper character", vim.log.levels.WARN)
    return
  end

  right = right ~= "" and right or pairs[left] or left

  local bufnr = vim.api.nvim_get_current_buf()
  local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(bufnr, "<"))
  local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(bufnr, ">"))

  if start_row == end_row and start_col == end_col then
    U.notify("Empty or invalid selection", vim.log.levels.WARN)
    return
  end

  local end_line = vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, false)[1] or ""
  local limit_col = math.min(end_col + 1, #end_line)

  local lines = vim.api.nvim_buf_get_text(
    bufnr,
    start_row - 1,
    start_col,
    end_row - 1,
    limit_col,
    {}
  )

  if #lines == 0 then return end

  lines[1] = left .. lines[1]
  lines[#lines] = lines[#lines] .. right

  vim.api.nvim_buf_set_text(
    bufnr,
    start_row - 1,
    start_col,
    end_row - 1,
    limit_col,
    lines
  )

  U.notify("Wrapped with: " .. left .. right)
end

vim.api.nvim_create_user_command("WrapIn", function(opts)
  U.wrap_in_chars(opts.fargs[1], opts.fargs[2])
end, {
  nargs = "*",
  range = true,
  desc = "Wrap visual selection with given characters",
})

-- Rename current file
vim.api.nvim_create_user_command("Rename", function(opts)
  local old = vim.fn.expand("%:p")
  local new = vim.fn.fnamemodify(opts.args, ":p")

  if old == new then
    U.notify("Same filename", vim.log.levels.ERROR)
    return
  end

  vim.cmd("saveas " .. vim.fn.fnameescape(new))
  vim.cmd("bd " .. vim.fn.fnameescape(old))
  vim.cmd("silent !rm " .. vim.fn.shellescape(old))
end, {
  nargs = 1,
  complete = "file",
})

return U
