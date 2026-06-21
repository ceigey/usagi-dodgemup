local player_size = 16
local player_speed = 180 -- px/s
local fire_delay = 0.1   -- s
local fire_timer = 0
local bullet_speed = 420 -- px/s
local player_bullet_w = 4
local player_bullet_h = 10
-- "It’s the time in seconds that an enemy will flash then they’re hit by a bullet" - docs
local hit_flash_time = 0.2 -- secs
local enemy_bullet_size = 12

-- Wave spawning
local GAME_W = 320
local GAME_H = 320
local WAVES = {
  {
    { 72,  -20 },
    { 112, -60 },
    { 200, -100 },
    { 240, -140 },
  },
  {
    { 72,           -20 },
    { 100,          -60 },
    { GAME_W - 72,  -20 },
    { GAME_W - 100, -60 },
  },
  {
    { 72,  -20 },
    { 102, -40 },
    { 132, -60 },
    { 162, -80 },
  },
  -- add more waves here youself!
}

---@class Player
---@field x number
---@field y number
---@field bullets table

---@class PlayerHitbox: Usagi.Rect
---@field x number
---@field y number
---@field w number
---@field h number

---get player hitbox
---@param player Player
---@return PlayerHitbox
local function get_player_hitbox(player)
  local hitbox_size = 4
  return {
    x = player.x + player_size / 2 - hitbox_size / 2,
    y = player.y + player_size / 2 - hitbox_size / 2,
    w = hitbox_size,
    h = hitbox_size,
  }
end

---@class Enemy: Usagi.Rect
---@field x number
---@field y number
---@field hp number
---@field w integer width
---@field h integer height
---@field speed number px/s
---@field color integer Usagi palette colour
---@field flash_timer integer how long left to flash for?
---@field fire_timer number -- seconds until first shot
---@field fire_delay number -- seconds between shots
---@field shots_fired number
---@field shots_limit number

-- Gotta init some enemies somehow
---comment
---@param x integer
---@param y integer
---@return Enemy
local function init_enemy(x, y)
  return {
    x = x,
    y = y,
    hp = 12,
    w = 16,
    h = 16,
    speed = 44, -- px/s
    color = gfx.COLOR_RED,
    flash_timer = 0,
    fire_timer = 1.5,
    fire_delay = 0.4,
    shots_fired = 0,
    shots_limit = 3,
  }
end

---@param dt integer
local function update_player_move(dt)
  local input_delta = { x = 0, y = 0 }
  if input.held(input.UP) then
    input_delta.y -= 1
  end
  if input.held(input.DOWN) then
    input_delta.y += 1
  end
  if input.held(input.LEFT) then
    input_delta.x -= 1
  end
  if input.held(input.RIGHT) then
    input_delta.x += 1
  end
  local normalized_input = util.vec_normalize(input_delta)
  State.player.x += normalized_input.x * player_speed * dt
  State.player.y += normalized_input.y * player_speed * dt
  State.player.x = util.clamp(State.player.x, 0, usagi.GAME_W - player_size)
  State.player.y = util.clamp(State.player.y, 0, usagi.GAME_H - player_size)
end

local function update_player_fire(dt)
  fire_timer -= dt

  if fire_timer <= 0 and input.held(input.BTN1) then
    local bul_y = State.player.y - player_bullet_h
    -- fire 3 bullets
    table.insert(State.player.bullets,
      { x = State.player.x - player_bullet_w, y = bul_y })
    table.insert(State.player.bullets,
      { x = State.player.x + player_size / 2 - player_bullet_w / 2, y = bul_y })
    table.insert(State.player.bullets,
      { x = State.player.x + player_size, y = bul_y })
    fire_timer = fire_delay
  end
end

---@param dt integer
local function update_player_bullets(dt)
  for i = #State.player.bullets, 1, -1 do
    local bullet = State.player.bullets[i]
    -- move the bullet upward
    bullet.y -= bullet_speed * dt

    -- check if the bullet has overlapped with any of the enemies
    for _, enemy in ipairs(State.enemies) do
      if util.rect_overlap(
            { x = bullet.x, y = bullet.y,
              w = player_bullet_w, h = player_bullet_h },
            enemy) and enemy.hp > 0
      then
        bullet.dead = true
        enemy.hp -= 1
        enemy.flash_timer = hit_flash_time

        -- This check happens here to make sure the score is only counted
        -- the first time health reaches 0
        if enemy.hp <= 0 then
          State.score += 100
        end
      end
    end

    -- remove bullets that have flown off the top of the screen
    if bullet.y < -player_bullet_h or bullet.dead then
      table.remove(State.player.bullets, i)
    end
  end
end

---@param dt integer
local function update_enemies(dt)
  for i = #State.enemies, 1, -1 do
    local enemy = State.enemies[i]

    enemy.y += enemy.speed * dt

    if enemy.flash_timer > 0 then
      enemy.flash_timer = enemy.flash_timer - dt
    end

    enemy.fire_timer -= dt
    if enemy.fire_timer <= 0 and enemy.shots_fired < enemy.shots_limit then
      local ex = enemy.x + enemy.w / 2 - enemy_bullet_size / 2
      local ey = enemy.y + enemy.h

      -- bullet center positions
      local bcx = ex + enemy_bullet_size / 2
      local bcy = ey + enemy_bullet_size / 2

      local angle = math.atan(
        (State.player.y + player_size / 2) - bcy,
        (State.player.x + player_size / 2) - bcx
      )

      table.insert(State.enemy_bullets,
        {
          x = ex,
          y = ey,
          angle = angle,
        })
      enemy.shots_fired += 1
      enemy.fire_timer = enemy.fire_delay
    end

    if enemy.hp <= 0 or enemy.y > usagi.GAME_H then
      table.remove(State.enemies, i)
    end
  end
