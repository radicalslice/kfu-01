baddie_bits = {
  tree = {64,80,96,112,113},
  wisp = {101, 102, 103},
  flower = {117, 118, 119},
  apple = {114,115,116},
  boss = {79,79,95,111,127,104}
}
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
      (direction == 0 and 3 or -3) + (rnd(2) - 1),
      -3 + (rnd(2) - 1),
      direction)
      )
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

  -- return number of colliding baddies
  player_boss_collision = function(bm,playerbb,x_offset)
    if bm.boss == nil then
      return false
    end

    if bm.boss.state == "dead" then
      return false
    end

    if collides_new(playerbb,bm.boss:getBB(x_offset)) then
      return true
    end

    return false
  end,
  player_boss_buffer_collision = function(bm,playerbb,x_offset)
    if bm.boss == nil then
      return false
    end
    
    if bm.boss.state == "dead" then
      return false
    end

    if collides_new(playerbb, bm.boss:getBB(x_offset)) then
      -- change boss state, that should trigger the boss to walk backwards
      local should_back_up = rnd()
      local dist_to_edge = abs(bm.boss:getDrawX(x_offset) - (bm.boss.direction == 0 and 120 or 0))
      if should_back_up > 0.92 and dist_to_edge >= 16 then
        bm.boss.state = "walk"
        bm.boss.state_t = 0.5
        bm.boss.frames_current = bm.boss.frames_walk
        bm.boss.frame_index = 1
        bm.boss.since_last_state = 0
        bm.boss.vx = (bm.boss.direction == 0) and 1 or -1
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
  combat_collision = function(bm,atkbb)
    local impact = false
    foreach(bm.baddies, function(b) 
      local bb = b:getBB()
      if collides_new(atkbb,b:getBB()) then
        sfx(4)
        del(bm.baddies, b)
        impact = true
        -- add some bits
        bm:add_bits(b.type, bb[1], bb[2], b.direction)
      end
    end)
    foreach(bm.projectiles, function(p) 
      local bb = p:getBB()
      if collides_new(atkbb,bb) then
        sfx(4)
        del(bm.projectiles, p)
        impact = true
        -- add some bits
        bm:add_bits('apple', bb[1], bb[2], p.direction)
      end
    end)
    return impact
  end,

  boss_combat_collision = function(bm,atkbb,x_offset)
    if bm.boss == nil then
      return
    elseif bm.boss.state == "dead" then
      return
    elseif bm.boss.invincible > 0 then
      return
    end
    printh("Xoffset: "..x_offset)

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
        foreach(baddie_bits.boss, function(bit)
          add(bm.bits, new_bit(bit,
            bossbb[1],
            bossbb[2],
            (bm.boss.direction == 0 and 2 or -2) + (rnd(1) - 1),
            -3 + (rnd(2) - 1),
            bm.boss.direction)
          )
        end
        )
      end
    end
  end,

  spawn = function(bm,btypes,direction)
    local start_x = direction == 0 and 132 or -4
    foreach(btypes, function(btype)
      local baddie = nil
      if btype == "tree" then
        baddie = new_tree(direction, start_x)
      elseif btype == "flower" then
        baddie = new_flower(direction, start_x)
      elseif btype == "wisp" then
        baddie = new_wisp(direction, start_x)
      else
        printh("unkown baddie type: "..btype)
      end
      add(bm.baddies, baddie)
      start_x = start_x + (direction == 0 and 16 or -16)
    end
    )
  end,

  spawn_boss = function(bmgr, direction, start_x, difficulty)
    bmgr.boss = new_boss(direction, start_x, difficulty)
  end,
}

function new_tree(direction, start_x)
  local baddie = {
    type = "tree",
    direction = direction,
    x = start_x,
    vx = direction == 0 and -1.4 or 1.4,
    y = 81,
    frames_walk = {65,66},
    frames_threat = {67,68},
    frame_index = 1,
    frame_wait = 0.2,
    since_last_frame = 0,
    frames_current = nil,
    update = function(b,dt,vx)
      if b.state == "hug" then
        return
      end

      b.x += b.vx - vx
      b.since_last_frame += dt

      if b.since_last_frame > b.frame_wait then
        b.frame_index += 1
        b.since_last_frame = 0
        if b.frame_index > #b.frames_current then
          b.frame_index = 1
        end
      end
    end,
    draw = function(b)
      local face_left = b.direction == 0
      spr(b.frames_current[b.frame_index],b.x,b.y,1,2,(face_left and true or false),false)
      -- draw bounding box
      -- local x0, y0, x1, y1 = b:getBB()
      -- rect(x0, y0, x1, y1,13)
      -- local x0, y0, x1, y1 = b:getFrontBB()
      -- rect(x0, y0, x1, y1,8)
    end,
    getBB = function(b)
      if b.direction == 0 then
        return {b.x-1,80,b.x+5,96} -- face left
      else
        return {b.x+2,80,b.x+8,96} -- face right
      end
    end,
    getFrontBB = function(b)
      if b.direction == 0 then
        return { b.x - 1,80,b.x+3,96 } -- face left
      else
        return  { b.x + 4,80,b.x+8,96 } -- face right
      end
    end,
  }
  baddie.frames_current = baddie.frames_walk
  return baddie
