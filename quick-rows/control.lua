local function generate_entities(count, name, recipe)
  local box = game.entity_prototypes[name].collision_box
  local height = math.ceil(box.right_bottom.y - box.left_top.y)

  local entities = {}
  for i = 1, count do
    table.insert(entities, {
      entity_number = i,
      name = name,
      position = {0, i * height},
      recipe = recipe,
    })
  end
  return entities
end

local function update(e, n)
  local player = game.get_player(e.player_index)
  local stack = player.cursor_stack
  if not stack.valid_for_read then return end

  local count, name, recipe
  if player.is_cursor_blueprint() then
    local entities = player.get_blueprint_entities()
    if not entities then return end
    count = #entities + n
    name = entities[1].name
    recipe = entities[1].recipe
  else
    count = 1 + n
    name = stack.name
  end
  if count < 1 or not game.entity_prototypes[name] then return end

  local entities = generate_entities(count, name, recipe)
  player.clear_cursor()
  stack.set_stack('blueprint')
  stack.set_blueprint_entities(entities)
  stack.label = tostring(#entities)
  player.cursor_stack_temporary = true
end

script.on_event("qr-decrease", function(e) update(e, -1) end)
script.on_event("qr-increase", function(e) update(e,  1) end)
