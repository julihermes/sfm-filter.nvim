local event = require "sfm.event"
local config = require "sfm.extensions.sfm-filter.config"
local sfm_actions = require "sfm.actions"

local SFM_ENTRY_FILTER_NAME = "sfm-filter"

local M = {
  sfm_explorer = nil,
}

--- check if the given entry is filtered
local function is_filtered(entry)
  if string.match(entry.name, "^[^.]") == nil then
    -- hidden
    return true
  end

  return config.opts.ignore_names[entry.name] and true or false
end

function M.refresh()
  local entry = sfm_actions.get_current_entry()

  sfm_actions.refresh()

  -- re-focus the current entry
  sfm_actions.focus_file(entry.path)
end

function M.handle_entry_filter()
  if not config.opts.show_hidden then
    M.sfm_explorer:register_entry_filter(SFM_ENTRY_FILTER_NAME, function(entry)
      return not is_filtered(entry)
    end)
  else
    M.sfm_explorer:remove_entry_filter(SFM_ENTRY_FILTER_NAME)
  end
end

function M.toggle_filter()
  config.opts.show_hidden = not config.opts.show_hidden

  M.handle_entry_filter()
  M.refresh()
end

function M.setup(sfm_explorer, opts)
  config.setup(opts)

  sfm_explorer:subscribe(event.ExplorerOpen, function(payload)
    local bufnr = payload["bufnr"]
    local options = {
      noremap = true,
      silent = true,
      expr = false,
    }

    if type(config.opts.mappings.toggle_filter) == "table" then
      for _, key in pairs(config.opts.mappings.toggle_filter) do
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          key,
          "<CMD>lua require('sfm.extensions.sfm-filter').toggle_filter()<CR>",
          options
        )
      end
    else
      vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        config.opts.mappings.toggle_filter,
        "<CMD>lua require('sfm.extensions.sfm-filter').toggle_filter()<CR>",
        options
      )
    end
  end)

  M.sfm_explorer = sfm_explorer
  M.handle_entry_filter()
end

return M
