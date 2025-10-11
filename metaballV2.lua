-- metaball.lua
local Classic = require "libs.classic"

local Metaball = Classic:extend()

function Metaball:new(area, x, y)
    self.area = area
    self.isMetaball = true
    self.x = x
    self.y = y

    -- Core metaball (R=300, position x, y)
    self.core = {x = x, y = y, r = 300, color = {0.3, 0.7, 1.0}} -- blueish core

    -- Orbiters (R=100, original logic)
    self.balls = {}
    for i = 1, 3 do
        local angle = (i / 3) * math.pi * 2
        local orbit_radius = 150 + love.math.random() * 80
        table.insert(self.balls, {
            angle = angle,
            orbit_radius = orbit_radius,
            orbit_speed = 1 + love.math.random() * 0.5,
            r = 100,
            x = x + math.cos((i / 3) * math.pi * 2) * 200,
            y = y + math.sin((i / 3) * math.pi * 2) * 200,
            state = "orbit",
            timer = love.math.random() * 2,
            tx = x,
            ty = y,
            color = {1.0, 0.5, 0.0} -- orange orbiters
        })
    end

    -- Shader with the ABSOLUTE MINIMAL coordinate fix
    self.shader = love.graphics.newShader([[
        extern number count;
        extern vec3 balls[16]; // x, y, radius
        extern vec3 colors[16]; // r,g,b
        extern vec2 screenSize; // <--- MINIMAL CHANGE 1: Add screenSize uniform

        vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
        {
            // MINIMAL CHANGE 2: Calculate robust pixel coordinates
            vec2 pixel_coords = uv * screenSize; 

            float intensity = 0.0;
            vec3 finalColor = vec3(0.0,0.0,0.0);

            for (int i = 0; i < int(count); i++) {
                vec3 b = balls[i];
                vec3 c = colors[i];
                
                // MINIMAL CHANGE 3: Use pixel_coords instead of the unreliable screen_coords
                float dx = pixel_coords.x - b.x; 
                float dy = pixel_coords.y - b.y;
                
                // Kept working calculation, multiplier (0.08), and radius (R=100 logic)
                float contribution = (b.z * b.z * 0.08) / (dx*dx + dy*dy + 1.0);
                intensity += contribution;
                finalColor += c * contribution;
            }

            // Kept working threshold (1.2)
            float alpha = smoothstep(0.0, 1.2, intensity);
            finalColor /= max(intensity, 0.001);
            return vec4(finalColor, alpha);
        }
    ]])
end

function Metaball:update(dt)
    local player = self.area.stage.player_circle
    if not player or player.dead then return end
    self.x = self.core.x
    self.y = self.core.y
    
    for _, b in ipairs(self.balls) do
        -- Continuous orbit
        b.angle = b.angle + dt * b.orbit_speed
        local ox = math.cos(b.angle) * b.orbit_radius
        local oy = math.sin(b.angle) * b.orbit_radius

        if b.state == "orbit" then
            b.x = self.core.x + ox
            b.y = self.core.y + oy
            b.timer = b.timer + dt
            if b.timer > love.math.random(2,4) then
                b.state = "attack"
                b.tx, b.ty = player.x, player.y
                b.timer = 0
            end

        elseif b.state == "attack" then
            local dx, dy = b.tx - b.x, b.ty - b.y
            local dist = math.sqrt(dx*dx + dy*dy)
            local speed = 300
            
            if dist ~= 0 then
                b.x = b.x + (dx/dist)*speed*dt + ox*0.05
                b.y = b.y + (dy/dist)*speed*dt + oy*0.05
            end
            
            if dist < 30 then
                b.state = "return"
            end

        elseif b.state == "return" then
            local dx, dy = self.core.x - b.x, self.core.y - b.y
            local dist = math.sqrt(dx*dx + dy*dy)
            local speed = 500
            
            if dist ~= 0 then
                b.x = b.x + (dx/dist)*speed*dt + ox*0.05
                b.y = b.y + (dy/dist)*speed*dt + oy*0.05
            end
            
            if dist < 20 then
                b.state = "orbit"
                b.timer = 0
            end
        end
    end
end

function Metaball:draw()
    local list = {{self.core.x, self.core.y, self.core.r}}
    local colors = {self.core.color}
    local w, h = love.graphics.getDimensions()

    for _, b in ipairs(self.balls) do
        table.insert(list, {b.x, b.y, b.r})
        table.insert(colors, b.color)
    end

    self.shader:send("count", #list)
    self.shader:send("balls", unpack(list))
    self.shader:send("colors", unpack(colors))
    
    -- MINIMAL CHANGE 4: Send screen size to shader
    self.shader:send("screenSize", {w, h}) 

    love.graphics.setShader(self.shader)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setShader()
end

return Metaball