end

---@param dt integer
local function update_enemy_bullets(dt)
  for i = #State.enemy_bullets, 1, -1 do
    local bullet = State.enemy_bullets[i]
    local speed = 120
    bullet.x += math.cos(bullet.angle) * speed * dt
    bullet.y += math.sin(bullet.angle) * speed * dt

    if util.rect_overlap(
          { x = bullet.x, y = bullet.y, w = enemy_bullet_size, h = enemy_bullet_size },
          get_player_hitbox(State.player)
        ) then
      bullet.dead = true
      State.game_over = true
      effect.flash(0.4, gfx.COLOR_WHITE)
      effect.screen_shake(0.8, 2)
    end

    if bullet.y > usagi.GAME_H or bullet.dead then
      table.remove(State.enemy_bullets, i)
    end
  end
end

local function try_spawn_enemies()
  if #State.enemies == 0 and State.current_wave < #WAVES then
    State.current_wave += 1

    State.enemies = {}
    for _, enemy in ipairs(WAVES[State.current_wave]) do
      table.insert(State.enemies, init_enemy(enemy[1], enemy[2]))
    end
  end
end


function _config()
  ---@type Usagi.Config
  return {
    name = "Shmup",
    game_id = "com.ceigey.shmuptutorial",
    game_width = GAME_W,
    game_height = GAME_H,
  }
end

function _init()
  -- Live reload preserves globals across saved edits but resets locals.
  -- Stash mutable game state in a capitalized global like `State` so it
  -- survives reloads; F5 calls _init again to reset.
  State = {
    player = {
      x = usagi.GAME_W / 2 - player_size / 2,
      y = usagi.GAME_H - 60,
      bullets = {},
    },
    enemies = {},
    enemy_bullets = {},
    game_over = false,
    current_wave = 0,
    timer = 60,
    score = 0,
  }
end

---update state each frame before draw
---@param dt integer -- delta time: seconds since last frame
function _update(dt)
  -- "if not try_game_over() ?"
  if State.game_over then
    if input.pressed(input.BTN1) then
      _init()
    end
  else
    -- "update_timer(dt)"
    State.timer -= dt
    State.timer = math.max(State.timer, 0)
    if State.timer == 0 then
      State.game_over = true
    end

    update_player_move(dt)
    update_player_fire(dt)
    update_player_bullets(dt)
    update_enemies(dt)
    update_enemy_bullets(dt)
    try_spawn_enemies()
  end
end

---draw each frame after update
---@param dt integer -- delta time: seconds since last frame
function _draw(dt)
  gfx.clear(gfx.COLOR_WHITE)

  -- ROUGH IDEA OF DRAW ORDER?
  -- Should look at famous shmups to see theirs
  -- DDP seems to have:
  -- Enemy bullets
  -- Player
  -- Player bullets
  -- enemy
  -- bg?
  if not State.game_over then
    gfx.rect_fill(
      State.player.x, State.player.y,
      player_size, player_size, gfx.COLOR_BLACK
    )
    local p_hitbox = get_player_hitbox(State.player)
    gfx.rect_fill(
      p_hitbox.x, p_hitbox.y, p_hitbox.w, p_hitbox.h,
      gfx.COLOR_WHITE
    )
  end

  -- ENEMIES (order specified by tutorial)
  for _, enemy in ipairs(State.enemies) do
    local color = enemy.color
    if enemy.flash_timer > 0 then
      color = gfx.COLOR_PINK
    end
    gfx.rect_fill(enemy.x, enemy.y, enemy.w, enemy.h, color)
  end

  -- FIRING (player!)
  for _, bullet in ipairs(State.player.bullets) do
    gfx.rect_fill(bullet.x, bullet.y,
      player_bullet_w, player_bullet_h, gfx.COLOR_LIGHT_GRAY)
  end

  -- ENEMY BULLETS RENDERING
  for _, bullet in ipairs(State.enemy_bullets) do
    gfx.rect_fill(bullet.x, bullet.y,
      enemy_bullet_size, enemy_bullet_size, gfx.COLOR_BLUE)
  end

  -- Things got a little funky here in the tutorial so I cleaned up the code
  -- (overlaid text etc)
  gfx.text(string.format("%.2f", State.timer), GAME_W / 2 - 16, 10, gfx.COLOR_BLACK)
  gfx.text("Score: " .. State.score, 10, 10, gfx.COLOR_BLACK)
  gfx.text("Wave: " .. State.current_wave, 10, 30, gfx.COLOR_BLACK)
  if State.game_over then
    if State.timer == 0 then
      gfx.text("TIME OUT", 10, 60, gfx.COLOR_BLACK)
    else
      gfx.text("GAME OVER", 10, 60, gfx.COLOR_BLACK)
    end
    gfx.text("Press " .. input.mapping_for(input.BTN1) .. " to restart!",
      10, 80, gfx.COLOR_BLACK)
  end
end
