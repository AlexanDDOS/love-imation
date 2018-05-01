local BASE = (...):match('(.-)[^%.]+$')
local post8 = love.graphics.getDefaultFilter ~= nil

local frame_aliases = {'drawable', 'x', 'y', 'r', 'sx', 'sy', 'ox', 'oy', 'kx', 'ky'}
local frame_defaults = {'', 0, 0, 0, 1, 1, 0, 0, 0, 0}
local frame_mt = {
  __index = function(t, k)
    if type(k) == 'string' then
      for i = 1, 10 do
        if i ~= 6 and k == frame_aliases[i] then
          return t[i] or frame_defaults[i]
        end
      end
      if k == 'sy' then
        return rawget(t, 6) or t[5]
      end
    end
    if k == 6 then
      return rawget(t, 6) or t[5]
    end
    return rawget(t, k) or frame_defaults[k]
  end,
  __newindex = function(t, k, v)
    if type(k) == 'string' then
      for i = 1, 10 do
        if k == frame_aliases[i] then
          t[i] = v
          return nil
        end
      end
    end
    rawset(t, k, v)
  end
}

local li = {}
li.isep = require(BASE .. 'imgSeparator')

local function newAnim(set, speed, isLooping, playNow, startFrame, filterMode) --filterMode = {min, mag} or a string standing for both values
  local def_fl = post8 and {love.graphics.getDefaultFilter()} or {'linear', 'linear'}
  isLooping = isLooping == nil or isLooping
  playNow = playNow == nil or playNow
  startFrame = startFrame or 1
  if filterMode then
    if type(filterMode) == 'string' then
      filterMode = {filterMode, filterMode}
    else
      for i = 1, 2 do
        filterMode[i] = filterMode[i] or def_fl[i]
      end
    end
  else
    filterMode = def_fl
  end

  local anim = {
    frames = {n = 0},
    isLooping = isLooping,
    frame = startFrame,
    time = 0,
    isPlaying = playNow,
    speed = speed
  }
  
  for i = 1, #set do
    
    anim.frames[i] = {}
    setmetatable(anim.frames[i], frame_mt)
    
    if type(set[i]) ~= 'table' then
      anim.frames[i][1] = set[i]
    else
      anim.frames[i][1] = set[i][1]
      for k, v in pairs(set[i]) do
        if k ~= 1 then
          anim.frames[i][k] = v
        end
      end
    end
    if type(anim.frames[i][1]) == 'string' then
      anim.frames[i][1] = love.graphics.newImage(set[i])
    end
    if anim.frames[i][1].setFilter then 
      anim.frames[i][1]:setFilter(unpack(filterMode))
    end
    
    anim.frames.n = anim.frames.n + 1
  end
  setmetatable(anim.frames, {
    __newindex = function(t, k, v)
      if k ~= 'n' then
        if t[k] == nil then
          if v ~= nil then
            rawset(t, 'n', t.n + 1)
          end
        else
          if v == nil then
            rawset(t, 'n', t.n - 1)
          end
        end
        rawset(t, k, v)
      end
    end
  })
  
  anim.time = li.getDuration(anim, anim.frame)
  
  return setmetatable(anim, li)
end

function li.__index(t, k)
  return rawget(t, k) or li[k]
end

function li.__newindex(t, k, v)
  if k == 'isPlaying' then
    if v then 
      t:play()
    else
      t:stop()
    end
  elseif k == 'frame' then
    rawset(t, "time", t:getDuration(v))
    rawset(t, k, v)
  elseif k == 'time' then
    rawset(t, "frame", t:getFrameByTime(v))
    rawset(t, k, v)
  else
  rawset(t, k, v)
  end
end

function li:getDuration(to, from) --Get duration from the frame 'from' to the frame 'to'
  from = from or 1
  to = to or self.frames.n
  
  if not self.isLooping then
    from = math.max(math.min(from, self.frames.n), 1)
    to = math.max(math.min(to, self.frames.n), 1)
  end
  
  return (from - to) * self.speed --If to > from, returned value is negative
end


function li:getFrameByTime(time, from)
  local animLen = self.frames.n
  local animDur = animLen * self.speed
  
  if from then
    time = time + self:getDuration(from)
  end
  
  if self.isLooping then
    if time < 0 then
      time = time - math.min(math.floor(time / animDur), -1) * animDur
    end
  else
    time = math.max(math.min(time, animDur - self.speed), 0)
  end
  return (math.floor(time / self.speed) % animLen) + 1
end

function li:update(dt)
  if self.isPlaying then
    local animDur = self.frames.n * self.speed
    self.time = self.time + dt
    if self.time >= animDur then
      if self.isLooping then
        rawset(self, "time", self.time - math.floor(self.time / animDur) * animDur)
      else
        rawset(self, "time", animDur)
        self.isPlaying = false
      end
    end
  end
  rawset(self, "frame", self:getFrameByTime(self.time))
end

function li:play(...)
  if ... then
    local t = {...}
    for k, v in pairs(t) do
      li.play(v)
    end
  end
  
  rawset(self, 'isPlaying', true)
  if not self.isLooping and self.time >= self.frames.n * self.speed then
    self.time = 0
    self.frame = self:getFrameByTime(self.time)
  end
end

function li:stop(...) 
  if ... then
    local t = {...}
    for k, v in pairs(t) do
      li.stop(v)
    end
  end
  
  rawset(self, 'isPlaying', false)
end

function li:getCurrentFrame()
  return self.frames[self.frame]
end

function li:draw(...)
  local frame = self:getCurrentFrame()
  local args = {frame[1], ...}
  local letters = {'x', 'y'}
  
  for i = 2, 10 do
    if i < 5 or i > 6 then
      args[i] = args[i] or frame_defaults[i] + frame[i]
    else
      args[i] = args[i] or frame_defaults[i] * frame[i]
    end
  end

  love.graphics.draw(unpack(args))
end

li.newAnimation = newAnim

return li