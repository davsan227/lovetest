local Enemy = require "enemy"
local Player = require "player"
local Area = require "area"
local Classic = require "objects.classic"
Timer = require "objects/hump/timer"

local Stage = Classic:extend()

function Stage:new(input)
    self.timer = Timer()
    self.area = Area(self)
    self.score = 0
    self.game_over = false

    -- player circle
    self.player_circle = Player(self.area, 400, 300, input)
    self.area:add(self.player_circle)

    -- slow-motion
    self.slowmo_timer = 0
    self.slowmo_duration = 1.5
    self.slowmo_factor = 0.3

    -- spawn enemies
    self.spawn_timer = 0 -- counts time since last spawn
    self.spawn_interval = 0.2 -- start spawning every 2 seconds
    self.enemy_speed_min = 50 -- base speed
    self.enemy_speed_max = 100
    self.difficulty_timer = 0 -- counts time for difficulty increase

    self.max_explosions = 3 -- starting explosions
    self.explosions = 3 -- current available explosions
    self.last_score_checkpoint = 0 -- track score for bonus
end

function Stage:update(dt)
    local effective_dt = dt
    if self.slowmo_timer > 0 then
        effective_dt = dt * self.slowmo_factor
        self.slowmo_timer = self.slowmo_timer - dt
        if self.slowmo_timer < 0 then
            self.slowmo_timer = 0
        end
    end

    if self.game_over then
        return
    end

    -- update timers and area first
    self.timer:update(dt)
    self.area:update(effective_dt) -- all explosions, including chain reactions, are updated here

    -- collision check
    for _, c in ipairs(self.area.game_objects) do
        if c ~= self.player_circle and not c.dead then
            local dx, dy = c.x - self.player_circle.x, c.y - self.player_circle.y
            local rsum = (self.player_circle.hitbox_radius or self.player_circle.radius) + (c.radius or 0)

            if dx * dx + dy * dy <= rsum * rsum then
                self.player_circle:hit() -- handle explosions and invulnerability
                break -- only first collision per frame
            end
        end
    end

    -- Check if there are any active explosions
    local active_explosions = false
    for _, obj in ipairs(self.area.game_objects) do
        if obj.exploding then
            active_explosions = true
            break
        end
    end

    -- Game over only if no explosions left AND no active explosions
    if self.explosions <= 0 and not active_explosions then
        self.game_over = true
    end

    -- === Explosion recharge ===
    if self.score - self.last_score_checkpoint >= 1000 then
        self.last_score_checkpoint = self.score
        self.explosions = math.min(self.explosions + 1, self.max_explosions)
    end

    -- === Spawn enemies gradually from outside screen ===
    self.spawn_timer = self.spawn_timer + dt
    if self.spawn_timer >= self.spawn_interval then
        self.spawn_timer = self.spawn_timer - self.spawn_interval

        local w, h = love.graphics.getDimensions()
        local edge = love.math.random(1, 4)
        local x, y

        if edge == 1 then
            x = math.random(0, w);
            y = -20
        elseif edge == 2 then
            x = math.random(0, w);
            y = h + 20
        elseif edge == 3 then
            x = -20;
            y = math.random(0, h)
        else
            x = w + 20;
            y = math.random(0, h)
        end

        -- aim toward player
        local targetX, targetY = self.player_circle.x, self.player_circle.y
        local angle = math.atan2(targetY - y, targetX - x)
        local speed = love.math.random(self.enemy_speed_min, self.enemy_speed_max)
        local enemy = Enemy(self.area, x, y)
        enemy.vx = math.cos(angle) * speed
        enemy.vy = math.sin(angle) * speed
        self.area:add(enemy)
    end

    -- === Increase difficulty over time ===
    self.difficulty_timer = self.difficulty_timer + dt
    if self.difficulty_timer >= 10 then
        self.difficulty_timer = 0
        self.spawn_interval = math.max(0.3, self.spawn_interval - 0.1)
        self.enemy_speed_min = self.enemy_speed_min + 5
        self.enemy_speed_max = self.enemy_speed_max + 5
    end
end

function Stage:draw()
    -- draw score and explosions
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. self.score, 10, 10)
    love.graphics.print("Ships: " .. self.explosions, 10, 30)

    -- draw all game objects (player + enemies)
    self.area:draw()

    -- optional: show explosion cooldown bar above player
    local player = self.player_circle
    if player.exploded then
        local w = 40 -- width of bar
        local h = 5 -- height of bar
        local x = player.x - w / 2
        local y = player.y - player.radius - 10
        local t = player.explode_timer / 3 -- 3 sec cooldown
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(0, 0.5, 1)
        love.graphics.rectangle("fill", x, y, w * t, h)
        love.graphics.setColor(1, 1, 1)
    end
end

return Stage
