-- shooter_enemy.lua
local Classic = require "libs.classic"
local Enemy = require "enemy"
local Timer = require "libs.hump.timer"
local HC = require "libs.HC"

local ShooterEnemy = Enemy:extend()

function ShooterEnemy:new(area, x, y)
    ShooterEnemy.super.new(self, area, x, y)
    
    -- Shooting properties
    self.shoot_interval = 1.5  -- seconds between shots
    self.shoot_timer = 0
    self.bullet_speed = 250
end

function ShooterEnemy:update(dt)
    ShooterEnemy.super.update(self, dt)  -- move and handle explosions

    if self.dead or self.exploding then
        return
    end

    -- Shoot at player
    self.shoot_timer = self.shoot_timer + dt
    if self.shoot_timer >= self.shoot_interval then
        self.shoot_timer = self.shoot_timer - self.shoot_interval
        self:shoot_at_player()
    end
end

function ShooterEnemy:shoot_at_player()
    local player = self.area.stage.player_circle
    if not player or player.dead then return end

    local dx, dy = player.x - self.x, player.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist == 0 then return end

    local vx, vy = dx / dist * self.bullet_speed, dy / dist * self.bullet_speed

    -- Create a bullet object
    local Bullet = require "bullet" -- we'll create this next
    local bullet = Bullet(self.area, self.x, self.y, vx, vy)
    self.area:add(bullet)
end

return ShooterEnemy
