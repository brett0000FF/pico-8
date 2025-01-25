pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--main
function _init()
 game_state = "menu"
 
 init_player()
 init_stars()
 init_enemies()
 init_levels()  -- initialize level system
 load_level(1)  -- load first level
 score = 0
 explosions = {}
 music(0)
end

function _update()
 update_stars()

 if game_state == "menu" then
  if btnp(❎) or btnp(🅾️) then
   game_state = "playing"
   sfx(6)
   music(-1)
  end
 end
 
 if game_state == "playing" then
  update_player()
  update_missiles()
  update_particles()
  update_enemies()
  update_explosions()
  check_level_complete()
 elseif game_state == "won" then
  -- handle game complete state
  if btnp(5) then
   _init() -- restart game
  end
 end
end

function _draw()
 cls(0)
 draw_stars()
 if game_state == "menu" then
 	draw_menu()
 elseif game_state == "playing" then
  draw_enemies()
  draw_player()
  draw_missiles()
  draw_explosions()
  print("score:"..score,2,2,7)
 elseif game_state == "won" then
  print("game complete!",35,60,7)
  print("score:"..score,40,70,7)
  print("press ❎ to restart",25,80,7)
 end
end
-->8
--player
ship_states = {
    left = 16,    -- sprite number for left movement
    right = 17,   -- sprite number for right movement
    straight = 1     -- sprite number for stationary
}

current_state = "straight"

function init_player()
 x=63
 y=110
 missiles = {}
 particles = {}
 current_state = "straight"
end

function update_player()
 local dx = 0
 local dy = 0

 if btn(➡️) then
  dx+=2
  current_state = "right"
 elseif btn(⬅️) then
  dx-=2
  current_state = "left"
 else
 	current_state = "straight"
 end
 if btn(⬆️) then
  dy-=2
 elseif btn(⬇️) then
  dy+=2
 end
 
 if dx != 0 and dy != 0 then
  dx *= 0.7071 -- approximation of 1/ヌ☉あ2
  dy *= 0.7071
 end
 
 x += dx
 x = mid(0, x, 120)
 y += dy
 y = mid(0, y, 120)
 
 if btnp(4) then
  sfx(1)
  add(missiles, {
   x=x,
   y=y,
   w=2,
   h=4
  })
 end
end

function update_missiles()
 for missile in all(missiles) do
  missile.y -= 3
  
  -- add particle trail
  add(particles, {
   x=missile.x+rnd(4),
   y=missile.y+8,
   dx=rnd(0.4)-0.2,
   dy=1+rnd(0.5),
   life=10+rnd(5),
   color=7
  })
  
  if missile.y <= 0 then
   del(missiles, missile)
  end
  
  for enemy in all(enemies) do
   if enemy.alive and
      check_collision(missile, enemy) then
    enemy.alive = false
    del(missiles, missile)
    create_explosion(enemy.x, enemy.y)
    score += enemy.points
    sfx(0)
   end
  end
 end
end

function update_particles()
 for p in all(particles) do
  p.x += p.dx
  p.y += p.dy
  p.life -= 1
  if p.life <= 0 then
   del(particles, p)
  end
 end
end

function draw_player(dir)
 spr(ship_states[current_state],x,y)
end

function draw_missiles()
 -- draw particles first (behind missiles)
 for p in all(particles) do
  pset(p.x, p.y, p.color)
 end
 
 -- then draw missiles
 for missile in all(missiles) do
  spr(2,missile.x,missile.y)
 end
end
-->8
--enemies
function init_enemies()
 enemies = {}
 for i=0,4 do
  add(enemies, {
   x=20+i*20,
   y=20,
   base_x=20+i*20,
   t=i*0.3,
   amplitude=10,
   speed=0.05,
   alive=true
  })
 end
end

function update_enemies()
 for enemy in all(enemies) do
  if enemy.alive then
   enemy.t += enemy.speed
   enemy.x = enemy.base_x + cos(enemy.t) * enemy.amplitude
  end
 end
end

function draw_enemies()
 for enemy in all(enemies) do
  if enemy.alive then
   if current_level == 1 then
   spr(3,enemy.x,enemy.y)
   end
   if current_level == 2 then
   spr(4,enemy.x,enemy.y)
   end
   if current_level == 3 then
   spr(5,enemy.x,enemy.y)
   end
  end
 end
end

function check_collision(a, b)
 return not (
  a.x > b.x+8 or
  a.y > b.y+8 or
  a.x+a.w < b.x or
  a.y+a.h < b.y
 )
end

function create_explosion(x, y)
    add(explosions, {
        x = x,
        y = y,
        frame = 18,  -- starting frame
        timer = 0,
        active = true
    })
end

function update_explosions()
    for e in all(explosions) do
        e.timer += 1
        -- change frame every 4 frames
        if e.timer == 4 then
            e.frame = 19
        elseif e.timer == 8 then
            e.frame = 20
        elseif e.timer == 12 then
            del(explosions, e)
        end
    end
end

function draw_explosions()
    for e in all(explosions) do
        spr(e.frame, e.x, e.y)
    end
