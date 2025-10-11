-- spawner.lua
local Classic = require "libs.classic"
local Formations = require "formations"
local ShooterEnemy = require "enemyshooter"
local WarningMarker = require "warning_marker"
local Metaball = require "metaball"


local Spawner = Classic:extend()

function Spawner:new(area)
    self.area = area
    self.formations = Formations(area)
    self.metaball_spawned = false
end

-- Spawn a line formation
function Spawner:spawnLineFormation(targetX, targetY, speedMin, speedMax)
    local w, h = love.graphics.getDimensions() 
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
function Spawner:spawnShooterWithWarning(maxEnemynumber)
   
    maxEnemynumber = maxEnemynumber or 4

    -- Count current active shooters and queued warnings
    local currentCount = 0
    for _, obj in ipairs(self.area.game_objects) do
        if (obj.isShooter and not obj.dead) or obj.isWarningMarker then
            currentCount = currentCount + 1
        end
    end

    if currentCount >= maxEnemynumber then
        return false -- cannot spawn another one
    end

    -- Determine spawn position (away from player)
    local player = self.area.stage.player_circle
    local margin = 100
    local x, y
    if player then
        local angle = love.math.random() * 2 * math.pi
        x = player.x + math.cos(angle) * margin
        y = player.y + math.sin(angle) * margin
        x = math.max(50, math.min(love.graphics.getWidth() - 50, x))
        y = math.max(50, math.min(love.graphics.getHeight() - 50, y))
    else
        x = love.math.random(50, love.graphics.getWidth() - 50)
        y = love.math.random(50, love.graphics.getHeight() - 50)
    end

    -- Create the warning marker
    local marker = WarningMarker(self.area, x, y, function(area, mx, my)
        local shooter = ShooterEnemy(area, mx, my)
        area:add(shooter)
    end)

    marker.isWarningMarker = true -- mark as warning so we count it

    self.area:add(marker)
    return true
end

-- Spawn a metaball: Checks max limit and returns true if a shooter was added.
function Spawner:spawnMetaballWithWarning(maxEnemynumber, spawnMetaballWithWarningMCenter)
    local w, h = love.graphics.getDimensions() 
    maxEnemynumber = maxEnemynumber or 2

    -- Count current active metaballs and queued warnings
    local currentCount = 0
    for _, obj in ipairs(self.area.game_objects) do
        if (obj.isMetaball and not obj.dead) or obj.isWarningMarker then
            currentCount = currentCount + 1
        end
    end

    if currentCount >= maxEnemynumber then
        return false -- cannot spawn another one
    end

    -- Determine spawn position (away from player)
    local x, y
    if spawnMetaballWithWarningMCenter == true then
        x = w / 2
        y = h / 2
    else
        local player = self.area.stage.player_circle
        local margin = 100

        if player then
            local angle = love.math.random() * 2 * math.pi
            x = player.x + math.cos(angle) * margin
            y = player.y + math.sin(angle) * margin
            x = math.max(50, math.min(love.graphics.getWidth() - 50, x))
            y = math.max(50, math.min(love.graphics.getHeight() - 50, y))
        else
            x = love.math.random(50, love.graphics.getWidth() - 50)
            y = love.math.random(50, love.graphics.getHeight() - 50)
        end
    end

    -- Create the warning marker
    local marker = WarningMarker(self.area, x, y, function(area, mx, my)
        local metaball = Metaball(area, mx, my)
        area:add(metaball)
    end)

    marker.isWarningMarker = true -- mark as warning so we count it

    self.area:add(marker)
    return true
end

return Spawner
