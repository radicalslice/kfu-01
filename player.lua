map_extent = 384
p_draw_y_stand = 81
p_draw_y_crouch = 84
FREEZE_NONE = 63
FREEZE_LR = 60

player_projectiles = {}

player = {
  frame_wait = 0.08,
  timings = {
    cpantic = 0.1,
    ckantic = 0.1,
    ckantic_od = 0.1,
    cpunch = 0.1,
    ckick = 0.1,
    ckick_od = 0.6,
    pantic = 0.1,
    pantic_od = 0.1,
    kantic = 0.1,
    kantic_od = 0.1,
    punch = 0.1,
    punch_od = 0.6,
    kick = 0.1,
    kick_od = 0.6,
    walk = 1,
    stand = 1,
  },
  frames = {
    walk = {4,3,4,2},
    stand = {1},
    pantic = {9},
    pantic_od = {42},
    kantic = {11},
    kantic_od = {192},
    punch = {8},
    punch_od = {40},
    kick = {10},
    kick_od = {194},
    crouch = {33},
    cpantic = {34},
    cpunch = {35},
    ckantic = {36},
    ckantic_od = {224},
    ckick = {37},
    ckick_od = {226},
    dead = {38},
  },
  reset = function(p, level_direction, freeze_mask)
    p.frames_current = p.frames["stand"]
    p.frame_index = 1
    p.state = "stand"
    p.state_ttl = 0
    p.health = 100
    p.od = 9
    p.mash_count_p, p.mash_count_k = 0, 0
    p.since_last_frame, p.since_last_state = 0, 0
    p.draw_x = 96
    p.draw_y = p_draw_y_stand
    p.direction = level_direction
    p.map_x = level_direction == 0 and map_extent - 16 or 16
    p.vx = 0
    p.vy = 0
    p.hugged_by_count = 0
    p.blocked = false
    p.allowed_inputs = freeze_mask
    p.invincible = 0
    p.overdrive_on = false
    p.overdrive = 0
  end,
  change_state = function(p, s)
    p.state = s
    p.since_last_state = 0
    p.frames_current = p.frames[s]
    p.state_ttl = p.timings[s]
    p.frame_index = 1

    printh("state: "..s)
  end,
  set_draw_x = function(p, x)
    p.draw_x = x
  end,
  update = function(p, dt)

    -- allowed       button       allowed'
    --      1           1|0            1
    --      0            1             0
    --      0            0             1
    for i=0,5 do
      -- 101111 (allowed inputs, blocking punch)
      -- 010000
      -- 111100
      if player.allowed_inputs & (1 << i) == 0 then
        -- input currently not allowed
        if not btn(i) then
          player.allowed_inputs |= (1 << i)
        end
      end
    end

    if p.overdrive_on then
      p.od -= dt 
      if p.od <= 0 then
        p.overdrive_on = false
        p.od = 0
      end
    end

    local od_states = {
      "pantic_od",
      "punch_od",
      "kantic_od",
      "kick_od",
      "ckantic_od",
      "ckick_od",
    }
    if btnp(2) and p.od > 0 and not exists(p.state, od_states) then
      p.overdrive_on = not p.overdrive_on
    end

    if p.invincible > 0 then
      p.invincible = max(0, p.invincible - dt)
    end

    if p.health <= 0 and p.state != "dead" then
      p.state = "dead" 
      p.frames_current = p.frames["dead"]
      p.vx = p.direction == 0 and 4 or -4
      p.vy = -3
    end

    if p.state == "stand" then
      p_update_stand(p, dt)
    elseif p.state == "walk" then
      p_update_walk(p, dt)
    elseif p.state == "pantic" then
      p_update_pantic(p, dt)
    elseif p.state == "pantic_od" then
      p_update_pantic_od(p, dt)
    elseif p.state == "kantic" then
      p_update_kantic(p, dt)
    elseif p.state == "kantic_od" then
      p_update_kantic_od(p, dt)
    elseif p.state == "punch" then
      p_update_punch(p, dt)
    elseif p.state == "punch_od" then
      p_update_punch_od(p, dt)
    elseif p.state == "kick" then
      p_update_kick(p, dt)
    elseif p.state == "kick_od" then
      p_update_kick_od(p, dt)
    elseif p.state == "crouch" then
      p_update_crouch(p, dt)
    elseif p.state == "cpantic" then
      p_update_cpantic(p, dt)
    elseif p.state == "cpunch" then
      p_update_cpunch(p, dt)
    elseif p.state == "ckantic" then
      p_update_ckantic(p, dt)
    elseif p.state == "ckantic_od" then
      p_update_ckantic_od(p, dt)
    elseif p.state == "ckick" then
      p_update_ckick(p, dt)
    elseif p.state == "ckick_od" then
      p_update_ckick_od(p, dt)
    elseif p.state == "hugged" then
      p_update_hugged(p, dt)
    elseif p.state == "dead" then
      p_update_dead(p, dt)
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
    if p.direction == 0 then
      return { p.draw_x,p.draw_y,p.draw_x + 8,p.draw_y + 16 } -- face left
    else
      return { p.draw_x - 1,p.draw_y,p.draw_x + 8,p.draw_y + 16 } -- face right
    end
  end,
  getFrontBB = function(p)
    if p.direction == 0 then
      return { p.draw_x,p.draw_y,p.draw_x + 2,p.draw_y + 16 }
    else
      return { p.draw_x+6,p.draw_y,p.draw_x + 8,p.draw_y + 16 }
    end
  end,
  getFrontBufferBB = function(p)
    if p.direction == 0 then
      return {p.draw_x-7,p.draw_y,p.draw_x - 4,p.draw_y + 16} -- face left
    else
      return {p.draw_x+11,p.draw_y,p.draw_x + 15,p.draw_y + 16} -- face right
    end
  end,
  getAtkBB = function(p)
    local face_right = p.direction == 1
    local y_shift = 0
    if p.state == "ckick" then
      y_shift = 2
    end

    local draw_x, draw_y = p.draw_x, p.draw_y
    if p.state == "punch" or p.state == "cpunch" then
      if face_right then
        return true,{draw_x + 7,draw_y+6,draw_x + 10,draw_y+8}
        else
        return true,{draw_x - 3,draw_y+6,draw_x,draw_y+8}
      end
    elseif p.state == "kick" or p.state == "ckick" then
      if face_right then
        return true,{draw_x+8,draw_y+y_shift+4,draw_x+12,draw_y+y_shift+7}
        else
        return true,{draw_x-6,draw_y+y_shift+4,draw_x-2,draw_y+y_shift+7}
      end
    end

    return false
  end,
  draw = function(p, last_extent, dt)
    if p.invincible > 0 and flr(p.invincible * 100) % 2 > 0 then
      return
    end

    if p.overdrive_on then
      local colors = {14,13,10,7,8}
      pal(8,14)
      pal(4,8)
    end

    local face_right = p.direction == 1

    local dim_x, dim_y = 1, 2
    if p.state == "dead" or p.state == "pantic_od" or p.state == "punch_od" or p.state == "kantic_od" or p.state == "kick_od" or p.state == "ckick_od" then
      dim_x = 2
    end

    spr(p.frames_current[p.frame_index], p.draw_x, p.draw_y, dim_x, dim_y, face_right and true or false,false)

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

    if p.hugged_by_count > 0
      and 
      p.state == "hugged" then
      print("!", p.draw_x + 1, p.draw_y - rnd(3) - 5, 8)
      print("!", p.draw_x + 3, p.draw_y - rnd(3) - 5, 8)
      print("!", p.draw_x + 5, p.draw_y - rnd(3) - 5, 8)
    end

    --[[ Draw fist / leg collision
    local checkme,bb = p:getAtkBB()
    if checkme then
      -- rect(bb[0], bb[1], bb[2], bb[3],14)
      -- last_extent = face_right and x3 or x2
    end
    ]]--
    if p.overdrive_on then
      pal(8,8)
      pal(4,4)
    end
    return last_extent
  end,
  handle_hug = function(p, current_huggers)
    p.hugged_by_count = current_huggers
    if p.hugged_by_count > 0 and (p.state == "stand" or p.state == "crouch" or p.state == "walk") then
      p.frames_current = (p.state == "crouch") and p.frames["crouch"] or p.frames["stand"]
      p.state = "hugged"
      p.since_last_state = 0
      p.frame_index = 1
    end
  end,
  handle_boss_collision = function(p, collides)
    p.blocked = collides  
  end,
  deduct_health = function(p, amount, flash)
    p.health = max(0, p.health - amount)
    if flash then
      p.invincible = 2
    end
  end,
  get_hinted_vx = function(p)
    if p.state == "walk" and player.draw_x >= 63 and player.draw_x <= 65 then
      if btn(1) then
        return 1
      elseif btn(0) then
        return -1
      end
    end
    return 0
  end,
}

