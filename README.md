<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/2d6eb58d-9ef0-4b70-8a3b-85890dcf10ac">
    <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/6b6edbd6-b603-46de-8911-d74985541bb7">
    <img style="min-height:160px;" alt="BASEDDvim logo" src="https://github.com/user-attachments/assets/2d6eb58d-9ef0-4b70-8a3b-85890dcf10ac">
  </picture>
</p>

## Preview
<img width="1440" alt="image" src="https://github.com/user-attachments/assets/d30adc52-c282-4d6c-81c7-26a492bef66f">

## Installation
```bash
git clone https://github.com/baseddxyz/BASEDDvim.git ~/.config/nvim
```

## Plugins

### AI & Code Completion
- **[supermaven-nvim](https://github.com/supermaven-inc/supermaven-nvim)** - AI-powered inline code completion
- **[sidekick.nvim](https://github.com/folke/sidekick.nvim)** - CLI integration for AI tools (Claude, etc.)
- **[amp.nvim](https://github.com/sourcegraph/amp.nvim)** - Sourcegraph's AI code assistant
- **[99](https://github.com/ThePrimeagen/99)** - AI-powered code refactoring with SKILL.md support

### Editor UI & Theme
- **[bufferline.nvim](https://github.com/akinsho/bufferline.nvim)** - Buffer tabline
- **[gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim)** - Gruvbox colorscheme
- **[smear-cursor.nvim](https://github.com/sphamba/smear-cursor.nvim)** - Smooth cursor animation
- **[trouble.nvim](https://github.com/folke/trouble.nvim)** - Pretty diagnostics, references, and more

### LSP & Completion
- **[blink.cmp](https://github.com/saghen/blink.cmp)** - Fast, modern completion engine
- **[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)** - LSP configurations
- **[rustaceanvim](https://github.com/mrcjkb/rustaceanvim)** - Rust tooling integration
- **[nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls)** - Java development (jdtls wrapper)
- **[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)** - Tree-sitter integration
- **[conform.nvim](https://github.com/stevearc/conform.nvim)** - Code formatter
- **[nvim-lint](https://github.com/mfussenegger/nvim-lint)** - Async linter
- **[lazydev.nvim](https://github.com/folke/lazydev.nvim)** - Neovim Lua development
- **[mason.nvim](https://github.com/williamboman/mason.nvim)** - Portable LSP/formatter installer

### Navigation & Editing
- **[flash.nvim](https://github.com/folke/flash.nvim)** - Quick navigation with labels
- **[snacks.nvim](https://github.com/folke/snacks.nvim)** - Picker, rename, dim, indent, and image utilities

### Mini Plugins Suite
- **[mini.nvim](https://github.com/echasnovski/mini.nvim)** - Collection of modular plugins:
  - `mini.icons` - Icons
  - `mini.starter` - Start screen
  - `mini.basics` - Basic mappings
  - `mini.files` - File explorer
  - `mini.statusline` - Status line
  - `mini.pairs` - Auto-close pairs
  - `mini.comment` - Comments
  - `mini.notify` - Notifications
  - `mini.trailspace` - Highlight trailing whitespace
  - `mini.diff` - Diff view
  - `mini.ai` - Text objects

### Utilities
- **[img-clip.nvim](https://github.com/HakonHarnes/img-clip.nvim)** - Paste images from clipboard
- **[toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)** - Persistent terminal
- **[vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)** - Seamless tmux navigation

### Installed Language Servers
- `lua_ls` - Lua
- `ts_ls` - TypeScript/JavaScript (with Vue support)
- `rust_analyzer` - Rust
- `gopls` - Go
- `ruby_lsp` - Ruby
- `jdtls` - Java

### Installed Formatters
- `stylua` - Lua
- `biome` - JavaScript/TypeScript
- `google-java-format` - Java

### Supported Languages
- Lua
- JavaScript/TypeScript/React
- Rust
- Go
- Ruby
- Java
- Markdown

## Keybindings

### File & Buffer Navigation
| Key | Mode | Description |
|-----|------|-------------|
| `<leader>ff` | n | Find files |
| `<leader>fb` | n | Find buffers |
| `<leader>e` | n | Open file explorer (mini.files) |

### Code Navigation (LSP)
| Key | Mode | Description |
|-----|------|-------------|
| `gd` | n | Go to definition |
| `gD` | n | Go to declaration |
| `gi` | n | Go to implementation |
| `gr` | n | Find references |
| `K` | n | Hover documentation |
| `<C-k>` | i | Signature help |
| `<leader>D` | n | Go to type definition |
| `<leader>ca` | n, v | Code action |
| `<leader>rn` | n | Rename |

### Code Actions
| Key | Mode | Description |
|-----|------|-------------|
| `<leader>fm` | n | Format buffer |
| `<leader>fM` | n, v | Format file/range |
| `<leader>/` | n, v | Toggle comment |
| `<leader>rr` | n | Rename file |

### AI & Code Completion
| Key | Mode | Description |
|-----|------|-------------|
| `<C-.>` | n, t, i, x | Sidekick toggle |
| `<leader>aa` | n | Sidekick toggle CLI |
| `<leader>as` | n | Select CLI |
| `<leader>ad` | n | Detach CLI session |
| `<leader>at` | n, x | Send this to AI |
| `<leader>af` | n | Send file to AI |
| `<leader>av` | x | Send selection to AI |
| `<leader>ap` | n, x | Select AI prompt |
| `<leader>ac` | n | Toggle Claude |
| `<leader>9f` | n | 99: Fill in function |
| `<leader>9v` | x | 99: Visual selection |
| `<leader>9s` | x | 99: Stop all requests |

### Completion Menu (blink.cmp)
| Key | Mode | Description |
|-----|------|-------------|
| `<C-space>` | i | Show/hide completion |
| `<C-e>` | i | Hide completion |
| `<CR>` | i | Select and accept |
| `<C-p>` | i | Select previous |
| `<C-n>` | i | Select next |
| `<C-b>` | i | Scroll documentation up |
| `<C-f>` | i | Scroll documentation down |
| `<Tab>` | i | Snippet forward |
| `<S-Tab>` | i | Snippet backward |

### Quick Navigation (flash.nvim)
| Key | Mode | Description |
|-----|------|-------------|
| `s` | n, x, o | Flash jump |
| `S` | n, x, o | Flash treesitter |
| `r` | o | Remote flash |
| `R` | o, x | Treesitter search |
| `<C-s>` | c | Toggle flash search |

### Tmux Integration
| Key | Mode | Description |
|-----|------|-------------|
| `<C-h>` | n | Navigate left |
| `<C-j>` | n | Navigate down |
| `<C-k>` | n | Navigate up |
| `<C-l>` | n | Navigate right |
| `<C-\>` | n | Navigate previous |

### Diagnostics & Troubleshooting
| Key | Mode | Description |
|-----|------|-------------|
| `<leader>tt` | n | Toggle diagnostics (Trouble) |
| `<leader>tT` | n | Buffer diagnostics |
| `<leader>cs` | n | Symbols |
| `<leader>cl` | n | LSP definitions/references |
| `<leader>tL` | n | Location list |
| `<leader>tQ` | n | Quickfix list |

### Utilities
| Key | Mode | Description |
|-----|------|-------------|
| `<leader>p` | n | Paste image from clipboard |
| `<leader>tf` | n | Toggle terminal (float) |
| `<leader>y` | n, v | Copy to clipboard |
| `<leader>uD` | n | Toggle dim (Snacks) |

