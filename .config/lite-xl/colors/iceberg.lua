-- Iceberg theme for Lite XL
-- Inspired by the Iceberg theme for Vim by cocopon (https://github.com/cocopon/iceberg.vim)
-- Author: Claude

local style = require "core.style"
local common = require "core.common"
local config = require "core.config"

-- Iceberg color palette
local colors = {
  -- Base colors
  bg          = "#151515", -- Dark blue-black background or #161821
  bg_alt      = "#151515", -- Slightly lighter background for contrast or #1e2132
  bg_highlight= "#2a3158", -- Selection/highlight background or #2a3158
  border      = "#6b7089", -- Border color
  fg          = "#c6c8d1", -- Default text color
  fg_dark     = "#6b7089", -- Muted text color
  accent      = "#84a0c6", -- Primary accent color (light blue)
  
  -- Syntax colors
  comment     = "#6b7089", -- Comments (medium gray-blue)
  string      = "#89b8c2", -- Strings (teal)
  number      = "#a093c7", -- Numbers (purple)
  keyword     = "#84a0c6", -- Keywords (blue)
  keyword2    = "#A093C7", -- Secondary keywords (purple)
  operator    = "#A1CDD8", -- Operators (blue)
  function_   = "#84a0c6", -- Functions (blue)
  literal     = "#84a0c6", -- Literals/constants (blue)
  
  -- UI colors
  selection   = "#2a3158", -- Selection background
  line_number = "#444b71", -- Line numbers
  line_number_active = "#c6c8d1", -- Active line number
  scrollbar   = "#444b71", -- Scrollbar
  scrollbar_hover = "#6b7089", -- Scrollbar when hovered
  
  -- Special colors
  error       = "#e27878", -- Error text (red)
  warning     = "#e2a478", -- Warning text (orange)
  info        = "#b4be82", -- Info text (green)
}

-- Apply colors to style
style.background = { common.color(colors.bg) }
style.background2 = { common.color(colors.bg_alt) }
style.background3 = { common.color(colors.bg_alt) }
style.text = { common.color(colors.fg) }
style.caret = { common.color(colors.fg) }
style.accent = { common.color(colors.accent) }
style.dim = { common.color(colors.fg_dark) }
style.divider = { common.color(colors.bg_alt) }
style.selection = { common.color(colors.selection) }
style.line_number = { common.color(colors.line_number) }
style.line_number2 = { common.color(colors.line_number_active) }
style.line_highlight = { common.color(colors.bg_highlight) }
style.scrollbar = { common.color(colors.scrollbar) }
style.scrollbar2 = { common.color(colors.scrollbar_hover) }

-- Ensure all color values are complete
style.scrollbar_track = { common.color(colors.bg_alt) }
style.drag_overlay = { common.color "#000000" }
style.drag_overlay_tab = { common.color "#93DDFA" }
style.good = { common.color "#72b886" }
style.warn = { common.color "#FFA94D" }  
style.error = { common.color "#FF3333" }
style.modified = { common.color "#1c7c9c" }
style.caret_line = { common.color "#1e2132" }
style.scrollbar_track = { common.color "#0f111a" }

-- Syntax highlighting
style.syntax = {
  ["normal"] = { common.color(colors.fg) },
  ["symbol"] = { common.color(colors.fg) },
  ["comment"] = { common.color(colors.comment) },
  ["keyword"] = { common.color(colors.keyword) },
  ["keyword2"] = { common.color(colors.keyword2) },
  ["number"] = { common.color(colors.number) },
  ["literal"] = { common.color(colors.literal) },
  ["string"] = { common.color(colors.string) },
  ["operator"] = { common.color(colors.operator) },
  ["function"] = { common.color(colors.function_) },
}

-- Adjust specific elements for Racket syntax
style.syntax["function"] = { common.color(colors.accent) }
style.syntax["operator"] = { common.color(colors.operator) }

-- Plugin-specific theming
-- LSP
if config.plugins.lsp then
  config.plugins.lsp.colors = {
    error = colors.error,
    warning = colors.warning,
    info = colors.info,
    hint = colors.comment
  }
end

-- Return the theme
return style
