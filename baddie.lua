baddie_bits = {
  tree = {64,80,96,112,113},
  wisp = {101, 102, 103},
  flower = {117, 118, 119},
  apple = {114,115,116},
  boss = {79,79,95,111,127,104}
}

boss_healths = {2,3,5}
boss_state_ttl = {1, 0.5, 0.3}
boss_throw_thresh = {0.95, 0.5, 0.3}
baddie_speed = {1.4, 1.4, 2}
bmgr = {
  baddies = {},
  bits = {},
  projectiles = {},
  boss = nil,

  reset = function(bm)
    bm.baddies = {}
    bm.boss = nil
  end,

  add_bits = function(bm, typ, x, y, direction)
    foreach(baddie_bits[typ], function(bit)
      add(bm.bits, new_bit(bit,
      x,
      y,
      (direction == 0 and 8 or -8) + (rnd(2) - 1),
      -3 + (rnd(2) - 1),
      direction,
      typ)
      )
    end)
  end,
  kill_huggers = function(bm)
    foreach(bm.baddies, function(b)
      if b.state == "hug" then
        local bb = b:getBB()
        bm:add_bits(b.type, bb[1], bb[2], b.direction)
        del(bm.baddies, b)
        sfx(4)
      end
    end)
  end,
  update = function(bm,dt,vx,x_offset)
    foreach(bm.baddies, function(b) b:update(dt,vx) end)
    if bm.boss != nil then
      bm.boss:update(dt,x_offset)
    end
    foreach(bm.projectiles, function(p)
      p:update(dt,vx)
      if p.x > 140 or p.x < -12 then
        del(bm.projectiles, p)
      end
    end)
    foreach(bm.bits, function(b)
      b:update(dt)
      if b.ttl <= 0 then
        del(bm.bits, b)
      end
    end)


  end,

  draw = function(bm, x_offset, dt)
    foreach(bm.baddies, function(b) b:draw() end)
    if bm.boss != nil then
      bm.boss:draw(x_offset)
    end
    foreach(bm.projectiles, function(p) p:draw() end)
    foreach(bm.bits, function(b) b:draw(dt) end)
  end,

  -- return number of colliding baddies
  player_collision = function(bm,playerbb)
    local count = 0
    foreach(bm.baddies, function(b) 
      b.state = "walk"
      -- local bx0,by0,bx1,by1 = b:getFrontBB()
      foreach(bm.baddies, function(inner_b)
        -- make sure this isn't the exact same baddie
        if inner_b.x != b.x 
          and inner_b.state == "hug"
          and collides_new(inner_b:getBB(),b:getFrontBB()) then
          b.state = "hug"
          count += 1
        end
      end)
      if collides_new(playerbb,b:getBB()) then
        count += 1
        b.state = "hug"
      end
    end)
    return count
  end,

  player_boss_collision = function(bm,playerbb,x_offset)
    if bm.boss:can_collide() != true then
      return false
    end

    if collides_new(playerbb,bm.boss:getBB(x_offset)) then
      return true
    end

    return false
  end,
  player_boss_buffer_collision = function(bm,playerbb,x_offset)
    if bm.boss:can_collide() != true then
      return false
    end
    
    if collides_new(playerbb, bm.boss:getBB(x_offset)) then
      -- change boss state, that should trigger the boss to walk backwards
      local should_back_up = rnd()
      local dist_to_edge = abs(bm.boss:getDrawX(x_offset) - (bm.boss.direction == 0 and 120 or 0))
      if should_back_up > 0.92 and dist_to_edge >= 16 then
        bm.boss:change_state("walk")
      end
    end
  end,
  player_projectile_collision = function(bm,playerbb)
    local count = 0
    foreach(bm.projectiles, function(p) 
      if collides_new(playerbb,p:getBB()) then
        del(bm.projectiles,p)
        count += 1
      end
    end)
    return count
  end,
  new_combat_collision = function(bm, tbl, atkbb)
    for i=1,#bm[tbl] do
      local tgt = bm[tbl][i]
      local bb = tgt:getBB() 
      if collides_new(atkbb, bb) then
        sfx(4)
        -- del(bm.projectiles, p)
        -- add impact sprite
        add(fx.impacts, {x=bb[1] + flr(rnd(2)) - 1, y= bb[2] + flr(rnd(2)) - 1, spr=impact_sprites[flr(rnd(2)) + 1], ttl=0.1})
        -- add some bits
        bm:add_bits(tgt.type, bb[1], bb[2], tgt.direction)
        return tgt
      end
    end
    return nil
  end,

  boss_combat_collision = function(bm,atkbb,x_offset)
    if bm.boss:can_collide() != true then
      return false
    end

    local bossbb = bm.boss:getBB(x_offset)
    if collides_new(atkbb,bossbb) then
      -- knock boss backwards / deduct health
      sfx(4)
      bm.boss.health -= 1
      bm.boss.invincible = 1
      if bm.boss.direction == 1 and bm.boss.x > 24 then
        bm.boss.x -= 5
        -- local dist_to_edge = abs(bm.boss.x - (bm.boss.direction == 0 and 112 or 0))
      elseif bm.boss.direction == 0 and bm.boss.x < 104 then
        bm.boss.x += 5
      end
      if bm.boss.health <= 0 then
        bm.boss.state = "dead"
        sfx(3)
        bm:add_bits(
            "boss",
            bossbb[1],
            bossbb[2],
            bm.boss.direction
        )
        return true
      end
    end
    return false
  end,

  spawn = function(bm,btypes,direction)
    local start_x = direction == 0 and 132 or -4
    foreach(btypes, function(btype)
      local baddie = nil
      if btype == "t" then
        baddie = new_tree(direction, start_x)
      elseif btype == "f" then
        baddie = new_flower(direction, start_x)
      elseif btype == "w" then
        baddie = new_wisp(direction, start_x)
      else
        printh("unkown baddie type: "..btype)
      end
      add(bm.baddies, baddie)
      start_x = start_x + (direction == 0 and 16 or -16)
    end
    )
  end,
}

