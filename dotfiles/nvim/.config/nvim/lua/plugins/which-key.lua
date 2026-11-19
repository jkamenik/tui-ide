local spec = {
  { "<leader>a", group = "claude" },
  { "<leader>aa", desc = "Accept Claude diff" },
  { "<leader>ab", desc = "Add buffer to Claude" },
  { "<leader>ac", desc = "Toggle Claude pane" },
  { "<leader>ad", desc = "Deny Claude diff" },
  { "<leader>af", desc = "Focus Claude pane" },
  { "<leader>as", desc = "Send selection to Claude", mode = "v" },
  { "<leader>e", desc = "Toggle file tree" },
  { "<leader>f", group = "find" },
  { "<leader>fb", desc = "Find buffers" },
  { "<leader>ff", desc = "Find files" },
  { "<leader>fg", desc = "Live grep" },
  { "<leader>g", group = "git" },
  { "<leader>gg", desc = "LazyGit" },
  { "<leader>m", group = "markdown" },
  { "<leader>mr", desc = "Toggle render" },
  { "<leader>p", desc = "Command palette" },
  { "<leader>v", group = "view" },
  { "<leader>vm", desc = "Toggle minimap" },
}

if #require("vault").workspaces() > 0 then
  spec[#spec + 1] = { "<leader>o", group = "obsidian" }
  spec[#spec + 1] = { "<leader>oo", desc = "Switch note" }
  spec[#spec + 1] = { "<leader>on", desc = "New note" }
end

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = { "<leader>" },
    opts = {
      spec = spec,
    },
    config = function(_, opts)
      require("which-key").setup(opts)
    end,
  },
}