-- mod-version:3

----------------------------------------------------------------
-- NAME        : gitblame
-- DESCRIPTION : Show git author and commit message on a certain line
-- AUTHOR      : Juliardi (github.com/juliardi)
----------------------------------------------------------------

local core = require "core"
local style = require "core.style"
local common = require "core.common"
local config = require "core.config"
local command = require "core.command"
local DocView = require "core.docview"
local gitblame = require "plugins.gitblame.gitblame"

config.plugins.gitblame = common.merge({

  text_color = { common.color "#b7b7b7" },

  font_size = 14,

  max_commit_message_length = 50,

  debug = false,

  git_executable = "/usr/bin/git",

  config_spec = {
    name = "Git Blame",
    {
      label = "Debug",
      description = "Display debugging message on the log.",
      path = "debug",
      type = "TOGGLE",
      default = false
    },
    {
      label = "Text Color",
      description = "Blame text color.",
      path = "text_color",
      type = "COLOR",
      default = "#b7b7b7"
    },
    {
      label = "Font Size",
      description = "Blame text font size.",
      path = "font_size",
      type = "NUMBER",
      default = 14
    },
    {
      label = "Max Commit Message Length",
      description = "Maximum commit message length shown.",
      path = "max_commit_message_length",
      type = "NUMBER",
      default = 50
    },
    {
      label = "Git Executable Path",
      description = "Git executable path.",
      path = "git_executable",
      type = "STRING",
      default = "/usr/bin/git"
    },
  },

}, config.plugins.gitblame)

local function get_active_view()
    if core.active_view:is(DocView) then
        return core.active_view
    end
end

local previous_scale = SCALE
local desc_font = style.code_font:copy(
  config.plugins.gitblame.font_size * SCALE
)

local function draw_blame_info_box(text, sx, sy)
  if previous_scale ~= SCALE then
    desc_font = style.code_font:copy(
      config.plugins.gitblame.font_size * SCALE
    )
    previous_scale = SCALE
  end

  local font = desc_font
  local lh = font:get_height()
  local y = sy + lh + (2 * style.padding.y)
  local width = 0

  local lines = {}
  for line in string.gmatch(text.."\n", "(.-)\n") do
      width = math.max(width, font:get_width(line))
      table.insert(lines, line)
  end

  sy = sy + lh + style.padding.y

  local height = #lines * font:get_height()

  -- draw background rect
  renderer.draw_rect(
    sx,
    sy,
    width + style.padding.x * 2,
    height + style.padding.y * 2,
    style.background3
  )

  -- draw text
  for _, line in pairs(lines) do
    common.draw_text(
      font,
      style.text,
      line,
      "left",
      sx + style.padding.x,
      y,
      width,
      lh
    )
    y = y + lh
  end
end

local function get_text_coordinates()
    local av = get_active_view()

    if av ~= nil then
        local line, _ = av.doc:get_selection()
        local x, y = av:get_line_screen_position(line)

        return x, y
    end

    return nil, nil
end

local parent_draw = DocView.draw

function DocView.draw(self)
    parent_draw(self)

    if config.plugins.gitblame.show_blame then
      local message

      local av = get_active_view()

      local blame_text = gitblame.get_blame_text(av)

      if blame_text ~= nil then
        message = "Git Blame | " .. blame_text

        -- let's get the coordinates for our text
        local x, y = get_text_coordinates()

        if x ~=nil and y ~= nil then
            draw_blame_info_box(message, x, y)
        end
      end

   end
end

local function predicate()
    return core.active_view:is(DocView)
end

local function toggle_gitblame()
   config.plugins.gitblame.show_blame = not config.plugins.gitblame.show_blame
end

command.add(predicate, {
    ["git blame:toggle"] = function()
        toggle_gitblame()
    end
})