end

function new_flower(direction, start_x)
  local baddie = {
    direction = direction,
    x = start_x,
    vx = direction == 0 and -1.4 or 1.4,
    y = 89,
    type = "flower",
    frames_walk = {85,86,87,88},
    frames_threat = {67,68},
    frame_index = 1,
    frame_wait = 0.05,
    since_last_frame = 0,
    frames_current = nil,
    update = function(b,dt,vx)
      if b.state == "hug" then
        return
      end

      b.x += b.vx - vx
      b.since_last_frame += dt

      if b.since_last_frame > b.frame_wait then
        b.frame_index += 1
        b.since_last_frame = 0
        if b.frame_index > #b.frames_current then
          b.frame_index = 1
        end
      end
    end,
    draw = function(b)
      local face_left = b.direction == 0
      spr(b.frames_current[b.frame_index],face_left and b.x or b.x,b.y,1,1,(face_left and true or false),false)
      -- draw bounding box
      -- local x0, y0, x1, y1 = b:getBB()
      -- rect(x0, y0, x1, y1,13)
      -- local x0, y0, x1, y1 = b:getFrontBB()
      -- rect(x0, y0, x1, y1,8)
    end,
    getBB = function(b)
      if b.direction == 0 then
        return {b.x-1,b.y,b.x+7,b.y+8} -- facing left
      else
        return {b.x,b.y,b.x+8,b.y+8} -- facing right
      end
    end,
    getFrontBB = function(b)
      if b.direction == 0 then
        return { b.x - 1,b.y+5,b.x+3,b.y+8 } -- face left
      else
        return { b.x + 4,b.y+5,b.x+8,b.y+8 } -- face right
      end
    end,
  }
  baddie.frames_current = baddie.frames_walk
  return baddie
end

function new_projectile(direction, start_x, start_y)
  local projectile = {
    direction = direction,
    x = start_x,
    vx = direction == 0 and -1.8 or 1.8,
    y = start_y,
    state_t = 1,
    since_last_state = 0,
    frames_default = {97,98,99,100},
    frame_index = 1,
    frame_wait = 0.05,
    since_last_frame = 0,
    frames_current = nil,
    update = function(p,dt,vx)
      if p.state == "default" then
        p:update_default(dt)
      end

      p.x += p.vx - vx

      p.since_last_frame += dt
      if p.since_last_frame > p.frame_wait then
        p.frame_index += 1
        p.since_last_frame = 0
        if p.frame_index > #p.frames_current then
          p.frame_index = 1
        end
      end
    end,
    draw = function(p)
      local face_left = p.direction == 0
      spr(p.frames_current[p.frame_index],face_left and p.x or p.x,p.y,1,1,(face_left and true or false),false)
      -- draw bounding box
      -- local x0, y0, x1, y1 = p:getBB()
      -- rect(x0, y0, x1, y1,13)
    end,
    getBB = function(p)
      return { p.x+2,p.y+2,p.x+6,p.y+6 }
    end,
    update_default = function(p, dt)
      p.since_last_state += dt
      p.x += p.vx
    end,
  }
  projectile.frames_current = projectile.frames_default
  return projectile

end

