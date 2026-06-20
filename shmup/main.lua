local player_size = 16
local player_speed = 180 -- px/s
local fire_delay = 0.1   -- s
local fire_timer = 0
local bullet_speed = 420 -- px/s
local player_bullet_w = 4
local player_bullet_h = 10

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

    -- remove bullets that have flown off the top of the screen
    -- TODO: Review if/how bullet pooling can be done
    if bullet.y < -player_bullet_h then
      table.remove(State.player.bullets, i)
    end
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

  -- FIRING (player!)
  for _, bullet in ipairs(State.player.bullets) do
    gfx.rect_fill(bullet.x, bullet.y,
      player_bullet_w, player_bullet_h, gfx.COLOR_LIGHT_GRAY)
  end
end
