return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = { "<leader>" },
    opts = {
      spec = {
        { "<leader>e", desc = "Toggle file tree" },
        { "<leader>f", group = "find" },
        { "<leader>fb", desc = "Find buffers" },
        { "<leader>ff", desc = "Find files" },
        { "<leader>fg", desc = "Live grep" },
        { "<leader>g", group = "git" },
        { "<leader>gg", desc = "LazyGit" },
        { "<leader>m", group = "markdown" },
        { "<leader>mr", desc = "Toggle render" },
        { "<leader>o", group = "obsidian" },
        { "<leader>oo", desc = "Switch note" },
        { "<leader>on", desc = "New note" },
        { "<leader>p", desc = "Command palette" },
      },
    },
    config = function(_, opts)
      require("which-key").setup(opts)
    end,
  },
}