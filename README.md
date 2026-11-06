# vale.nvim

A theme engine for Neovim and a studio to design themes in the browser. A vale theme is
plain data — palettes of named colours plus a mapping from semantic roles ("strings",
"keywords", "folder") to those colours — loaded as a colorscheme that covers the editor,
syntax, treesitter, LSP, terminals, the statusline and around forty plugins.

The plugin ships one theme, **vale** (`vale-night`, `vale-day`), modelled on VS Code's Dark
and Light Modern. `:Vale` opens the studio to create your own or tweak it, with live
preview in the page and in Neovim.

## Requirements

- Neovim ≥ 0.12
- A browser, for the studio
- No other plugins (lualine and the integrated plugins are used when present)

## Install

```lua
vim.pack.add({ "https://github.com/RayIci/vale.nvim" })
require("vale").setup()
require("vale.studio").setup() -- :Vale
vim.cmd.colorscheme("vale-night")
```

## Themes and where they live

```
<plugin>/themes/vale/          bundled, read-only (night.lua, day.lua, semantics.lua)
<plugin>/colors/vale-*.lua     its colorscheme loaders
<themes_dir>/<name>/           your themes                (default: ~/.config/nvim/themes)
<output_dir>/colors/           loaders the studio writes  (default: ~/.config/nvim)
<output_dir>/lua/lualine/themes/
```

```lua
require("vale").setup({
  themes_dir = vim.fn.stdpath("config") .. "/themes",
  output_dir = vim.fn.stdpath("config"),
})
```

A theme in `themes_dir` wins over a bundled theme of the same name. The plugin never writes
into its own install directory: saving the bundled `vale` theme in the studio first copies
it into `themes_dir`, so a plugin update cannot overwrite your edits (delete the copy to go
back to the bundled one).

A theme is `<name>/night.lua` and/or `<name>/day.lua` (pure-data palettes: `base`,
`accent`, `signal`, `ansi`, `ui` blocks) and an optional `semantics.lua` re-pointing roles,
for both variants or per variant. Each variant loads as `:colorscheme <name>-<variant>`.

## Studio

| Command | |
|---|---|
| `:Vale` | Open the theme list in the browser |
| `:Vale new <name>` | New-theme form: variants, and a start from the VS Code reference or a copy of an existing theme |
| `:Vale edit <name>` | Edit every palette slot and semantic role, previewed live in the page and in Neovim |
| `:Vale stop` | Stop the studio |

The studio is an HTTP server inside Neovim bound to `127.0.0.1` with a per-session token.
Nothing is written until you save; closing the page discards unsaved edits. Saving changes
only the lines of the slots you changed.

## Lua API

`require("vale")`: `setup(opts)`, `load(name, variant)`, `list()`, `colorschemes()`,
`themes_dir()`, `bundled_dir()`, `theme_path(name, file?)`, `is_bundled(name)`,
`copy_to_user(name)`. `require("vale.studio")`: `setup()`, `open()`, `stop()`, `url()`, `discard()`. See
`:help vale`.

`colorschemes()` returns every `<name>-<variant>`, bundled and yours, each once — handy for
a theme picker.

## Development

```sh
make test
make fmt-check
```

## License

MIT
