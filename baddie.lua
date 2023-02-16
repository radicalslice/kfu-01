bmgr = {
  baddies = {},

  update = function(bm,dt)
    foreach(bm.baddies, function(b) b:update(dt) end)
  end,

  draw = function(bm)
    foreach(bm.baddies, function(b) b:draw() end)
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

  combat_collision = function(bm,px0,py0,px1,py1)
    foreach(bm.baddies, function(b) 
      local bx0,by0,bx1,by1 = b:getBB()
      if collides(px0,py0,px1,py1,bx0,by0,bx1,by1) then
        del(bm.baddies, b)
      end
    end)
  end,

  spawn = function(bm,num,direction)
    local start_x = direction == 0 and 132 or -4
    for i=1,num do
      add(bm.baddies, new_baddie(direction, start_x))
      start_x = start_x + (direction == 0 and 10 or -10)
    end
  end,
}

function new_baddie(direction, start_x)
  local baddie = {
    direction = direction,
    x = start_x,
    vx = direction == 0 and -1.3 or 1.3,
    y = 80,
    frames_walk = {65,66},
    frames_threat = {67,68},
    frame_index = 1,
    frame_wait = 0.2,
    since_last_frame = 0,
    frames_current = nil,
    update = function(b,dt)
      if b.state == "hug" then
        return
      end

      b.x += b.vx
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
