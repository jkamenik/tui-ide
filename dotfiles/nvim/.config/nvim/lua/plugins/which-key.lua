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
        { "<leader>p", desc = "Command palette" },
      },
    },
    config = function(_, opts)
      require("which-key").setup(opts)
    end,
  },
}