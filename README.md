# blink-cmp-ghostty

Ghostty configuration completion source for
[blink.cmp](https://github.com/saghen/blink.cmp).

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
