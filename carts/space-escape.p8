pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--main
function _init()
 game_state = "menu"
 init_player()
 init_stars()
 init_game_progression() -- new function replacing init_levels()
 score = 0
 explosions = {}
 music(0)
end

function _update()
 update_stars()

 if game_state == "menu" then
  if btnp(❎) or btnp(🅾️) then
   game_state = "playing"
   sfx(7)
   music(1)
  end
 end
 
if game_state == "playing" then 
  if player_dying then
   death_timer -= 1
   if death_timer <= 0 then
    game_state = "game_over"
   end
  else
   update_player()
   update_missiles()
   update_particles()
  end
  update_enemy_spawning()
  update_enemies()
  update_explosions()
  update_difficulty()
 elseif game_state == "game_over" then
  if btnp(❎) then
   _init()
  end
 end
end

function _draw()
 cls(0)
 draw_stars()
 if game_state == "menu" then
  draw_menu()
 elseif game_state == "playing" then
  if not player_dying then
   draw_player()
  end
  draw_enemies()
  draw_missiles()
  draw_explosions()
  print("score:"..score,2,2,7)
  print("wave:"..flr(difficulty),2,8,7)
 elseif game_state == "game_over" then
  print("game over!",45,50,7)
  print("score:"..score,45,60,7)
  print("press ❎ to restart",30,70,7)
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
  --sfx(8)
 elseif btn(⬅️) then
  dx-=2
  current_state = "left"
  --sfx(8)
 else
 	current_state = "straight"
 	--sfx(-1,3)
 end
 if btn(⬆️) then
  dy-=2
 -- sfx(8,3)
 elseif btn(⬇️) then
  dy+=2
  --sfx(8)
 end
 
  -- create engine trails
 -- only emit particles every other frame
 if (dx != 0 or dy != 0) and t() % 0.1 < 0.05 then
  -- left engine
  add(particles, {
   x=x+2,
   y=y+7,
   dx=rnd(0.2)-0.1,
   dy=0.5+rnd(0.5),
   life=3+rnd(2),
   color=rnd({9,10}) -- orange/yellow colors
  })
  
  -- right engine
  add(particles, {
   x=x+5.5,
   y=y+7,
   dx=rnd(0.2)-0.1,
   dy=0.5+rnd(0.5),
   life=3+rnd(2),
   color=rnd({9,10}) -- orange/yellow colors
  })
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
   enemy.t += .02
   enemy.x = enemy.base_x + cos(enemy.t) * enemy.amplitude
   enemy.y += enemy.dy
   
   if enemy.y > 128 then
    del(enemies, enemy)
   end
   
   -- check if we're not already dying
   if not player_dying and check_collision(enemy, {x=x,y=y,w=8,h=8}) then
    create_explosion(x, y)
    sfx(0)
    player_dying = true
    death_timer = 15  -- give time for explosion animation
   end
  end
 end
end

-- in init_game_progression()
function init_game_progression()
 enemies = {}
 spawn_timer = 0
 difficulty = 1
 time_survived = 0
 spawn_interval = 40  -- increased from 60 to spawn less frequently
 max_enemies = 7
 player_dying = false  -- add this new state
 death_timer = 0
end

function update_enemy_spawning()
 spawn_timer += 1
 if spawn_timer >= spawn_interval then
  spawn_timer = 0
  local enemy_type = flr(rnd(3)) + 1
  local enemy_x = rnd(112) + 8  -- store x position in variable
  
  add(enemies, {
   x = enemy_x,
   y = -8,
   base_x = enemy_x,  -- use the stored x position
   t = rnd(1),
   amplitude = 5 + rnd(3),
   speed = 0.2 + difficulty * 0.1,
   sprite = 2 + enemy_type,  -- this will give us sprites 3, 4, or 5
   alive = true,
   points = 50 * enemy_type * difficulty,
   dy = 0.4 + rnd(0.3) + (difficulty * 0.15), 
   w = 8,
   h = 8
  })
 end
 
   dy = 0.2 + rnd(0.3)  -- reduced from 0.5 + rnd(0.5)

end

function update_difficulty()
 time_survived += 1
 if time_survived % 300 == 0 then
  difficulty += 0.5
  max_enemies = min(7 + flr(difficulty * 1.5), 15) 
  spawn_interval = max(40 - flr(difficulty * 3), 12)
 end
end

function draw_enemies()
 for enemy in all(enemies) do
  if enemy.alive then
   spr(enemy.sprite, enemy.x, enemy.y)
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
  active = true,
  particles = {}
 })
    
 for i=1,12 do
  local angle = rnd()
  local speed = 1 + rnd(2)
  add(explosions[#explosions].particles, {
   x = x + 4,  -- center of sprite
   y = y + 4,
   dx = cos(angle) * speed,
   dy = sin(angle) * speed,
   life = 10 + rnd(10),
   color = rnd({8,9,10})
  })
 end
end

