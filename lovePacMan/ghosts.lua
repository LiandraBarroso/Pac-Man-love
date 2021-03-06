function setState(val, state)
  if state == 'fright' and val.state == 'exitHome' then return end
  val.state = state
  -- if state == 'fright' then pacMan.speedCoef = levelSpec[LEVEL].pacManFrightSpeed end
  local res = ''
  if val.direction == 'up' then
    res = 'down'
  elseif val.direction == 'right' then
    res = 'left'
  elseif val.direction == 'down' then
    res = 'up'
  else
    res = 'right'
  end
  val.nextDecision = res
end

local function distance (x1, y1, x2, y2 )
  local dx = x1 - x2
  local dy = y1 - y2
  return math.sqrt ( dx * dx + dy * dy )
end

local frightAtlas = love.graphics.newImage('assets/img/fantomesPacman5.png')

local function getNextTile(val)
  local rndX, rndY = round(val.x), round(val.y) 
  if val.direction == "left" then
    return rndX -1, rndY
  elseif val.direction == 'right' then
    return rndX +1, rndY
  elseif val.direction == 'up' then 
    return rndX, rndY-1
  elseif val.direction == 'down' then 
    return rndX, rndY+1
  end
end

local function getSurTile(x,y)
  return 
  {
    OBSTACLE[y-1][x],
    OBSTACLE[y][x+1],
    OBSTACLE[y+1][x],
    OBSTACLE[y][x-1],
  }
end

local function update (val, dt)
  

  if val.state == 'goHome' then
    if round(val.x) == round(val.startX) and round(val.y) == round(val.startY) then
      val:init()
      return
    else
      local dx = round(val.startX) - val.x
      local dy = round(val.startY) - val.y
      val.x = val.x + dt * val.speed * val.speedCoef * dx *0.8
      val.y = val.y + dt * val.speed * val.speedCoef * dy *0.8
      return
    end
  end

  if round(val.x) == round(pacMan.x) and round(val.y) == round(pacMan.y) then
    if val.state == 'goHome' then
    elseif val.state == 'fright' then
      S_EATGHOST:play()
      pacMan.succCatch = pacMan.succCatch + 1
      if pacMan.succCatch > 5 then pacMan.succCatch = 5 end 
      pacMan.score = pacMan.score + CATCHPOINT[pacMan.succCatch]
      val.state = 'goHome'
      return
    else
      pacMan_states.game.catch()
    end
  end
  
  if val.state == 'fright' then
    val.curAtlas = 'frightAtlas'
    val.animDir ='fright'
  else
    val.curAtlas = 'atlas'
    val.animDir = val.direction
  end

  if round(val.x) < 3 and round(val.y) == 18 then val.x = 27; val.nextX = 26 return end
  if round(val.x) > 27 and round(val.y) == 18  then val.x = 3; val.nextX = 4 return end

  if round(val.x) == val.nextX and round(val.y) == val.nextY then

    val.direction = val.nextDecision

    local nX, nY = getNextTile(val)
    local surObst = getSurTile(nX,nY)

    local dist = {}
    for i=1,#surObst do
      repeat
        if surObst[i] == 1 then break end -- == continue
        if i == 1 and val.direction == 'down' then break end
        if i == 2 and val.direction == 'left' then break end
        if i == 3 and val.direction == 'up' then break end
        if i == 4 and val.direction == 'right' then break end
        if i == 1 then
          table.insert(dist, { dist = math.abs(distance(val.targetX, val.targetY, nX, nY-1)), x=nX,y=nY-1, dir="up" })
        elseif i == 2 then
          table.insert(dist, { dist= math.abs(distance(val.targetX, val.targetY, nX+1, nY)), x=nX+1,y=nY, dir="right"})
        elseif i == 3 then
          table.insert(dist, { dist = math.abs(distance(val.targetX, val.targetY, nX, nY+1)), x=nX, y=nY+1, dir ="down"})
        elseif i == 4 then
          table.insert(dist, { dist = math.abs(distance(val.targetX, val.targetY, nX-1, nY)), x=nX-1, y=nY, dir="left"})
        end
      until true
    end
    if val.state == 'fright' then
      table.sort(dist, function(a,b)
        local aa = love.math.random()
        return aa%2 > 1 
      end)
    else
      table.sort(dist, function(a,b) return a.dist < b.dist end)
    end

    val.nextX = nX
    val.nextY = nY

    val.nextDecision = dist[1].dir
  end

  if val.direction == 'left' or val.direction == 'right' then
    if val.y%1 ~= 0 then val.y = round(val.y)end
  elseif val.direction == 'up' or val.direction == 'down' then
    if val.x%1 ~= 0 then val.x = round(val.x)end
  end
  
  if val.direction == 'left' then
    val.dirX= -1
    val.dirY = 0
  elseif val.direction == 'right' then
    val.dirX= 1
    val.dirY = 0
  elseif val.direction == 'up' then
    val.dirX= 0
    val.dirY = -1
  elseif val.direction == 'down' then
      val.dirX= 0
      val.dirY = 1
  end

  if not val.state == 'fright' then
    val.animDir = val.direction
  end
  val.x = val.x + dt * val.speed * val.speedCoef * val.dirX
  val.y = val.y + dt * val.speed * val.speedCoef * val.dirY

