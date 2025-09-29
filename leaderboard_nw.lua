-- local https = require("https")
local ltn12 = require("ltn12")
local json = require("objects/dkjson/dkjson")

local Leaderboard = {}
Leaderboard.__index = Leaderboard

-- Firebase endpoint
Leaderboard.url = "https://ecgame-d742b-default-rtdb.asia-southeast1.firebasedatabase.app/leaderboard.json"

Leaderboard.scores = {}

-- Submit a score
function Leaderboard:submit(playerName, score)
    local payload = json.encode({ player = playerName, score = score })
    local response_body = {}
    local res, code, headers, status = https.request{
        url = self.url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#payload)
        },
        source = ltn12.source.string(payload),
        sink = ltn12.sink.table(response_body)
    }
    print("Submitted:", table.concat(response_body))
end

-- Fetch top 10 scores
function Leaderboard:getTop()
    local response_body = {}
    local res, code, headers, status = https.request{
        url = self.url,
        method = "GET",
        sink = ltn12.sink.table(response_body)
    }

    local ok, decoded = pcall(json.decode, table.concat(response_body))
    if ok and decoded then
        local scores = {}
        for k, v in pairs(decoded) do
            if v and v.player and v.score then
                table.insert(scores, v)
            end
        end
        table.sort(scores, function(a, b) return a.score > b.score end)
        self.scores = {}
        for i = 1, math.min(10, #scores) do
            table.insert(self.scores, scores[i])
        end
    else
        print("Failed to fetch leaderboard")
        self.scores = {}
    end
end

-- Draw leaderboard
function Leaderboard:draw(x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Leaderboard", x, y)
    local line = 1
    for i, entry in ipairs(self.scores) do
        if entry and entry.player and entry.score then
            love.graphics.print(i .. ". " .. entry.player .. " - " .. entry.score, x, y + line * 20)
            line = line + 1
        end
    end
end

return Leaderboard
