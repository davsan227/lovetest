local Classic = require "libs.classic"

local Metaball = Classic:extend()

function Metaball:new(area, x, y)
    self.x, self.y = x, y
    self.core = {x = x, y = y, r = 60}
    self.balls = {}
    self.timer = 0
    self.isMetaball = true

    -- orbiters
    for i = 1, 3 do
        table.insert(self.balls, {
            state = "orbit",
            angle = (i / 3) * math.pi * 2,
            orbit_radius = 100,
            orbit_speed = 1 + love.math.random() * 0.5,
            r = 25,
            x = x,
            y = y,
            timer = love.math.random() * 2
        })
    end

    -- shader
    self.shader = love.graphics.newShader([[
        extern number count;
        extern vec3 balls[16]; // x, y, radius

        vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
        {
            float intensity = 0.0;
            for (int i = 0; i < int(count); i++) {
                vec3 b = balls[i];
                float dx = screen_coords.x - b.x;
                float dy = screen_coords.y - b.y;
                intensity += (b.z * b.z) / (dx*dx + dy*dy + 1.0);
            }
            float alpha = smoothstep(0.9, 1.0, intensity * 0.003);
            return vec4(vec3(0.3, 0.7, 1.0), alpha);
        }
    ]])
end

function Metaball:update(dt, player)
    for _, b in ipairs(self.balls) do
        if b.state == "orbit" then
            b.angle = b.angle + dt * b.orbit_speed
            b.x = self.core.x + math.cos(b.angle) * b.orbit_radius
            b.y = self.core.y + math.sin(b.angle) * b.orbit_radius
            b.timer = b.timer + dt
            if b.timer > love.math.random(2, 4) then
                b.state = "attack"
                b.tx, b.ty = player.x, player.y
                b.timer = 0
            end

        elseif b.state == "attack" then
            local dx, dy = b.tx - b.x, b.ty - b.y
            local dist = math.sqrt(dx * dx + dy * dy)
            local speed = 300
            b.x = b.x + dx / dist * dt * speed
            b.y = b.y + dy / dist * dt * speed
            if dist < 20 then
                b.state = "return"
            end

        elseif b.state == "return" then
            local dx, dy = self.core.x - b.x, self.core.y - b.y
            local dist = math.sqrt(dx * dx + dy * dy)
            local speed = 500
            b.x = b.x + dx / dist * dt * speed
            b.y = b.y + dy / dist * dt * speed
            if dist < 10 then
                b.state = "orbit"
                b.timer = 0
            end
        end
    end
end

function Metaball:draw()
    -- build array for shader
    local list = {{self.core.x, self.core.y, self.core.r}}
    for _, b in ipairs(self.balls) do
        table.insert(list, {b.x, b.y, b.r})
    end

    self.shader:send("count", #list)
    self.shader:send("balls", unpack(list))

    love.graphics.setShader(self.shader)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()
end

return Metaball
