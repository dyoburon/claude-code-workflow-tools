-- Custom colorscheme: #3893E7 (blue), #D1617F (pink/rose), #DEA922 (gold)
vim.cmd("hi clear")
vim.g.colors_name = "custom_gradient"

local blue = "#3893E7"
local pink = "#D1617F"
local gold = "#DEA922"

local bg = "#000000"
local bg_dark = "#000000"
local bg_light = "#0a0a0a"
local bg_float = "#050505"
local fg = "#E0E0E3"
local fg_dim = "#737aa2"
local comment = "#565f89"
local gutter = "#3b4261"
local selection = "#283457"
local red = "#f7768e"
local green = "#9ece6a"

local hl = function(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Editor
hl("Normal", { fg = fg, bg = bg })
hl("NormalFloat", { fg = fg, bg = bg_float })
hl("FloatBorder", { fg = blue, bg = bg_float })
hl("Cursor", { fg = bg, bg = blue })
hl("CursorLine", { bg = bg_light })
hl("CursorLineNr", { fg = gold, bold = true })
hl("LineNr", { fg = gutter })
hl("Visual", { bg = selection })
hl("Search", { fg = bg, bg = gold })
hl("IncSearch", { fg = bg, bg = pink })
hl("Pmenu", { fg = fg, bg = bg_float })
hl("PmenuSel", { fg = bg, bg = blue })
hl("PmenuThumb", { bg = blue })
hl("StatusLine", { fg = fg, bg = bg_light })
hl("StatusLineNC", { fg = fg_dim, bg = bg_dark })
hl("WinSeparator", { fg = gutter })
hl("SignColumn", { bg = bg })
hl("ColorColumn", { bg = bg_light })
hl("MatchParen", { fg = gold, bold = true })
hl("NonText", { fg = gutter })
hl("SpecialKey", { fg = gutter })
hl("Directory", { fg = blue })
hl("Title", { fg = blue, bold = true })
hl("ErrorMsg", { fg = red })
hl("WarningMsg", { fg = gold })
hl("ModeMsg", { fg = blue, bold = true })
hl("MoreMsg", { fg = blue })
hl("Question", { fg = blue })
hl("Folded", { fg = comment, bg = bg_light })
hl("FoldColumn", { fg = gutter })
hl("DiffAdd", { bg = "#1a2a1a" })
hl("DiffChange", { bg = "#1a1a2a" })
hl("DiffDelete", { fg = "#4a2a2a", bg = "#2a1a1a" })
hl("DiffText", { bg = "#2a2a3a" })

-- Syntax
hl("Comment", { fg = comment, italic = true })
hl("Constant", { fg = gold })
hl("String", { fg = gold })
hl("Character", { fg = gold })
hl("Number", { fg = pink })
hl("Boolean", { fg = pink })
hl("Float", { fg = pink })
hl("Identifier", { fg = fg })
hl("Function", { fg = blue, bold = true })
hl("Statement", { fg = pink })
hl("Conditional", { fg = pink })
hl("Repeat", { fg = pink })
hl("Label", { fg = blue })
hl("Operator", { fg = pink })
hl("Keyword", { fg = pink, italic = true })
hl("Exception", { fg = pink })
hl("PreProc", { fg = blue })
hl("Include", { fg = blue })
hl("Define", { fg = blue })
hl("Macro", { fg = blue })
hl("Type", { fg = blue })
hl("StorageClass", { fg = pink })
hl("Structure", { fg = blue })
hl("Typedef", { fg = blue })
hl("Special", { fg = gold })
hl("SpecialChar", { fg = gold })
hl("Tag", { fg = pink })
hl("Delimiter", { fg = fg_dim })
hl("SpecialComment", { fg = comment })
hl("Debug", { fg = pink })
hl("Underlined", { fg = blue, underline = true })
hl("Error", { fg = red })
hl("Todo", { fg = gold, bold = true })

-- Treesitter
hl("@variable", { fg = fg })
hl("@variable.builtin", { fg = pink })
hl("@variable.parameter", { fg = fg, italic = true })
hl("@constant", { fg = gold })
hl("@constant.builtin", { fg = gold })
hl("@module", { fg = blue })
hl("@string", { fg = gold })
hl("@string.escape", { fg = pink })
hl("@character", { fg = gold })
hl("@number", { fg = pink })
hl("@boolean", { fg = pink })
hl("@type", { fg = blue })
hl("@type.builtin", { fg = blue, italic = true })
hl("@attribute", { fg = gold })
hl("@property", { fg = blue })
hl("@function", { fg = blue, bold = true })
hl("@function.builtin", { fg = blue })
hl("@function.method", { fg = blue })
hl("@constructor", { fg = gold })
hl("@keyword", { fg = pink, italic = true })
hl("@keyword.function", { fg = pink })
hl("@keyword.return", { fg = pink })
hl("@keyword.operator", { fg = pink })
hl("@punctuation.bracket", { fg = fg_dim })
hl("@punctuation.delimiter", { fg = fg_dim })
hl("@tag", { fg = pink })
hl("@tag.attribute", { fg = gold })
hl("@tag.delimiter", { fg = fg_dim })

-- Diagnostics
hl("DiagnosticError", { fg = red })
hl("DiagnosticWarn", { fg = gold })
hl("DiagnosticInfo", { fg = blue })
hl("DiagnosticHint", { fg = blue })
hl("DiagnosticUnderlineError", { undercurl = true, sp = red })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = gold })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = blue })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = blue })

