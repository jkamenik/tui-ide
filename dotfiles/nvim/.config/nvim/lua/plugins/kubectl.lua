-- k9s-style Kubernetes browser inside Neovim: resources, logs, exec, and
-- manifest editing in buffers (ADR-0048). Opens in its own tab on <leader>kk.
return {
  {
    "ramilito/kubectl.nvim",
    version = "2.*",
    dependencies = { "saghen/blink.download" },
    cmd = { "Kubectl", "Kubectx" },
    opts = {},
    keys = {
      { "<leader>kk", function() require("kubectl").toggle({ tab = true }) end, desc = "Toggle kubectl" },
    },
  },
}
