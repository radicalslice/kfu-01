map_extent = 384
max_od = 9
p_draw_y_stand = 81
p_draw_y_crouch = 84
FREEZE_NONE = 63
FREEZE_LR = 60

dblw_states = {"dead", "pantic_od", "punch_od", "kantic_od", "kick_od", "ckick_od", "unmash"}
player_projectiles = {}

player = {
  frame_wait = 0.08,
  last_score = 0,
  score = 0,
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
    unmash = 0.2,
    walk = 1,
    stand = 1,
    victory = 1,
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
    unmash = {198},
    victory = {200},
  },
  reset = function(p, level_direction, freeze_mask)
    p.frames_current = p.frames["stand"]
    p.frame_index = 1
    p.state = "stand"
    p.score = p.last_score
    p.state_ttl = 0
    p.health = 100
    p.od = 0
    p.mash_count = 0
    p.since_last_frame, p.since_last_state = 0, 0
    p.draw_x = level_direction == 0 and map_extent - 16 or 16
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
  end,
  change_state = function(p, s)
    p.state = s
    p.since_last_state = 0
    p.frames_current = p.frames[s]
    p.state_ttl = p.timings[s]
    p.frame_index = 1
  end,
  set_draw_x = function(p, x)
    p.draw_x = x
  end,
  update = function(p, dt, bm, bmp) -- btn(), btnp()
    p.since_last_state += dt
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
        if not read_bm(bm, i) then
          player.allowed_inputs |= (1 << i)
        end
      end
    end

    if p.overdrive_on then
      p.od -= dt 
      if p.od <= 0 then
        p.overdrive_on = false
        p.od = 0
        sfx(10)
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
    if read_bm(bmp, 2) and p.od > 0 and not exists(p.state, od_states) then
      p.overdrive_on = not p.overdrive_on
      if p.overdrive_on == true then
        -- stop the action and add a timer
        __update = timers_only
        p:change_state("victory")
        for j=1,8 do
          add(fx.parts, new_part(p.draw_x + 4, p.draw_y + 8, {5,6,8,9,14,14}, 5, 0.8))
          sfx(9)
        end
        add(timers, {remaining=0.4, callback=function()
          __update = game_update
          p:change_state("stand")
        end
        })
        add(timers, {remaining=0.1, callback=function()
          for j=1,8 do
            add(fx.parts, new_part(p.draw_x + 4, p.draw_y + 8, {5,6,8,9,14,14}, 5, 0.8))
          end
        end
        })
        else
          sfx(10)
      end
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

    -- do state update
    player_state_funcs[p.state](p, dt, bm, bmp)
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
    end
    if exists(p.state, dblw_states) then
      return { p.draw_x +7,p.draw_y,p.draw_x + 15,p.draw_y + 16 } -- face right, dbl
    end
    return { p.draw_x - 1,p.draw_y,p.draw_x + 8,p.draw_y + 16 } -- face right
  end,
  getFrontBB = function(p)
    if p.direction == 0 then
      return { p.draw_x,p.draw_y,p.draw_x + 2,p.draw_y + 16 }
    end
    if exists(p.state, dblw_states) then
      return { p.draw_x + 14,p.draw_y,p.draw_x + 16,p.draw_y + 16 } -- face right, dbl
    end
      return { p.draw_x+6,p.draw_y,p.draw_x + 8,p.draw_y + 16 }
  end,
  getFrontBufferBB = function(p)
    if p.direction == 0 then
      return {p.draw_x-7,p.draw_y,p.draw_x - 4,p.draw_y + 16} -- face left
    end
    if exists(p.state, dblw_states) then
      return { p.draw_x + 19,p.draw_y,p.draw_x + 23,p.draw_y + 16 } -- face right, dbl
    end
    return {p.draw_x+11,p.draw_y,p.draw_x + 15,p.draw_y + 16} -- face right
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
  draw = function(p, dt)
    if p.invincible > 0 and flr(p.invincible * 100) % 2 > 0 then
      return
    end

    if p.overdrive_on then
      if p.od > 1 or (p.od < 1 and ((p.od * 100) % 2 > 0)) then
        pal(8,14)
        pal(4,8)
      end
    end

    local face_right = p.direction == 1

    local dim_x, dim_y = 1, 2
    if exists(p.state, dblw_states) then
      dim_x = 2
    end

    spr(p.frames_current[p.frame_index], p.draw_x, p.draw_y, dim_x, dim_y, face_right and true or false,false)

    -- Draw player's collision box
    local bb = p:getBB()
    foreach({p:getBB(), p:getFrontBB(), p:getFrontBufferBB()}, function(bb)
      -- rect(bb[1], bb[2], bb[3], bb[4], 11)
    end)

    local atkbits = {
      punch = {21, -2, 2, 7}, --spr, x left, x right, y
      kantic = {23, -2, 2, 8},
      kick = {6, -4, 4, 5},
      cpunch = {21, -2, 2, 7},
      ckick = {7, -7,7,2 }
    }
    -- Draw the attack-y bits
    if atkbits[p.state] != nil then
      local tbl = atkbits[p.state]
      spr(tbl[1], face_right and p.draw_x + tbl[3] or p.draw_x + tbl[2], p.draw_y + tbl[4], 1,1,face_right and true or false)
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
    end
    ]]--
    if p.overdrive_on then
      pal(8,8)
      pal(4,4)
    end
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

    if p.od > 0 then
      p.od = 0
    end
  end,
  add_od = function(p, amount)
    p.od = min(p.od + amount, 9)
  end,
  get_hinted_vx = function(p, bm)
    if p.state == "walk" and player.draw_x >= 63 and player.draw_x <= 65 then
      if read_bm(bm, 1) then
        return 1
      elseif read_bm(bm, 0) then
        return -1
      end
    end
    return 0
  end,
}

