local BASE = (...):match('(.-)[^%.]+$')
local post8 = love.graphics.getDefaultFilter ~= nil

local frame_alias = {drawable = 1, x = 2, y = 3, r = 4, sx = 5, sy = 6, ox = 7, oy = 8, kx = 9, ky = 10}

local frame_mt = {
  __index = function(t, k)
    local r = rawget(t, k)
    if r == nil then
      k = frame_alias[k] or k
      r = rawget(t, k)
      if k == 6 then
        r = r or rawget(t, 5)
      end
    end
    return r
  end,
  __newindex = function(t, k, v)
    rawset(t, frame_alias[k] or k, v)
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
    frames = {n = 0, dur = 0},
    isLooping = isLooping,
    frame = startFrame,
    lastFrame = startFrame,
    time = 0,
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
    anim.frames.dur = anim.frames.dur + anim.speed
    
  end
  
  setmetatable(anim, li)
  
  anim.isPlaying = playNow
  anim.time = anim:getDuration(anim.frame)
  
  return anim
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
  end
end

function li:getDuration(to, from) --Get duration from the frame 'from' to the frame 'to'
  from = from or 1
  to = to or self.frames.n
  
  
  if not self.isLooping then
    from = math.max(math.min(from, self.frames.n), 1)
    to = math.max(math.min(to, self.frames.n), 1)
  end
  
  return (to - from) * self.speed --If to > from, returned value is negative
end


function li:getFrameByTime(time, from)
  
  if from then
    time = time + self:getDuration(from)
  end
  
  if self.isLooping then
    if time < 0 then
      time = time - math.min(math.floor(time / self.frames.dur), -1) * self.frames.dur
    end
  else
    time = math.max(math.min(time, self.frames.dur - self.speed), 0)
  end
  return (math.floor(time / self.speed) % self.frames.n) + 1
end

function li:update(dt)
  self.frames.n = #self.frames
  self.frames.dur = self.frames.n * self.speed
  
  if self.lastFrame ~= self.frame then
    self.time = self:getDuration(self.frame)
  end
  
  if not self.isLooping and self.time >= self.frames.dur then
    self.time = self.frames.dur
    self:stop()
  end
  
  if self.isPlaying then
    self.time = self.time + dt
    if self.time >= self.frames.dur and self.isLooping then
      self.time = self.time - math.floor(self.time / self.frames.dur) * self.frames.dur
    end
  end
  self.lastFrame = self.frame
  self.frame = self:getFrameByTime(self.time)
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
  
  for i = 2, 10 do
    if i < 5 or i > 6 then
      args[i] = (args[i] or 0) + (frame[i] or 0)
    else
      args[i] = (args[i] or 1) * (frame[i] or 1)
    end
  end

  love.graphics.draw(unpack(args))
end

li.newAnimation = newAnim

return li