# terminal_picker.nvim

A Neovim plugin for managing [vim-floaterm](https://github.com/voldikss/vim-floaterm) terminals with fuzzy finder integration. Easily create, select, and switch between floating terminals, with automatic terminal mode entry.

## Features

- **Terminal Picker**: Fuzzy-select from existing terminals using fzf_lua or vim.ui.
- **New Terminal Creation**: Interactive workflow to create named terminals (regular or external tools).
- **Mode Ensures**: Automatically enters terminal mode ('t') on switch or creation for immediate interaction.
- **Integration**: Leverages vim-floaterm for robust terminal management.
- **Fallback Support**: Uses vim.ui if fzf_lua is unavailable.
- **Automatic Mode Entry**: Enters terminal mode ('t') automatically after switching to or creating terminals for immediate interaction.

## Requirements

- Neovim
- [vim-floaterm](https://github.com/voldikss/vim-floaterm)
- Optional: [fzf-lua](https://github.com/ibhagwan/fzf-lua) for enhanced pickers

## Demo

https://github.com/user-attachments/assets/51460583-ade3-46fb-a03c-9e2fdc91bd75

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    'yourusername/terminal_picker.nvim',
    dependencies = {
        'voldikss/vim-floaterm',
        'ibhagwan/fzf-lua',  -- optional
    },
    config = function()
        require('terminal_picker').setup({
            config = {
                tools = {
                    {
                        icon = "",
                        name = "lazygit",
                        cmd = function()
                            return require("terminal_picker").External_tool(vim.loop.cwd(), "lazygit")
                        end
                    },
                    {
                        icon = "",
                        name = "htop",
                        cmd = function()
                            return require("terminal_picker").External_tool("[Here your path]", "htop", {width = 0.8, height = 0.8})
                        end
                    },
                    {
                        icon = "",
                        name = "ranger",
                        cmd = function()
                            return require("terminal_picker").External_tool(vim.loop.cwd(), "ranger")
                        end
                    },
                    {
                        icon = "",
                        name = "neofetch",
                        cmd = function()
                            return require("terminal_picker").Regular_terminal("[Here your path]", {width = 0.6, height = 0.4}, "neofetch")
                        end
                    }
                }
            },
            fzf_lua = {}  -- fzf_lua options
        })
    end
}
```

> Replace '[Here your path]' with desired paths (e.g., `vim.loop.cwd()`). Use functions for dynamic paths/commands; `External_tool` for tools, `Regular_terminal` for shells.


## Usage

### Commands

- `:TerminalPicker`: Open picker to select and switch to an existing terminal.
- `:TerminalPickerNew`: Start workflow to create a new terminal (prompts for name, then tool type).
- `:TerminalPickerKillAll`: Kill all floaterm terminals at once.

### Setup Options

```lua
require('terminal_picker').setup({
    config = {
        tools = {  -- Custom external tools
            {
                icon = '',
                name = 'mytool',
                cmd = 'FloatermNew --name={%name_id%} --title=[{%icon%}{%name%}] mycommand'
            }
        }
    },
    fzf_lua = {  -- Passed to fzf_lua pickers
        winopts = { height = 0.4, width = 0.6 }
    }
})
```

- **config.tools**: Array of tools with `icon`, `name`, `cmd` (string or function).
- **fzf_lua**: Options for fzf_lua pickers (prompt, winopts, etc.).

### API

#### `M.Regular_terminal(path, props, cmd)`

Generate a FloatermNew command for a regular terminal.

- `path`: Working directory (string or nil).
- `props`: Table of properties (all optional, with defaults from vim-floaterm):
  - `width`: Float (0-1) for width relative to screen (default: 0.9).
  - `height`: Float (0-1) for height relative to screen (default: 0.9).
  - `position`: String for window position (e.g., 'center', 'topleft', 'bottomright'; default: 'center').
  - `wintype`: String for window type ('float' for floating, 'split' for split; default: 'float').
  - `autoclose`: Number for auto-close behavior (0=never, 1=on normal exit, 2=always; default: 0).
  - `titleposition`: String for title position ('left', 'center', 'right'; default: 'left').
  - `borderchars`: String for border characters (8 chars; default: '─│─│┌┐┘└').
  - `shell`: String for shell command (default: '&shell').
  
  **Note:** In this moment, we support these properties, but if you want to get more information about these properties, you can go to and read in vim-floaterm documentation.
- `cmd`: Optional command to run in the terminal.

Returns: Command string.

#### `M.External_tool(path, tool, props)`

Generate a FloatermNew command for an external tool.

- `path`: Working directory (string or nil).
- `tool`: Tool command (string).
- `props`: Table of properties (all optional, with defaults from vim-floaterm):
  - `width`: Float (0-1) for width relative to screen (default: 0.9).
  - `height`: Float (0-1) for height relative to screen (default: 0.9).
  - `position`: String for window position (e.g., 'center', 'topleft', 'bottomright'; default: 'center').
  - `wintype`: String for window type ('float' for floating, 'split' for split; default: 'float').
  - `autoclose`: Number for auto-close behavior (0=never, 1=on normal exit, 2=always; default: 0).
  - `titleposition`: String for title position ('left', 'center', 'right'; default: 'left').
  - `borderchars`: String for border characters (8 chars; default: '─│─│┌┐┘└').
  - `shell`: String for shell command (default: '&shell').

  **Note:** In this moment, we support these properties, but if you want to get more information about these properties, you can go to and read in vim-floaterm documentation.

Returns: Command string or nil if invalid.

#### Internal Functions

- `Choice_terminal(choice)`: Switch to terminal by choice string, ensures mode.
- `Create_new_terminal(id, name, item)`: Create terminal, ensures mode.
- `Select()`: Picker for existing terminals.
- `New_terminal()`: Workflow for new terminal.
- `Kill_all()`: Workflow for kill all terminals.

### Examples

#### Basic Setup

```lua
require('terminal_picker').setup()
```

#### Custom Tools

```lua
require('terminal_picker').setup({
    config = {
        tools = {  -- Custom external tools
            {
                icon = '',
                name = 'mytool',
                cmd = 'FloatermNew --name={%name_id%} --title=[{%icon%}{%name%}] mycommand'
            },
            {
                icon = "",
                name = "lazygit",
                cmd = function()
                    return require("terminal_picker").External_tool(vim.loop.cwd(), "lazygit")
                end
            }
        }  -- Mix string and function cmds as needed
    },
    fzf_lua = {  -- Passed to fzf_lua pickers
        winopts = { height = 0.4, width = 0.6 }
    }
})
```

> **Note:** Do not modify the `{% %}` placeholders in `cmd` strings (e.g., `{%name_id%}`, `{%icon%}`, `{%name%}`). They are automatically replaced by the plugin with appropriate values like unique IDs or names. Altering them may cause errors.

#### Usage in Workflow

1. Run `:TerminalPickerNew`.
2. Enter terminal name (e.g., "mytTerm").
3. Select tool (e.g., "terminal" for shell).
4. Terminal opens in float window, ready for input (mode 't'). Sometimes the plugins has problems to focus the terminal in "Terminal" mode, so, just press i or a (it will be fix this in the future).

## Key Bindings

No default keymaps. Example mappings:

```lua
vim.keymap.set('n', '<leader>tp', ':TerminalPicker<CR>')
vim.keymap.set('n', '<leader>tn', ':TerminalPickerNew<CR>')
vim.keymap.set('n', '<leader>tk', ':TerminalPickerKillAll<CR>')
```

## Troubleshooting

- **No terminals listed**: Ensure vim-floaterm is installed and terminals exist.
- **Picker not working**: Check fzf_lua installation; falls back to vim.ui.
- **Mode not entering after switch/create**: The plugin ensures 't' mode automatically; if issues persist, check vim-floaterm settings or reload the plugin.
- **Errors on create**: Verify tool commands; pcall catches failures.
- **Path issues**: Uses `vim.loop.cwd()`.

## Contributing

Report issues or suggest features.

## License

MIT
