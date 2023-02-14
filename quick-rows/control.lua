local function generate_entities(count, pad, fields)
  local proto = game.entity_prototypes[fields.name]
  local side = fields.direction % 4 > 0 and proto.tile_width or proto.tile_height

  if fields.name == 'locomotive' or fields.name:match('-wagon$') then
    -- TODO api request for connection_distance + joint_distance
    side = 7
  end

  local entities = {}
  for i = 1, count do
    local entity = {
      entity_number = i,
      position = {0, i * (side + pad)},
    }
    for k, v in pairs(fields) do
      entity[k] = v
    end
    table.insert(entities, entity)
  end
  entities[1].tags = {pad = pad}

  return entities
end

local function update(e, change)
  local player = game.get_player(e.player_index)
  local stack = player.cursor_stack
  if not stack.valid_for_read then return end

  local n = change.count and change.count or 0
  local dir = change.direction and change.direction or 0
  local pad = change.pad and change.pad or 0

  local count, fields
  if player.is_cursor_blueprint() then
    local entities = stack.get_blueprint_entities()
    if not entities then return end
    pad = pad + (stack.get_blueprint_entity_tag(1, "pad") or 0)
    if pad < 0 then return end
    count = #entities + n
    local first = entities[1]
    fields = {
      name = first.name,
      direction = ((first.direction or 0) + dir) % 8,
      items = first.items,
      recipe = first.recipe
    }
  else
    count = 1 + n
    -- TODO api request for stack direction
    fields = {
      name = stack.name,
      direction = 0
    }
  end

  local proto = game.entity_prototypes[fields.name]
  if count < 1
    or not proto
    or not proto.flags["player-creation"]
    or proto.flags["not-blueprintable"]
    then return
  end

  if not player.is_cursor_blueprint() then
    player.clear_cursor()
    stack.set_stack('blueprint')
  end

  local entities = generate_entities(count, pad, fields)
  stack.set_blueprint_entities(entities)
  stack.label = tostring(#entities)
  player.cursor_stack_temporary = true
end

script.on_event("qr-decrease", function(e) update(e, {count = -1}) end)
script.on_event("qr-increase", function(e) update(e, {count =  1}) end)
script.on_event("qr-pad-decrease", function(e) update(e, {pad = -1}) end)
script.on_event("qr-pad-increase", function(e) update(e, {pad =  1}) end)
script.on_event("qr-rotate", function(e) update(e, {direction = 2}) end)
