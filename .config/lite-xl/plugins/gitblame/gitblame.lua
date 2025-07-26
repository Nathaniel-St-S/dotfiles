local core = require "core"
local config = require "core.config"

local gitblame = {}

local blame_pattern = "%w+[ (_.%w]+[ ]+%d+[-]?%d+[-]?%d+[ ]?%d+[:]?%d+[:]?%d+[ ]+[+-]?%d+"
local hash_pattern = "[0-9a-f]+"
-- local username_pattern = "[ _.%w]+"
local opening_bracket_pattern = "[ (]*"
local datetime_pattern = "%d+[-]?%d+[-]?%d+[ ]?%d+[:]?%d+[:]?%d+[ ]+[+-]?%d+"

local not_commited_yet_hash = "00000000"

local not_git_repo_message = "fatal: not a git repository"

local function exec(cmd)
    local proc = process.start(cmd)

    if proc then

        local output = ""

        while true do
            local rdbuf = proc:read_stdout()
            if not rdbuf then
                break
            else
                output = output .. rdbuf
            end
        end

        return output
    end

    return nil
end

local function log_data(var_name, var_value)
  if config.plugins.gitblame.debug then
    if var_value ~= nil then
      if type(var_value) == 'table' then
        core.try(function (var)
            local data = table.concat(var, " ")
            core.log("[GITBLAME] " .. var_name .. " : " .. data)
          end, var_value
        )
      else
        core.try(
          function (name, value)
            core.log("[GITBLAME] " .. name .. " : " .. value)
          end, var_name, var_value
        )
      end
    else
      core.try(
        function (name)
          core.log("[GITBLAME] " .. name .. " : nil")
        end, var_name
      )
    end
  end
end

local function get_commit_message(commit_hash)
  local git_command = {config.plugins.gitblame.git_executable, "show", "--no-color", "--pretty=format:%s", "--no-patch", commit_hash}

  log_data("get_commit_message.git_command", git_command)

  local result = exec(git_command)
  if result ~= nil then
    local length = result:len()

    if length ~= nil then
      if length > config.plugins.gitblame.max_commit_message_length then
        result = result:sub(0, config.plugins.gitblame.max_commit_message_length) .. "..."
      end
    end
  end

  return result
end

local function truncate_blame_text(blame_text)
  local _, first_index = blame_text:find(hash_pattern)

  local last_index, _ = blame_text:find(datetime_pattern)

  return blame_text:sub(first_index+1, last_index-1)
end

function gitblame.get_blame_text(active_view)
  if active_view ~= nil then
    local abs_filename = active_view.doc.abs_filename
    local line, _ = active_view.doc:get_selection()

    local git_command = {config.plugins.gitblame.git_executable, "blame", "-L", line .. "," .. line, abs_filename}

    log_data("get_blame_text.git_command", git_command)

    local git_output = exec(git_command)

    log_data("git_output", git_output)

    local blame_text = git_output:match(blame_pattern)

    log_data("blame_text", blame_text)

    if blame_text == nil then
      local a, _ = git_output:find(not_git_repo_message)

      if a ~= nil then
        return "Not a git repository"
      end

      return nil
    end

    local commit_hash = blame_text:match(hash_pattern)

    log_data("commit_hash", commit_hash)

    if commit_hash == nil then
      return nil
    end

    if commit_hash == not_commited_yet_hash then
      return "Not Committed Yet"
    end

    local datetime = blame_text:match(datetime_pattern)

    log_data("datetime", datetime)

    blame_text = truncate_blame_text(blame_text)

    log_data("truncated_blame_text", blame_text)

    local _, username_start_index = blame_text:find(opening_bracket_pattern)

    local username = blame_text:sub(username_start_index+1, blame_text:len() - 1)

    log_data("username", username)

    local commit_message = get_commit_message(commit_hash)

    local result = commit_hash .. ' | ' .. "(" .. username .. ") " .. datetime .. ' | ' ..  commit_message

    log_data("result", result)

    return result
  end
end

return gitblame