function p_update_hugged(p, dt)
  -- deduct some health in here
  if p.state != "stand" and p.state != "crouch" and p.state != "hugged" then
    return
  end

  p:deduct_health(ceil(dt * p.hugged_by_count * 10), false)

  if p.hugged_by_count == 0 then
    p:change_state("stand")
    return
  end

  if btn(0) then
    p.direction = 0
  elseif btn(1) then
    p.direction = 1
  end

  if btn(3) and p.frames_current == p.frames["stand"] then
    p.draw_y = p_draw_y_crouch
    p.frames_current = p.frames["crouch"]
    return
  elseif not btn(3) and p.frames_current == p.frames["crouch"] then
    p.frames_current = p.frames["stand"]
    p.draw_y = p_draw_y_stand
    return
  end

  local filtered = btnp() & p.allowed_inputs
  if filtered & (1 << 4) > 0 then
    p.mash_count_p += 1
    -- 101111 = 47
    p.allowed_inputs &= ~(1 << 4) -- 111111 & 101111
    if p.mash_count_p > p.hugged_by_count then
      if p.frames_current == p.frames["crouch"] then
        p:change_state("cpantic")
      else 
        p:change_state("pantic")
      end
      p.mash_count_p , p.mash_count_k = 0,0
      return
    end
  elseif filtered & (1 << 5) > 0 then
    p.mash_count_k += 1
    p.allowed_inputs &= ~(1<<5)
    if p.mash_count_k > p.hugged_by_count then
      if p.frames_current == p.frames["crouch"] then
        p:change_state("ckantic")
      else
        p:change_state("kantic")
      end
      p.mash_count_p , p.mash_count_k = 0,0
      return
    end
  end