end

local function draw (val)
  if val.blink then
    love.graphics.setColor(1,1,1,val.blinkTime%1)
  end
  love.graphics.draw(val[val.curAtlas], val.sprites[val.animDir][val.keyframe],
  (val.x-1)*BLOCKSIZE*PPM + BLOCKSIZE*PPM*0.5,
  (val.y-1)*BLOCKSIZE*PPM + BLOCKSIZE*PPM*0.5,
  val.angle,
  val.scaleSignX * PPM * 1.6,
  val.scaleSignY * PPM * 1.6,
  16*0.5,
  16*0.5)

  if val.blink then
    love.graphics.setColor(1,1,1,1)
  end

  if DEBUG then 
    love.graphics.setColor(val.color.r,val.color.g,val.color.b,val.color.a)
    love.graphics.rectangle('fill',(val.targetX-1)*BLOCKSIZE*PPM , (val.targetY-1)*BLOCKSIZE*PPM, BLOCKSIZE*PPM, BLOCKSIZE*PPM)
    love.graphics.print('x: '..val.x..'; y: '..val.y, (VW*PPM)+10, 45,0,PPM)
    love.graphics.print('dir: '..val.direction, (VW*PPM)+10, 60,0,PPM)
    love.graphics.print('nextX: '..val.nextX..'; nextY: '..val.nextY, (VW*PPM)+10, 75,0,PPM)
    love.graphics.print('nextDecision: '..val.nextDecision, (VW*PPM)+10, 90,0,PPM)
    love.graphics.print('state: '..val.state, (VW*PPM)+10, 105,0,PPM)
    love.graphics.setColor(1,1,1,1)
  end
end


--------------------------------blinky-------------------------------------
g_red = {
    startX=14.5, startY=12+3,
    x=14.5, y=12+3,
    timer = 0,
    speed = 7.4,
    color = {r=1, g=0, b=0, a=0.7},
    dirX = 0,
    dirY = 0,
    direction = "right",
    animDir = "right",
    curAtlas = "atlas",
    keyframe=1,
    nbrFrame=2,
    fps=5,
    angle=0,
    scaleSignX= 1,
    scaleSignY= 1,
    state = "scatter",
    targetX = 25,
    targetY = 1,
    speedCoef = 0.75,
    nextDecision = "right",
    nextX = 16,
    nextY = 12+3,
    chaseIter = 1,
    scatterIter = 1,
    blink = false,
    blinkTime = 0
  }
  g_red.animTimer = 1 /g_red.fps
  g_red.atlas= love.graphics.newImage('assets/img/fantomesPacman4.png')
  g_red.frightAtlas = frightAtlas
  g_red.sprites = {}
  g_red.sprites.right = {
    love.graphics.newQuad(4*16,0,16,16,g_red.atlas:getDimensions()),
    love.graphics.newQuad(1*16,0,16,16,g_red.atlas:getDimensions()),
  }
  g_red.sprites.down = {
    love.graphics.newQuad(2*16,0,16,16,g_red.atlas:getDimensions()),
    love.graphics.newQuad(1*16,0,16,16,g_red.atlas:getDimensions()),
  }
  g_red.sprites.left = {
    love.graphics.newQuad(4*16,0,16,16,g_red.atlas:getDimensions()),
    love.graphics.newQuad(1*16,0,16,16,g_red.atlas:getDimensions()),
  }
  g_red.sprites.up = {
    love.graphics.newQuad(6*16,0,16,16,g_red.atlas:getDimensions()),
    love.graphics.newQuad(1*16,0,16,16,g_red.atlas:getDimensions()),
  }
  g_red.sprites.fright = {
    love.graphics.newQuad(0*16,0,16,16,frightAtlas:getDimensions()),
    love.graphics.newQuad(1*16,0,16,16,frightAtlas:getDimensions()),
  }


