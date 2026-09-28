return {
  {
    "nvim-mini/mini.map",
    version = "*",
    event = "VeryLazy",
    -- The function is lazy's, not a keymaps.lua string: lazy loads the plugin
    -- (running config, so the MiniMap global and refresh autocmds exist) before
    -- calling it. A string rhs in keymaps.lua would be overwritten here and only
    -- replayed, and require("mini.map") alone leaves the module unconfigured.
    keys = {
      {
        "<leader>vm",
        function()
          MiniMap.toggle()
        end,
        desc = "Toggle minimap",
      },
    },
    config = function()
      local map = require("mini.map")
      map.setup({
        integrations = {
          map.gen_integration.builtin_search(),
          map.gen_integration.diagnostic(),
        },
      })

      -- The module makes neither mappings nor refresh autocmds: it exposes
      -- MiniMap.open/refresh/close and leaves the wiring to the user. Without
      -- these the map is a stale snapshot of the buffer at open time.
      -- No gitsigns or mini.diff integration: neither is a dependency here.
      local group = vim.api.nvim_create_augroup("MiniMapRefresh", { clear = true })
      vim.api.nvim_create_autocmd({
        "BufWinEnter",
        "BufWinLeave",
        "WinEnter",
        "WinLeave",
        "VimResized",
        "OptionSet",
      }, {
        group = group,
        callback = function()
          map.refresh()
        end,
      })
    end,
  },
}
