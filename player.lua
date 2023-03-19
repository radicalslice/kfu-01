map_extent = 512
player = {
  frame_wait = 0.08,
  frames_walk = {4,3,4,2},
  frames_stand = {1},
  frames_pantic = {9},
  frames_punch = {8},
  frames_kantic = {11},
  frames_kick = {10},
  frames_crouch = {33},
  frames_cpantic = {34},
  frames_cpunch = {35},
  frames_ckantic = {36},
  frames_ckick = {37},
  reset = function(p, level_direction)
    p.frames_current = p.frames_stand  
    p.frame_index = 1
    p.state = "stand"
    p.state_t = 0
    p.health = 100
    p.mash_count_p, p.mash_count_k = 0, 0
    p.since_last_frame, p.since_last_state = 0, 0
    p.draw_x = 96
    p.draw_y = 80
    p.direction = level_direction
    p.map_x = level_direction == 0 and map_extent - 16 or 16
    p.vx = 0
    p.hugged_by_count = 0
    p.blocked = false
    p.freeze_input = true
  end,
  update = function(p, dt)
    p.vx = 0

    -- btn() = 001000
    ------     xoDURL
    if btn() == 0 or btn() == 8 then
      player.freeze_input = false
    end

    if p.state == "stand" then
      p_update_stand(p, dt)
    elseif p.state == "walk" then
      p_update_walk(p, dt)
    elseif p.state == "pantic" then
      p_update_pantic(p, dt)
    elseif p.state == "kantic" then
      p_update_kantic(p, dt)
    elseif p.state == "punch" then
      p_update_punch(p, dt)
    elseif p.state == "kick" then
      p_update_kick(p, dt)
    elseif p.state == "crouch" then
      p_update_crouch(p, dt)
    elseif p.state == "cpantic" then
      p_update_cpantic(p, dt)
    elseif p.state == "cpunch" then
      p_update_cpunch(p, dt)
    elseif p.state == "ckantic" then
      p_update_ckantic(p, dt)
    elseif p.state == "ckick" then
      p_update_ckick(p, dt)
    elseif p.state == "hugged" then
      p_update_hugged(p, dt)
    end
    p.since_last_frame += dt

    if p.since_last_frame > p.frame_wait then
      p.frame_index += 1
      p.since_last_frame = 0
      if p.frame_index > #p.frames_current then
        p.frame_index = 1
      end
    end

  end,
  getBB = function(p)
    local face_right = p.direction == 1
    if face_right then
      return p.draw_x - 1,p.draw_y,p.draw_x + 8,p.draw_y + 16
    else
      return p.draw_x,p.draw_y,p.draw_x + 8,p.draw_y + 16
    end
  end,
  getFrontBB = function(p)
    local face_right = p.direction == 1
    if face_right then
      return p.draw_x+6,p.draw_y,p.draw_x + 8,p.draw_y + 16
    else
      return p.draw_x,p.draw_y,p.draw_x + 2,p.draw_y + 16
    end
  end,
  getFrontBufferBB = function(p)
    local face_right = p.direction == 1
    if face_right then
      return p.draw_x+11,p.draw_y,p.draw_x + 15,p.draw_y + 16
    else
      return p.draw_x-7,p.draw_y,p.draw_x - 4,p.draw_y + 16
    end
  end,
  getAtkBB = function(p)
    local face_right = p.direction == 1
    if p.state == "punch" then
      if face_right then
        local left = p.draw_x + 8
        return true,left,p.draw_y+6,left+2,p.draw_y+8
        else
        local left = p.draw_x -3
        return true,left,p.draw_y+6,left+2,p.draw_y+8
      end
    elseif p.state == "kick" then
      if face_right then
        return true,p.draw_x+8,p.draw_y+4,p.draw_x + 12,p.draw_y+7
        else
        local left = p.draw_x -5
        return true,left,p.draw_y+4,left + 3,p.draw_y+7
      end
    elseif p.state == "cpunch" then
      if face_right then
        return true,p.draw_x + 6,p.draw_y+6,p.draw_x + 10,p.draw_y+9
        else
        return true,p.draw_x - 3,p.draw_y+6,p.draw_x,p.draw_y+9
      end
   elseif p.state == "ckick" then
      if face_right then
        return true,p.draw_x + 8,p.draw_y+6,p.draw_x + 12,p.draw_y+9
        else
        return true,p.draw_x - 5,p.draw_y+6,p.draw_x - 1,p.draw_y+9
      end
    

    end

    return false
  end,
  draw = function(p, last_extent, dt)
    palt(0, false)
    palt(15, true)
    local face_right = p.direction == 1
    if p.map_x < 64 then
      p.draw_x = max(0,p.map_x)
    elseif p.map_x > (map_extent - 64) then
      p.draw_x = min(120,128 - (map_extent - p.map_x))
    end

    spr(p.frames_current[p.frame_index], p.draw_x, p.draw_y, 1, 2, face_right and true or false,false)

    -- Draw player's collision box
    local x0, y0, x1, y1 = p:getBB()
    -- rect(x0, y0, x1, y1,11)

    -- Find the front collision box
    x0, y0, x1, y1 = p:getFrontBB()
    -- rect(x0, y0, x1, y1,1)

    x0, y0, x1, y1 = p:getFrontBufferBB()
    -- rect(x0, y0, x1, y1,1)

    -- Draw the attack-y bits
    if p.state == "punch" then
      spr(21, face_right and p.draw_x + 8 or p.draw_x - 2, p.draw_y + 7)
    elseif p.state == "kantic" then
      spr(23,face_right and p.draw_x + 2 or p.draw_x - 2,p.draw_y + 8,1,1,face_right and true or false)
    elseif p.state == "kick" then
      spr(6,face_right and p.draw_x + 4 or p.draw_x - 4,p.draw_y,1,2,face_right and true or false)
    elseif p.state == "cpunch" then
      spr(21,face_right and p.draw_x + 2 or p.draw_x - 2,p.draw_y+7,1,1,face_right and true or false)
    elseif p.state == "ckick" then
      spr(7,face_right and p.draw_x + 7 or p.draw_x - 7,p.draw_y+2,1,1,face_right and true or false)
    end

    -- Draw fist / leg collision
    local checkme,x2,y2,x3,y3 = p:getAtkBB()
    if checkme then
      -- rect(x2, y2, x3, y3,14)
      -- last_extent = face_right and x3 or x2
    end
    pal()
    return last_extent
  end,
  handle_hug = function(p, current_huggers)
    p.hugged_by_count = current_huggers
    if p.hugged_by_count > 0 and (p.state == "stand" or p.state == "crouch" or p.state == "walk") then
      p.frames_current = (p.state == "crouch") and p.frames_crouch or p.frames_stand
      p.state = "hugged"
      p.since_last_state = 0
      p.frame_index = 1
    end
  end,
  handle_boss_collision = function(p, collides)
    p.blocked = collides  
  end,
  deduct_health = function(p, amount)
    p.health = max(0, p.health - amount)
  end,
}

