local player_size = 16
local player_speed = 180 -- px/s

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
        }
    }
end

---update state each frame before draw
---@param dt integer -- delta time: seconds since last frame
function _update(dt)
    local input_delta = { x = 0, y = 0 }
    local blah = 1
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

---draw each frame after update
---@param dt integer -- delta time: seconds since last frame
function _draw(dt)
    gfx.clear(gfx.COLOR_WHITE)
    gfx.rect_fill(
        State.player.x, State.player.y,
        player_size, player_size, gfx.COLOR_BLACK
    )
end
