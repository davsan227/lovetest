Timer = require 'objects/hump/timer'
Input = require 'objects/boipushy/Input'
io.stdout:setvbuf("no")
local numbers = {}
rect_1 = {
    x = 300,
    y = 300,
    w = 200,
    h = 50
}

rect_2 = {
    x = 300,
    y = 300,
    w = 200,
    h = 50,
}

a = {1, 2, '3', 4, '5', 6, 7, true, 9, 10, 11, a = 1, b = 2, c = 3, {1, 2, 3}}
b = {1, 1, 3, 4, 5, 6, 7, false}
c = {'1', '2', '3', 4, 5, 6}
d = {1, 4, 3, 4, 5, 6}

circle = {radius = 24}
local activeTweens = {}

function love.load()
    input = Input()
    timer = Timer()
    print("hello")
    input:bind('mouse1', 'test')
    input:bind('r', 'r_key')
    input:bind('t', 't_key')
    input:bind('y', 'y_key')
    input:bind('right', 'right_key')
    input:bind('left', 'left_key')
    input:bind('mouse2', function()
        print(love.math.random())
    end)
    input:bind('y', 'down')
    for k, v in pairs(a) do
    print(k, v)
end
local count = 0
for k, v in pairs(b) do
    if v==1 then 
    count = count+1
    end
end
print(count)
for k, v in pairs(d) do
   
end
print(count)
     
    
    -- rect_1 = {x = 400, y = 300, w = 50, h = 200}
    -- rect_2 = {x = 400, y = 300, w = 200, h = 50}

    -- timer:after(1, function()
    --     timer:tween(1, rect_1, {}, 'in-out-cubic', function()
    --         timer:tween(1, rect_1, {w=10, h=100}, 'in-out-cubic', function()
    --     end)
    --     end)
    -- end)

    -- for i = 1, 10 do
    --     timer:after(i * 2, function()
    --     table.insert(numbers, love.math.random())
    -- end)
    -- end
    activeTweens = {}

    function animateCircle()
    -- expand
    local expandTween = timer:tween(0.5, circle, {radius = 96}, 'in-out-cubic', function()
        -- shrink
        local shrinkTween = timer:tween(0.5, circle, {radius = 24}, 'in-out-cubic', animateCircle)
        activeTweens[1] = shrinkTween
    end)
    activeTweens[1] = expandTween
end

end



function love.keypressed(key)
    if key == "y" then
     timer:clear()

        -- start a fresh animation
        animateCircle()
    end
    end


 

function love.update(dt)

    timer:update(dt)

    if input:pressed('test') then
        print('pressed')
    end
    if input:down('right_key') then
        rect_1.x = rect_1.x + 1
    end
    if input:down('left_key') then
        rect_1.x = rect_1.x - 1
    end

    if input:released('test') then
        print('released')
    end
    if input:pressed('r_key') then
        rect_1.h = rect_1.h / 1.5
        rect_1.w = rect_1.w / 1.5
        print('rrr')
    end

    if input:pressed('t_key') then
        rect_1.h = rect_1.h * 1.5
        rect_1.w = rect_1.w * 1.5
        print('ttt')
    end

    

    if input:down('down') then
        print('aaa')
    end

end

function love.draw()
    love.graphics.circle('fill', 400, 300, circle.radius)
    -- for i, num in ipairs(numbers) do
    -- love.graphics.print(num, 300, i * 50)
    -- draw red rectangle first (background)
    -- love.graphics.setColor(255, 0, 0)
    -- love.graphics.rectangle('fill', rect_2.x, rect_2.y - rect_2.h / 2, rect_2.w, rect_2.h)

    -- -- draw blue rectangle on top
    -- love.graphics.setColor(0, 0, 255)
    -- love.graphics.rectangle('fill', rect_1.x, rect_1.y - rect_1.h / 2, rect_1.w, rect_1.h)
    end


