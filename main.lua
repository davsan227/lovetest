local Input = require "objects/boipushy/Input"
local Stage = require "stage"
local Leaderboard = require("leaderboard")
local lb = Leaderboard

local input
local playerName = ""
local enteringName = false

function love.load()
    if jit then
        print("LuaJIT version:", jit.version)
        print("Lua version:", _VERSION)
        print(jit.arch)
    end

    love.window.setTitle("Exploding Circles")
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    -- Input bindings
    input = Input()
    input:bind("left", "left_key")
    input:bind("right", "right_key")
    input:bind("up", "up_key")
    input:bind("down", "down_key")
    input:bind("a", "left_key")
    input:bind("d", "right_key")
    input:bind("w", "up_key")
    input:bind("s", "down_key")
    input:bind("mouse1", "explode")

    -- Initialize stage
    stage = Stage(input)

    -- Fetch leaderboard initially
    lb:getTop()
end

function love.textinput(t)
    if enteringName then
        playerName = playerName .. t
    end
end

function love.keypressed(key)
    if enteringName then
        if key == "backspace" then
            playerName = playerName:sub(1, -2)
        elseif key == "return" or key == "kpenter" then
            -- Submit score after entering name
            lb:submit(playerName ~= "" and playerName or "Player", math.floor(stage.score))
            lb:getTop()
            enteringName = false
        end
    end
end

function love.update(dt)
    stage:update(dt)

    -- Handle explosions
    if input:pressed("explode") then
        if stage.game_over then
            -- Restart game
            stage = Stage(input)
            playerName = ""
            enteringName = false
        else
            -- Trigger player explosion
            local area = stage.area
            local exploded_now = stage.player_circle:explode(area.game_objects)
            if exploded_now then
                stage.slowmo_timer = stage.slowmo_duration
            end
        end
    end

    -- When game over, ask for name if not already submitted
    if stage.game_over and not stage.leaderboard_handled then
        enteringName = true
        stage.leaderboard_handled = true
    end
end

function love.draw()
    stage:draw()

    -- Game over text
    if stage.game_over then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("GAME OVER", 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), "center")

        -- Player name input
        if enteringName then
            love.graphics.printf("Enter Name: " .. playerName, 0, love.graphics.getHeight() / 2,
                love.graphics.getWidth(), "center")
        end

        -- Draw leaderboard
        lb:draw(200, 100)
    end

end