function new_basic_baddie(direction, height, width, x, y, frames, frame_wait)
  local baddie = {
    direction = direction,
    x = x,
    y = y,
    vx = direction == 0 and -(baddie_speed[level_index]) or baddie_speed[level_index],
    height = height,
    width = width,
    frames_walk = frames,
    frame_index = 1,
    frame_wait = frame_wait,
    since_last_frame = 0,
    frames_current = nil,
    update = basic_baddie_update,
    draw = basic_baddie_draw,
  }
  baddie.frames_current = baddie.frames_walk
  return baddie
end
-- pass in: direction, h/w, y, frames, frame_wait
function new_tree(direction, start_x)
  local baddie = new_basic_baddie(direction, 2, 1, start_x, 81, {65,66},0.2)
  baddie.type="tree"
  baddie.getBB = function(b)
    if b.direction == 0 then
      return {b.x-1,80,b.x+5,96} -- face left
    else
      return {b.x+2,80,b.x+8,96} -- face right
    end
  end
  baddie.getFrontBB = function(b)
    if b.direction == 0 then
      return { b.x - 1,80,b.x+3,96 } -- face left
    else
      return  { b.x + 4,80,b.x+8,96 } -- face right
    end
  end
  return baddie
end

function small_bb(b)
  local offset = 0
  if b.direction == 0 then
    offset = -1 -- facing left
  end
  return {b.x - offset,b.y,b.x+8 - offset,b.y+8}
end

function small_front_bb(b)
  local offset = 0
  if b.direction == 1 then
    offset = 5 -- facing right
  end
  return { b.x + offset,b.y+5,b.x+3 + offset,b.y+8 }
end

function new_flower(direction, start_x)
  local baddie = new_basic_baddie(direction, 1, 1, start_x, 89, {85,86,87,88,86},0.0666)
  baddie.type = "flower"
  baddie.getBB = small_bb
  baddie.getFrontBB = small_front_bb
  return baddie
end

