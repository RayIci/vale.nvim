# vale-engine Specification

## Purpose
The vale theme engine: themes as plain-data palettes and semantic role mappings, loaded as Neovim colorschemes covering the editor, syntax, LSP, terminals, the statusline and a broad set of plugins, with themes bundled in the plugin or kept in the user's configuration.

## Requirements

### Requirement: Theme format
A theme SHALL be a directory `<name>/` holding one or both variant palettes (`night.lua` dark, `day.lua` light) and an optional `semantics.lua`. Theme names SHALL use only lowercase letters, digits and hyphens. Each variant SHALL load as the colorscheme `<name>-<variant>` via a `colors/<name>-<variant>.lua` that only calls into the vale engine. The plugin SHALL ship the theme `vale` with both variants and their loaders.

#### Scenario: Theme on disk
- **WHEN** the bundled theme `vale` is inspected
- **THEN** `themes/vale/night.lua` and `themes/vale/day.lua` exist in the plugin, and its `colors/vale-night.lua` and `colors/vale-day.lua` each only delegate to the vale engine

#### Scenario: Single-variant theme
- **WHEN** a theme `ocean` has only `night.lua`
- **THEN** `:colorscheme ocean-night` loads, and no `ocean-day` colorscheme exists

### Requirement: Bundled and user themes
Themes SHALL be found in two places: the user's themes directory and the themes bundled with the plugin. A theme in the user's directory SHALL take precedence over a bundled theme of the same name, and the plugin SHALL never write into its own install directory.

#### Scenario: User copy wins
- **WHEN** the user's themes directory holds its own `vale` theme with a different editor background
- **THEN** `:colorscheme vale-night` uses the user's background

#### Scenario: Bundled theme without a user copy
- **WHEN** the user's themes directory has no `vale` theme
- **THEN** `:colorscheme vale-night` loads the bundled theme

