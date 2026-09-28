local ok, obs_local = pcall(require, "obsidian-local")
if not ok then
  obs_local = {}
end

local workspaces = obs_local.workspaces or {}

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})

local spec = {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSInstall markdown markdown_inline",
    config = function()
      require("nvim-treesitter").setup()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown" },
        callback = function()
          vim.treesitter.start()
        end,
      })
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      preset = "obsidian",
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
    end,
  },
  {
    "cavanaug/render-markdown-mermaid.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "MeanderingProgrammer/render-markdown.nvim",
    },
    build = ":TSUpdate markdown markdown_inline",
    opts = {},
  },
}

if #workspaces > 0 then
  spec[#spec + 1] = {
    "epwalsh/obsidian.nvim",
    version = "*",
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      { "nvim-telescope/telescope.nvim" },
    },
    opts = {
      ui = { enable = false },
      workspaces = workspaces,
      completion = { nvim_cmp = false },
      picker = { name = "telescope.nvim" },
    },
    config = function(_, opts)
      require("obsidian").setup(opts)
    end,
  }
end

return spec