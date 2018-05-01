local isep = {}

function isep.crop(img, sx, sy, sw, sh, convert)--img = input imageData, convert = if it will return Image instead of ImageData
  convert = convert == nil or convert
  
  local t = type(img)
  t = t == 'userdata' and img.type and img:type() or t
  
  if t == 'string' then
    img = love.image.newImageData(img)
    t = img:type()
  end
  
  assert(t == "ImageData", "ImageData or string expected, got " .. t)
  
  local returned = love.image.newImageData(sw, sh)
  local function f(x, y, r, g, b, a)
    x = x + sx
    y = y + sy
    if x > img:getWidth() - 1 or y > img:getHeight() - 1 then
      return 0, 0, 0, 0
    end
    return img:getPixel(x, y)
  end
  returned:mapPixel(f)
  
  if convert then
    return love.graphics.newImage(returned)
  end
  return returned
end

function isep.separate(img, w, h, x, y, ex, ey, opt) --img = input imageData, (ex, ey) = end point, opt = frame option table (love.graphics.draw()'s args) or function(x, y, w, h) returning it
  if type(img) == 'string' then
    img = love.image.newImageData(img)
  end
  
  x, y = x or 1, y or 1
  if type(ex) == 'number' then
    if type(ey) == 'number' then
      opt = opt or {}
    else
      opt = opt or ey or {}
      ey = img:getHeight()
    end
  else
    opt = opt or ey or ex or {}
    ey = img:getHeight()
    ex = img:getWidth()
  end
  
  
  local f
  
  if type(opt) == 'table' then
    f = function()
      return opt
    end
  else
    f = opt
  end
  
  local returned, n = {}, 0
  
  for i = x, ex - w, w do
    for j = y, ey - h, h do
      n = n + 1
      returned[n] = {isep.crop(img,i, j, w, h)}
      for k, v in pairs(f(i, j, w, h)) do
        returned[n][k] = v 
      end
    end
  end
  
  return returned
end
return isep