### Requirement: Configurable directories
`setup(opts)` SHALL accept `themes_dir` (the user's themes) and `output_dir` (where the studio writes `colors/` and `lua/lualine/themes/` loaders), both defaulting to the Neovim configuration directory (`themes/` inside it, and the directory itself).

#### Scenario: Defaults
- **WHEN** `setup()` is called without options
- **THEN** themes are read from and written to `stdpath("config")/themes`, and loaders go under `stdpath("config")`

### Requirement: Colorscheme listing
The plugin SHALL list every available theme with its variants, and every vale colorscheme name, covering bundled and user themes with each name listed once.

#### Scenario: Listed once
- **WHEN** the user has a copy of the bundled `vale` theme
- **THEN** `vale-night` appears once in the colorscheme list

### Requirement: Loadable variants
Loading `<name>-<variant>` SHALL clear existing highlights, set `g:colors_name` to `<name>-<variant>`, and set `background` to `dark` for `night` and `light` for `day`.

#### Scenario: Load the dark variant
- **WHEN** the user runs `:colorscheme vale-night`
- **THEN** `vim.g.colors_name` is `vale-night`, `vim.o.background` is `dark`, and the `Normal` group uses the night palette's editor background and foreground

#### Scenario: Load the light variant
- **WHEN** the user runs `:colorscheme vale-day`
- **THEN** `vim.g.colors_name` is `vale-day`, `vim.o.background` is `light`, and the `Normal` group uses the day palette's editor background and foreground

#### Scenario: Switch between themes
- **WHEN** the user loads `vale-night` and then another generated theme
- **THEN** no highlight group keeps a colour from the vale-night palette

### Requirement: Portable plain-data palette
Each variant palette SHALL contain only literal data: no functions, no `require`, no computed values. Every colour SHALL be a `#RRGGBB` hex string (alpha pre-blended against the editor background) or, in the `ansi` and `ui` blocks, the name of a colour defined in `base`, `accent` or `signal`. Each colour entry SHALL be on its own line and carry a comment describing its role.

#### Scenario: Palette is readable outside Neovim
- **WHEN** a palette file is evaluated by a plain Lua interpreter with no Neovim APIs available
- **THEN** it returns a table without error

#### Scenario: Name references resolve
- **WHEN** any `ansi` or `ui` entry is a colour name rather than hex
- **THEN** that name exists in the same palette's `base`, `accent` or `signal` block

### Requirement: Palette blocks and keys
A palette SHALL have the blocks `base` (background-to-foreground shades), `accent` (named hues), `signal` (diagnostic and git status colours), `ansi` (exactly 16 entries named `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white` and their `bright_` counterparts, mapping to terminal slots 0–15), and `ui` (at least `bg`, `fg`, `cursor`, `selection`, `border`, `accent`, `accent_fg`). Every palette of every theme SHALL have the same key set.

#### Scenario: Keys match across palettes
- **WHEN** any two palettes (of the same or different themes) are compared
- **THEN** they define the same keys in every block

### Requirement: Layered semantic roles
Highlight groups SHALL NOT reference palette hex values directly. They SHALL reference semantic roles (for example keyword, control-flow keyword, function, string, type, variable, parameter, property, constant, number, comment, diagnostic error/warn/info/hint, git add/change/delete), each resolved to a palette colour; a role MAY instead resolve to the palette's plain foreground.

#### Scenario: Default mapping
- **WHEN** a theme has no `semantics.lua`
- **THEN** its keywords use the palette's `blue` and its strings use `orange`, as in the shared default mapping

### Requirement: Semantic role override layers
Semantic roles SHALL resolve through three layers, later layers winning: the shared default mapping shipped with vale (mirroring VS Code), the theme's `semantics.lua` overrides, and that file's per-variant overrides. A theme's `semantics.lua` SHALL contain only the roles it changes, as literal data.

#### Scenario: Theme remaps a role
- **WHEN** a theme's `semantics.lua` sets strings to `green` and the theme is loaded
- **THEN** every string-related group (Vim syntax, treesitter captures, LSP semantic tokens) shows the palette's `green`, and other themes are unaffected

#### Scenario: Variant-only override
- **WHEN** a theme's `semantics.lua` remaps the folder role only for `day`
- **THEN** `<name>-day` uses the remapped colour and `<name>-night` keeps the default

### Requirement: Editor, syntax, treesitter and LSP coverage
Every generated colorscheme SHALL define the built-in editor UI groups (`:h highlight-groups`), the standard Vim syntax groups, treesitter capture groups (`@…`, `:h treesitter-highlight-groups`), LSP semantic token groups (`@lsp.type.*`, `@lsp.mod.*`, `@lsp.typemod.*`), and diagnostic groups (base, virtual text, underline, sign, floating). LSP semantic token groups SHALL link to or match their treesitter equivalents so a token keeps the same colour whether or not a language server is attached.

#### Scenario: Semantic tokens agree with treesitter
- **WHEN** a Java file is opened with vale-night active and jdtls attaches, applying semantic tokens
- **THEN** class names, method names, parameters, readonly fields and enum members keep the same colours they had under treesitter alone

#### Scenario: Diagnostics are distinct
- **WHEN** a buffer shows an error, a warning, an info and a hint diagnostic
- **THEN** each severity uses its own colour for virtual text, sign and underline

### Requirement: Installed plugin integrations
Every generated colorscheme SHALL define the highlight groups of every UI-affecting plugin it has an integration for. Each integration SHALL live in its own module. A group the engine defines SHALL still hold its defined value after all plugins' `ColorScheme` handlers have run.

#### Scenario: Diff readability
- **WHEN** a diff is shown in diffview or neogit
- **THEN** added, deleted, changed and changed-text regions are distinguishable from each other and the foreground text stays readable on each

#### Scenario: Plugins do not override
- **WHEN** any generated colorscheme is loaded with every integrated plugin installed
- **THEN** every highlight group the engine defines reads back with the engine's value

### Requirement: Required plugin integrations
Plugin integrations SHALL cover at least: gitsigns, diffview, neogit, git-conflict, telescope, neo-tree, bufferline, lualine, barbecue/navic, which-key, noice, snacks, trouble, todo-comments, indent-blankline, rainbow-delimiters, flash, illuminate, blink.cmp, lspsaga, lightbulb, nvim-dap, nvim-dap-ui, nvim-dap-virtual-text, neotest, overseer, grug-far, render-markdown, toggleterm, nvim-ufo, multicursor, sidekick, mason, window-picker, copilot, vim-dadbod-ui, easy-dotnet, kulala and agentdiff.

#### Scenario: Integration is present
- **WHEN** vale-night is active and the user opens telescope, neo-tree, and a diffview
- **THEN** their windows, borders, selections and diff regions use vale-night colours, not colours linked from a previous theme or the Neovim default

#### Scenario: Agent review colours
- **WHEN** vale-night is active and a file shows pending agent changes
- **THEN** the overlay's removed lines, added lines, hint and conflict marks use vale-night colours

### Requirement: Statusline theme
Each generated colorscheme SHALL have a lualine theme resolvable by `theme = "auto"` (a `lua/lualine/themes/<name>-<variant>.lua` file delegating to the vale engine), built from the theme's roles, reflecting palette changes on the next colorscheme load.

#### Scenario: Statusline follows the theme
- **WHEN** vale-day is loaded
- **THEN** lualine's mode section uses vale-day's accent colour in normal mode

### Requirement: Terminal colours
Loading a generated colorscheme SHALL set `vim.g.terminal_color_0` through `vim.g.terminal_color_15` from that palette's `ansi` block in slot order (`black` = 0 … `white` = 7, `bright_black` = 8 … `bright_white` = 15).

#### Scenario: Terminal buffer colours
- **WHEN** vale-night is active and the user opens a toggleterm terminal running `ls --color`
- **THEN** the ANSI colours shown match the night palette's `ansi` slots

### Requirement: VS Code Modern reference palette
The vale plugin SHALL ship a reference palette with the VS Code Dark Modern and Light Modern values for every palette key, in the palette format with all values as hex, sourced from the theme files and colour registries in the `microsoft/vscode` repository, with the source recorded alongside each value. It SHALL serve as the starting point for new themes. No reference colorscheme plugin SHALL be installed.

#### Scenario: Reference values are traceable
- **WHEN** the user looks up a reference value such as the dark keyword colour
- **THEN** the reference records the value and which VS Code file and key it came from

### Requirement: Folder icon hook
Every generated colorscheme SHALL define a `FolderIcon` highlight group with the theme's folder colour, so theme-agnostic configuration and plugins can pick up the folder colour without referencing vale.

#### Scenario: Folder colour under a generated theme
- **WHEN** vale-night is active and neo-tree is open
- **THEN** folder icons use vale-night's folder colour
