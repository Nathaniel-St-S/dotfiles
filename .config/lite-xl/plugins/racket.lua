-- mod-version:3
local syntax = require "core.syntax"
local config = require "core.config"

-- Define LSP configuration (will be used if LSP plugin is available)
config.plugins.lsp = config.plugins.lsp or {}
config.plugins.lsp.racket_lsp = {
  enabled = true,
  command = {"racket", "--lib", "racket-langserver"},
  file_patterns = {"%.rkt$", "%.rktl$", "%.rktd$", "%.scrbl$"},
  settings = {
    ["racket-langserver"] = {
      args = {"--stdio"}
    }
  }
}

-- File association
syntax.add {
  name = "Racket",
  files = {"%.rkt$", "%.rktl$", "%.rktd$", "%.scrbl$"},
  comment = ";;",
  patterns = {
    -- Comments
    { pattern = ";.-\n", 
      type = "comment" },
    
    -- Multiline comments
    { pattern = { "#|", "|#", "\\" },
      type = "comment" },
    
    -- Strings
    { pattern = { '"', '"', '\\' },
      type = "string" },
    
    -- Numbers (simplified)
    { pattern = "%-?%d+%.?%d*", 
      type = "number" },
    { pattern = "%-?0x%x+",
      type = "number" },
    
    -- Booleans
    { pattern = "#[tf]", 
      type = "literal" },
    
    -- Character literals
    { pattern = "#\\%S+",
      type = "literal" },
    
    -- Keywords (symbols starting with #:)
    { pattern = "#:[%w%-]+",
      type = "keyword2" },
    
    -- Quoted symbols
    { pattern = "'[%w%-]+",
      type = "literal" },
    
    -- Core Racket keywords
    { pattern = "%f[%w](" .. table.concat({
      "define", "lambda", "λ", "if", "cond", "else", "case", "when", "unless",
      "let", "let%*", "letrec", "begin", "set!", "quote", "unquote",
      "require", "provide", "module", "match", "and", "or", "not"
    }, "|") .. ")%f[^%w]",
      type = "keyword" },
    
    -- Common functions
    { pattern = "%f[%w](" .. table.concat({
      "map", "apply", "filter", "car", "cdr", "cons", "list", "append",
      "length", "reverse", "null%?", "pair%?", "list%?", "equal%?",
      "display", "printf", "format", "error", "void"
    }, "|") .. ")%f[^%w]",
      type = "function" },
    
    -- Identifiers (general)
    { pattern = "[%w][%w%-%?%!%+%*%/%%<>=]*",
      type = "normal" },
    
    -- Operators
    { pattern = "[%+%-%*%/%^%%<>=]+",
      type = "operator" },
  },
  symbols = {}
}

-- Simple indentation
local indent_size = config.indent_size or 2

-- Initialize LSP for Racket if available
local lsp_ok, lsp = pcall(require, "plugins.lsp")
if lsp_ok and config.plugins.lsp.racket_lsp.enabled then
  lsp.add_server {
    name = "racket-langserver",
    language = "racket", 
    file_patterns = config.plugins.lsp.racket_lsp.file_patterns,
    command = config.plugins.lsp.racket_lsp.command,
    settings = config.plugins.lsp.racket_lsp.settings
  }
end