function new_boss(direction, start_x, difficulty)
  local boss = {
    direction = direction,
    x = start_x,
    vx = direction == 0 and -1.4 or 1.4,
    y = 81,
    max_health = difficulty == 1 and 3 or 5,
    health = difficulty == 1 and 3 or 5,
    throw_threshold = difficulty == 1 and 0.95 or 0.5,
    state_t = difficulty == 1 and 1 or 0.5,
    state = "wait",
    since_last_state = 0,
    invincible = 0,
    frames_wait = {73},
    frames_walk = {73,75},
    frames_upantic = {77},
    frames_downantic = {107},
    frames_upthrow = {105},
    frames_downthrow = {109},
    frame_index = 1,
    frame_wait = 0.1,
    since_last_frame = 0,
    frames_current = nil,
    update = function(b,dt,x_offset)

      if b.invincible > 0 then
        b.invincible = max(0, b.invincible - dt)
      else
        b.invincible = 0
      end

      if b.state == "walk" then
        b:update_walk(dt)
      elseif b.state == "wait" then
        b:update_wait(dt)
      elseif b.state == "upantic" then
        b:update_upantic(dt, x_offset)
      elseif b.state == "upthrow" then
        b:update_upthrow(dt)
      elseif b.state == "downantic" then
        b:update_downantic(dt, x_offset)
      elseif b.state == "downthrow" then
        b:update_downthrow(dt)
      elseif b.state == "dead" then
        return
      end

      -- do nothing!
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
      if b.state == "dead" then
        return
      end

      if b.invincible > 0 and flr(b.invincible * 100) % 2 > 0 then
        return
      end
      local face_left = b.direction == 0
      spr(b.frames_current[b.frame_index],b:getDrawX(x_offset),b.y,2,2,(face_left and true or false),false)
      -- draw bounding box
      -- local x0, y0, x1, y1 = b:getBB(x_offset)
      -- rect(x0, y0, x1, y1,13)
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
    update_wait = function(b, dt)
      b.since_last_state += dt
      if b.since_last_state > b.state_t then
        local chance_to_throw = rnd()
        if chance_to_throw > b.throw_threshold then
          local up_or_down = rnd()
          if up_or_down > 0.5 then
            b.state = "upantic"
            b.frames_current = b.frames_upantic
          else
            b.state = "downantic"
            b.frames_current = b.frames_downantic
          end
          b.since_last_state = 0
          b.frame_index = 1
        end
      end
    end,
    update_upantic = function(b, dt, x_antic)
      b.since_last_state += dt
      if b.since_last_state > b.state_t then
        b.state = "upthrow"
        b.since_last_state = 0
        b.frames_current = b.frames_upthrow
        b.frame_index = 1
        add(bmgr.projectiles, new_projectile(b.direction, b:getDrawX(x_antic), 82))
      end
    end,
    update_upthrow = function(b, dt)
      b.since_last_state += dt
      if b.since_last_state > 1 then
        b.state = "wait"
        b.since_last_state = 0
        b.frames_current = b.frames_wait
        b.frame_index = 1
      end
    end,
    update_downantic = function(b, dt, x_offset)
      b.since_last_state += dt
      if b.since_last_state > b.state_t then
        b.state = "downthrow"
        b.since_last_state = 0
        b.frames_current = b.frames_downthrow
        b.frame_index = 1
        add(bmgr.projectiles, new_projectile(b.direction, b:getDrawX(x_offset), 88))
      end
    end,
    update_downthrow = function(b, dt)
      b.since_last_state += dt
      if b.since_last_state > 1 then
        b.state = "wait"
        b.since_last_state = 0
        b.frames_current = b.frames_wait
        b.frame_index = 1
      end
    end,
    update_walk = function(b, dt)
      b.since_last_state += dt
      b.x += b.vx 

      if b.since_last_state > b.state_t then
        b.state = "wait"
        b.frames_current = b.frames_wait
        b.frame_index = 1
      end
    end,
  }
  boss.frames_current = boss.frames_wait
  return boss
end

function new_wisp(direction, start_x)
  local baddie = {
    type = "wisp",
    direction = direction,
    x = start_x,
    vx = direction == 0 and -1.4 or 1.4,
    y = 82,
    frames_walk = {69,70,71},
    frame_index = 1,
    frame_wait = 0.1,
    since_last_frame = 0,
    frames_current = nil,
    update = function(b,dt,vx)
      if b.state == "hug" then
        return
      end

      b.x += b.vx - vx
      b.since_last_frame += dt

      if b.since_last_frame > b.frame_wait then
        b.frame_index += 1
        b.since_last_frame = 0
        if b.frame_index > #b.frames_current then
          b.frame_index = 1
        end
      end
    end,
    draw = function(b)
      local face_left = b.direction == 0
      spr(b.frames_current[b.frame_index],b.x,b.y,1,1,(face_left and true or false),false)
      -- draw bounding box
      -- local x0, y0, x1, y1 = b:getBB()
      -- rect(x0, y0, x1, y1,13)
      -- local x0, y0, x1, y1 = b:getFrontBB()
      -- rect(x0, y0, x1, y1,8)
    end,
    getBB = function(b)
      if b.direction == 0 then
        return {b.x-1,b.y,b.x+7,b.y+8} -- face left
      else
        printh("BB right: "..b.x..','..b.y)
        return {b.x,b.y,b.x+8,b.y+8} -- face right
      end
    end,
    getFrontBB = function(b)
      if b.direction == 0 then
        return {b.x - 1,b.y+5,b.x+3,b.y+8} -- face left
      else
        return {b.x + 4,b.y+5,b.x+8,b.y+8} -- face right
      end
    end,
  }
  baddie.frames_current = baddie.frames_walk
  return baddie
end

function new_bit(sprnum, x, y, vx, vy, direction)
  local bit = {
    x = x,
    y = y,
    vx = vx,
    vy = vy,
    sprnum = sprnum,
    ttl = 1,
    direction = direction,
    update = function(b,dt)
      b.x += b.vx
      b.y += b.vy
      b.vx *= 0.8
      b.vy = min(b.vy + 0.5, 10)
      b.ttl -= dt
    end,
    draw = function(b, dt)
      if flr(dt * 100) % 2 > 0 then
        spr(b.sprnum,b.x,b.y,1,1,(b.direction == 1 and true or false),false)
      end
    end
  }
  return bit
end
