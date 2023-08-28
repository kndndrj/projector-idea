# Neovim Projector IDEA Loader

Extension for [nvim-projector](https://github.com/kndndrj/nvim-projector) that
adds additional IDEA loader.

NOTE: Currently there is only support for goland.

## Installation

Install it as any other plugin. Be aware that
[`xml2lua`](https://github.com/manoelcampos/xml2lua) is needed as luarocks
dependency. Example using packer.nvim:

```lua
use {
  "kndndrj/nvim-projector",
  requires = {
    "MunifTanjim/nui.nvim",
    "kndndrj/projector-idea"
  },
  rocks = {
    "xml2lua",
  },
  config = function()
    require("projector").setup {
      loaders = {
        require("projector_idea").Loader:new(),
        -- ... your other loaders
      },
      -- ... the rest of your config
    }
  end,
}
```
