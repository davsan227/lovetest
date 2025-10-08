-- spawner.lua
local Classic = require "libs.classic"
local Formations = require "formations"
local ShooterEnemy = require "enemyshooter"

local w, h = love.graphics.getDimensions() -- global for this file

local Spawner = Classic:extend()

function Spawner:new(area)
    self.area = area
    self.formations = Formations(area)
end

-- Spawn a line formation
function Spawner:spawnLineFormation(targetX, targetY, speedMin, speedMax)
    local edge = love.math.random(1, 4)
    local x, y
    if edge == 1 then
        x, y = math.random(0, w), -20
    elseif edge == 2 then
        x, y = math.random(0, w), h + 20
    elseif edge == 3 then
        x, y = -20, math.random(0, h)
    else
        x, y = w + 20, math.random(0, h)
    end

    local count = math.max(2, love.math.random(2, 3))
    self.formations:line(count, x, y, targetX, targetY, 50, speedMin, speedMax)
end

-- Spawn a shooter: Checks max limit and returns true if a shooter was added.
function Spawner:spawnShooter(maxShooters)
    maxShooters = maxShooters or 4

    -- Count current active shooters
    local currentShooters = 0
    for _, obj in ipairs(self.area.game_objects) do
        -- Ensure obj exists and is the correct class
        if obj.isShooter and not obj.dead then
            currentShooters = currentShooters + 1
        end
    end
    -- The print statement for counting active shooters is removed from the loop.

    -- === THE LIMIT CHECK ===
    if currentShooters >= maxShooters then 
        return false -- Indicate NO spawn happened
    end

    -- Spawn away from player
    local player = self.area.stage.player_circle
    local margin = 100
    local x, y
    if player then
        local angle = love.math.random() * 2 * math.pi
        x = player.x + math.cos(angle) * margin
        y = player.y + math.sin(angle) * margin
        -- Clamp to screen bounds
        x = math.max(50, math.min(w - 50, x))
        y = math.max(50, math.min(h - 50, y))
    else
        x = math.random(50, w - 50)
        y = math.random(50, h - 50)
    end

    -- Add the shooter
    local shooter = ShooterEnemy(self.area, x, y)
    self.area:add(shooter)

    -- print("Shooter spawned at:", x, y, "| Active shooters:", currentShooters + 1)
    return true -- Indicate a spawn DID happen
end

return Spawner