g_red.draw = function(val)
  draw(val)
end

g_red.update = function(val, dt)
  val.timer = val.timer  + dt
  if val.state == 'chase' then
    val.speedCoef = levelSpec[LEVEL].ghostSpeed
    val.targetX, val.targetY = round(pacMan.x), round(pacMan.y)
    if val.timer >= levelSpec[LEVEL].chaseTime[val.chaseIter] then
      val.chaseIter = val.chaseIter + 1
      if val.chaseIter > 4 then val.chaseIter = 4 end
      val.timer = 0
      setState(val, 'scatter')
    end
  elseif val.state == 'scatter' then
    val.speedCoef = levelSpec[LEVEL].ghostSpeed
    if val.timer >= levelSpec[LEVEL].scatterTime[val.scatterIter] then
      val.scatterIter = val.scatterIter + 1
      if val.scatterIter > 4 then val.scatterIter = 4 end
      val.timer = 0
      setState(val, 'chase')
    end
    val.targetX, val.targetY = 25, 1
  elseif val.state == 'fright' then
    val.speedCoef =levelSpec[LEVEL].ghostFrightSpeed
    if val.timer >= levelSpec[LEVEL].frightTime then
      pacMan.speedCoef = levelSpec[LEVEL].pacManSpeed
      val.timer = 0
      val.blink = false
      val.blinkTime = 0
      setState(val, 'chase')
    elseif val.timer >= levelSpec[LEVEL].frightTime - 2 then
      val.blink = true
      val.blinkTime = val.blinkTime + 3*dt
    end
  end
  update(val, dt)
end

g_red.init = function(val)
  val.startX=14.5
  val.startY=12+3
  val.x=14.5
  val.y=12+3
  val.timer = 0
  val.dirX = 0
  val.dirY = 0
  val.direction = "right"
  val.animDir = "right"
  val.curAtlas = "atlas"
  val.keyframe=1
  val.angle=0
  val.scaleSignX= 1
  val.scaleSignY= 1
  val.state = "scatter"
  val.targetX = 25
  val.targetY = 1
  val.speedCoef = levelSpec[LEVEL].ghostSpeed
  val.nextDecision = "right"
  val.nextX = 16
  val.nextY = 12+3
  val.blink = false
  val.blinkTime = 0
end


--------------------------------pinky-------------------------------------
g_pink = {
  startX=12, startY=18,
  x=12, y=19,
  timer = 0,
  speed = 7.4,
  color = {r=1, g=0, b=1, a=0.7},
  dirX = 0,
  dirY = 0,
  direction = "up",
  animDir = "up",
  curAtlas = "atlas",
  keyframe=1,
  nbrFrame=2,
  fps=5,
  angle=0,
  scaleSignX= 1,
  scaleSignY= 1,
  state = "exitHome",
  targetX = 15,
  targetY = 15,
  speedCoef = 0.75,
  nextDecision = "up",
  nextX = 12,
  nextY = 17,
  chaseIter = 1,
  scatterIter = 1,
  blink = false,
  blinkTime = 0
}
g_pink.animTimer = 1 /g_pink.fps
g_pink.atlas= love.graphics.newImage('assets/img/fantomesPacman2.png')
g_pink.frightAtlas = frightAtlas
g_pink.sprites = {}
g_pink.sprites.right = {
  love.graphics.newQuad(4*16,0,16,16,g_pink.atlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,g_pink.atlas:getDimensions()),
}
g_pink.sprites.down = {
  love.graphics.newQuad(2*16,0,16,16,g_pink.atlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,g_pink.atlas:getDimensions()),
}
g_pink.sprites.left = {
  love.graphics.newQuad(4*16,0,16,16,g_pink.atlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,g_pink.atlas:getDimensions()),
}
g_pink.sprites.up = {
  love.graphics.newQuad(6*16,0,16,16,g_pink.atlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,g_pink.atlas:getDimensions()),
}
g_pink.sprites.fright = {
  love.graphics.newQuad(0*16,0,16,16,frightAtlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,frightAtlas:getDimensions()),
}


