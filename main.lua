local myutils = require("game.utils")

function _config()
  ---@type Usagi.Config
  return { name = "Game", game_id = "com.usagiengine.dodgemup" }
end

function _init()
  -- Live reload preserves globals across saved edits but resets locals.
  -- Stash mutable game state in a capitalized global like `State` so it
  -- survives reloads; F5 calls _init again to reset.
  State = {
    player = {
      x = 20,
      y = 40,
    },
    ---@class (exact) Enemy
    ---@field x integer -- x coord
    ---@field y integer -- y coord
    ---@field speed number -- pixels per frame?

    ---@type table<integer, Enemy>
    enemies = {},
    enemy_spawner = {
      timer = 0,
      delay_secs = 0.5,
    },
    game_over = false,
    play_time = 0,
  }
end

---update state each frame before draw
---@param dt integer -- delta time: seconds since last frame
function _update(dt)
  local dx = 0
  local dy = 0
  local speed = 1.5
  if input.held(input.LEFT) then
    dx = dx - 1
  end
  if input.held(input.RIGHT) then
    dx = dx + 1
  end
  if input.held(input.UP) then
    dy = dy - 1
  end
  if input.held(input.DOWN) then
    dy = dy + 1
  end
  if input.held(input.BTN2) then
    speed = 3
  else
    speed = 1.5
  end

  local normal_dvec = util.vec_normalize({ x = dx, y = dy })

  -- Stop cheaters in their tracks with advanced kernel anti-cheat technique
  -- called THE CLAMP FUNCTION
  --
  State.player.x = util.clamp(
    speed * normal_dvec.x + State.player.x,
    0,
    usagi.GAME_W - 16
  )
  State.player.y = util.clamp(
    speed * normal_dvec.y + State.player.y,
    0,
    usagi.GAME_H - 16
  )

  -- Sneakily avoiding refresh troubles
  State.enemies = State.enemies or {}
  State.enemy_spawner = State.enemy_spawner or {}
  State.enemy_spawner.timer = (State.enemy_spawner.timer or 2) - dt
  if State.enemy_spawner.timer <= 0 then
    print("[ENEMY_SPAWNER] Enjoy...")
    local padding = 10
    table.insert(State.enemies, {
      x = usagi.GAME_W,
      y = math.random(padding, usagi.GAME_H - padding), -- 40,
      speed = math.random(3, 5)
    })
    State.enemy_spawner.timer = State.enemy_spawner.delay_secs
  end

  for i, enemy in pairs(State.enemies) do
    if not State.game_over and util.circ_rect_overlap(
          { x = enemy.x, y = enemy.y, r = 8 },
          { x = State.player.x, y = State.player.y, w = 16, h = 16 }
        ) then
      print("[GAME_OVER] Deaded")
      State.game_over = true
      -- break
    end

    enemy.x = enemy.x - enemy.speed

    if enemy.x <= -16 then
      State.enemies[i] = nil
      -- I have NO idea if this is wise
      -- basically Lua "counts" until the first "hole" in the table e.g. nil
      -- assigning table[key] = nil actually deletes key
      -- so table[1] = nil means #table == 0, even if table[2], table[3] etc all exist!
      -- this is "good" because I don't have to worry about pooling array spaces somehow
      -- or doing table.remove MID ITERATION (gasp!)
      -- alternatively I could just assign random hash keys,
      -- if I want to know the length then I have to count them all (which'll probably happen...)
      print("[ENEMY#" .. i .. "] Culled offscreen, table length: ", #State.enemies)
    end
  end

  if State.game_over then
    State.player.x = -30
    State.player.y = -30
  end

  if State.game_over and input.pressed(input.BTN1) then
    print("[GAME_OVER] Restarting...")
    _init()
  end

  if not State.game_over then
    State.play_time = State.play_time + dt
  end
end

---draw each frame after update
---@param dt integer -- delta time: seconds since last frame
function _draw(dt)
  if State.game_over then
    gfx.text("GAME OVER", 10, 10, gfx.COLOR_WHITE)
    gfx.text("Press " .. input.mapping_for(input.BTN1) .. " to restart", 10, 30, gfx.COLOR_WHITE)
    gfx.text("Score: " .. math.floor(State.play_time), 10, 50, gfx.COLOR_WHITE)
  else
    gfx.text(myutils.greet("Ceige!") .. " Score: " .. math.floor(State.play_time), 10, 10,
      gfx.COLOR_WHITE)
  end
  gfx.clear(gfx.COLOR_BLACK)
  gfx.rect_fill(State.player.x, State.player.y, 16, 16, gfx.COLOR_BLUE)

  for i, enemy in pairs(State.enemies) do
    local color = gfx.COLOR_RED
    if enemy.speed > 3 then
      color = gfx.COLOR_ORANGE
    end
    if enemy.speed > 4 then
      color = gfx.COLOR_YELLOW
    end
    gfx.circ_fill(enemy.x, enemy.y, 8, color)
  end
end
