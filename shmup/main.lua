local player_size = 16
local player_speed = 180 -- px/s
local fire_delay = 0.1   -- s
local fire_timer = 0
local bullet_speed = 420 -- px/s
local player_bullet_w = 4
local player_bullet_h = 10
-- "It’s the time in seconds that an enemy will flash then they’re hit by a bullet" - docs
local hit_flash_time = 0.2 -- secs


---@class Enemy: Usagi.Rect
---@field x number
---@field y number
---@field hp number
---@field w integer width
---@field h integer height
---@field speed number px/s
---@field color integer Usagi palette colour
---@field flash_timer integer how long left to flash for?

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
    flash_timer = 0
  }
end

function _config()
  ---@type Usagi.Config
  return {
    name = "Shmup",
    game_id = "com.ceigey.shmuptutorial"
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
    enemies = {
      init_enemy(72, -20),
      init_enemy(usagi.GAME_W - 72, -20),
      init_enemy(usagi.GAME_W / 2, -60),
    }
  }
end

---update state each frame before draw
---@param dt integer -- delta time: seconds since last frame
function _update(dt)
  -- MOVEMENT
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

  -- FIRING
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

  for i = #State.player.bullets, 1, -1 do
    local bullet = State.player.bullets[i]
    -- move the bullet upward
    bullet.y -= bullet_speed * dt

    -- ENEMY COLLISIONS
    -- check if the bullet has overlapped with any of the enemies
    for _, enemy in ipairs(State.enemies) do
      if util.rect_overlap(
            { x = bullet.x, y = bullet.y,
              w = player_bullet_w, h = player_bullet_h },
            enemy) then
        bullet.dead = true
        enemy.hp -= 1
        enemy.flash_timer = hit_flash_time
      end
    end

    -- remove bullets that have flown off the top of the screen
    -- TODO: Review if/how bullet pooling can be done
    if bullet.y < -player_bullet_h or bullet.dead then
      table.remove(State.player.bullets, i)
    end
  end

  -- ENEMY MOVEMENT
  for i = #State.enemies, 1, -1 do
    local enemy = State.enemies[i]

    enemy.y += enemy.speed * dt

    if enemy.flash_timer > 0 then
      enemy.flash_timer = enemy.flash_timer - dt
    end

    if enemy.hp <= 0 or enemy.y > usagi.GAME_H then
      table.remove(State.enemies, i)
    end
  end

  -- SPAWN NEW ENEMIES
  if #State.enemies == 0 then
    table.insert(
      State.enemies,
      init_enemy(72, -20)
    )
    table.insert(
      State.enemies,
      init_enemy(usagi.GAME_W - 72, -20)
    )
    table.insert(
      State.enemies,
      init_enemy(usagi.GAME_W / 2, -60)
    )
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
  gfx.rect_fill(
    State.player.x, State.player.y,
    player_size, player_size, gfx.COLOR_BLACK
  )

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
end