g_pink.draw = function(val)
draw(val)
end

g_pink.update = function(val, dt)
val.timer = val.timer  + dt

if val.state == 'chase' then
  val.speedCoef = levelSpec[LEVEL].ghostSpeed

  if pacMan.direction == 'up' then
    val.targetX, val.targetY = math.max(round(pacMan.x)-4, 1), math.max(round(pacMan.y)-4,4)
  elseif pacMan.direction == 'right' then
    val.targetX, val.targetY = math.min(round(pacMan.x)+4, 28), round(pacMan.y)   
  elseif pacMan.direction == 'down' then
    val.targetX, val.targetY = round(pacMan.x), math.min(round(pacMan.y)+4,34)
  elseif pacMan.direction == 'left' then
    val.targetX, val.targetY = math.max(round(pacMan.x)-4, 1), round(pacMan.y)
  end

  if val.timer >= levelSpec[LEVEL].chaseTime[val.chaseIter] then
    val.chaseIter = val.chaseIter + 1
    if val.chaseIter > 4 then val.chaseIter = 4 end
    val.timer = 0
    setState(val, 'scatter')
  end
elseif val.state == 'scatter' then
  val.speedCoef = levelSpec[LEVEL].ghostSpeed
  if val.timer >= levelSpec[LEVEL].scatterTime[val.scatterIter] then
    val.scatterIter = val.scatterIter + 1
    if val.scatterIter > 4 then val.scatterIter = 4 end
    val.timer = 0
    setState(val, 'chase')
  end
  val.targetX, val.targetY = 5, 1
elseif val.state == 'fright' then
  val.speedCoef =levelSpec[LEVEL].ghostFrightSpeed
  if val.timer >= levelSpec[LEVEL].frightTime then
    pacMan.speedCoef = levelSpec[LEVEL].pacManSpeed
    val.timer = 0
    val.blink = false
    val.blinkTime = 0
    setState(val, 'chase')
  elseif val.timer >= levelSpec[LEVEL].frightTime - 2 then
    val.blink = true
    val.blinkTime = val.blinkTime + 3*dt
  end
elseif val.state == 'exitHome' then
  if round(val.x) == val.targetX and round(val.y) == val.targetY then
  val.timer = 0
  setState(val, 'scatter')
  end
  val.targetX, val.targetY = 15, 15
end
update(val, dt)
end

g_pink.init = function(val)
val.startX=12
val.startY=18
val.x=12
val.y=19
val.timer = 0
val.dirX = 0
val.dirY = 0
val.direction = "up"
val.animDir = "up"
val.curAtlas = "atlas"
val.keyframe=1
val.angle=0
val.scaleSignX= 1
val.scaleSignY= 1
val.state = "exitHome"
val.targetX = 15
val.targetY = 15
val.speedCoef = levelSpec[LEVEL].ghostSpeed
val.nextDecision = "up"
val.nextX = 12
val.nextY = 17
val.blink = false
val.blinkTime = 0
end

