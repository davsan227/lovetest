local Input = require "objects.boipushy.Input"
local Stage = require "stage"
local Leaderboard = require("leaderboard")
local lb = Leaderboard

local input
local playerName = ""
local enteringName = false
local stage
local showLeaderboard = false -- new flag

function love.load()
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
            -- Submit name and switch to leaderboard
            lb:submit(playerName ~= "" and playerName or "Player", math.floor(stage.score))
            lb:getTop()
            enteringName = false
            showLeaderboard = true
            love.keyboard.setTextInput(false)
        end
    end
end

function love.update(dt)
    stage:update(dt)

    -- Handle explosions / clicks
    if input:pressed("explode") then
        if stage.game_over then
            if enteringName then
                -- Submit score via mouse click
                lb:submit(playerName ~= "" and playerName or "Player", math.floor(stage.score))
                lb:getTop()
                enteringName = false
                showLeaderboard = true
                love.keyboard.setTextInput(false)
            elseif showLeaderboard then
                -- Restart game
                stage = Stage(input)
                playerName = ""
                showLeaderboard = false
            end
        else
            -- Trigger explosion during gameplay
            local exploded_now = stage.player_circle:explode(stage.area.game_objects)
            if exploded_now then
                stage.slowmo_timer = stage.slowmo_duration
            end
        end
    end

    -- When game over, ask for name if not already submitted
    if stage.game_over and not stage.leaderboard_handled then
        enteringName = true
        love.keyboard.setTextInput(true)
        stage.leaderboard_handled = true
    end
end

function love.draw()
    stage:draw()

    if stage.game_over then
        love.graphics.setColor(1,1,1)

        if enteringName then
            love.graphics.printf("GAME OVER - Enter Name:", 0, love.graphics.getHeight() / 2 - 40,
                love.graphics.getWidth(), "center")
            love.graphics.printf(playerName, 0, love.graphics.getHeight() / 2,
                love.graphics.getWidth(), "center")
        elseif showLeaderboard then
            love.graphics.printf("Leaderboard (Click to Restart)", 0, 50, love.graphics.getWidth(), "center")
            lb:draw(200, 100)
        else
            love.graphics.printf("GAME OVER", 0, love.graphics.getHeight() / 2 - 40,
                love.graphics.getWidth(), "center")
        end
    end
end
