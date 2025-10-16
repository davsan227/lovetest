-- enemy.lua
local Classic = require "libs.classic"
local Timer = require "libs.hump.timer"
local HC = require "libs.HC"

local Enemy = Classic:extend()

function Enemy:new(area, x, y)
    self.area = area
    self.x, self.y = x, y
    self.radius = 20 -- visible size
    self.hitbox_radius = self.radius * 0.75 -- collision size
    self.dead = false
    self.shape = HC.circle(self.x, self.y, self.hitbox_radius)

    -- default velocity (can be overwritten later)
    self.vx = 0
    self.vy = 0

    -- explosion
    self.exploding = false
    self.explosion_radius = 0
    self.explosion_duration = 0.3
    self.explosion_timer = 0

    self.timer = Timer()
end

function Enemy:update(dt)
    -- handle explosion animation
    if self.exploding then
        self.explosion_timer = self.explosion_timer + dt
        local t = self.explosion_timer / self.explosion_duration
        self.explosion_radius = self.radius + t * 50
        if self.explosion_timer >= self.explosion_duration then
            self.dead = true
            self.exploding = false
        end
        return
    end

    -- move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Remove if out of bounds
    local w, h = love.graphics.getDimensions()
    local buffer = 200
    if self.x < -buffer or self.x > w + buffer or self.y < -buffer or self.y > h + buffer then
        self.dead = true
    end

    -- move the hitbox
    if self.shape then
        self.shape:moveTo(self.x, self.y)
    end
end

-- Explosion with chain reaction threshold
-- chainThreshold: minimum number of simultaneous nearby explosions required to trigger

function Enemy:explode(chainThreshold)
    chainThreshold = tonumber(chainThreshold) or 1
    if self.dead or self.exploding then
        return
    end

    -- Initialize chain tracking
    self.area.currentExplosionChain = self.area.currentExplosionChain or {
        id = love.timer.getTime(),
        pending = {},
        processing = false
    }

    local chain = self.area.currentExplosionChain

    -- Mark as pending for this chain
    if not chain.pending[self] then
        chain.pending[self] = true
    end

    -- Only schedule processing once per chain
    if not chain.processing then
        chain.processing = true
        self.area.stage.timer:after(0.2, function()
            local total = 0
            for _ in pairs(chain.pending) do
                total = total + 1

            end
            print("Chain pending count: " .. total)
            if total >= chainThreshold then
                -- Trigger all pending explosions
                for e, _ in pairs(chain.pending) do
                    e.exploding = true
                    e.explosion_timer = 0
                    e.explosion_radius = e.radius
                    e.dead = false
                    -- Score
                    if self.area.stage then
                        local score = e.isShooter and 1800 or 10
                        self.area.stage.score = self.area.stage.score + score
                    end
                end
            end

            -- Reset chain
            self.area.currentExplosionChain = nil
        end)
    end

    -- propagate to nearby enemies
    for _, obj in ipairs(self.area.game_objects) do
        if obj ~= self and not obj.dead and not obj.exploding and obj ~= self.area.stage.player_circle then
            local dx, dy = obj.x - self.x, obj.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < 100 then
                local delay = dist / 250
                self.area.stage.timer:after(delay, function()
                    if obj.explode then
                        obj:explode(chainThreshold)
                    else
                        obj.dead = true
                    end
                end)
            end
        end
    end
end

function Enemy:destroy()
    if self.shape then
        HC.remove(self.shape)
        self.shape = nil
    end
end

function Enemy:draw()
    if self.exploding then
        -- Keep all the explosion drawing code as is
        local t = self.explosion_timer / self.explosion_duration
        local alpha = 1 - t
        love.graphics.setColor(1, 0, 0, alpha)
        love.graphics.circle("fill", self.x, self.y, self.explosion_radius)
        love.graphics.setColor(1, 1, 1)
        return
    end

    -- *** NEW / SIMPLIFIED COLOR LOGIC ***

    -- Check for a custom color property (used by ShooterEnemy)
    if self.custom_color then
        love.graphics.setColor(self.custom_color[1], self.custom_color[2], self.custom_color[3], 1)
    else
        -- Default fixed color for generic enemies (REPLACES THE DARKNESS CODE)
        -- Example: A simple, fixed red color
        love.graphics.setColor(1, 0.3, 0.3, 1)
    end

    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setColor(1, 1, 1)
end

return Enemy
