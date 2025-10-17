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
    self.exploded = false
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
function Enemy:explode(chain)

   -- chain = { count, pending, pending_lookup }
    if self.exploding or self.exploded then return end

    -- If no chain was provided, explode immediately (fallback for isolated explosions)
    if not chain then
        self.exploding = true
        self.exploded = true
        self.explosion_timer = 0
        self.explosion_radius = self.radius
        if self.area and self.area.stage then
            local score = (self.isShooter and 1800 or 10)
            self.area.stage.score = self.area.stage.score + score
        end
        return
    end

    -- Mark as exploded so it won't trigger again
    self.exploding = true
    self.exploded = true

    -- Increment chain count (this explosion increases the global count)
    chain.count = chain.count + 1

    if self.area and self.area.stage then
    local score = (self.isShooter and 1800 or 10)
        self.area.stage.score = self.area.stage.score + score
    end

    -- Schedule all nearby enemies to be considered later (for chain spread timing)
    for _, obj in ipairs(self.area.game_objects) do
        if obj ~= self and obj ~= self.area.stage.player_circle and not obj.dead and obj.explode then
            local dx, dy = obj.x - self.x, obj.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < 100 then
                if not chain.pending_lookup[obj] then
                    chain.pending_lookup[obj] = true
                    local delay = dist / 250
                    self.area.stage.timer:after(delay, function()
                        if not obj.exploded and not obj.dead and not chain.halted then
                            table.insert(chain.pending, obj)
                        end
                        if self.area and self.area.processPending then
                            self.area:processPending(chain)
                        end
                    end)
                end
            end
        end
    end

    -- Immediately check for any pending that may now qualify
    if self.area and self.area.processPending then
        self.area:processPending(chain)
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
