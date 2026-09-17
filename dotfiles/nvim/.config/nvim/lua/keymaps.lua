local map = vim.keymap.set

map("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file tree" })
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>p", "<cmd>Telescope commands<cr>", { desc = "Command palette" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })
map("n", "<leader>oo", "<cmd>ObsidianQuickSwitch<cr>", { desc = "Obsidian switch note" })
map("n", "<leader>on", "<cmd>ObsidianNew<cr>", { desc = "Obsidian new note" })
map("n", "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", { desc = "Toggle markdown render" })