pico-8 cartridge // http://www.pico-8.com
version 37
__lua__

#include player.lua
#include baddie.lua

function _init()
  last_ts = 0
  player:reset()
  -- spawn :: Num -> Direction -> Void
  -- bmgr:spawn(3, 1)
  -- bmgr:spawn(3, 0)
end

function _update()
  local now = time()
  local dt = now - last_ts
  player:update(dt)
  bmgr:update(dt)

  local px0, py0, px1, py1 = player:getBB()
  local current_huggers = bmgr:player_collision(px0,py0,px1,py1)

  local checkme,px0,py0,px1,py1 = player:getAtkBB()
  if checkme then
    bmgr:combat_collision(px0,py0,px1,py1)
  end

  last_ts = now
end

function _draw()
  cls()
  palt(0, false)
  rectfill(0,0,128,128,12)
  rectfill(0,0,128,32,6)
  --rectfill(0,94,128,108,3)
  -- map(0,14,0,96)
  if player.map_x > 64 and player.map_x < map_extent - 64 then
    for i=0,1 do
      map(0,14,i*128-player.map_x%128,96,16,16)
      -- map(0,14,128 - (player.map_x % 128),96)
      -- map(0,14,player.map_x % 128,96)
    end
  else
    map(0,14,0,96,16,16)
  end
  -- map(0,14,0,96)
  bmgr:draw()
  player:draw()
  print("map_x: ".. player.map_x, 4,4,0)
  print("draw_x: ".. player.draw_x, 4,10,0)
end

function collides(x0, y0, x1, y1, x2, y2, x3, y3)
  if (
    x0 < x3
    and x1 > x2
    and y1 > y2
    and y0 < y3
    ) then
    return true
  end

  return false
end





























__gfx__
00000000f444444ffffffffffffffffff444444fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ff994444f444444ff444444fff994444fffffffffffffffffffffffff444444ff444444ff444444ff444444fffffffffffffffffffffffffffffffff
00000000f9c94444ff994444ff994444f9c94444ffffffffffffffffffffffffff994444ff994444ff994444ff994444ffffffffffffffffffffffffffffffff
0000000099994944f9c94444f9c9444499994944fffffffffffffffffffffffff9c94444f9c94444f9c94444f9c94444ffffffffffffffffffffffffffffffff
00000000f44449449999494499994944f4444944ffffffffffffffffffffffff99994944999949449999494499994944ffffffffffffffffffffffffffffffff
00000000ff44444ff4444944f4444944ff44444fffffffff00fffffffff00ffff4444944f4444944f4444944f4444944ffffffffffffffffffffffffffffffff
00000000ff4498ffff44444fff44444fff4498ffffffffff088ffffffff00222ff84444fff44444fff84444fff44444fffffffffffffffffffffffffffffffff
00000000f0899809ff4498ffff4498ffff89808fffffffff0888fffffff00222ff4498ffff4498ffff4498ffff4498ffffffffffffffffffffffffffffffffff
00000000f0888099ff808889ff88880fff88098f99ffffffff888ffff8ffffff808888fff99088ffff8998098f8998094444444f4444444f4444444fffffffff
00000000f9888899f9990889f9888999ff88998f99fffffffff888fff8ffffff8088888ff990888f8088809980888099f9c94444f9c94444f9c94444ffffffff
00000000ff00000ff990000ff9000009ff00990fffffffffffff88ff00ffffffff00000fff00000f8808889988088899994449449944494499444944ffffffff
00000000ff88888fff88882fff88888fff88888fffffffffffffffff00ffffffff28888fff88888ff88008ff888008fff444444ff444444ff484444fffffffff
00000000ff88888ff8888822f2888888ff88888fffffffffffffffff00fffffff2288888ff88888fff888fffff888fffff44998f9880488fff44488fffffffff
00000000ff88f88f888fff22222fff88fff8022fffffffffffffffffffffffff222fff00ff22f88ffff88ffffff88ffff980999f9880888fff000099ffffffff
00000000ff00f00f088fff00022fff00fff0000fffffffffffffffffffffffff200fff00ff00f80ffff00ffffff00fffff02880fff02880f28888899ffffffff
00000000f000f00f000fff00000fff00fff00f0fffffffffffffffffffffffff000ffff0f000f00ffff000fffff000fff0028800f002880022888800ffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000333ff333333ff333333ff333333ff333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000333b33b3333b33b3333b33b3333b33b3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
000000003f3333333f3333333f3333333f333333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000f3b3b343f3b3b343f3b3b343f3b3b343ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000f3b43333f3b43333f3b43333f3b43333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000334333f3334333f33043330333033303ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000b3b443f3b3b443f3b30440f3b3b040f3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000f377773ff377773ff377773ff377773fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000ff7070ffff7070ffff7070ffff7070ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000ff7040ffff7040ff9f7040f9ff7040ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000ff4444ffff4444ff9944449999444499ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000ff4400ffff4400fff944009f9f4400f9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000ff4044ffff4044ffff4400ffff4400ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000ff4444ffff4444ffff4444ffff4444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000ff4f444fff44f44fff4f444fff44f44fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000f4ff4f44ff4f4f4ff4ff4f44ff4f4f4fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99fff9fffff9ff9ff99ff99ff9ff9f9f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff99ff99fffffff9ffff99fff9f9ff9f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999f99f999f999999f9ff99999f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f9999999999999999099f99999999f99000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9999099999f99f999999f9999f999909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999f99f999ff99999999999f999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99ff99999999999999999ff999999f99000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999990999f9999999f999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99099999999999999f99999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9999909f9999f9999999999999099999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9999999999f999999999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9999999999f99999999f999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9f9999999999990999990999999ff999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999ff99999f99999999999f9999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
999999999999999999999999f9999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
999999999999999f9999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999990999999999999990999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9990999f999999999909999999990999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
999999999999999999999f9999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9999999999999999999999999999999f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999f909999999999999f9999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
999f9999999999999f999999999f9999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99ff999f9999999999990999999f9999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
999999999999999999999999f9999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999909999999f999909999999999f9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9f99999999999999999909f999909999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
999999999f9999999999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081828380818283808182838081828380818283000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9091929390919293909192939091929390919293000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a0a1a2a3a0a1a2a3a0a1a2a3a0a1a2a3a0a1a2a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b0b1b2b3b0b1b2b3b0b1b2b3b0b1b2b3b0b1b2b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
