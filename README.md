# What is Love-Imation?
**"Love-Imation"** is an animation library written for [the LÖVE engine](https://love2d.org).  
It helps to make animations with constant framerate of sprites (or any other drawable LÖVE objects), even if the sprites are merged into one spritesheet (by separating it by a special sub-module).

# How does it work?
*Note: a reference to the library and an example animation are repectively named* `li` *and* `anim` *in the below text.*  
Firstly, you need to initialize an new animation table. You can do it by calling `li.newAnimation()` with the following arguments (in the order as they are stated here, arguments without default values are obligatory):
1. Frame set table (see below, stored later as `anim.frames`)
2. Animation speed (in seconds, stored later as `anim.speed`)
3. If the animation will be looping (defaults to `true`, stored later as `anim.isLooping`)
4. If the animation will play after the initialization (defaults to `true`, initial value of `anim.isPlaying`)
5. Start frame (defaults to 1, initial value of `anim.frame`)
6. Filter modes (table of arguments, defaults to `{love.graphics.getDefaultFilter()}` or `{'linear', 'linear'}` in versions prior to 0.9.0)  

## Frame and frame set tables 
Animation frame set is stored in the array-like order (i.e. with integer ordered keys). After the initialzation, you can also get the table's size by the key `'n'`.  
After the initalization, each frame set table value must be a frame table standing for arguments for `love.grpahics.draw(...)`. The arguments can be assinged by either their order number or their interal names according to [this LÖVE wiki page](https://love2d.org/wiki/love.graphics.draw). After it, the table also has a special metatable returning default values instead of non-setted and binding the string keys to the number ones.
While the initalization, frame table can be generated from a drawable object or a string with a filepath to an image.  
```Lua
anim1 = li.newAnimation({"frame1.png", "frame2.png"}, 1 / 30)
anim2 = li.newAnimation({
  {love.graphics.newImage("frame1.png")},
  {love.graphics.newImage("frame2.png")}
}, 1 / 30)
--In fact, anim1 is equal to anim2 
 ```
    
## Propeties
Each animation has some variables to process it and to get/change information about it.  
* `anim.frame` = Current frame number
* `anim.frames` = Frame set
    * `anim.frames.n` = frame set size (faster than `#anim.frames`)
* `anim.time` = Time passed after the first frame was shown
* `anim.isLooping` = If the animation is looping (starts again after it has finished)
* `anim.isPlaying` = If the animation is playing
  * `anim:play([...])` or `anim.isPlaying = true` = Play/resume the animation (`anim.time` aren't reseted). Can also get other animations to play/resume as arguments.
  * `anim:stop([...])` or `anim.isPlaying = false` = Stop/pause the animation (`anim.time` aren't reseted). Can also get other animations to stop/pause as arguments.
* `anim.getDuration([to[, from]])` = get time passed between `from or 1` starts and `to or anim.frames.n` finishes
* `anim.getFrameByTime(time[, from]) = get the number of the frame shown while the animation time is equal `time + anim:getDuration(from or 1)`
* `anim.getCurrentFrame()` = return `anim.frames[anim.frame]`  
  
## Updating and drawing
You can update animations by calling `anim:update(dt)`, where `dt` is a delta-time (time passed after the previous frame). The calling are recomended to be done by `love.update(dt)` with its `dt` as the argument.  
You can also draw correctly the current frame with an additional transform by calling `anim:draw(...)` while drawing. It gets an argument list like `love.grpahics.draw(...)` gets without the first (`drawable`) argument. The frame/default values are added to (or multiplies, if they are scale arguments) respective got ones and the functions calls `love.graphics.draw(anim.getCurrentFrame()[1], ...)`.  
  
# What is Image Separator ('isep', 'imgSeparator.lua')?
**Image separator** (imported as `li.isep`) is a sub-module for croping images and separating spritesheets. It has only 2 functions:  
* `li.isep.crop(img, sx, sy, sw, sh[, convert])` = create new ImageData from a rect area from (`sx`, `sy`) to (`sx + sw`, `sy + sh`) of ImageData 'img' and return it. The new ImageData also are converted to an image before returning, if `convert` is equal to `true` (by default, it is). `img` can be also a string with a filepath to a source image and are replaced by its ImageData while croping. Pixels out of `img`'s size are setted as transparent (`{0, 0, 0, 0}`).
* `li.isep.separate(img, w, h [, x, y [, ex, ey]][, opt])` = give a frame set from ImageData `img` by dividing its rect area from (`x or 0`, `y or 0`) to (`ex or img:getWidth()`, `ey or img:getHeight()`) into `w`x`h` sprites. The sprites are added to frame tables with arguments contained in `opt`, if it's a table, or returned by `opt(i, j, w, h)`, where `i` and `j` are dividing loop variables standing for the sprite's left-top angle on the original image, if it's a function.

# Which LÖVE versions support the library?
The library are tested in LÖVE 11.1, but you probably can use it in any version of LÖVE.

# Under what the library is licensed?
It's licensed under the MIT/X11 license (see [LICENSE](https://raw.githubusercontent.com/AlexanDDOS/love-imation/master/LICENSE)).
