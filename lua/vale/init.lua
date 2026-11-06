---vale: theme engine. A theme is a directory `<name>/` (night.lua and/or
---day.lua pure-data palettes, optional semantics.lua) in the user's themes
---directory or among the themes bundled with the plugin; each variant loads as
---the colorscheme `<name>-<variant>`.
---Layers: palette (pure data) → semantics (role → palette name: shared
---default, then theme, then variant overrides) → groups/* and integrations/*.
---@class Vale
local M = {}

---@alias ValeVariant "night"|"day"
---@alias ValeRoles table<string, string> role → "#RRGGBB"

---Unsaved studio edits applied on top of the files.
---@class ValeOverrides
---@field palette? table<string, string> "block.key" → "#RRGGBB"
---@field semantics? table replaces the theme's semantics.lua (same shape: role = name, night = {}, day = {})

M.variants = { "night", "day" }

M.blocks = { "base", "accent", "signal", "ansi", "ui" }

-- Terminal slot order for the named ansi keys (0-15).
M.ansi_order = {
  "black",
  "red",
  "green",
  "yellow",
  "blue",
  "magenta",
  "cyan",
  "white",
  "bright_black",
  "bright_red",
  "bright_green",
  "bright_yellow",
  "bright_blue",
  "bright_magenta",
  "bright_cyan",
  "bright_white",
}

-- Highlight modules, applied in order (later ones win on conflicts).
M.modules = {
  "vale.groups.editor",
  "vale.groups.syntax",
  "vale.groups.treesitter",
  "vale.groups.lsp",
  "vale.groups.diagnostics",
  "vale.integrations",
}

---Repository root of the plugin (holds the bundled themes/).
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))))

---@class ValeOpts
---@field themes_dir string the user's themes (created and edited themes live here)
---@field output_dir string where the studio writes colors/ and lua/lualine/themes/ loaders

---@return ValeOpts
local function defaults()
  local config = vim.fn.stdpath("config") --[[@as string]]
  return { themes_dir = vim.fs.joinpath(config, "themes"), output_dir = config }
end

---@type ValeOpts
M.options = defaults()

---@param opts? ValeOpts|{}
function M.setup(opts)
  M.options = vim.tbl_extend("force", defaults(), opts or {})
end

---The user's themes directory (where new and edited themes are written).
---@return string
function M.themes_dir()
  return M.options.themes_dir
end

---Themes shipped with the plugin. Read-only: editing one copies it into the
---user's themes directory first.
---@return string
function M.bundled_dir()
  return vim.fs.joinpath(root, "themes")
end

---Directory of a theme: the user's copy when there is one, else the bundled
---theme, else where a new user theme would go.
---@param name string
---@return string
function M.theme_dir(name)
  local user = vim.fs.joinpath(M.themes_dir(), name)
  if vim.uv.fs_stat(user) then
    return user
  end
  local bundled = vim.fs.joinpath(M.bundled_dir(), name)
  if vim.uv.fs_stat(bundled) then
    return bundled
  end
  return user
end

---Whether `name` resolves to the bundled copy (no user copy shadows it).
---@param name string
---@return boolean
function M.is_bundled(name)
  return vim.uv.fs_stat(vim.fs.joinpath(M.themes_dir(), name)) == nil
    and vim.uv.fs_stat(vim.fs.joinpath(M.bundled_dir(), name)) ~= nil
end

---Copy a bundled theme into the user's themes directory, so it can be edited
---without touching the plugin's install directory. The bundled colorscheme
---loaders already resolve the user copy first.
---@param name string
---@return string dir the user copy
function M.copy_to_user(name)
  local from = vim.fs.joinpath(M.bundled_dir(), name)
  local to = vim.fs.joinpath(M.themes_dir(), name)
  vim.fn.mkdir(to, "p")
  for file, kind in vim.fs.dir(from) do
    if kind == "file" then
      vim.fn.writefile(vim.fn.readfile(vim.fs.joinpath(from, file), "b"), vim.fs.joinpath(to, file), "b")
    end
  end
  return to
end

---@param name string
---@param file? string file inside the theme directory
---@return string
function M.theme_path(name, file)
  local dir = M.theme_dir(name)
  return file and vim.fs.joinpath(dir, file) or dir
end

---@param name string
---@param variant ValeVariant
---@return string
function M.palette_path(name, variant)
  return M.theme_path(name, variant .. ".lua")
end

---Read a palette fresh from disk (dofile, so edits are seen on reload).
---@param name string
---@param variant ValeVariant
---@return table
function M.read_palette(name, variant)
  return dofile(M.palette_path(name, variant))
end

---A theme's own semantics overrides ({} when it has none).
---@param name string
---@return table
function M.read_semantics(name)
  local path = M.theme_path(name, "semantics.lua")
  return vim.uv.fs_stat(path) and dofile(path) or {}
end

---Every theme with the variants it has, sorted by name: the user's themes
---and the bundled ones (a user copy of a bundled theme is listed once).
---@return { name: string, variants: ValeVariant[], bundled: boolean }[]
function M.list()
  local out, seen = {}, {}
  for _, dir in ipairs({ M.themes_dir(), M.bundled_dir() }) do
    if vim.uv.fs_stat(dir) then
      for name, kind in vim.fs.dir(dir) do
        if kind == "directory" and not seen[name] then
          seen[name] = true
          local variants = vim.tbl_filter(function(v)
            return vim.uv.fs_stat(M.palette_path(name, v)) ~= nil
          end, M.variants)
          if #variants > 0 then
            out[#out + 1] = { name = name, variants = variants, bundled = M.is_bundled(name) }
          end
        end
      end
    end
  end
  table.sort(out, function(a, b)
    return a.name < b.name
  end)
  return out
end

---Every vale colorscheme (`<name>-<variant>`), sorted.
---@return string[]
function M.colorschemes()
  local out = {}
  for _, theme in ipairs(M.list()) do
    for _, variant in ipairs(theme.variants) do
      out[#out + 1] = theme.name .. "-" .. variant
    end
  end
  table.sort(out)
  return out
end

---Resolve a palette into a flat colour table: base/accent/signal names at the
---top level, plus `ui` and `ansi` sub-tables with names resolved to hex.
---@param p table raw palette
---@param overrides? table<string, string> "block.key" → "#RRGGBB"
---@return table
function M.resolve(p, overrides)
  p = vim.deepcopy(p)
  for slot, hex in pairs(overrides or {}) do
    local block, key = slot:match("^(%w+)%.([%w_]+)$")
    if block and p[block] then
      p[block][key] = hex
    end
  end
  local c = {}
  for _, block in ipairs({ "base", "accent", "signal" }) do
    for k, v in pairs(p[block]) do
      c[k] = v
    end
  end
  for _, block in ipairs({ "ui", "ansi" }) do
    c[block] = {}
    for k, v in pairs(p[block]) do
      c[block][k] = v:sub(1, 1) == "#" and v or c[v]
    end
  end
  return c
end

---Role → palette name after layering: shared default, the theme's
---semantics (its semantics.lua, or an unsaved replacement), then its
---per-variant table.
---@param name string
---@param variant ValeVariant
---@param theme_semantics? table replacement for the theme's semantics.lua
---@return table<string, string>
function M.role_names(name, variant, theme_semantics)
  local names = vim.deepcopy(require("vale.semantics"))
  local theme = theme_semantics or M.read_semantics(name)
  for role, value in pairs(theme) do
    if type(value) == "string" then
      names[role] = value
    end
  end
  for role, value in pairs(theme[variant] or {}) do
    names[role] = value
  end
  return names
end

---Map semantic roles to hex for a resolved palette.
---@param c table resolved palette
---@param names table<string, string> role → palette name (see role_names)
---@return ValeRoles
function M.roles(c, names)
  local r = {}
  for role, name in pairs(names) do
    if type(name) == "string" then
      local ui = name:match("^ui%.(.+)$")
      r[role] = ui and c.ui[ui] or c[name]
      if not r[role] then
        error(("vale: role %q points at unknown palette name %q"):format(role, name))
      end
    end
  end
  return r
end

---Build every highlight group for a theme variant without applying it.
---@param name string
---@param variant ValeVariant
---@param overrides? ValeOverrides
---@return table<string, vim.api.keyset.highlight> groups, table c, ValeRoles r
function M.build(name, variant, overrides)
  overrides = overrides or {}
  local c = M.resolve(M.read_palette(name, variant), overrides.palette)
  local r = M.roles(c, M.role_names(name, variant, overrides.semantics))
  local groups = {}
  for _, mod in ipairs(M.modules) do
    for name, spec in pairs(require(mod)(r, c)) do
      groups[name] = spec
    end
  end
  return groups, c, r
end

---Drop cached vale modules so edits to semantics/groups/integrations apply.
function M.unload()
  for name in pairs(package.loaded) do
    if name == "vale.semantics" or name:match("^vale%.groups") or name:match("^vale%.integrations") then
      package.loaded[name] = nil
    end
  end
end

---The theme variant loaded last (nil before any vale theme loads).
---@type { name: string, variant: ValeVariant, c: table, r: ValeRoles }|nil
M.current = nil

---Load a theme variant as the active colorscheme `<name>-<variant>`.
---@param name string
---@param variant ValeVariant
---@param overrides? ValeOverrides unsaved studio edits
function M.load(name, variant, overrides)
  local groups, c, r = M.build(name, variant, overrides)

  if vim.g.colors_name then
    vim.cmd("hi clear")
  end
  vim.o.termguicolors = true
  vim.o.background = variant == "day" and "light" or "dark"
  vim.g.colors_name = name .. "-" .. variant

  for name, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, name, spec)
  end
  for i, key in ipairs(M.ansi_order) do
    vim.g["terminal_color_" .. (i - 1)] = c.ansi[key]
  end

  M.current = { name = name, variant = variant, c = c, r = r }
  -- lualine `require`s its theme; drop the cached table so edits and studio
  -- previews reach the statusline on the next ColorScheme.
  package.loaded["lualine.themes." .. name .. "-" .. variant] = nil
end

return M
