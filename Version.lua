-- Pog Raid version check, kept deliberately light:
--   * one tiny guild message at login ("V<version>"),
--   * a handful of the addons that hear it (about REPLIERS, picked at random,
--     everyone in a small guild) whisper their version back, at most once per
--     person every 10 minutes ("W<version>"), so a newer version gets noticed
--     without the whole guild answering every login,
--   * everyone else's version rides along on Sync's fingerprint, sent at
--     login and every 10 minutes; the list is saved between sessions.
-- A newer version seen anywhere gives one chat note per session.
local _, ns = ...

local Version = {}
ns.Version = Version

Version.KEEP = 30 * 86400   -- forget people not seen for a month
Version.seen = {}           -- this session: key -> version
Version.replied = {}        -- key -> GetTime() we last answered them
Version.REPLY_EVERY = 600
Version.REPLIERS = 5

local function parse(v)
    local a, b, c = tostring(v or ""):match("^(%d+)%.(%d+)%.(%d+)$")
    if not a then return nil end
    return { tonumber(a), tonumber(b), tonumber(c) }
end

-- -1 / 0 / 1 like a comparison, or nil if either isn't a version.
function Version.Compare(x, y)
    local a, b = parse(x), parse(y)
    if not a or not b then return nil end
    for i = 1, 3 do
        if a[i] ~= b[i] then return a[i] < b[i] and -1 or 1 end
    end
    return 0
end

local function store()
    ns.db.versions = ns.db.versions or {}
    return ns.db.versions
end

Version.dev = {}            -- this session: key -> { v, dota } for dev builds

function Version:Note(sender, version)
    if not sender or type(version) ~= "string" then return end
    local base, dev = version:gsub("%-dev$", "")
    local dota
    base, dota = base:gsub("%-dota$", "")
    if not parse(base) then return end
    dota = dota == 1
    local key = ns.Attendance:Key(sender)
    if key == ns.Sync:Me() then return end
    -- Dev builds still advertise capabilities, but aren't listed as releases.
    if dev == 1 then
        self.dev[key] = { v = base, dota = dota }
        return
    end
    self.dev[key] = nil
    self.seen[key] = base
    store()[key] = { v = base, t = ns.Now(), dota = dota }
    if dota and Version.Compare(base, ns.VERSION) == 1 and not self.warned then
        self.warned = true
        ns.Print(("a newer Dota raid tools (%s) is out, you have %s. Update it from GitHub Releases."):format(base, ns.VERSION))
    end
    if ns.Settings then ns.Settings:Changed() end
end

-- Newest version known in the guild (including ours).
function Version:Newest()
    local best = ns.VERSION
    for _, e in pairs(store()) do
        if e.dota and Version.Compare(e.v, best) == 1 then best = e.v end
    end
    return best
end

-- Guildies known to run either addon: { name, version, dota, t, online }.
function Version:List()
    local now, out = ns.Now(), {}
    for name, e in pairs(store()) do
        if now - e.t > Version.KEEP then
            store()[name] = nil
        else
            out[#out + 1] = { name = name, version = e.v, dota = e.dota == true, t = e.t, online = ns.Roster.online[name] == true }
        end
    end
    table.sort(out, function(a, b)
        if a.online ~= b.online then return a.online end
        if a.dota ~= b.dota then return a.dota end
        local c = Version.Compare(a.version, b.version)
        if c and c ~= 0 then return c == 1 end
        return a.name < b.name
    end)
    return out
end

function Version:Announce()
    if IsInGuild() then ns.Comm.Send("V" .. ns.WireVersion(), "GUILD") end
end

function Version:OnMessage(kind, text, channel, sender)
    local v = text:sub(2)
    if kind == "V" and channel == "GUILD" then
        self:Note(sender, v)
        local key = ns.Attendance:Key(sender)
        local last = self.replied[key]
        if (not last or GetTime() - last >= Version.REPLY_EVERY) and math.random() * ns.Sync:Peers() < Version.REPLIERS then
            self.replied[key] = GetTime()
            ns.Comm.Send("W" .. ns.WireVersion(), "WHISPER", Ambiguate(sender, "none"))
        end
    elseif kind == "W" and channel == "WHISPER" then
        self:Note(sender, v)
    end
end

ns.On("PLAYER_LOGIN", function() C_Timer.After(25, function() Version:Announce() end) end)
