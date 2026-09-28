-- Vault workspaces from the machine-local overlay, filtered to vaults that
-- actually exist. This repo does not own the second-brain checkout, so a
-- machine can have the overlay without the vault (fresh machine, repo not
-- cloned yet, clone moved) and obsidian.nvim errors on every markdown buffer
-- when a workspace path is missing.
local M = {}

function M.workspaces()
  local ok, local_config = pcall(require, "obsidian-local")
  if not ok then
    return {}
  end

  return vim.tbl_filter(function(workspace)
    return workspace.path ~= nil and vim.uv.fs_stat(vim.fn.expand(workspace.path)) ~= nil
  end, local_config.workspaces or {})
end

return M