end

function p_update_stand(p)
    if p.map_x < 64 then
      p:set_draw_x(max(0,p.map_x))
    elseif p.map_x > (map_extent - 64) then
      p:set_draw_x(min(120,128 - (map_extent - p.map_x)))
    else
      p:set_draw_x(64)
    end
    local filtered = btn() & p.allowed_inputs
    if filtered & (1 << 4) > 0 then
      -- Shift a 1 to the fourth position:
      -- 010000 -> 101111
      -- 111111 & 101111 = 101111
      p.allowed_inputs &= ~(1 << 4)
      if p.overdrive_on then
        p:set_draw_x(p.direction == 0 and p.draw_x -2 or p.draw_x - 6)
        p:change_state("pantic_od")
      else
        p:change_state("pantic")
      end
      sfx(1)
      return
    end

    if filtered & (1 << 5) > 0 then
      p.allowed_inputs &= ~(1 << 5)
      if p.overdrive_on then
        p:set_draw_x(p.direction == 0 and p.draw_x-2 or p.draw_x -6)
        p:change_state("kantic_od")
      else
        p:change_state("kantic")
      end
      sfx(0)
      return
    end

    if filtered & (1 << 0) > 0 then
      p.direction = 0 
      p:change_state("walk")
    elseif filtered & (1 << 1) > 0 then
      p.direction = 1
      p:change_state("walk")
    elseif btn(3) then
      p:change_state("crouch")
      p.draw_y = p_draw_y_crouch
      return
    end
end

function p_update_walk(p)
  if p.map_x < 64 then
    p:set_draw_x(max(0,p.map_x))
  elseif p.map_x > (map_extent - 64) then
    p:set_draw_x(min(120,128 - (map_extent - p.map_x)))
  else
    p:set_draw_x(64)
  end

  
  if not btn(0) and not btn(1) then
    p:change_state("stand")
  elseif btn(0) and p.map_x > 0 then
    p.direction = 0 
    p.map_x -= p.blocked != true and 1 or 0
    p.vx = (player.draw_x >= 63 and player.draw_x <= 65) and -1 or 0
  elseif btn(1) and p.map_x < (map_extent - 8) then
    p.direction = 1
    p.map_x += p.blocked != true and 1 or 0
    p.vx = (player.draw_x >= 63 and player.draw_x <= 65) and 1 or 0
  end

  local filtered = btn() & p.allowed_inputs
  if filtered & (1 << 4) > 0 then
    p.allowed_inputs &= ~(1 << 4)
    if p.overdrive_on then
      p:set_draw_x(p.direction == 0 and p.draw_x -2 or p.draw_x - 6)
      p:change_state("pantic_od")
    else
      p:change_state("pantic")
    end
    sfx(1)
    return
  end

  if filtered & (1 << 5) > 0 then
    p.allowed_inputs &= ~(1 << 5)
    if p.overdrive_on then
      p:set_draw_x(p.direction == 0 and p.draw_x-2 or p.draw_x -6)
      p:change_state("kantic_od")
    else
      p:change_state("kantic")
    end
    sfx(0)
    return
  end
