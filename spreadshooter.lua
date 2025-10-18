-- spreadshooter.lua
local Classic = require "libs.classic"
local Enemy = require "enemy"
local Timer = require "libs.hump.timer"

local SpreadShooter = Enemy:extend()

function SpreadShooter:new(area, x, y, bulletPattern)
    SpreadShooter.super.new(self, area, x, y)
    
    -- Shooting
    self.shoot_interval = 1.5
    self.shoot_timer = 0
    self.bullet_speed = 250
    
    -- Identification
    self.isSpreadShooter = true
    self.score_value = 500
    self.chainThreshold = 8
    self.custom_color = {0, 0, 2}
    
    -- internal flags
    self._counted_dead = false
    self.bulletPattern =  bulletPattern or "spread" 
end

function SpreadShooter:update(dt)
    SpreadShooter.super.update(self, dt)
    if self.dead or self.exploding then
        self:countDead()
        return
    end

    -- Shooting
    self.shoot_timer = self.shoot_timer + dt
    if self.shoot_timer >= self.shoot_interval then
        self.shoot_timer = self.shoot_timer - self.shoot_interval
        self:shootPattern()
    end
end

-- choose shooting pattern based on currentShoot
function SpreadShooter:shootPattern()
    if self.bulletPattern == "spread" then
        self:shoot_spread(20)
    elseif self.bulletPattern == "storm" then
        self:shoot_bullet_storm(40)
    elseif self.bulletPattern == "hell" then
        self:shoot_bullet_hell(30)
    end
end

-- shooting patterns
function SpreadShooter:shoot_spread(numBullets)
    local Bullet = require "bullet"
    numBullets = numBullets or 8
    local angleStep = (2 * math.pi) / numBullets
    for i = 0, numBullets - 1 do
        local angle = i * angleStep
        local vx = math.cos(angle) * self.bullet_speed
        local vy = math.sin(angle) * self.bullet_speed
        local bullet = Bullet(self.area, self.x, self.y, vx, vy)
        self.area:add(bullet)
    end
end

function SpreadShooter:shoot_bullet_storm(numBullets)
    local Bullet = require "bullet"
    numBullets = numBullets or 20
     local angleStep = (2 * math.pi) / numBullets
    for i = 0, numBullets - 1 do
        local angle = i * angleStep
        local vx = math.cos(angle) * self.bullet_speed
        local vy = math.sin(angle) * self.bullet_speed
        local bullet = Bullet(self.area, self.x, self.y, vx, vy, {drag=0.982, life=5})
        self.area:add(bullet)
    end
end

function SpreadShooter:shoot_bullet_hell(numBullets)
    local Bullet = require "bullet"
    numBullets = numBullets or 50
    for i = 1, numBullets do
        local angle = love.math.random() * 2 * math.pi
        local speed = love.math.random(100, 250)
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        local bullet = Bullet(self.area, self.x, self.y, vx, vy, {drag=0.991, life=6})
        self.area:add(bullet)
    end
end


-- -- explosion override
-- function SpreadShooter:explode()
--     Enemy.explode(self)
--     -- optionally count death immediately if explode guarantees dead
--     if self.dead then
--         self:countDead()
--     end
-- end

-- counting deaths
function SpreadShooter:countDead()
    if self.dead and not self._counted_dead and self.area and self.area.stage then
        self._counted_dead = true
        self.area.stage.spreadshooter_dead_count = (self.area.stage.spreadshooter_dead_count or 0) + 1
        print("SpreadShooter destroyed! Total: " .. self.area.stage.spreadshooter_dead_count)
    end
end

return SpreadShooter