-- Git signs
hl("GitSignsAdd", { fg = green })
hl("GitSignsChange", { fg = blue })
hl("GitSignsDelete", { fg = red })

-- Telescope
hl("TelescopeNormal", { fg = fg, bg = bg_float })
hl("TelescopeBorder", { fg = blue, bg = bg_float })
hl("TelescopePromptNormal", { fg = fg, bg = bg_light })
hl("TelescopePromptBorder", { fg = blue, bg = bg_light })
hl("TelescopePromptTitle", { fg = bg, bg = blue, bold = true })
hl("TelescopePreviewTitle", { fg = bg, bg = gold, bold = true })
hl("TelescopeResultsTitle", { fg = bg, bg = pink, bold = true })
hl("TelescopeSelection", { bg = selection })
hl("TelescopeMatching", { fg = gold, bold = true })

-- Indent guides
hl("IndentBlanklineChar", { fg = gutter })
hl("IblIndent", { fg = gutter })
hl("IblScope", { fg = blue })

-- Notify
hl("NotifyINFOBorder", { fg = blue })
hl("NotifyINFOTitle", { fg = blue })
hl("NotifyINFOIcon", { fg = blue })
hl("NotifyWARNBorder", { fg = gold })
hl("NotifyWARNTitle", { fg = gold })
hl("NotifyWARNIcon", { fg = gold })
hl("NotifyERRORBorder", { fg = red })
hl("NotifyERRORTitle", { fg = red })
hl("NotifyERRORIcon", { fg = red })

-- Mini
hl("MiniStarterHeader", { fg = blue, bold = true })
hl("MiniStarterFooter", { fg = comment, italic = true })
hl("MiniStarterItem", { fg = fg })
hl("MiniStarterItemPrefix", { fg = gold })
hl("MiniStarterSection", { fg = pink, bold = true })
hl("MiniStarterQuery", { fg = gold })

-- WhichKey
hl("WhichKey", { fg = pink })
hl("WhichKeyGroup", { fg = blue })
hl("WhichKeyDesc", { fg = fg })
hl("WhichKeySeparator", { fg = comment })
hl("WhichKeyValue", { fg = fg_dim })

-- Dashboard / lazy
hl("LazyButton", { fg = fg, bg = bg_light })
hl("LazyButtonActive", { fg = bg, bg = blue, bold = true })
hl("LazyH1", { fg = bg, bg = blue, bold = true })
hl("LazySpecial", { fg = gold })