player_state_funcs = {
  stand = function(p, dt, bm)
    if p.map_x < 64 then
      p:set_draw_x(max(0,p.map_x))
    elseif p.map_x > (map_extent - 64) then
      p:set_draw_x(min(120,128 - (map_extent - p.map_x)))
    else
      p:set_draw_x(64)
    end
    local filtered = bm & p.allowed_inputs
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
    elseif read_bm(bm, 3) then
      p:change_state("crouch")
      p.draw_y = p_draw_y_crouch
      return
    end
  end,
  walk = function(p, dt, bm)
    if p.map_x < 64 then
      p:set_draw_x(max(0,p.map_x))
    elseif p.map_x > (map_extent - 64) then
      p:set_draw_x(min(120,128 - (map_extent - p.map_x)))
    else
      p:set_draw_x(64)
    end

    if not read_bm(bm, 0) and not read_bm(bm, 1) then
      p:change_state("stand")
    elseif read_bm(bm, 0) and p.map_x > 0 then
      p.direction = 0 
      p.map_x -= p.blocked != true and 1 or 0
      p.vx = (player.draw_x >= 63 and player.draw_x <= 65) and -1 or 0
    elseif read_bm(bm, 1) and p.map_x < (map_extent - 8) then
      p.direction = 1
      p.map_x += p.blocked != true and 1 or 0
      p.vx = (player.draw_x >= 63 and player.draw_x <= 65) and 1 or 0
    end

    local filtered = bm & p.allowed_inputs
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
  end,
  pantic = function(p, dt)
    if p.since_last_state > p.state_ttl then
      p:change_state("punch")
    end
  end,
  pantic_od = function(p, dt)
    if p.since_last_state > p.state_ttl then
      p:change_state("punch_od")
      sfx(8)
    end
  end,
  kantic = function(p, dt)
    if p.since_last_state > p.state_ttl then
      p:change_state("kick")
    end
  end,
  kantic_od = function(p, dt)
    if p.since_last_state > p.state_ttl then
      p:change_state("kick_od")
      sfx(8)
    end
  end,
  punch = function(p, dt)
    if p.since_last_state > p.state_ttl then
      p:change_state("stand")
    end
  end,
  punch_od = function(p, dt)

    if p.since_last_state > p.state_ttl then
      -- p.draw_x += (p.direction == 0 and 2 or 6)
      -- p:set_draw_x(p.direction == 0 and p.draw_x + 2 or p.draw_x + 6)
      p:set_draw_x(p.direction == 0 and p.draw_x + 2 or p.draw_x + 6)
      p:change_state("stand")
    end

    -- spawn projectile here...
    if #player_projectiles == 0 then
      local start_x = (p.direction == 0 and p.draw_x-8 or p.draw_x + 16)
      add_projectile(start_x,start_x,p.direction,p.draw_y+5,p.draw_y+13,p.timings.punch_od + 0.01,"punch")
    end
  end,
  kick = function(p, dt)

    if p.since_last_state > p.state_ttl then
      p:change_state("stand")
    end
  end,
  kick_od = function(p, dt)

    if p.since_last_state > p.state_ttl then
      p:set_draw_x(p.direction == 0 and p.draw_x+2 or p.draw_x+6)
      p:change_state("stand")
    end

    -- spawn projectile here...
    if #player_projectiles == 0 then
      local start_x = {
        (p.direction == 0 and p.draw_x-7 or p.draw_x-5),
        (p.direction == 0 and p.draw_x+13 or p.draw_x + 15),
      }
      for i=1,2 do
        add_projectile(start_x[i], start_x[i], (i == 1 and 0 or 1),p.draw_y+5,p.draw_y+8,p.timings.punch_od + 0.01,"kick")
      end
    end
  end,

  crouch = function(p, dt, bm)
    local filtered = bm & p.allowed_inputs
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
    if not read_bm(bm, 3) then
      p:change_state("stand")
      p.draw_y = p_draw_y_stand
    end
    if read_bm(bm, 0) then
      p.direction = 0
    end
    if read_bm(bm, 1) then
      p.direction = 1
    end
  end,
  cpantic = function(p, dt)

    if p.since_last_state > p.state_ttl then
      p:change_state("cpunch")
    end
  end,
  ckantic = function(p, dt)

    if p.since_last_state > p.state_ttl then
      p:change_state("ckick")
    end
  end,
  ckantic_od = function(p, dt)

    if p.since_last_state > p.state_ttl then
      p:set_draw_x((p.direction == 0 and p.draw_x-4 or p.draw_x-4))
      p:change_state("ckick_od")
      sfx(8)
    end
  end,
  cpunch = function(p, dt)


    if p.since_last_state > p.state_ttl then
      p:change_state("crouch")
    end
  end,
  ckick = function(p, dt)


    if p.since_last_state > p.state_ttl then
      p:change_state("crouch")
    end
  end,
  ckick_od = function(p, dt)


    if p.since_last_state > p.state_ttl then
      p:set_draw_x((p.direction == 0 and p.draw_x + 4 or p.draw_x + 4))
      p:change_state("crouch")
    end

    -- spawn projectile here...
    if #player_projectiles == 0 then
      local start_x = {
        (p.direction == 0 and p.draw_x-5 or p.draw_x - 6),
        (p.direction == 0 and p.draw_x+14 or p.draw_x + 13),
      }
      for i=1,2 do
        add_projectile(start_x[i], start_x[i], (i == 1 and 0 or 1),p.draw_y+7,p.draw_y+10,p.timings.punch_od + 0.01,"kick")
      end
    end
  end,
  dead = function(p, dt, bm)
    p.draw_x += p.vx
    p.draw_y += p.vy
    p.vx *= 0.8
    p.vy = min(p.vy + 0.5, 10)
  end,
  hugged = function(p, dt, bm, bmp)
    -- deduct some health in here
    if p.state != "stand" and p.state != "crouch" and p.state != "hugged" then
      return
    end

    p:deduct_health(ceil(dt * p.hugged_by_count * 10), false)

    if p.hugged_by_count == 0 then
      p:change_state("stand")
      return
    end

    if read_bm(bm, 0) then
      p.direction = 0
    elseif read_bm(bm, 1) then
      p.direction = 1
    end

    if read_bm(bm, 3) and p.frames_current == p.frames["stand"] then
      p.draw_y = p_draw_y_crouch
      p.frames_current = p.frames["crouch"]
      return
    elseif not read_bm(bm, 3) and p.frames_current == p.frames["crouch"] then
      p.frames_current = p.frames["stand"]
      p.draw_y = p_draw_y_stand
      return
    end

    local filtered = bmp & p.allowed_inputs
    if filtered & (1 << 4) > 0 then
      p.mash_count += 1
      -- 101111 = 47
      p.allowed_inputs &= ~(1 << 4) -- 111111 & 101111
    elseif filtered & (1 << 5) > 0 then
      p.mash_count += 1
      p.allowed_inputs &= ~(1<<5)
    end

    if p.mash_count > p.hugged_by_count then
      p:change_state("unmash")
      bmgr:kill_huggers()
      p.mash_count = 0
      p.draw_y = p_draw_y_stand
      if p.direction == 1 then
        p.draw_x -= 3
      end
      sfx(6)
      return
    end
  end,
  unmash = function(p, dt)
    if p.since_last_state > p.state_ttl then
      if p.direction == 1 then
        p.draw_x += 3
      end
      p:change_state("stand")
    end
  end,
  victory = function(p, dt)
  end,
}

-- simulating btn / btnp
function read_bm(bm, idx)
  return (bm & (1 << idx)) > 0
end

function add_projectile(hx,tx,dir,topy,boty,ttl,typ)
  add(player_projectiles, {head_x=hx, tail_x=tx, direction=dir,top_y=topy,bottom_y=boty,ttl=ttl,t=typ})
end