function new_projectile(direction, start_x, start_y)
  local proj = new_basic_baddie(direction, 1, 1, start_x, start_y, {97,98,99,100},0.05)
  proj.type = "apple"
  proj.vx = direction == 0 and -baddie_speed[level_index] or baddie_speed[level_index]
  proj.update = basic_baddie_update
  proj.draw = basic_baddie_draw
  proj.getBB = function(p)
    return { p.x+2,p.y+2,p.x+6,p.y+6 }
  end
  return proj
end

function new_boss(direction, start_x)
  local boss = {
    direction = direction,
    x = start_x,
    vx = direction == 0 and -1.4 or 1.4,
    y = 81,
    max_health = boss_healths[level_index],
    health = boss_healths[level_index],
    throw_threshold = boss_throw_thresh[level_index],
    state_t = boss_state_ttl[level_index],
    state = "wait",
    since_last_state = 0,
    invincible = 0,
    frames = {
      wait = {73},
      walk = {73,75},
      upantic = {77},
      downantic = {107},
      upthrow = {105},
      downthrow = {109},
    },
    frame_index = 1,
    frame_wait = 0.1,
    since_last_frame = 0,
    frames_current = nil,
    can_collide = function(b)
      if b.state == "dead" 
        or b.invincible > 0 then
        return false
      end
      return true
    end,
    update = function(b,dt,x_offset)

      if b.invincible > 0 then
        b.invincible = max(0, b.invincible - dt)
      else
        b.invincible = 0
      end

      b.since_last_state += dt
      boss_state_funcs[b.state](b, dt, x_offset)

      -- do frame updates
      b.since_last_frame += dt
      if b.since_last_frame > b.frame_wait then
        b.frame_index += 1
        b.since_last_frame = 0
        if b.frame_index > #b.frames_current then
          b.frame_index = 1
        end
      end
    end,
    draw = function(b, x_offset)
      palt(0, false)
      palt(15, true)
      if b.state == "dead" then
        return
      end

      if b.invincible > 0 and flr(b.invincible * 100) % 2 > 0 then
        return
      end
      if is_last_level() then
        tree_pal_swap()
        apple_pal_swap()
      end
      local face_left = b.direction == 0
      spr(b.frames_current[b.frame_index],b:getDrawX(x_offset),b.y,2,2,(face_left and true or false),false)
      -- draw bounding box
      -- local x0, y0, x1, y1 = b:getBB(x_offset)
      -- rect(x0, y0, x1, y1,13)
      pal()
    end,
    getDrawX = function(b, x_offset)
      if b.direction == 1 then
        return b.x - max(0, x_offset - 64)
      else
        return b.x - x_offset + 64 + max(0, x_offset - (map_extent - 64))
      end
    end,
    getBB = function(b, x_offset)
        return { b:getDrawX(x_offset),b.y,b:getDrawX(x_offset)+16,b.y+16 }
    end,
    change_state = function(b, s, st)
      b.state = s
      b.since_last_state = 0
      state_t = boss_state_ttl[level_index]
      b.frames_current = b.frames[s]
      b.frame_index = 1
    end,
  }
  boss.frames_current = boss.frames["wait"]
  return boss
end

function new_wisp(direction, start_x)
  local baddie = new_basic_baddie(direction, 1, 1, start_x, 82, {69,70,71},0.1)
  baddie.type = "wisp"
  baddie.getBB = small_bb
  baddie.getFrontBB = small_front_bb
  return baddie
end

function new_bit(sprnum, x, y, vx, vy, direction, typ)
  local bit = {
    x = x,
    y = y,
    vx = vx,
    vy = vy,
    sprnum = sprnum,
    typ = typ,
    ttl = 1,
    direction = direction,
    update = function(b,dt)
      b.x += b.vx
      b.y += b.vy
      b.vx *= 0.90
      b.vy = min(b.vy + 0.5, 10)
      b.ttl -= dt
    end,
    draw = function(b, dt)
      palt(0, false)
      palt(15, true)
      if is_last_level() then
        if b.typ == "tree" then
          tree_pal_swap()
        elseif b.typ == "flower" then
          flower_pal_swap()
        elseif b.typ == "wisp" then
          wisp_pal_swap()
        elseif b.typ == "apple" then
          apple_pal_swap()
        end
      end
      if flr(dt * 100) % 2 > 0 then
        spr(b.sprnum,b.x,b.y,1,1,(b.direction == 1 and true or false),false)
      end
      pal()
    end
  }
  return bit
