vim.cmd('set noexpandtab')
vim.cmd('set tabstop=2')
vim.cmd('set softtabstop=2')
vim.cmd('set shiftwidth=2')

vim.cmd('set relativenumber')

vim.g.mapleader = ' '

-- mappings
local map = vim.keymap.set

map('n', '<TAB>', '<cmd>bnext<cr>', { desc = 'Go to next buffer' })
map('n', '<S-TAB>', '<cmd>bprevious<cr>', { desc = 'Go to previes buffer' })
map('n', '<leader>x', '<cmd>bdelete<cr>', { desc = 'Delete Buffer' })
map('n', '<leader>X', '<cmd>bd!<cr>', { desc = 'Force Delete Buffer' })

