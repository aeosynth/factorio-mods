local function generate_entities(count, name, fields)
  local box = game.entity_prototypes[name].collision_box
  local height = math.ceil(box.right_bottom.y - box.left_top.y)

  if name == 'locomotive' or name:match('-wagon$') then
    -- TODO api request for connection_distance + joint_distance
    height = 7
  end

  local entities = {}
  for i = 1, count do
    local entity = {
      name = name,
      entity_number = i,
      position = {0, i * height},
    }
    for k, v in pairs(fields) do
      entity[k] = v
    end
    table.insert(entities, entity)
  end
  return entities
end

local function update(e, n)
  local player = game.get_player(e.player_index)
  local stack = player.cursor_stack
  if not stack.valid_for_read then return end

  local count, name, fields
  if player.is_cursor_blueprint() then
    local entities = player.get_blueprint_entities()
    if not entities then return end
    count = #entities + n
    local first = entities[1]
    name = first.name
    fields = {
      recipe = first.recipe
    }
  else
    count = 1 + n
    name = stack.name
    fields = {}
  end
  if count < 1 or not game.entity_prototypes[name] then return end

  local entities = generate_entities(count, name, fields)
  player.clear_cursor()
  stack.set_stack('blueprint')
  stack.set_blueprint_entities(entities)
  stack.label = tostring(#entities)
  player.cursor_stack_temporary = true
end

script.on_event("qr-decrease", function(e) update(e, -1) end)
script.on_event("qr-increase", function(e) update(e,  1) end)
