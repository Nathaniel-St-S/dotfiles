-- mod-version:3
-- idle_world.lua - Enhanced Lite XL plugin with idle pixel animal world, day-night cycle, aging, reproduction, species types, weather, and biomes

--print("=== IDLE WORLD PLUGIN: Starting to load ===")

local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"
local View = require "core.view"
local config = require "core.config"
local renderer = require "renderer"
local style = require "core.style"

local IdleWorldView = View:extend()

-- Config
local TILE_SIZE = 16
local ANIMAL_SIZE = 6
local INITIAL_ANIMALS = 20
local MAX_ANIMALS = 50
local DAY_NIGHT_SPEED = 0.002  -- Lower values = slower day/night cycle (default was 0.01)

-- Biome colors and properties
local BIOMES = {
  forest = {
    color = {34, 139, 34, 255},    -- Forest green
    tiles = {"grass", "tree", "bush"},
    animal_preference = {walker = 1.5, flyer = 1.0, aquatic = 0.2}
  },
  desert = {
    color = {238, 203, 173, 255},  -- Sandy brown
    tiles = {"sand", "rock", "cactus"},
    animal_preference = {walker = 1.0, flyer = 1.3, aquatic = 0.1}
  },
  water = {
    color = {65, 105, 225, 255},   -- Royal blue
    tiles = {"water", "water", "water"},
    animal_preference = {walker = 0.3, flyer = 0.8, aquatic = 2.0}
  },
  grassland = {
    color = {124, 252, 0, 255},    -- Lawn green
    tiles = {"grass", "grass", "flower"},
    animal_preference = {walker = 1.2, flyer = 1.4, aquatic = 0.5}
  },
  mountain = {
    color = {139, 137, 137, 255},  -- Dark gray
    tiles = {"rock", "stone", "snow"},
    animal_preference = {walker = 0.8, flyer = 1.6, aquatic = 0.1}
  }
}

local TILE_COLORS = {
  grass = {77, 179, 77, 255},
  water = {51, 102, 204, 255},
  sand = {204, 179, 77, 255},
  dirt = {128, 77, 51, 255},
  rock = {128, 128, 128, 255},
  tree = {34, 89, 34, 255},
  bush = {60, 120, 60, 255},
  cactus = {107, 142, 35, 255},
  flower = {255, 182, 193, 255},
  stone = {105, 105, 105, 255},
  snow = {240, 248, 255, 255}
}

-- Weather types
local WEATHER_TYPES = {
  clear = {name = "Clear", intensity = 0, color = {255, 255, 255, 0}},
  rain = {name = "Rain", intensity = 0.8, color = {100, 149, 237, 120}},
  snow = {name = "Snow", intensity = 0.6, color = {255, 250, 250, 100}},
  storm = {name = "Storm", intensity = 1.2, color = {70, 70, 70, 150}},
  wind = {name = "Wind", intensity = 0.4, color = {200, 200, 200, 60}}
}