---------------------------------inky---------------------------------------
g_blue = {
  startX=14, startY=18,
  x=14, y=19,
  timer = 0,
  speed = 7.4,
  color = {r=0, g=0, b=1, a=0.7},
  dirX = 0,
  dirY = 0,
  direction = "up",
  animDir = "up",
  curAtlas = "atlas",
  keyframe=1,
  nbrFrame=2,
  fps=5,
  angle=0,
  scaleSignX= 1,
  scaleSignY= 1,
  state = "exitHome",
  targetX = 15,
  targetY = 14,
  speedCoef = 0.75,
  nextDecision = "up",
  nextX = 14,
  nextY = 17,
  chaseIter = 1,
  scatterIter = 1,
  blink = false,
  blinkTime = 0
}
g_blue.animTimer = 1 /g_blue.fps
g_blue.atlas= love.graphics.newImage('assets/img/fantomesPacman.png')
g_blue.frightAtlas = frightAtlas
g_blue.sprites = {}
g_blue.sprites.right = {
  love.graphics.newQuad(4*16,0,16,16,g_blue.atlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,g_blue.atlas:getDimensions()),
}
g_blue.sprites.down = {
  love.graphics.newQuad(2*16,0,16,16,g_blue.atlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,g_blue.atlas:getDimensions()),
}
g_blue.sprites.left = {
  love.graphics.newQuad(4*16,0,16,16,g_blue.atlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,g_blue.atlas:getDimensions()),
}
g_blue.sprites.up = {
  love.graphics.newQuad(6*16,0,16,16,g_blue.atlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,g_blue.atlas:getDimensions()),
}
g_blue.sprites.fright = {
  love.graphics.newQuad(0*16,0,16,16,frightAtlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,frightAtlas:getDimensions()),
}


g_blue.draw = function(val)
draw(val)
end

g_blue.update = function(val, dt)
  if 244 - DOTS < 30 and LEVEL < 3 then return end
val.timer = val.timer  + dt

if val.state == 'chase' then
  val.speedCoef = levelSpec[LEVEL].ghostSpeed


  local symX,symY = nil, nil

  if pacMan.direction == 'up' then
    symX, symY = round(pacMan.x)-2, round(pacMan.y)-2
  elseif pacMan.direction == 'right' then
    symX, symY = round(pacMan.x)+2, round(pacMan.y)   
  elseif pacMan.direction == 'down' then
    symX, symY = round(pacMan.x), round(pacMan.y)+2
  elseif pacMan.direction == 'left' then
    symX, symY = round(pacMan.x)-2, round(pacMan.y)
  end


  val.targetX = clamp(symX + symX - round(g_red.x), 1, 28)
  val.targetY = clamp(symY + symY - round(g_red.y), 1, 34)



  if val.timer >= levelSpec[LEVEL].chaseTime[val.chaseIter] then
    val.chaseIter = val.chaseIter + 1
    if val.chaseIter > 4 then val.chaseIter = 4 end
    val.timer = 0
    setState(val, 'scatter')
  end
elseif val.state == 'scatter' then
  val.speedCoef = levelSpec[LEVEL].ghostSpeed
  if val.timer >= levelSpec[LEVEL].scatterTime[val.scatterIter] then
    val.scatterIter = val.scatterIter + 1
    if val.scatterIter > 4 then val.scatterIter = 4 end
    val.timer = 0
    setState(val, 'chase')
  end
  val.targetX, val.targetY = 1, 36
elseif val.state == 'fright' then
  val.speedCoef =levelSpec[LEVEL].ghostFrightSpeed
  if val.timer >= levelSpec[LEVEL].frightTime then
    pacMan.speedCoef = levelSpec[LEVEL].pacManSpeed
    val.timer = 0
    val.blink = false
    val.blinkTime = 0
    setState(val, 'chase')
  elseif val.timer >= levelSpec[LEVEL].frightTime - 2 then
    val.blink = true
    val.blinkTime = val.blinkTime + 3*dt
  end
elseif val.state == 'exitHome' then
  if round(val.x) == val.targetX and round(val.y) == val.targetY then
  val.timer = 0
  setState(val, 'scatter')
  end
  val.targetX, val.targetY = 15, 15
end
update(val, dt)
end

g_blue.init = function(val)
val.startX=14
val.startY=18
val.x=14
val.y=19
val.timer = 0
val.dirX = 0
val.dirY = 0
val.direction = "up"
val.animDir = "up"
val.curAtlas = "atlas"
val.keyframe=1
val.angle=0
val.scaleSignX= 1
val.scaleSignY= 1
val.state = "exitHome"
val.targetX = 15
val.targetY = 15
val.speedCoef = levelSpec[LEVEL].ghostSpeed
val.nextDecision = "up"
val.nextX = 14
val.nextY = 17
val.blink = false
val.blinkTime = 0
end

