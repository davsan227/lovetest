-- shooter_enemy.lua
local Classic = require "libs.classic"
local Enemy = require "enemy"
local Timer = require "libs.hump.timer"

local ShooterEnemy = Enemy:extend()

function ShooterEnemy:new(area, x, y)
    ShooterEnemy.super.new(self, area, x, y)
    self.shoot_interval = 1.5
    self.shoot_timer = 0
    self.bullet_speed = 250
    self.isShooter = true
    self.score_value = 500 -- Overrides the 10 from the paren
    self.chainThreshold = 2
    self.custom_color = {0, 1, 0} -- Example: Green for the shooter

end

function ShooterEnemy:update(dt)
    ShooterEnemy.super.update(self, dt)
    if self.dead or self.exploding then return end

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
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return end

    local vx = dx / dist * self.bullet_speed
    local vy = dy / dist * self.bullet_speed

    local Bullet = require "bullet"
    local bullet = Bullet(self.area, self.x, self.y, vx, vy)
    self.area:add(bullet)
end

function ShooterEnemy:explode()
    -- Only explode if at least 2 objects triggered the chain (for example)
    Enemy.explode(self, self.chainThreshold)
end


return ShooterEnemy
