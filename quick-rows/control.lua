local function generate_entities(count, name, fields)
  local height = game.entity_prototypes[name].tile_height

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

local function update(e, change)
  local player = game.get_player(e.player_index)
  local stack = player.cursor_stack
  if not stack.valid_for_read then return end

  local n = change.count and change.count or 0
  local dir = change.direction and change.direction or 0

  local count, name, fields
  if player.is_cursor_blueprint() then
    local entities = player.get_blueprint_entities()
    if not entities then return end
    count = #entities + n
    local first = entities[1]
    name = first.name
    fields = {
      direction = ((first.direction or 0) + dir) % 8,
      items = first.items,
      recipe = first.recipe
    }
  else
    count = 1 + n
    name = stack.name
    -- TODO api request for stack direction
    fields = {}
  end

  local proto = game.entity_prototypes[name]
  if count < 1
    or not proto
    or not proto.flags["player-creation"]
    or proto.flags["not-blueprintable"]
    then return
  end

  local entities = generate_entities(count, name, fields)
  player.clear_cursor()
  stack.set_stack('blueprint')
  stack.set_blueprint_entities(entities)
  stack.label = tostring(#entities)
  player.cursor_stack_temporary = true
end

script.on_event("qr-decrease", function(e) update(e, {count = -1}) end)
script.on_event("qr-increase", function(e) update(e, {count =  1}) end)
script.on_event("qr-rotate",   function(e) update(e, {direction = 2}) end)
