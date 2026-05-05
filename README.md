# blink-cmp-ghostty

Ghostty configuration completion source for
[blink.cmp](https://github.com/saghen/blink.cmp).

> [!NOTE]
> Due to GitHub's historic unreliability, active development is hosted on
> [Forgejo](https://git.barrettruth.com/barrettruth/blink-cmp-ghostty).
> GitHub is maintained as a read-only mirror.
> See `:help blink-cmp-ghostty-forgejo` for canonical project links.

![blink-cmp-ghostty preview](https://github.com/user-attachments/assets/da2ec4bf-8f96-46a6-8fc0-13ebb0fcccb3)

## Features

- Completes Ghostty configuration keys with documentation
- Provides enum values for configuration options
- Documentation extracted from `ghostty +show-config --docs`

## Requirements

- Neovim 0.10.0+
- [blink.cmp](https://github.com/saghen/blink.cmp)
- [Ghostty](https://ghostty.org)

## Installation

With `vim.pack` (Neovim 0.12+):

```lua
vim.pack.add({
  'https://git.barrettruth.com/barrettruth/blink-cmp-ghostty',
})
```

Or via [luarocks](https://luarocks.org/modules/barrettruth/blink-cmp-ghostty):

```
luarocks install blink-cmp-ghostty
```

Configure `blink.cmp`:

```lua
require('blink.cmp').setup({
  sources = {
    default = { 'ghostty' },
    providers = {
      ghostty = {
        name = 'Ghostty',
        module = 'blink-cmp-ghostty',
      },
    },
  },
})
```