function p_update_hugged(p, dt)
  -- deduct some health in here
  if p.state != "stand" and p.state != "crouch" and p.state != "hugged" then
    return
  end

  p:deduct_health(ceil(dt * p.hugged_by_count * 10))

  if p.hugged_by_count == 0 then
    p.state = "stand"
    p.frames_current = p.frames_stand
    p.frame_index = 1
    p.since_last_state = 0
    return
  end

  if btn(0) then
    p.direction = 0
  elseif btn(1) then
    p.direction = 1
  end

  if btn(3) and p.frames_current == p.frames_stand then
    p.draw_y += 3
    p.frames_current = p.frames_crouch
    return
  elseif not btn(3) and p.frames_current == p.frames_crouch then
    p.frames_current = p.frames_stand
    p.draw_y -= 3
    return
  end

  if btnp(4) and not p.freeze_input then
    p.mash_count_p += 1
    p.freeze_input = true
    if p.mash_count_p > p.hugged_by_count then
      if p.frames_current == p.frames_crouch then
        p.state = "cpantic"
        p.frames_current = p.frames_cpantic
      else 
        p.state = "pantic"
        p.frames_current = p.frames_pantic
      end
      p.since_last_state = 0
      p.mash_count_p , p.mash_count_k = 0,0
      return
    end
  elseif btnp(5) and not p.freeze_input then
    p.mash_count_k += 1
    p.freeze_input = true
    if p.mash_count_k > p.hugged_by_count then
      if p.frames_current == p.frames_crouch then
        p.state = "ckantic"
        p.frames_current = p.frames_ckantic
      else
        p.state = "kantic"
        p.frames_current = p.frames_kantic
      end
      p.since_last_state = 0
      p.mash_count_p , p.mash_count_k = 0,0
      return
    end
  end
