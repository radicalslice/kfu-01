PART_MAX_G = 5
GRAV = 0
  function new_part(x, y, vx, vy, colors, start_size, ttl)
    local newP = {
      colors = colors,
      x = x,
      y = y,
      ttl = ttl,
      max_ttl = ttl,
      size = start_size,
      max_size = start_size,
    }
    newP.vel_x = sin(rnd()) * vx
    newP.vel_y = cos(rnd()) * vy

    newP.draw = function(p)
        -- {5,6,8,9,14,14}
        -- {dark grey, light grey, red, orange, pink, pink}
        local idx = (p.ttl * #p.colors) \ p.max_ttl

        circfill(
          p.x,
          p.y,
          p.size,
          p.colors[idx + 1]
        )
    end

    newP.update = function(p, dt)
      p.y += p.vel_y
      p.vel_y = p.vel_y * 0.8

      p.x += p.vel_x  
      p.vel_x = p.vel_x * 0.8
      
      p.ttl -= dt

      p.size = (p.ttl * p.max_size) \ p.max_ttl
    end

    return newP
  end
