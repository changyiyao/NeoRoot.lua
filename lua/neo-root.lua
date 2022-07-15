local NOREF_NOERR_TRUNC = { noremap = true, silent = true, nowait = true }
local NOREF_NOERR = { noremap = true, silent = true }
local EXPR_NOREF_NOERR_TRUNC = { expr = true, noremap = true, silent = true, nowait = true }
---------------------------------------------------------------------------------------------------
-- constants
RED_PILL = 1
BLUE_PILL = 2
YELLOW_PILL = 3
-- globals
CUR_MODE = BLUE_PILL
_PROJ_ROOT = vim.fn.getcwd()
PROJ_ROOT = vim.fn.getcwd() -- this cannot be relative path!

local M = {}

local notify = require'notify'
local path = require'neo-root-path'

---------------------------------------------------------------------------------------------------
function M.setup(config)
  CUR_MODE = config.CUR_MODE
end

function M.apply_change()
  -- NOTE: Don't use `string.find` to compare type, since empty string `''` will always match
  -- NOTE: Don't use `vim.opt.filetype`, since everyone set it locally.
  if vim.bo.buftype ~= "terminal" -- TODO: should be customizable
    and vim.api.nvim_win_get_config(0).relative == ''
    and vim.bo.filetype ~= "dashboard"
    and vim.bo.filetype ~= "help"
    and vim.bo.filetype ~= "fugitive"
    and vim.bo.filetype ~= "TelescopePrompt"
    and vim.bo.filetype ~= "Outline"
    and vim.bo.filetype ~= "flutterToolsOutline"
    and vim.bo.filetype ~= "NvimTree"
    and vim.bo.filetype ~= "FTerm" then
    if CUR_MODE == RED_PILL then
      vim.cmd('cd ' .. vim.fn.expand('%:p:h'))
    elseif CUR_MODE == BLUE_PILL then-- CUR_MODE == BLUE_PILL
      vim.cmd('cd ' .. PROJ_ROOT)
    elseif CUR_MODE == YELLOW_PILL then-- CUR_MODE == YELLOW_PILL
      local current_dir = vim.fn.expand("%:p:h")
      local root_patterns = { ".git", "pubspec.yaml" }
      local root_dir = path.find_root(root_patterns, current_dir) or PROJ_ROOT
      vim.cmd('cd ' .. root_dir)
    end
    M.notify(vim.fn.getcwd() .. ' (cwd = ' .. CUR_MODE .. ')')
  end
end

function M.notify(message)
  -- notify({ message }, 'INFO', {
  --   title = 'NeoRoot',
  --   timeout = 3,
  -- })
end

function M.change_mode()
  if vim.api.nvim_win_get_config(0).relative ~= '' then
    M.notify('[NeoRoot] Cannot change mode in floating window.')
    return
  end
  if CUR_MODE == BLUE_PILL then
    CUR_MODE = YELLOW_PILL
  elseif CUR_MODE == RED_PILL then
    CUR_MODE = BLUE_PILL
  elseif CUR_MODE == YELLOW_PILL then
    CUR_MODE = BLUE_PILL
  end
  M.apply_change()
end

function M.change_project_root()
  CUR_MODE = BLUE_PILL
  local input = vim.fn.input('Set Project Root: ')
  if (input == '' or input:match('%s+')) then -- reset signal
    PROJ_ROOT = _PROJ_ROOT
    M.apply_change()
    return
  end

  if input:sub(1,2) == './' or input:sub(1,3) == '../' then -- relative path
    local cwd = vim.fn.getcwd()
    if cwd:sub(-1) == '/' then
      vim.cmd('cd ' .. cwd ..  input)
    else
      vim.cmd('cd ' .. cwd .. '/' .. input)
    end
  else -- the last case `~`
    vim.cmd('cd ' .. input)
  end
  -- `PROJ_ROOT` only store normalized result
  PROJ_ROOT = vim.fn.getcwd()
  M.apply_change()
end

local function setup_vim_commands()
  vim.cmd [[
    command! NeoRoot lua require('neo-root').apply_change()
    command! NeoRootSwitchMode lua require('neo-root').change_mode()
    command! NeoRootChange lua require('neo-root').change_project_root()
  ]]
end

setup_vim_commands()

return M
