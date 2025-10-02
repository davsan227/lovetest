local https = require("https")
local json = require("objects.dkjson.dkjson")

local Leaderboard = {}
Leaderboard.__index = Leaderboard

Leaderboard.url = "https://ecgame-d742b-default-rtdb.asia-southeast1.firebasedatabase.app/leaderboard.json"
Leaderboard.scores = {}

-- Fetch top 10 scores
-- Fetch top 10 scores
function Leaderboard:getTop()
    -- Some libraries return the status code as a separate value.
    -- Adjusting to handle `code, body` as return values.
    local ok, code, body = pcall(function()
        return https.request(self.url)
    end)

    if not ok or code ~= 200 or not body then
        print("Failed to fetch leaderboard. HTTP Status:", code, "Error:", body)
        self.scores = {}
        return
    end

    local decoded_ok, decoded = pcall(json.decode, body)
    if not decoded_ok or not decoded then
        print("Failed to decode leaderboard JSON")
        self.scores = {}
        return
    end

    if type(decoded) ~= "table" then
        print("Decoded JSON is not a table. Cannot process leaderboard data.")
        self.scores = {}
        return
    end

    local scores = {}
    for _, v in pairs(decoded) do
        if v and v.player and v.score then
            table.insert(scores, {player = v.player, score = v.score})
        end
    end

    table.sort(scores, function(a,b) return a.score > b.score end)
    self.scores = {}
    for i = 1, math.min(10, #scores) do
        table.insert(self.scores, scores[i])
    end
end

-- Submit score
function Leaderboard:submit(playerName, score)
    local payload = json.encode({player = playerName, score = score})

    -- Create an options table for the POST request
    local options = {
        method = "POST",
        data = payload,
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = #payload -- Optional but good practice
        }
    }

    local ok, code, body = pcall(function()
        -- The request function is called with the URL and a single options table
        return https.request(self.url, options)
    end)

    if not ok or code ~= 200 then
        print("Failed to submit score. HTTP Status:", code, "Error:", body)
        return
    end

    print("Submitted:", playerName, score)
    self:getTop() -- refresh
end

-- Draw leaderboard
function Leaderboard:draw(x,y)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Leaderboard", x,y)
    local line = 1
    for i,entry in ipairs(self.scores) do
        love.graphics.print(i..". "..entry.player.." - "..entry.score, x, y + line*20)
        line = line + 1
    end
end

return Leaderboard
