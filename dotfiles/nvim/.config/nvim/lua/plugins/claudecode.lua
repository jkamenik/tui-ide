-- Serves the IDE protocol and opens `claude` in a side split on demand, already
-- connected. The server starts with Neovim; the split only opens on <leader>ac.
return {
  {
    "coder/claudecode.nvim",
    event = "VeryLazy",
    opts = {
      terminal = {
        provider = "native",
        split_side = "right",
        split_width_percentage = 0.35,
      },
    },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude pane" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude pane" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add buffer to Claude" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Claude diff" },
    },
  },
}
