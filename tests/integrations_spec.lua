local H = require("helpers")

---Resolved definition of a group, following links.
local function resolved(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

describe("snacks integration", function()
  it("defines the picker window groups directly, not as links to defaults", function()
    H.setup()
    vim.cmd.colorscheme("vale-night")
    for _, name in ipairs({
      "SnacksPicker",
      "SnacksPickerBorder",
      "SnacksPickerListCursorLine",
      "SnacksPickerPreview",
      "SnacksPickerInputBorder",
      "SnacksPickerMatch",
    }) do
      local own = vim.api.nvim_get_hl(0, { name = name })
      ok(own.link == nil, name .. " is a link to " .. tostring(own.link))
      ok(next(resolved(name)) ~= nil, name .. " is empty")
    end
  end)

  it("uses the theme's selection for the picker cursor line", function()
    H.setup()
    vim.cmd.colorscheme("vale-night")
    eq(resolved("Visual").bg, resolved("SnacksPickerListCursorLine").bg)
    vim.cmd.colorscheme("vale-day")
    eq(resolved("Visual").bg, resolved("SnacksPickerListCursorLine").bg)
  end)

  it("colours the explorer's git marks and folder hook from the theme", function()
    H.setup()
    vim.cmd.colorscheme("vale-night")
    local modified = resolved("SnacksPickerGitStatusModified")
    eq(resolved("DiagnosticWarn").fg, modified.fg)
    ok(resolved("FolderIcon").fg ~= nil, "FolderIcon has a foreground")
    ok(resolved("SnacksPickerTree").fg ~= nil, "tree guides have a foreground")
  end)
end)