--------------------------------clyde---------------------------------------
g_oran = {
  startX=16, startY=18,
  x=16, y=19,
  timer = 0,
  speed = 7.4,
  color = {r=1, g=211/255, b=32/255, a=0.7},
  dirX = 0,
  dirY = 0,
  direction = "up",
  animDir = "up",
  curAtlas = "atlas",
  keyframe=1,
  nbrFrame=2,
  fps=5,
  angle=0,
  scaleSignX= 1,
  scaleSignY= 1,
  state = "exitHome",
  targetX = 15,
  targetY = 14,
  speedCoef = 0.75,
  nextDecision = "up",
  nextX = 16,
  nextY = 17,
  chaseIter = 1,
  scatterIter = 1,
  blink = false,
  blinkTime = 0
}
g_oran.animTimer = 1 /g_oran.fps
g_oran.atlas= love.graphics.newImage('assets/img/fantomesPacman3.png')
g_oran.frightAtlas = frightAtlas
g_oran.sprites = {}
g_oran.sprites.right = {
  love.graphics.newQuad(4*16,0,16,16,g_oran.atlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,g_oran.atlas:getDimensions()),
}
g_oran.sprites.down = {
  love.graphics.newQuad(2*16,0,16,16,g_oran.atlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,g_oran.atlas:getDimensions()),
}
g_oran.sprites.left = {
  love.graphics.newQuad(4*16,0,16,16,g_oran.atlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,g_oran.atlas:getDimensions()),
}
g_oran.sprites.up = {
  love.graphics.newQuad(6*16,0,16,16,g_oran.atlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,g_oran.atlas:getDimensions()),
}
g_oran.sprites.fright = {
  love.graphics.newQuad(0*16,0,16,16,frightAtlas:getDimensions()),
  love.graphics.newQuad(1*16,0,16,16,frightAtlas:getDimensions()),
}


g_oran.draw = function(val)
draw(val)
end

g_oran.update = function(val, dt)
  if 244 - DOTS < 60 and LEVEL < 3 then return end
val.timer = val.timer  + dt

if val.state == 'chase' then
  val.speedCoef = levelSpec[LEVEL].ghostSpeed

  if math.abs(distance(val.x, val.y, pacMan.x, pacMan.y)) > 8 then
    val.targetX, val.targetY = round(pacMan.x), round(pacMan.y)
  else
    val.targetX, val.targetY = 28, 36
  end

  if val.timer >= levelSpec[LEVEL].chaseTime[val.chaseIter] then
    val.chaseIter = val.chaseIter + 1
    if val.chaseIter > 4 then val.chaseIter = 4 end
    val.timer = 0
    setState(val, 'scatter')
  end
elseif val.state == 'scatter' then
  val.speedCoef = levelSpec[LEVEL].ghostSpeed
  if val.timer >= levelSpec[LEVEL].scatterTime[val.scatterIter] then
    val.scatterIter = val.scatterIter + 1
    if val.scatterIter > 4 then val.scatterIter = 4 end
    val.timer = 0
    setState(val, 'chase')
  end
  val.targetX, val.targetY = 28, 36
elseif val.state == 'fright' then
  val.speedCoef =levelSpec[LEVEL].ghostFrightSpeed
  if val.timer >= levelSpec[LEVEL].frightTime then
    pacMan.speedCoef = levelSpec[LEVEL].pacManSpeed
    val.timer = 0
    val.blink = false
    val.blinkTime = 0
    setState(val, 'chase')
  elseif val.timer >= levelSpec[LEVEL].frightTime - 2 then
    val.blink = true
    val.blinkTime = val.blinkTime + 3*dt
  end
elseif val.state == 'exitHome' then
  if round(val.x) == val.targetX and round(val.y) == val.targetY then
  val.timer = 0
  setState(val, 'scatter')
  end
  val.targetX, val.targetY = 15, 15
end
update(val, dt)
end

g_oran.init = function(val)
val.startX=16
val.startY=18
val.x=16
val.y=19
val.timer = 0
val.dirX = 0
val.dirY = 0
val.direction = "up"
val.animDir = "up"
val.curAtlas = "atlas"
val.keyframe=1
val.angle=0
val.scaleSignX= 1
val.scaleSignY= 1
val.state = "exitHome"
val.targetX = 15
val.targetY = 15
val.speedCoef = levelSpec[LEVEL].ghostSpeed
val.nextDecision = "up"
val.nextX = 16
val.nextY = 17
val.blink = false
val.blinkTime = 0
end