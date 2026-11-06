local H = require("helpers")

describe("saving", function()
  it("copies a bundled theme into the user's themes before the first save", function()
    H.setup()
    local bundled = H.snapshot(H.repo .. "/themes")
    local ok_save, err = require("vale.studio.writer").save("vale", { night = { ["base.bg"] = "#000001" } })
    ok(ok_save, err)
    eq(bundled, H.snapshot(H.repo .. "/themes"), "the install directory is unchanged")
    local copy = vim.fn.readfile(H.config .. "/themes/vale/night.lua")
    local original = vim.fn.readfile(H.repo .. "/themes/vale/night.lua")
    eq(#original, #copy)
    local changed = {}
    for i = 1, #copy do
      if copy[i] ~= original[i] then
        changed[#changed + 1] = copy[i]
      end
    end
    eq(1, #changed, "exactly one line changed")
    ok(changed[1]:find('"#000001"', 1, true), changed[1])
    eq(vim.fn.readfile(H.repo .. "/themes/vale/day.lua"), vim.fn.readfile(H.config .. "/themes/vale/day.lua"))
  end)

  it("edits only the changed slot lines and keeps every other byte", function()
    local writer = require("vale.studio.writer")
    local lines = {
      "return {",
      "  base = {",
      '    bg = "#111111", -- editor background',
      '    fg = "#eeeeee", -- text',
      "  },",
      "}",
    }
    local out = assert(writer.apply(lines, { ["base.bg"] = "#222222" }))
    eq('    bg = "#222222", -- editor background', out[3])
    lines[3] = out[3]
    eq(lines, out)
    local none, err = writer.apply(lines, { ["base.nope"] = "#000000" })
    eq(nil, none)
    ok(err:find("found none", 1, true), err)
  end)
end)

describe("creating", function()
  it("writes a new theme and its loaders into the configuration, never the plugin", function()
    local vale = H.setup()
    local repo = { themes = H.snapshot(H.repo .. "/themes"), colors = H.snapshot(H.repo .. "/colors") }
    local generate = require("vale.studio.generate")
    ok(generate.create("ocean", { "night" }, "vscode"))
    ok(vim.uv.fs_stat(H.config .. "/themes/ocean/night.lua"), "palette in the user themes")
    eq({ 'require("vale").load("ocean", "night")' }, vim.fn.readfile(H.config .. "/colors/ocean-night.lua"))
    ok(vim.uv.fs_stat(H.config .. "/lua/lualine/themes/ocean-night.lua"), "statusline loader")
    eq(nil, vim.uv.fs_stat(H.config .. "/colors/ocean-day.lua"), "only the chosen variant")
    vim.cmd.colorscheme("ocean-night")
    eq("ocean-night", vim.g.colors_name)
    ok(vim.tbl_contains(vale.colorschemes(), "ocean-night"))
    eq(repo, { themes = H.snapshot(H.repo .. "/themes"), colors = H.snapshot(H.repo .. "/colors") })
  end)

  it("copies from a bundled theme", function()
    H.setup()
    local generate = require("vale.studio.generate")
    ok(generate.create("copied", { "night", "day" }, "vale"))
    eq(
      vim.list_slice(vim.fn.readfile(H.repo .. "/themes/vale/night.lua"), 2),
      vim.list_slice(vim.fn.readfile(H.config .. "/themes/copied/night.lua"), 2)
    )
    ok(vim.uv.fs_stat(H.config .. "/themes/copied/semantics.lua"), "semantics copied")
  end)

  it("rejects taken and invalid names", function()
    H.setup()
    local generate = require("vale.studio.generate")
    ok(generate.check_name("vale"), "the bundled theme's name is taken")
    ok(generate.check_name("Bad Name"), "invalid characters")
    eq(nil, generate.check_name("fresh"))
  end)
end)
