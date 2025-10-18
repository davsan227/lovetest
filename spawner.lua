-- spawner.lua
local Classic = require "libs.classic"
local Formations = require "formations"
local ShooterEnemy = require "enemyshooter"
local WarningMarker = require "warning_marker"
local Metaball = require "metaball"
local SpreadShooterEnemy = require "spreadshooter"

local Spawner = Classic:extend()

function Spawner:new(area)
    self.area = area
    self.formations = Formations(area)
    self.metaball_spawned = false
end

-- Spawn a line formation
function Spawner:spawnLineFormation(speedMin, speedMax)
    local w, h = love.graphics.getDimensions()
    local edge = love.math.random(1, 4)
    local x, y, angle
    local margin = 40 -- how far outside screen they start

    if edge == 1 then
        -- From top → downward
        x, y = love.math.random(0, w), -margin
        angle = math.pi / 2
    elseif edge == 2 then
        -- From bottom → upward
        x, y = love.math.random(0, w), h + margin
        angle = -math.pi / 2
    elseif edge == 3 then
        -- From left → right
        x, y = -margin, love.math.random(0, h)
        angle = 0
    else
        -- From right → left
        x, y = w + margin, love.math.random(0, h)
        angle = math.pi
    end

    local count = math.max(2, love.math.random(2, 3))
    local spacing = 50
    self.formations:line(count, x, y, angle, spacing, speedMin, speedMax)
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
    maxEnemynumber = maxEnemynumber or 1

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

    -- Determine spawn position (on the center)
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

-- Spawn a SpreadShooter: Checks max limit and returns true if a shooter was added.
function Spawner:spawnSpreadShooterWithWarning(maxEnemynumber, spawnSpreadShooterMCenter, bulletPattern)
    local w, h = love.graphics.getDimensions()
    maxEnemynumber = maxEnemynumber or 1

    -- Count current active spreadshooter and queued warnings
    local currentCount = 0
    for _, obj in ipairs(self.area.game_objects) do
        if (obj.isSpreadShooter and not obj.dead) or obj.isWarningMarker then
            currentCount = currentCount + 1
        end
    end

    if currentCount >= maxEnemynumber then
        return false -- cannot spawn another one
    end

    -- Determine spawn position (on the center)
    local x, y
    if spawnSpreadShooterMCenter == true then
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
        local spreadShooter = SpreadShooterEnemy(area, mx, my, bulletPattern)
        area:add(spreadShooter)
    end)

    marker.isWarningMarker = true -- mark as warning so we count it

    self.area:add(marker)
    return true
end

return Spawner
