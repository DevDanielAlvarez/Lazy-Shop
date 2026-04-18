# LazyShop - Plugin Manager for Neovim

LazyShop is a plugin manager for Neovim that allows you to **install, configure, and manage plugins** in an interactive and visual way.

## 🚀 Features

- **📦 Add Plugins**: Search and install plugins from the online repository
- **⚙️ Configure Plugins**: Interactive interface to configure plugin options
- **🎨 Support for Multiple Data Types**:
  - Boolean (true/false selection)
  - Select (dropdown with multiple choices)
  - Number (numeric input with min/max validation)
  - String (free text input)
- **💾 Auto-save**: Configuration settings are automatically saved to the plugin file

## 📖 How to Use

### 1. Opening the LazyShop Menu

```vim
:LazyShop
```

This opens a menu with the following options:

```
┌─ LazyShop ────────────────────┐
│ • Add a Plugin                │
│ • Configure a Plugin          │
│ • Edit Configuration          │
│ • About                       │
└───────────────────────────────┘
```

### 2. Adding a Plugin

1. Open LazyShop: `:LazyShop`
2. Select **"Add a Plugin"**
3. Use the search bar (`>`) to search for a plugin
4. Press `<Tab>` to navigate to the plugin list
5. Select the desired plugin and press `<Enter>`
6. Choose the configuration style:
   - `opts = {}` (recommended, declarative)
   - `config = function() end` (imperative, more flexible)

The plugin file will be created in `~/.config/nvim/lua/plugins/`

### 3. Configuring a Plugin

1. Open LazyShop: `:LazyShop`
2. Select **"Configure a Plugin"**
3. Use the search bar (`>`) to search for a plugin
4. Select the plugin you want to configure
5. If the plugin has available options, you will see:
   ```
   [Available Options]
    • Option 1 (type)
    • Option 2 (type)
    • ...
   
   <Enter> to configure the options
   ```
6. Press `<Enter>` and answer the questions for each option

#### Option Types

**Boolean** (true/false)
```
Enabled (boolean)
Choose: 
  true
  false
```

**Select** (choose from a list)
```
Flavor (select)
Choose:
  latte
  frappe
  macchiato
  mocha
```

**Number** (number with validation)
```
Delay (number) [range: 10..5000]
Enter: 1000
```

**String** (free text)
```
Mapping (string)
Enter: <C-\\>
```

### 4. Navigation

- **`j/k` or arrow keys**: Navigate between items
- **`Enter`**: Select item
- **`Esc`**: Exit menu
- **`Tab`**: Switch between search bar and plugin list

## ⚙️ Plugin Configuration

Configured plugins are saved in `~/.config/nvim/lua/plugins/` with the following structure:

```lua
return {
  "user/plugin-name",
  opts = {
    option1 = true,
    option2 = "value",
    option3 = 1000,
  }
}
```

To apply the changes, **restart Neovim**:
```vim
:quit
nvim
```

## 📝 Configuration File

The repository of plugins and their options is located at:
```
~/.config/nvim/lua/lazy-shop-repository/repository.json
```

This file contains the list of available plugins and their configurable options.

## 🔧 Supported Plugins

Some plugins already have pre-configured options:

- **catppuccin** - Colorful theme (flavor, transparent_background)
- **gitsigns.nvim** - Git integration (enabled, signcolumn, numhl, etc)
- **neo-tree.nvim** - File explorer
- **bufferline.nvim** - Buffer bar
- **toggleterm.nvim** - Floating terminal
- **indent-blankline.nvim** - Indentation guides
- And many more...

## 🌐 Adding Plugins to the Online Repository

To add new plugins to the LazyShop online repository with their configuration options, you should:

1. Visit the repository: https://github.com/DevDanielAlvarez/lazy-shop-repository
2. Read the **README.md** of the repository for detailed instructions
3. Fork the repository
4. Edit the `repository.json` with the information of the new plugin
5. Submit a pull request

The online repository manages:
- List of available plugins
- Plugin descriptions
- Configuration options for each plugin
- Categories and URLs

**→ Check the README at:** https://github.com/DevDanielAlvarez/lazy-shop-repository

## 🐛 Troubleshooting

### Plugin doesn't appear in the "Add a Plugin" list

- Make sure the `repository.json` file exists in `~/.config/nvim/lua/lazy-shop-repository/`
- Make sure your connection to GitHub is working (required to update the list)

### I can't configure a plugin

- The plugin may not have pre-configured options
- You can edit the file manually at `~/.config/nvim/lua/plugins/plugin-name.lua`

### Changes didn't apply

- **Always restart Neovim** after configuring plugins
- Use `:quit` to close and reopen

## 📂 Folder Structure

```
~/.config/nvim/
├── lua/
│   ├── lazy-shop/
│   │   ├── init.lua                 # Main menu
│   │   ├── option-renderer.lua      # Option rendering functions
│   │   ├── plugin-manager.lua       # Plugin manager
│   │   └── repository.lua           # Repository loader
│   │
│   ├── lazy-shop-repository/
│   │   └── repository.json          # List of plugins and options
│   │
│   └── plugins/
│       ├── plugin1.lua              # Plugin 1 file
│       ├── plugin2.lua              # Plugin 2 file
│       └── ...
│
└── init.lua                         # Neovim main configuration
```

## 🚀 Next Steps

1. Configure your favorite plugins with `:LazyShop`
2. Restart Neovim to apply the changes
3. Contribute new plugins to the repository:
   https://github.com/DevDanielAlvarez/lazy-shop-repository

## 📄 License

LazyShop is under the same license as lazy.nvim (Apache 2.0)

---

**Questions or suggestions?** Open an issue on the repository! 🎉

