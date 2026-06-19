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
    enemies = {}
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
  State.player.x = speed * normal_dvec.x + State.player.x
  State.player.y = speed * normal_dvec.y + State.player.y
end

---draw each frame after update
---@param dt integer -- delta time: seconds since last frame
function _draw(dt)
  gfx.clear(gfx.COLOR_BLACK)
  gfx.text(myutils.greet("Ceige!"), 10, 10, gfx.COLOR_WHITE)
  gfx.rect_fill(State.player.x, State.player.y, 16, 16, gfx.COLOR_BLUE)
end
