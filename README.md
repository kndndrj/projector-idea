# Neovim Projector IDEA Loader

Extension for [nvim-projector](https://github.com/kndndrj/nvim-projector) that
adds additional IDEA loaders.
Currently there is only support for goland!

NOTE: Only basic functionality for now.

## Idea

- module: `idea`
- options:
  - `path` - *string*: path to `workspace.xml` - default:
    `./.idea/workspace.xml`
- variable expansion: Idea's variables (e.g. `$PROJECT_DIR$`)
- requirements:
  - `xml2lua` - luarocks