end
-->8
--stars
function init_stars()
 stars = {}
 -- distant stars
 for i=1,60 do
  add(stars, {
   x=rnd(128),
   y=rnd(128),
   speed=0.25+rnd(0.5),
   size=1,
   col=1
  })
 end
 -- medium stars
 for i=1,30 do
  add(stars, {
   x=rnd(128),
   y=rnd(128),
   speed=0.75+rnd(0.5),
   size=1,
   col=7
  })
 end
 -- close stars
 for i=1,10 do
  add(stars, {
   x=rnd(128),
   y=rnd(128),
   speed=1.5+rnd(1),
   size=2,
   col=7
  })
 end
end

function update_stars()
 for star in all(stars) do
  star.y += star.speed
  if star.y > 128 then
   star.y = 0
   star.x = rnd(128)
  end
 end
end

function draw_stars()
 for star in all(stars) do
  if star.size == 1 then
   pset(star.x,star.y,star.col)
  else
   circfill(star.x,star.y,0,star.col)
  end
 end
end
-->8
--levels
function init_levels()
 current_level = 1
 level_complete = false
 
 -- store all level configurations
 levels = {
  -- level 1: basic side-to-side movement
  {
   enemy_count = 5,
   formation = "line",
   speed = 0.02,
   amplitude = 10,
   points = 100,
   sprite = 3
  },
  -- level 2: faster zigzag pattern
  {
   enemy_count = 7,
   formation = "v",
   speed = 0.03,
   amplitude = 15,
   points = 150,
   sprite = 4
  },
  -- level 3: two rows, complex movement
  {
   enemy_count = 10,
   formation = "double",
   speed = 0.04,
   amplitude = 20,
   points = 200,
   sprite = 5
  }
 }
end

function load_level(level_num)
 enemies = {}
 local level = levels[level_num]
 
 -- different enemy formations
 if level.formation == "line" then
  for i=0,level.enemy_count-1 do
   add(enemies, {
    x=20+i*20,
    y=20,
    base_x=20+i*20,
    t=i*0.3,
    amplitude=level.amplitude,
    speed=level.speed,
    sprite=level.sprite,
    alive=true,
    points=level.points
   })
  end
 elseif level.formation == "v" then
  for i=0,level.enemy_count-1 do
   add(enemies, {
    x=20+i*15,
    y=20+abs(i-level.enemy_count/2)*8,
    base_x=20+i*15,
    t=i*0.3,
    amplitude=level.amplitude,
    speed=level.speed,
    sprite=level.sprite,
    alive=true,
    points=level.points
   })
  end
 elseif level.formation == "double" then
  -- create two rows of enemies
  for row=0,1 do
   for i=0,4 do
    add(enemies, {
     x=20+i*20,
     y=20+row*20,
     base_x=20+i*20,
     t=i*0.3+row&.05,
     amplitude=level.amplitude,
     speed=level.speed,
     sprite=level.sprite,
     alive=true,
     points=level.points
    })
   end
  end
 end
end

function check_level_complete()
 local all_defeated = true
 -- check if all enemies are defeated
 for enemy in all(enemies) do
  if enemy.alive then
   all_defeated = false
   break
  end
 end
 
 if all_defeated then
  -- if we get here, no enemies are alive
  current_level += 1
  if current_level <= #levels then
   load_level(current_level)
   -- optional: show "level complete" message
   -- optional: add delay between levels
  else
   -- game complete!
   game_state = "won"
  end
 end
end
-->8
--menus
function draw_menu()
 local title = "space taste"
 local instruct = "press ❎ to start" 
 print(title, center(title), 48, 7)

 if t() % 1 < 0.7 then
  print(instruct, center(instruct), 90, 12)
 end
end
-->8
-- extras
function center(len)
 return (128 - #len *4) / 2
end
__gfx__
000000000007700000888800b000000b800000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007cc700008aa800b0bbbb0b0cccccc00b0880b000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007cc700008aa800bbaaaabb0caaaac00888888000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007cc700008aa8000baaaab00caaaac088cccc8800000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000077cc770008aa8000baaaab00c0000c0888cc88800000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000777777000000000bbbaabbb5c0000c5088cc88000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009779000000000000bbbb00500000050088880000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000900900000000000008800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cc70000007cc000090099000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cc70000007cc000990990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cc70000007cc00009aa00090099000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cc67000076cc00099a09000099a900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00776700007677000090a90000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00079000000970000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
84010000326502e650296502665022650206501d6501b6501a650176501565013650116500f6500e6500c6500b650096500865007650066500565004650036500265002650016500165000650006500e6000f600
00010000000000375003750047500575006750087500a7500c7500e7501175015750177501b7502075024750277502a7500000000000000000000000000000000000000000000000000000000000000000000000
0028000a01950069500a9500895003950019500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
84010000326502e650296502665022650206501d6501b6501a650176501565013650116500f6500e6500c6500b650096500865007650066500565004650036500265002650016500165000650006500e6000f600
0028000a0c0500e050110501005011050130500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0028000a0190000050000500000000050000500001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d0d00002f7532f7532f7531d7031a7031970319703197031a7031d7032070326703297032a7032a7032c7032970325703217031f7031d7031c7031b7031d7032170326703277030070300703007030070300703
__music__
00 05044344

