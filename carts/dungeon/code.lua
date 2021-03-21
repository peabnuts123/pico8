-- Constants
local COLOR = {
  BLACK = 0,
  DARK_BLUE = 1,
  DARK_PURPLE = 2,
  DARK_GREEN = 3,
  BROWN = 4,
  DARK_GREY = 5,
  LIGHT_GREY = 6,
  WHITE = 7,
  RED = 8,
  ORANGE = 9,
  YELLOW = 10,
  GREEN = 11,
  BLUE = 12,
  LAVENDER = 13,
  PINK = 14,
  LIGHT_PEACH = 15,
}

-- Config
local area_width = 1000
local area_height = 300
local grid_size = 30
local camera_speed = 2
local num_points = 50
local point_dead_zone = 40
local cave_lerp_interval = 20
local cave_size = 20
local cave_max_wander_fluctuation = 10
local cave_max_size_fluctuation = 10

-- State
local camera_x = 0
local camera_y = 0
local points = {}
local point_connections = {}

-- Functions
function vec2(x, y)
  return { x = x, y = y }
end

function rnd_vec2(x_max, y_max, x_min, y_min)
  x_min = x_min or 0
  y_min = y_min or 0
  return vec2(rnd(x_max - x_min) + x_min, rnd(y_max - y_min) + y_min)
end

function vec2_length(vector)
  -- Scale down vector components to compute larger lengths
  local c = max(abs(vector.x), abs(vector.y))
  local x = vector.x / c
  local y = vector.y / c

  return sqrt(x*x + y*y) * c
end

function point_distance(p1, p2)
  local delta = vec2(p2.x - p1.x, p2.y - p1.y)
  return vec2_length(delta)
end

function point_to_str(p)
  return "x=" .. p.x .. ", y=" .. p.y
end

function generate_points()
  points = {}

  local max_num_retries = 5
  local max_num_loops = num_points * 5
  local current_num_loops = 0
  local current_num_retries = 0

  -- Attempt to generate `num_points` points that are at
  -- least `point_distance` away from each other.
  -- Point generation may produce a scenario where this is impossible,
  --  so only attempt to do so `max_num_loops` times.
  -- If generation fails, it will be retried, up to a maxium of
  --  `max_num_retries` times
  while (#points < num_points and current_num_retries < max_num_retries) do
    points = {}

    -- Generate points list
    while (#points < num_points) do
      -- Roll new point
      local new_point = rnd_vec2(area_width, area_height)

      -- Check that new point is not too close to another point
      local too_close = false
      for p in all(points) do
        if (point_distance(p, new_point) < point_dead_zone) then
          too_close = true
          break
        end
      end

      -- Add to points table if valid
      if not too_close then
        add(points, new_point)
      end

      -- Ensure point generation does not go on too long
      current_num_loops += 1
      if (current_num_loops >= max_num_loops) then
        break
      end
    end -- while

    -- Ensure point generation does not go on too long
    if (#points < num_points) then
      -- Need to retry
      current_num_retries += 1
      assert(current_num_retries >= max_num_retries, "could not generate valid points after " .. max_num_retries .. " retries")
    end
  end -- while
end

function generate_connections()
  point_connections = {}

  -- don't even try if there's no other points to compare
  if (#points <= 1) then return end

  local processed_points = {
    points[flr(rnd(#points)) + 1],
  }
  -- pick a random starting point
  local sanity_counter = 0
  while #processed_points < #points do
    -- find nearest point to processed_points
    local nearest_distance = 0x7fff
    local nearest_index = -1
    local nearest_processed_index = -1
    for i=1,#points do
      local p_current = points[i]

      -- ensure `current_point` is not in `processed_points`
      local is_already_processed = false
      for p_processed in all(processed_points) do
        if (p_current == p_processed) then
          is_already_processed = true
        end
      end
      if (not is_already_processed) then
        -- point is not yet processed
        -- compare distance to all processed points
        -- for p_processed in all(processed_points) do
        for j=1,#processed_points do
          local p_processed = processed_points[j]
          local distance = point_distance(p_current, p_processed)
          if (distance < nearest_distance) then
            nearest_distance = distance
            nearest_index = i
            nearest_processed_index = j
          end
        end
      end
    end

    -- sanity check
    assert(nearest_index ~= -1, "could not generate connections. no nearest point?")

    -- store connection between new point and processed point
    add(point_connections, {
      a = points[nearest_index],
      b = processed_points[nearest_processed_index],
    })
    -- mark new point as processed
    add(processed_points, points[nearest_index])

    -- sanity check to prevent infinite loop
    sanity_counter += 1
    assert(sanity_counter < 200, "too many iterations trying to generate connections")
  end
end

-- Lifecycle
function _init()
  cls()

  generate_points()
  generate_connections()
end

function _update60()
  if btn(⬅️) then
    camera_x -= camera_speed
  end
  if btn(➡️) then
    camera_x += camera_speed
  end
  if btn(⬆️) then
    camera_y -= camera_speed
  end
  if btn(⬇️) then
    camera_y += camera_speed
  end

  if btnp(❎) then
    generate_points()
    generate_connections()
  end
end

function _draw()
  cls()

  camera(camera_x, camera_y)

  -- fill area with "dirt"
  fillp(0x5A5C)
  rectfill(0, 0, area_width, area_height, COLOR.BROWN)
  fillp()

  -- carve out "caves"
  local old_srand = rnd()
  srand(42)
  for connection in all(point_connections) do
    -- manually draw at start / end
    circfill(connection.a.x, connection.a.y, cave_size, COLOR.BLACK)
    circfill(connection.b.x, connection.b.y, cave_size, COLOR.BLACK)

    local connection_vector = vec2(connection.b.x - connection.a.x, connection.b.y - connection.a.y)
    local connection_length = vec2_length(connection_vector)
    -- draw circles at regular intervals along the connection
    for i=cave_lerp_interval,connection_length,cave_lerp_interval do
      local p = vec2(
        connection.a.x + (connection_vector.x * (i / connection_length)) + rnd(cave_max_wander_fluctuation),
        connection.a.y + (connection_vector.y * (i / connection_length)) + rnd(cave_max_wander_fluctuation)
      )
      circfill(p.x, p.y, cave_size + rnd(cave_max_size_fluctuation), COLOR.BLACK)
    end
  end
  srand(old_srand)

  -- draw background grid
  for x=0,area_width,grid_size do
    line(x, 0, x, area_height, COLOR.DARK_GREY)
  end
  for y=0,area_height,grid_size do
    line(0, y, area_width, y)
  end
  rect(0, 0, area_width, area_height, COLOR.RED)

  -- draw point connections
  -- for connection in all(point_connections) do
  --   line(connection.a.x, connection.a.y, connection.b.x, connection.b.y, COLOR.LIGHT_GREY)
  -- end
  -- -- draw points
  -- for p in all(points) do
  --   circ(p.x, p.y, 2, COLOR.RED)
  -- end

  -- draw ui
  camera() -- unset camera offset

  print("cpu: " .. (stat(1) * 100) .. "%", 10, 10, COLOR.WHITE)
  print("fps: " .. stat(7), 10, 20, COLOR.WHITE)
end
