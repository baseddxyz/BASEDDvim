-- Markdown filetype config. Borrowed from baseddxyz/paketo.
-- Establishes the after/ftplugin/ pattern for per-filetype settings.
vim.cmd("setlocal spell wrap")
vim.cmd("setlocal foldmethod=expr foldexpr=v:lua.vim.treesitter.foldexpr()")
