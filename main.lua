local textutils = require("game.textutils")

function _config()
    ---@type Usagi.Config
    return { name = "Game", game_id = "com.usagiengine.dodgemup" }
end

function _init()
    -- Live reload preserves globals across saved edits but resets locals.
    -- Stash mutable game state in a capitalized global like `State` so it
    -- survives reloads; F5 calls _init again to reset.
    State = {}
end

---update state each frame before draw
---@param dt integer -- delta time: seconds since last frame
function _update(dt)
end

---draw each frame after update
---@param dt integer -- delta time: seconds since last frame
function _draw(dt)
    gfx.clear(gfx.COLOR_BLACK)
    gfx.text(textutils.greet("Ceige!"), 10, 10, gfx.COLOR_WHITE)
end