end

function basic_baddie_update(b, dt, vx)
    -- update = function(b,dt,vx)
    if b.state == "hug" then
      return
    end

    b.x += b.vx - vx
    b.since_last_frame += dt

    if b.type != "apple" and rnd() > 0.7 then
      local px = b.direction == 0 and b.x + 8 or b.x
      local py = b.y + 14
      local pc = {15,4,9}
      if b.type == "flower" or b.type == "wisp" then
        py = b.y + 6
        if b.type == "wisp" then
          pc = {7,6,5}
        end
      end

      add(fx.parts, new_part(px, py, 1, 0.2, pc, 2, 0.8))
    end

    if b.since_last_frame > b.frame_wait then
      b.frame_index += 1
      b.since_last_frame = 0
      if b.frame_index > #b.frames_current then
        b.frame_index = 1
      end
    end
end

function tree_pal_swap()
  pal(3,8)
  pal(11,2)
  pal(4, 13)
end

function wisp_pal_swap()
  pal(7,11)
  pal(6,3)
end

function apple_pal_swap()
  pal(8,11)
end

function flower_pal_swap()
  pal(10,12)
  pal(3,8)
end

function basic_baddie_draw(b)
      -- draw bounding box
      local bb = b:getBB()
      -- rect(bb[1], bb[2], bb[3], bb[4],13)
      if b.getFrontBB != nil then
        -- bb = b:getFrontBB()
        -- rect(bb[1], bb[2], bb[3], bb[4],8)
      end
      palt(0, false)
      palt(15, true)
  local face_left = b.direction == 0
  if is_last_level() then
    if b.type == "tree" then
      tree_pal_swap()
    elseif b.type == "flower" then
      flower_pal_swap()
    elseif b.type == "wisp" then
      wisp_pal_swap()
    elseif b.type == "apple" then
      apple_pal_swap()
    end
  end

  spr(b.frames_current[b.frame_index],face_left and b.x or b.x,b.y,b.width,b.height,(face_left and true or false),false)
  pal()
end

boss_state_funcs = {
  wait = function(b, dt)
    if b.since_last_state > b.state_t then
      -- chance to throw
      if rnd() > b.throw_threshold then
        -- up_or_down
        if rnd() > 0.5 then
          b:change_state("upantic")
        else
          b:change_state("downantic")
        end
      end
    end
  end,
  walk = function(b, dt, x_offset)
    b.vx = (b.direction == 0) and 1 or -1
    b.x += b.vx 

    -- make dust
    if rnd() > 0.4 then
      local px = b.direction == 0 and b:getDrawX(x_offset) + 16 or b:getDrawX(x_offset)
      add(fx.parts, new_part(px, b.y + 14, 1, 0.2, {15,4,9}, 3, 0.8))
    end
    if b:getDrawX(x_offset) < 1 or b:getDrawX(x_offset) > 120 or b.since_last_state > b.state_t then
      b:change_state("wait")
    end
  end,
  upantic = function(b, dt, x_antic)
    if b.since_last_state > b.state_t then
      add(bmgr.projectiles, new_projectile(b.direction, b:getDrawX(x_antic), 82))
      b:change_state("upthrow")
    end
  end,
  upthrow = function(b, dt)
    if b.since_last_state > 1 then
      b:change_state("wait")
    end
  end,
  downantic = function(b, dt, x_offset)
    if b.since_last_state > b.state_t then
      add(bmgr.projectiles, new_projectile(b.direction, b:getDrawX(x_offset), 88))
      b:change_state("downthrow")
    end
  end,
  downthrow = function(b, dt)
    if b.since_last_state > 1 then
      b:change_state("wait")
    end
  end,
  dead = function(b, dt)
    return
  end,
}
