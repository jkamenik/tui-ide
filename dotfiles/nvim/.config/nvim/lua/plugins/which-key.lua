local ok, obs_local = pcall(require, "obsidian-local")

local spec = {
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
}

if ok and obs_local.workspaces and #obs_local.workspaces > 0 then
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