-- lua/abhinav/options.lua

-- Toggle Terminal Function
function ToggleTerminal()
  local term_buf = -1
  -- Check for existing terminal buffer
  for buf = 1, vim.fn.bufnr('$') do
    if vim.fn.getbufvar(buf, '&buftype') == 'terminal' then
      term_buf = buf
      break
    end
  end

  -- If terminal buffer exists
  if term_buf ~= -1 then
    local term_win = vim.fn.bufwinnr(term_buf)
    -- If terminal buffer is visible, hide it
    if term_win ~= -1 then
      if vim.fn.winnr() == term_win then
        -- Exit terminal insert mode before switching
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, true, true), 'n', true)
        vim.cmd('hide')
      else
        -- Focus the terminal window
        vim.cmd(term_win .. 'wincmd w')
      end
    else
      -- If the terminal buffer is hidden, open it in a new split at the bottom
      vim.cmd('botright split')
      vim.cmd('buffer ' .. term_buf)
    end
  else
    -- If no terminal buffer exists, create a new one in a horizontal split at the bottom
    vim.cmd('botright split term://' .. vim.o.shell)
  end
end

-- Get Valid File Buffer Directory
function GetValidFileBufferDir()
  -- Get the list of all buffers
  local buffers = vim.fn.filter(vim.fn.range(1, vim.fn.bufnr('$')), 'buflisted(v:val)')
  -- Get the current buffer number
  local current_bufnr = vim.fn.bufnr('%')

  -- Iterate over buffers in reverse order to find the last valid file buffer
  for i = #buffers, 1, -1 do
    local buf = buffers[i]
    if buf ~= current_bufnr and vim.fn.bufname(buf):find('^term:') == nil and vim.fn.getbufvar(buf, '&buftype') == '' then
      return vim.fn.fnamemodify(vim.fn.bufname(buf), ':p:h')
    end
  end
  return ''
end

-- Get Current or Previous File Directory
function GetCurrentOrPreviousFileDir()
  local current_bufnr = vim.fn.bufnr('%')
  local current_bufname = vim.fn.bufname(current_bufnr)

  -- Check if the current buffer is a terminal
  if current_bufname:find('^term:') ~= nil or vim.fn.getbufvar(current_bufnr, '&buftype') == 'terminal' then
    -- Fall back to the previous non-terminal buffer
    return GetValidFileBufferDir()
  else
    -- Return the directory of the current buffer
    return vim.fn.fnamemodify(current_bufname, ':p:h')
  end
end

-- Change Terminal Directory
function ChangeTermDir()
  -- Get the directory of the current or previous non-terminal buffer
  local file_dir = GetCurrentOrPreviousFileDir()
  if file_dir == '' then
    print("No valid file buffer found")
    return
  end
  local file_dir_escaped = vim.fn.shellescape(file_dir)

  -- Check if in a terminal buffer
  if vim.bo.buftype == 'terminal' then
    -- Send the cd command to the terminal
    vim.fn.chansend(vim.b.terminal_job_id, "cd " .. file_dir_escaped .. "\n")
  else
    print("Not in a terminal buffer")
  end
end

-- Create a custom command for changing the terminal directory
vim.api.nvim_create_user_command('TermCd', ChangeTermDir, {})

-- Mappings
vim.api.nvim_set_keymap('n', 'bt', ':lua ToggleTerminal()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', 'bi', '<C-\\><C-n>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '//', ':TermCd<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '//', '<C-\\><C-n>:TermCd<CR>', { noremap = true, silent = true })