end

function p_update_stand(p)
    if btn(4) and not p.freeze_input then
      p.state = "pantic"
      p.state_t = 0.1
      p.frames_current = p.frames_pantic
      p.since_last_state = 0
      p.freeze_input = true
      sfx(1)
      return
    end

    if btn(5) and not p.freeze_input then
      p.state = "kantic"
      p.state_t = 0.15
      p.frames_current = p.frames_kantic
      p.since_last_state = 0
      p.freeze_input = true
      sfx(0)
      return
    end

    if btn(0) and not player.freeze_input then
      p.direction = 0 
      p.frames_current = p.frames_walk
      p.state = "walk"
    elseif btn(1) and not player.freeze_input then
      p.direction = 1
      p.frames_current = p.frames_walk
      p.state = "walk"
    elseif btn(3) then
      p.frames_current = p.frames_crouch
      p.state = "crouch"
      p.draw_y += 3
      return
    end
end

function p_update_walk(p)
  
  if not btn(0) and not btn(1) then
    p.frames_current = p.frames_stand
    p.frame_index = 1
    p.state = "stand"
  elseif btn(0) and p.map_x > 0 then
    p.direction = 0 
    p.map_x -= p.blocked != true and 1 or 0
    p.vx = (player.draw_x >= 63 and player.draw_x <= 65) and -1 or 0
  elseif btn(1) and p.map_x < (map_extent - 8) then
    p.direction = 1
    p.map_x += p.blocked != true and 1 or 0
    p.vx = (player.draw_x >= 63 and player.draw_x <= 65) and 1 or 0
  end
end

function p_update_pantic(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_t then
      p.state = "punch"
      p.since_last_state = 0
      p.state_t = 0.15
      p.frames_current = p.frames_punch
    end
end

function p_update_kantic(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_t then
      p.state = "kick"
      p.since_last_state = 0
      p.state_t = 0.2
      p.frames_current = p.frames_kick
    end
end

function p_update_punch(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_t then
      p.state = "stand"
      p.since_last_state = 0
      p.frames_current = p.frames_stand
    end

end

function p_update_kick(p, dt)

    p.since_last_state += dt

    if p.since_last_state > p.state_t then
      p.state = "stand"
      p.since_last_state = 0
      p.frames_current = p.frames_stand
    end
end

function p_update_crouch(p, dt)
    if btn(4) and not p.freeze_input then
      p.state = "cpantic"
      p.state_t = 0.1
      p.frames_current = p.frames_cpantic
      p.since_last_state = 0
      p.freeze_input = true
      sfx(1)
    end
    if btn(5) and not p.freeze_input then
      p.state = "ckantic"
      p.state_t = 0.15
      p.frames_current = p.frames_ckantic
      p.since_last_state = 0
      p.freeze_input = true
      sfx(0)
    end
    if not btn(3) then
      p.state = "stand"
      p.since_last_state = 0
      p.frames_current = p.frames_stand
      p.draw_y -= 3
    end
end

function p_update_cpantic(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_t then
      p.state = "cpunch"
      p.since_last_state = 0
      p.state_t = 0.15
      p.frames_current = p.frames_cpunch
    end
end

function p_update_ckantic(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_t then
      p.state = "ckick"
      p.since_last_state = 0
      p.state_t = 0.2
      p.frames_current = p.frames_ckick
    end
end

function p_update_cpunch(p, dt)

    p.since_last_state += dt

    if p.since_last_state > p.state_t then
      p.state = "crouch"
      p.since_last_state = 0
      p.frames_current = p.frames_crouch
    end
end

function p_update_ckick(p, dt)

    p.since_last_state += dt

    if p.since_last_state > p.state_t then
      p.state = "crouch"
      p.since_last_state = 0
      p.frames_current = p.frames_crouch
    end
end