end

function p_update_pantic(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:change_state("punch")
    end
end

function p_update_pantic_od(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:change_state("punch_od")
    end
end

function p_update_kantic(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:change_state("kick")
    end
end

function p_update_kantic_od(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:change_state("kick_od")
    end
end

function p_update_punch(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:change_state("stand")
    end

end

function p_update_punch_od(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      -- p.draw_x += (p.direction == 0 and 2 or 6)
      p:set_draw_x(p.direction == 0 and p.draw_x + 2 or p.draw_x + 6)
      p:change_state("stand")
    end
    
    -- spawn projectile here...
    if #player_projectiles == 0 then
      local start_x = (p.direction == 0 and p.draw_x-8 or p.draw_x + 16)
      add(player_projectiles, {head_x=start_x, tail_x=start_x, direction=p.direction,top_y=p.draw_y+5,bottom_y=p.draw_y+13,ttl=p.timings.punch_od + 0.01,t="punch"})
    end
end

function p_update_kick(p, dt)

    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:change_state("stand")
    end
end

function p_update_kick_od(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:set_draw_x(p.direction == 0 and p.draw_x+2 or p.draw_x+6)
      p:change_state("stand")
    end
    
    -- spawn projectile here...
    if #player_projectiles == 0 then
      local start_x_0 = (p.direction == 0 and p.draw_x-7 or p.draw_x - 5)
      local start_x_1 = (p.direction == 0 and p.draw_x+13 or p.draw_x + 15)
      add(player_projectiles, {head_x=start_x_0, tail_x=start_x_0, direction=0,top_y=p.draw_y+5,bottom_y=p.draw_y+8,ttl=p.timings.punch_od + 0.01,t="kick"})
      add(player_projectiles, {head_x=start_x_1, tail_x=start_x_1, direction=1,top_y=p.draw_y+5,bottom_y=p.draw_y+8,ttl=p.timings.punch_od + 0.01,t="kick"})
    end
end

function p_update_crouch(p, dt)
    local filtered = btn() & p.allowed_inputs
    if filtered & (1 << 4) > 0 then
      p.allowed_inputs &= ~(1 << 4)
      if p.overdrive_on then
        p.draw_y -= 3
        p:set_draw_x(p.direction == 0 and p.draw_x -2 or p.draw_x - 6)
        p:change_state("pantic_od")
      else
        p:change_state("cpantic")
      end
      sfx(1)
    end
    if filtered & (1 << 5) > 0 then
      p.allowed_inputs &= ~(1 << 5)
      if p.overdrive_on then
        p:change_state("ckantic_od")
      else
        p:change_state("ckantic")
      end
      sfx(0)
    end
    if not btn(3) then
      p:change_state("stand")
      p.draw_y = p_draw_y_stand
    end
    if btn(0) then
      p.direction = 0
    end
    if btn(1) then
      p.direction = 1
    end
end

function p_update_cpantic(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:change_state("cpunch")
    end
end

function p_update_ckantic(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:change_state("ckick")
    end
end

function p_update_ckantic_od(p, dt)
    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:set_draw_x((p.direction == 0 and p.draw_x-4 or p.draw_x-4))
      p:change_state("ckick_od")
    end
end

function p_update_cpunch(p, dt)

    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:change_state("crouch")
    end
end

function p_update_ckick(p, dt)

    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:change_state("crouch")
    end
end

function p_update_ckick_od(p, dt)

    p.since_last_state += dt

    if p.since_last_state > p.state_ttl then
      p:set_draw_x((p.direction == 0 and p.draw_x + 4 or p.draw_x + 4))
      p:change_state("crouch")
    end

    -- spawn projectile here...
    if #player_projectiles == 0 then
      local start_x_0 = (p.direction == 0 and p.draw_x-5 or p.draw_x - 6)
      local start_x_1 = (p.direction == 0 and p.draw_x+14 or p.draw_x + 13)
      add(player_projectiles, {head_x=start_x_0, tail_x=start_x_0, direction=0,top_y=p.draw_y+7,bottom_y=p.draw_y+10,ttl=p.timings.punch_od + 0.01,t="kick"})
      add(player_projectiles, {head_x=start_x_1, tail_x=start_x_1, direction=1,top_y=p.draw_y+7,bottom_y=p.draw_y+10,ttl=p.timings.punch_od + 0.01,t="kick"})
    end
end

function p_update_dead(p, dt)
  p.draw_x += p.vx
  p.draw_y += p.vy
  p.vx *= 0.8
  p.vy = min(p.vy + 0.5, 10)
end

