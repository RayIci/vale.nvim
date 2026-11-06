---Per-test fixtures: a temp directory standing in for the user's Neovim
---configuration (themes/, colors/, lua/lualine/themes/), temp XDG homes, and
---a clean plugin. The repository's own bundled theme is never written to.
local H = {}

---@type string? stands in for stdpath("config") during the test
H.config = nil

---Absolute path of the repository root.
H.repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")

local saved = {} ---@type table<string, string|false>

local function unload()
  for name in pairs(package.loaded) do
    if name == "vale" or name:find("^vale%.") or name:find("^lualine%.themes%.") then
      package.loaded[name] = nil
    end
  end
  vim.g.colors_name = nil
end

function H.begin_test()
  local dir = vim.fn.tempname() .. "-config"
  vim.fn.mkdir(dir, "p")
  H.config = assert(vim.uv.fs_realpath(dir))
  for _, key in ipairs({ "XDG_STATE_HOME", "XDG_DATA_HOME" }) do
    saved[key] = vim.env[key] or false
    vim.env[key] = H.config .. "-" .. key:lower()
  end
  unload()
  -- The user's configuration comes before the plugin on 'runtimepath'.
  vim.opt.rtp:prepend(H.config)
end

function H.end_test()
  vim.opt.rtp:remove(H.config)
  unload()
  vim.cmd("silent! %bwipeout!")
  for key, value in pairs(saved) do
    vim.env[key] = value or nil
  end
  vim.fn.delete(H.config, "rf")
  H.config = nil
end

---Set the plugin up against the temp configuration.
---@return Vale
function H.setup()
  local vale = require("vale")
  vale.setup({ themes_dir = H.config .. "/themes", output_dir = H.config })
  return vale
end

---Normal's background of the active colorscheme, as "#rrggbb".
---@return string
function H.normal_bg()
  return ("#%06x"):format(vim.api.nvim_get_hl(0, { name = "Normal" }).bg)
end

---Every file under `dir` with its contents, for before/after comparisons.
---@param dir string
---@return table<string, string>
function H.snapshot(dir)
  local out = {}
  for name, kind in vim.fs.dir(dir, { depth = 10 }) do
    if kind == "file" then
      out[name] = table.concat(vim.fn.readfile(dir .. "/" .. name, "b"), "\n")
    end
  end
  return out
end

return H