function update_explosions()
 for e in all(explosions) do
  e.timer += 1
  
  if e.timer == 4 then
   e.frame = 19
  elseif e.timer == 8 then
   e.frame = 20
  elseif e.timer == 12 then
   del(explosions, e)
  end
  
  for p in all(e.particles) do
   p.x += p.dx
   p.y += p.dy
   p.dx *= 0.9
   p.dy *= 0.9
   p.life -= 1
   if p.life <= 0 then
    del(e.particles, p)
   end
  end
 end
end

function draw_explosions()
 for e in all(explosions) do
  spr(e.frame, e.x, e.y)
  for p in all(e.particles) do
   pset(p.x, p.y, p.color)
  end
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
 local title = "space escape"
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
000000000007700000888800b000000b8000000800000000000000000000cccccccc000000000000000000000000000000000000000000000000000000000000
00000000007cc700008aa800b0bbbb0b0cccccc00b0880b0000000000cccccccccccccc000000000000000000000000000000000000000000000000000000000
00700700007cc700008aa800bbaaaabb0caaaac0088888800000000cccccccccccccccccc0000000000000000000000000000000000000000000000000000000
00077000007cc700008aa8000baaaab00caaaac088cccc88000000cccccccccccccccccccc000000000000000000000000000000000000000000000000000000
00077000077cc770008aa8000baaaab00c0000c0888cc88800000cccccccccccccccccccccc00000000000000000000000000000000000000000000000000000
007007000777777000000000bbbaabbb5c0000c5088cc8800000cccccccccccccccccccccccc0000000000000000000000000000000000000000000000000000
00000000009779000000000000bbbb005000000500888800000cccccccccccccccccccccccccc000000000000000000000000000000000000000000000000000
00000000000000000000000000900900000000000008800000cccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000
00077000000770000000000000000000000000000000000000cccccccccccccccccccccc4444cc00000000000000000000000000000000000000000000000000
00cc70000007cc00009009900000090000000000000000000ccccccccccccccccccccc44444444c0000000000000000000000000000000000000000000000000
00cc70000007cc00099099000000000000000000000000000ccccccccccccccccccccc44444444c0000000000000000000000000000000000000000000000000
00cc70000007cc00009aa0009009900000090000000000000ccccccccccccccccccccc44444444c0000000000000000000000000000000000000000000000000
00cc67000076cc00099a09000099a9000000900000000000cccccccccccccccccccccc44444444cc000000000000000000000000000000000000000000000000
00776700007677000090a900009000000000000000000000cccbbbcccccccccccccccccc4444cccc000000000000000000000000000000000000000000000000
000790000009700000009000000000000000000000000000ccbbbbbccccccccccccccccccccccccc000000000000000000000000000000000000000000000000
000000000000000000900000000000000000000000000000cbbbbbbbccccccccccc44444cccccccc000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000bbbbbbbbbcccccccc444444444cccccc000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000bbbbbbbbbccccccc44444444444ccccc000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000bbbbbbbbbccccccc44444444444ccccc000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000004444b4bbbccccccc44444444444cccc0000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000444b4b4bbcccccc44444444444ccccc0000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000004444b44bbcccccc444444444ccccccc0000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000444444bccccccc444444444cccccc00000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000bbbbbccccccccc4444444ccccccc00000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000bbbcccccccccc4444444cccccc000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000cccccccccccccc444ccccccc0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000cccccccccccccccccccccc00000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000cccccccccccccc77cccc000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000ccccc7777777777ccc0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000cc7777777777cc000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000077777777000000000000000000000000000000000000000000000000000000000000
__sfx__
84010000190011c0511e05122051260512b051310513505138051380511b0013e0013c0013900137001340012500120001260012a001330010500104001030010200102001010010100100001000010e0010f001
00010000000000375003750047500575006750087500a7500c7500e7501175015750177501b7502075024750277502a7500000000000000000000000000000000000000000000000000000000000000000000000
0028000a01950069500a9500895003950019500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
84010000326502e650296502665022650206501d6501b6501a650176501565013650116500f6500e6500c6500b650096500865007650066500565004650036500265002650016500165000650006500e6000f600
0028000a0c0500e050110501005011050130500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0028000a0190000050000500000000050000500001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002800000c1500e150111501015011150131500010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
0006000013050160501b05034000380001d0001d0001d0001d000300002f0002d0002c0002a000280002800000000000000000000000000000000000000000000000000000000000000000000000000000000000
900900000c5230c5230c5231950319503195031950319503195031950319503195031950319503195031b50319503175031650314503135031250312503145031950300503005030050300503005030050300503
001000120015003150021500715000100001000015003150021500715000100001000015000100001000010003100021000710000100001000010000100001000010000100001000010000100001000010000100
781000100017000150001300015000170001500013000150001700015000130001500017000150001500015001100005000050000500005000050000500005000050000500005000050000500005000050000500
781000100017000500002300050000170005000033000500001700050000330005000017000500003500050000500005000050000500005000050000500005000050000500005000050000500005000050000500
__music__
00 05044344
03 490a0b44

