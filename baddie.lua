bmgr = {
  baddies = {},
  boss = nil,

  reset = function(bm)
    bm.baddies = {}
  end,

  update = function(bm,dt,vx)
    foreach(bm.baddies, function(b) b:update(dt,vx) end)
    if bm.boss != nil then
      bm.boss:update(dt)
    end
  end,

  draw = function(bm)
    foreach(bm.baddies, function(b) b:draw() end)
    if bm.boss != nil then
      bm.boss:draw()
    end
  end,

  -- return number of colliding baddies
  player_collision = function(bm,px0,py0,px1,py1)
    local count = 0
    foreach(bm.baddies, function(b) 
      b.state = "walk"
      local bx0,by0,bx1,by1 = b:getFrontBB()
      foreach(bm.baddies, function(inner_b)
        local ibx0,iby0,ibx1,iby1 = inner_b:getBB()
        -- make sure this isn't the exact same baddie
        if inner_b.x != b.x 
          and inner_b.state == "hug"
          and collides(ibx0,iby0,ibx1,iby1,bx0,by0,bx1,by1) then
          b.state = "hug"
          count += 1
        end
      end)
      local bx0,by0,bx1,by1 = b:getBB()
      if collides(px0,py0,px1,py1,bx0,by0,bx1,by1) then
        count += 1
        b.state = "hug"
      end
    end)
    return count
  end,

  -- return number of colliding baddies
  player_boss_collision = function(bm,px0,py0,px1,py1)
    if bm.boss == nil then
      return false
    end

    local bx0,by0,bx1,by1 = bm.boss:getBB()
    if collides(px0,py0,px1,py1,bx0,by0,bx1,by1) then
      return true
    end

    return false
  end,
  player_boss_buffer_collision = function(bm,px0,py0,px1,py1)
    local bx0,by0,bx1,by1 = bm.boss:getBB()
    if collides(px0,py0,px1,py1,bx0,by0,bx1,by1) then
      -- change boss state, that should trigger the boss to walk backwards
      bm.boss.state = "walk"
      bm.boss.state_t = 1
      bm.boss.since_last_state = 0
      bm.boss.vx = (bm.boss.direction == 0) and 1 or -1
    end
  end,
  combat_collision = function(bm,px0,py0,px1,py1)
    foreach(bm.baddies, function(b) 
      local bx0,by0,bx1,by1 = b:getBB()
      if collides(px0,py0,px1,py1,bx0,by0,bx1,by1) then
        del(bm.baddies, b)
      end
    end)
  end,

  boss_combat_collision = function(bm,px0,py0,px1,py1)
    if bm.boss == nil then
      return
    elseif bm.boss.invincible > 0 then
      return
    end

    local bx0,by0,bx1,by1 = bm.boss:getBB()
    if collides(px0,py0,px1,py1,bx0,by0,bx1,by1) then
      -- knock boss backwards / deduct health
      bm.boss.health -= 1
      bm.boss.invincible = 1
      if bm.boss.direction == 1 then
        bm.boss.x -= 5
      else
        bm.boss.x += 5
      end
      if bm.boss.health <= 0 then
        bm.boss = nil
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
        else
          printh("unkown baddie type: "..btype)
      end
      add(bm.baddies, baddie)
      start_x = start_x + (direction == 0 and 10 or -10)
    end
    )
  end,

  spawn_boss = function(bmgr, direction, start_x)
    bmgr.boss = new_boss(direction, start_x)
  end,
}

function new_tree(direction, start_x)
  local baddie = {
    direction = direction,
    x = start_x,
    vx = direction == 0 and -1.2 or 1.2,
    y = 80,
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
      palt(0, false)
      palt(15, true)
      spr(b.frames_current[b.frame_index],face_left and b.x or b.x,b.y,1,2,(face_left and true or false),false)
      -- draw bounding box
      local x0, y0, x1, y1 = b:getBB()
      -- rect(x0, y0, x1, y1,13)
      local x0, y0, x1, y1 = b:getFrontBB()
      -- rect(x0, y0, x1, y1,8)
      pal()
    end,
    getBB = function(b)
      local face_left = b.direction == 0
      if face_left then
        return b.x-1,80,b.x+7,96
      else
        return b.x,80,b.x+8,96
      end
    end,
    getFrontBB = function(b)
      local face_left = b.direction == 0
      if face_left then
        return b.x - 1,80,b.x+3,96
      else
        return b.x + 4,80,b.x+8,96
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
    vx = direction == 0 and -1.2 or 1.2,
    y = 89,
    frames_walk = {85,86,87,88},
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
      palt(0, false)
      palt(15, true)
      spr(b.frames_current[b.frame_index],face_left and b.x or b.x,b.y,1,1,(face_left and true or false),false)
      -- draw bounding box
      local x0, y0, x1, y1 = b:getBB()
      -- rect(x0, y0, x1, y1,13)
      local x0, y0, x1, y1 = b:getFrontBB()
      -- rect(x0, y0, x1, y1,8)
      pal()
    end,
    getBB = function(b)
      local face_left = b.direction == 0
      if face_left then
        return b.x-1,b.y,b.x+7,b.y+8
      else
        return b.x,b.y,b.x+8,b.y+8
      end
    end,
    getFrontBB = function(b)
      local face_left = b.direction == 0
      if face_left then
        return b.x - 1,b.y+5,b.x+3,b.y+8
      else
        return b.x + 4,b.y+5,b.x+8,b.y+8
      end
    end,
  }
  baddie.frames_current = baddie.frames_walk
  return baddie
end

function new_boss(direction, start_x)
  local boss = {
    direction = direction,
    x = start_x,
    vx = direction == 0 and -1.2 or 1.2,
    y = 80,
    health = 3,
    state = "wait",
    invincible = 0,
    frames_walk = {73,75},
    frames_upantic = {77},
    frames_downantic = {107},
    frames_upthrow = {105},
    frames_downthrow = {109},
    frame_index = 1,
    frame_wait = 0.5,
    since_last_frame = 0,
    frames_current = nil,
    update = function(b,dt,vx)
      -- do nothing!
      if b.invincible > 0 then
        b.invincible = max(0, b.invincible - dt)
      end

      if b.state == "walk" then
        b:update_walk(dt)
      end

      if b.since_last_frame > b.frame_wait then
        b.frame_index += 1
        b.since_last_frame = 0
        if b.frame_index > #b.frames_current then
          b.frame_index = 1
        end
      end
    end,
    draw = function(b)
      if b.invincible > 0 and flr(b.invincible * 100) % 2 > 0 then
        return
      end
      local face_left = b.direction == 0
      palt(0, false)
      palt(15, true)
      spr(b.frames_current[b.frame_index],face_left and b.x or b.x,b.y,2,2,(face_left and true or false),false)
      -- draw bounding box
      local x0, y0, x1, y1 = b:getBB()
      -- rect(x0, y0, x1, y1,13)
      pal()
    end,
    getBB = function(b)
        return b.x,b.y,b.x+16,b.y+16
    end,
    update_wait = function(b) end,
    update_walk = function(b, dt)
      b.since_last_state += dt
      b.x += b.vx 

      if b.since_last_state > b.state_t then
        b.state = "wait"
      end
    end,
  }
  boss.frames_current = boss.frames_walk
  return boss
end