-- Helper functions
local function rand_choice(t)
  return t[math.random(1, #t)]
end

local function distance(x1, y1, x2, y2)
  return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

-- Safe random function that ensures integer bounds
local function safe_random(min_val, max_val)
  -- Handle single parameter case
  if max_val == nil then
    if min_val == nil then
      return math.random()  -- No parameters, return 0-1
    else
      local max_int = math.floor(min_val + 0.5)
      if max_int < 1 then max_int = 1 end
      return math.random(max_int)
    end
  end
  
  -- Handle two parameter case
  local min_int = math.floor(min_val + 0.5)
  local max_int = math.floor(max_val + 0.5)
  if min_int > max_int then
    min_int, max_int = max_int, min_int
  end
  if min_int == max_int then
    return min_int
  end
  return math.random(min_int, max_int)
end

function IdleWorldView:new()
  IdleWorldView.super.new(self)
  self.background = {}
  self.biome_map = {}
  self.animals = {}
  self.particles = {}
  self.time = 0
  self.daylight = 1
  self.last_update = 0
  self.world_width = 800
  self.world_height = 500
  self.last_size_w = 0
  self.last_size_h = 0
  
  -- Weather system
  self.weather = {
    current = "clear",
    duration = 0,
    max_duration = math.random(300, 800),
    transition_time = 0
  }
  
  self:generate_world()
  self:spawn_animals(INITIAL_ANIMALS)
  self.scrollable = false
  --print("Idle World initialized with " .. #self.animals .. " animals")
end

function IdleWorldView:get_name()
  return "Idle Animal World"
end

function IdleWorldView:update_world_size()
  local w, h = self.size.x, self.size.y
  if w ~= self.last_size_w or h ~= self.last_size_h then
    local old_width = self.world_width
    local old_height = self.world_height
    
    self.world_width = math.max(400, w - 20)
    self.world_height = math.max(300, h - 40)
    
    -- Scale animal positions if world size changed significantly
    if old_width > 0 and old_height > 0 then
      local scale_x = self.world_width / old_width
      local scale_y = self.world_height / old_height
      
      for _, animal in ipairs(self.animals) do
        -- Floor the scaled positions to ensure they're integers
        animal.x = math.floor(math.max(0, math.min(self.world_width - ANIMAL_SIZE, animal.x * scale_x)) + 0.5)
        animal.y = math.floor(math.max(0, math.min(self.world_height - ANIMAL_SIZE, animal.y * scale_y)) + 0.5)
      end
    end
    
    self:generate_world()
    self.last_size_w = w
    self.last_size_h = h
  end
end

function IdleWorldView:generate_biomes()
  local rows = math.ceil(self.world_height / TILE_SIZE)
  local cols = math.ceil(self.world_width / TILE_SIZE)
  
  -- Generate biome centers
  local biome_centers = {}
  local biome_names = {"forest", "desert", "water", "grassland", "mountain"}
  local num_biomes = math.random(3, 6)
  
  for i = 1, num_biomes do
    table.insert(biome_centers, {
      x = math.random(1, cols),
      y = math.random(1, rows),
      biome = rand_choice(biome_names),
      radius = math.random(8, 20)
    })
  end
  
  -- Fill biome map based on nearest biome center
  self.biome_map = {}
  for y = 1, rows do
    self.biome_map[y] = {}
    for x = 1, cols do
      local closest_biome = "grassland"  -- default
      local min_distance = math.huge
      
      for _, center in ipairs(biome_centers) do
        local dist = distance(x, y, center.x, center.y)
        local influenced_dist = dist - (center.radius * 0.5)
        
        if influenced_dist < min_distance then
          min_distance = influenced_dist
          closest_biome = center.biome
        end
      end
      
      self.biome_map[y][x] = closest_biome
    end
  end
end

function IdleWorldView:generate_world()
  self:generate_biomes()
  
  local rows = math.ceil(self.world_height / TILE_SIZE)
  local cols = math.ceil(self.world_width / TILE_SIZE)
  
  self.background = {}
  for y = 1, rows do
    self.background[y] = {}
    for x = 1, cols do
      local biome = self.biome_map[y] and self.biome_map[y][x] or "grassland"
      self.background[y][x] = rand_choice(BIOMES[biome].tiles)
    end
  end
  --print("Generated world: " .. cols .. "x" .. rows .. " tiles with biomes")
end

function IdleWorldView:get_biome_at(x, y)
  local tile_x = math.floor(x / TILE_SIZE) + 1
  local tile_y = math.floor(y / TILE_SIZE) + 1
  
  if self.biome_map[tile_y] and self.biome_map[tile_y][tile_x] then
    return self.biome_map[tile_y][tile_x]
  end
  return "grassland"
end

function IdleWorldView:spawn_animals(n)
  for i = 1, n do
    local species = rand_choice({"walker", "flyer", "aquatic"})
    local x = safe_random(0, self.world_width - ANIMAL_SIZE)
    local y = safe_random(0, self.world_height - ANIMAL_SIZE)
    
    table.insert(self.animals, {
      x = x,
      y = y,
      dx = (math.random() - 0.5) * 2,
      dy = (math.random() - 0.5) * 2,
      color = self:get_species_color(species),
      mode = (math.random() < 0.5 and "wander") or "flock",
      age = 0,
      lifespan = math.random(600, 1200),
      species = species,
      cooldown = 0,
      preferred_biome = self:get_biome_at(x, y),
    })
  end
end

function IdleWorldView:get_species_color(species)
  if species == "walker" then
    return {math.random(150, 255), math.random(100, 200), math.random(50, 150), 255}
  elseif species == "flyer" then
    return {math.random(100, 200), math.random(150, 255), math.random(200, 255), 255}
  else -- aquatic
    return {math.random(50, 150), math.random(100, 200), math.random(150, 255), 255}
  end
end

function IdleWorldView:update_weather()
  self.weather.duration = self.weather.duration + 1
  
  -- Change weather periodically
  if self.weather.duration >= self.weather.max_duration then
    local weather_types = {"clear", "rain", "snow", "storm", "wind"}
    local new_weather = rand_choice(weather_types)
    
    -- Make clear weather more likely
    if math.random() < 0.4 then
      new_weather = "clear"
    end
    
    self.weather.current = new_weather
    self.weather.duration = 0
    self.weather.max_duration = math.random(200, 600)
    self.weather.transition_time = 60
  end
  
  if self.weather.transition_time > 0 then
    self.weather.transition_time = self.weather.transition_time - 1
  end
end

function IdleWorldView:spawn_weather_particles()
  local weather = WEATHER_TYPES[self.weather.current]
  if weather.intensity == 0 then return end
  
  -- Spawn particles based on weather intensity
  local particle_count = math.floor(weather.intensity * 3)
  
  for i = 1, particle_count do
    if #self.particles < 200 then -- Limit particles
      local particle = {
        x = safe_random(-20, self.world_width + 20),
        y = -10,
        life = math.random(60, 120),
        weather_type = self.weather.current
      }
      
      if self.weather.current == "rain" or self.weather.current == "storm" then
        particle.dx = (math.random() - 0.5) * 2
        particle.dy = safe_random(3, 6)
        particle.size = safe_random(1, 2)
      elseif self.weather.current == "snow" then
        particle.dx = (math.random() - 0.5) * 4
        particle.dy = safe_random(1, 3)
        particle.size = safe_random(2, 4)
      elseif self.weather.current == "wind" then
        particle.dx = safe_random(2, 8)
        particle.dy = (math.random() - 0.5) * 2
        particle.size = 1
      end
      
      table.insert(self.particles, particle)
    end
  end
end

function IdleWorldView:update_particles()
  for i = #self.particles, 1, -1 do
    local p = self.particles[i]
    p.x = p.x + (p.dx or 0)
    p.y = p.y + (p.dy or 0)
    p.life = p.life - 1
    
    -- Remove particles that are off-screen or expired
    if p.life <= 0 or p.y > self.world_height + 20 or p.x > self.world_width + 20 or p.x < -20 then
      table.remove(self.particles, i)
    end
  end
end

function IdleWorldView:update()
  local current_time = os.clock()
  if current_time - self.last_update < 0.016 then -- ~60 FPS
    return
  end
  self.last_update = current_time
  
  -- Update world size if view was resized
  self:update_world_size()
  
  self.time = self.time + 1
  -- Day-night cycle (0.3 to 1.0 brightness) - configurable speed
  self.daylight = 0.65 + 0.35 * math.sin(self.time * DAY_NIGHT_SPEED)
  
  -- Update weather
  self:update_weather()
  self:spawn_weather_particles()
  self:update_particles()
  
  local weather_effect = WEATHER_TYPES[self.weather.current]
  local new_animals = {}

  for i = #self.animals, 1, -1 do
    local a = self.animals[i]
    local current_biome = self:get_biome_at(a.x, a.y)
    local biome_preference = BIOMES[current_biome].animal_preference[a.species] or 1.0

    -- Behavior logic with biome influence
    if a.mode == "wander" then
      -- Random walk with biome preference
      a.dx = a.dx + (math.random() - 0.5) * 0.2
      a.dy = a.dy + (math.random() - 0.5) * 0.2
      
      -- Bias toward preferred biome
      if biome_preference < 1.0 then
        -- Try to move toward a better biome
        local target_x = math.random() * self.world_width
        local target_y = math.random() * self.world_height
        a.dx = a.dx + ((target_x - a.x) * 0.001)
        a.dy = a.dy + ((target_y - a.y) * 0.001)
      end
    else -- flock
      -- Move toward center of other animals of same species
      local cx, cy = 0, 0
      local count = 0
      for j, other in ipairs(self.animals) do
        if j ~= i and other.species == a.species then
          cx = cx + other.x
          cy = cy + other.y
          count = count + 1
        end
      end
      if count > 0 then
        cx = cx / count
        cy = cy / count
        a.dx = a.dx + ((cx - a.x) * 0.002)
        a.dy = a.dy + ((cy - a.y) * 0.002)
      end
    end

    -- Weather effects on movement
    local speed_modifier = 1.0
    if self.weather.current == "storm" then
      if a.species == "flyer" then
        speed_modifier = 0.3  -- Flyers struggle in storms
      else
        speed_modifier = 0.7  -- Others slow down too
      end
    elseif self.weather.current == "wind" then
      if a.species == "flyer" then
        a.dx = a.dx + (math.random() - 0.5)  -- Wind affects flyers
      end
    elseif self.weather.current == "rain" then
      speed_modifier = 0.8  -- Everyone slows in rain
    end

    -- Limit velocity with weather and biome effects
    local base_speed = (a.species == "flyer") and 3 or (a.species == "aquatic" and 2 or 1.5)
    local max_speed = base_speed * speed_modifier * biome_preference
    local speed = math.sqrt(a.dx * a.dx + a.dy * a.dy)
    if speed > max_speed then
      a.dx = (a.dx / speed) * max_speed
      a.dy = (a.dy / speed) * max_speed
    end

    -- Update position
    a.x = a.x + a.dx
    a.y = a.y + a.dy

    -- Bounce off walls
    if a.x < 0 then 
      a.x = 0
      a.dx = math.abs(a.dx)
    elseif a.x > self.world_width - ANIMAL_SIZE then
      a.x = self.world_width - ANIMAL_SIZE
      a.dx = -math.abs(a.dx)
    end
    
    if a.y < 0 then
      a.y = 0
      a.dy = math.abs(a.dy)
    elseif a.y > self.world_height - ANIMAL_SIZE then
      a.y = self.world_height - ANIMAL_SIZE
      a.dy = -math.abs(a.dy)
    end

    -- Aging and death (affected by biome suitability)
    local aging_rate = 2.0 - biome_preference  -- Age faster in unsuitable biomes
    a.age = a.age + aging_rate
    
    if a.age > a.lifespan then
      table.remove(self.animals, i)
    else
      -- Reproduction (more likely in suitable biomes)
      local reproduction_chance = 0.003 * biome_preference
      if a.cooldown <= 0 and #self.animals + #new_animals < MAX_ANIMALS then
        if math.random() < reproduction_chance then
          local child_x = math.max(0, math.min(self.world_width - ANIMAL_SIZE, a.x + (math.random() - 0.5) * 40))
          local child_y = math.max(0, math.min(self.world_height - ANIMAL_SIZE, a.y + (math.random() - 0.5) * 40))
          
          local child = {
            x = child_x,
            y = child_y,
            dx = (math.random() - 0.5) * 2,
            dy = (math.random() - 0.5) * 2,
            color = { 
              math.max(50, math.min(255, a.color[1] + (math.random() - 0.5) * 60)),
              math.max(50, math.min(255, a.color[2] + (math.random() - 0.5) * 60)),
              math.max(50, math.min(255, a.color[3] + (math.random() - 0.5) * 60)),
              255
            },
            mode = rand_choice({"wander", "flock"}),
            age = 0,
            lifespan = math.random(600, 1200),
            species = a.species,
            cooldown = 200,
            preferred_biome = current_biome,
          }
          a.cooldown = 300
          table.insert(new_animals, child)
        end
      else
        a.cooldown = math.max(0, a.cooldown - 1)
      end
    end
  end

  -- Add new animals
  for _, child in ipairs(new_animals) do
    table.insert(self.animals, child)
  end
  
  -- Spawn new animals if population gets too low
  if #self.animals < 5 then
    self:spawn_animals(5)
  end
end

function IdleWorldView:draw()
  IdleWorldView.super.draw(self)
  
  local x, y = self:get_content_offset()
  local w, h = self.size.x, self.size.y
  
  -- Clear the entire view area with a background color
  renderer.draw_rect(x, y, w, h, {32, 32, 48, 255})
  
  -- Helper function to apply day-night lighting and weather
  local function mod_color(c)
    local weather_effect = WEATHER_TYPES[self.weather.current]
    local base_light = self.daylight
    
    -- Weather affects lighting
    if self.weather.current == "storm" then
      base_light = base_light * 0.6
    elseif self.weather.current == "rain" then
      base_light = base_light * 0.8
    end
    
    return {
      math.floor(c[1] * base_light),
      math.floor(c[2] * base_light),
      math.floor(c[3] * base_light),
      c[4]
    }
  end

  -- Calculate world offset to center it in the view
  local world_offset_x = x + math.max(0, (w - self.world_width) / 2)
  local world_offset_y = y + math.max(0, (h - self.world_height) / 2)

  -- Draw background tiles
  for row_idx, row in ipairs(self.background) do
    for col_idx, tile in ipairs(row) do
      local tx = world_offset_x + (col_idx - 1) * TILE_SIZE
      local ty = world_offset_y + (row_idx - 1) * TILE_SIZE
      local color = mod_color(TILE_COLORS[tile])
      renderer.draw_rect(tx, ty, TILE_SIZE, TILE_SIZE, color)
    end
  end

  -- Draw animals
  for _, a in ipairs(self.animals) do
    local color = mod_color(a.color)
    local ax = world_offset_x + a.x
    local ay = world_offset_y + a.y
    
    -- Species-specific rendering
    if a.species == "flyer" then
      -- Draw glow (larger, semi-transparent)
      local glow_color = {color[1], color[2], color[3], 64}
      renderer.draw_rect(ax - 1, ay - 1, ANIMAL_SIZE + 2, ANIMAL_SIZE + 2, glow_color)
    elseif a.species == "aquatic" then
      -- Draw water ripple effect
      local ripple_color = {100, 150, 255, 32}
      renderer.draw_rect(ax - 2, ay - 2, ANIMAL_SIZE + 4, ANIMAL_SIZE + 4, ripple_color)
    end
    
    -- Draw main body
    renderer.draw_rect(ax, ay, ANIMAL_SIZE, ANIMAL_SIZE, color)
  end

  -- Draw weather particles
  for _, p in ipairs(self.particles) do
    local px = world_offset_x + p.x
    local py = world_offset_y + p.y
    local alpha = math.floor(255 * (p.life / 120))
    
    if p.weather_type == "rain" or p.weather_type == "storm" then
      renderer.draw_rect(px, py, 1, p.size * 3, {150, 200, 255, alpha})
    elseif p.weather_type == "snow" then
      renderer.draw_rect(px, py, p.size, p.size, {255, 255, 255, alpha})
    elseif p.weather_type == "wind" then
      renderer.draw_rect(px, py, 3, 1, {200, 200, 200, alpha})
    end
  end

  -- Draw weather overlay
  local weather_effect = WEATHER_TYPES[self.weather.current]
  if weather_effect.intensity > 0 then
    local overlay_alpha = math.floor(weather_effect.color[4] * (weather_effect.intensity * 0.5))
    local overlay_color = {weather_effect.color[1], weather_effect.color[2], weather_effect.color[3], overlay_alpha}
    renderer.draw_rect(world_offset_x, world_offset_y, self.world_width, self.world_height, overlay_color)
  end

  -- Draw info text
  local info_text = string.format("Animals: %d | Time: %d | Daylight: %.1f | World: %dx%d | Weather: %s", 
                                 #self.animals, self.time, self.daylight, 
                                 math.floor(self.world_width), math.floor(self.world_height),
                                 WEATHER_TYPES[self.weather.current].name)
  renderer.draw_text(style.font, info_text, x + 10, y + 10, {255, 255, 255, 255})
  
  -- Draw species count
  local species_count = {walker = 0, flyer = 0, aquatic = 0}
  for _, a in ipairs(self.animals) do
    species_count[a.species] = species_count[a.species] + 1
  end
  local species_text = string.format("Walkers: %d | Flyers: %d | Aquatic: %d | Particles: %d", 
                                    species_count.walker, species_count.flyer, species_count.aquatic, #self.particles)
  renderer.draw_text(style.font, species_text, x + 10, y + 30, {200, 200, 200, 255})
end

-- Make sure the view updates regularly
function IdleWorldView:on_mouse_moved(x, y, dx, dy)
  return true
end

function IdleWorldView:on_mouse_pressed(button, x, y, clicks)
  if button == "left" then
    local content_x, content_y = self:get_content_offset()
    local w, h = self.size.x, self.size.y
    local world_offset_x = content_x + math.max(0, (w - self.world_width) / 2)
    local world_offset_y = content_y + math.max(0, (h - self.world_height) / 2)
    
    local world_x = x - world_offset_x
    local world_y = y - world_offset_y
    
    if world_x >= 0 and world_x <= self.world_width and world_y >= 0 and world_y <= self.world_height then
      local biome = self:get_biome_at(world_x, world_y)
      
      for i = 1, 3 do
        -- Choose species based on biome preference
        local species = "walker"
        local biome_prefs = BIOMES[biome].animal_preference
        local rand_val = math.random()
        
        if biome_prefs.aquatic > 1.5 and rand_val < 0.4 then
          species = "aquatic"
        elseif biome_prefs.flyer > 1.2 and rand_val < 0.7 then
          species = "flyer"
        end
        
        local spawn_x = math.max(0, math.min(self.world_width - ANIMAL_SIZE, world_x + (math.random() - 0.5) * 40))
        local spawn_y = math.max(0, math.min(self.world_height - ANIMAL_SIZE, world_y + (math.random() - 0.5) * 40))
        
        table.insert(self.animals, {
          x = spawn_x,
          y = spawn_y,
          dx = (math.random() - 0.5) * 2,
          dy = (math.random() - 0.5) * 2,
          color = self:get_species_color(species),
          mode = rand_choice({"wander", "flock"}),
          age = 0,
          lifespan = math.random(600, 1200),
          species = species,
          cooldown = 0,
          preferred_biome = biome,
        })
      end
    end
  end
  return true
end

-- Register commands
command.add(nil, {
  ["idle-world:open"] = function()
    --print("Opening Idle World...")
    local view = IdleWorldView()
    local node = core.root_view:get_active_node()
    node:add_view(view)
    --print("Idle World view created and added")
  end
})

keymap.add({ ["ctrl+shift+i"] = "idle-world:open" })

command.add(nil, {
  ["idle-world:toggle"] = function()
    command.perform("idle-world:open")
  end
})

-- Auto-update loop
core.add_thread(function()
  while true do
    for _, view in ipairs(core.root_view.root_node:get_children()) do
      if view.update and view.animals then
        view:update()
        core.redraw = true
      end
    end
    coroutine.yield(0.016) -- ~60 FPS
  end
end)

-- print("Idle World plugin loaded successfully")
-- print("Use Ctrl+Shift+I to open Idle World, or use command palette: 'Idle World: Open'")
