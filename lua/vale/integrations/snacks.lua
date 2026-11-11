---snacks.nvim: notifier, picker (and vim.ui.select), input, indent and the
---base window groups. Reference highlights (snacks.words) use the LSP groups.
---@param r ValeRoles
return function(r)
  local g = {
    SnacksNormal = { fg = r.fg, bg = r.bg_float },
    SnacksNormalNC = { fg = r.fg, bg = r.bg_float },
    SnacksWinBar = { fg = r.fg_bright, bg = r.bg_float, bold = true },
    SnacksBackdrop = { bg = r.bg_chrome },
    SnacksTitle = { fg = r.fg_bright, bold = true },
    SnacksFooter = { fg = r.fg_muted },
    SnacksFooterKey = { fg = r.keyword },
    SnacksFooterDesc = { fg = r.fg_muted },
    SnacksDim = { fg = r.fg_muted },
    SnacksNotifierHistory = { fg = r.fg, bg = r.bg_float },
    SnacksNotifierHistoryTitle = { fg = r.fg_bright, bold = true },
    SnacksNotifierHistoryDateTime = { fg = r.fg_muted },
    SnacksNotifierMinimal = { fg = r.fg, bg = r.bg_float },
    SnacksIndent = { fg = r.guide },
    SnacksIndentScope = { fg = r.guide_active },
    SnacksInputNormal = { fg = r.fg, bg = r.bg_float },
    SnacksInputBorder = { fg = r.accent, bg = r.bg_float },
    SnacksInputTitle = { fg = r.fg_bright, bg = r.bg_float, bold = true },
    SnacksInputIcon = { fg = r.accent },
    -- picker windows (VS Code quick-open look: float surface, list selection)
    SnacksPicker = { fg = r.fg, bg = r.bg_float },
    SnacksPickerBorder = { fg = r.border_float, bg = r.bg_float },
    SnacksPickerTitle = { fg = r.fg_bright, bg = r.bg_float, bold = true },
    SnacksPickerBoxTitle = { fg = r.fg_bright, bg = r.bg_float, bold = true },
    SnacksPickerFooter = { fg = r.fg_muted, bg = r.bg_float },
    SnacksPickerInput = { fg = r.fg, bg = r.bg_float },
    SnacksPickerInputBorder = { fg = r.accent, bg = r.bg_float },
    SnacksPickerInputTitle = { fg = r.fg_bright, bg = r.bg_float, bold = true },
    SnacksPickerInputSearch = { fg = r.keyword },
    SnacksPickerPrompt = { fg = r.accent },
    SnacksPickerList = { fg = r.fg, bg = r.bg_float },
    SnacksPickerListBorder = { fg = r.border_float, bg = r.bg_float },
    SnacksPickerListTitle = { fg = r.fg_bright, bg = r.bg_float, bold = true },
    SnacksPickerListCursorLine = { bg = r.selection },
    SnacksPickerPreview = { fg = r.fg, bg = r.bg_float },
    SnacksPickerPreviewBorder = { fg = r.border_float, bg = r.bg_float },
    SnacksPickerPreviewTitle = { fg = r.fg_bright, bg = r.bg_float, bold = true },
    SnacksPickerPreviewCursorLine = { bg = r.bg_line },
    SnacksPickerCursorLine = { bg = r.selection },
    SnacksPickerMatch = { fg = r.link, bold = true },
    SnacksPickerSearch = { bg = r.search },
    SnacksPickerSelected = { fg = r.accent },
    SnacksPickerUnselected = { fg = r.fg_muted },
    SnacksPickerSpecial = { fg = r.keyword },
    SnacksPickerLabel = { fg = r.keyword },
    SnacksPickerTotals = { fg = r.fg_muted },
    SnacksPickerToggle = { fg = r.info, bg = r.bg_surface },
    SnacksPickerSpinner = { fg = r.accent },
    SnacksPickerIdx = { fg = r.fg_muted },
    SnacksPickerDir = { fg = r.fg_muted },
    SnacksPickerFile = { fg = r.fg },
    SnacksPickerDirectory = { fg = r.fg },
    SnacksPickerPathHidden = { fg = r.fg_muted },
    SnacksPickerPathIgnored = { fg = r.fg_muted },
    SnacksPickerComment = { fg = r.fg_muted },
    SnacksPickerDesc = { fg = r.fg_muted },
    SnacksPickerRow = { fg = r.fg_muted },
    SnacksPickerCol = { fg = r.fg_muted },
    SnacksPickerPickWin = { fg = r.fg_on_accent, bg = r.accent, bold = true },
    SnacksPickerPickWinCurrent = { fg = r.fg_on_accent, bg = r.search_current, bold = true },
    -- explorer (a picker source): tree guides and git status like neo-tree's
    SnacksPickerTree = { fg = r.guide },
    SnacksPickerGitStatus = { fg = r.fg_muted },
    SnacksPickerGitStatusAdded = { fg = r.git_add },
    SnacksPickerGitStatusUntracked = { fg = r.git_add },
    SnacksPickerGitStatusModified = { fg = r.warn },
    SnacksPickerGitStatusDeleted = { fg = r.git_delete },
    SnacksPickerGitStatusRenamed = { fg = r.git_add },
    SnacksPickerGitStatusCopied = { fg = r.git_add },
    SnacksPickerGitStatusIgnored = { fg = r.fg_muted },
    SnacksPickerGitStatusUnmerged = { fg = r.error },
    SnacksPickerGitStatusStaged = { fg = r.git_add },
    -- FolderIcon is the theme-agnostic hook the configuration's explorer reads.
    FolderIcon = { fg = r.folder },
  }
  local levels = { Info = r.info, Warn = r.warn, Error = r.error, Debug = r.fg_muted, Trace = r.fg_muted }
  for level, color in pairs(levels) do
    g["SnacksNotifier" .. level] = { fg = r.fg, bg = r.bg_float }
    g["SnacksNotifierIcon" .. level] = { fg = color, bg = r.bg_float }
    g["SnacksNotifierTitle" .. level] = { fg = color, bg = r.bg_float, bold = true }
    g["SnacksNotifierBorder" .. level] = { fg = color, bg = r.bg_float }
    g["SnacksNotifierFooter" .. level] = { fg = r.fg_muted, bg = r.bg_float }
  end
  return g
end
