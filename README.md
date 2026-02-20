# blink-cmp-ghostty

Ghostty configuration completion source for
[blink.cmp](https://github.com/saghen/blink.cmp).

<img width="1920" height="1196" alt="blink-cmp-ghostty preview" src="https://github.com/user-attachments/assets/da2ec4bf-8f96-46a6-8fc0-13ebb0fcccb3" />


## Features

- Completes Ghostty configuration keys with documentation
- Provides enum values for configuration options
- Documentation extracted from `ghostty +show-config --docs`

## Requirements

- Neovim 0.10.0+
- [blink.cmp](https://github.com/saghen/blink.cmp)
- [Ghostty](https://ghostty.org)

## Installation

Install via
[luarocks](https://luarocks.org/modules/barrettruth/blink-cmp-ghostty):

```
luarocks install blink-cmp-ghostty
```

Or with lazy.nvim:

```lua
{
  'saghen/blink.cmp',
  dependencies = {
    'barrettruth/blink-cmp-ghostty',
  },
  opts = {
    sources = {
      default = { 'ghostty' },
      providers = {
        ghostty = {
          name = 'Ghostty',
          module = 'blink-cmp-ghostty',
        },
      },
    },
  },
}
```
