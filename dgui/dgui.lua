----------------------------------------------------------------------
-- LICENSE
----------------------------------------------------------------------

-- MIT License

-- Copyright (c) 2021 Klayton Kowalski

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- https://github.com/klaytonkowalski/defold-gui-handler

----------------------------------------------------------------------
-- PROPERTIES
----------------------------------------------------------------------

local dgui = {}

dgui.enabled = false

dgui.group = nil
dgui.groups = {}

dgui.input_bindings = {
	next = {},
	previous = {},
	select = {}
}

dgui.display_mode = nil
dgui.display_modes = {
	color = { idle = vmath.vector4(), selected = vmath.vector4() }
}

----------------------------------------------------------------------
-- FUNCTIONS
----------------------------------------------------------------------

local function make_transparent(color)
	return vmath.vector4(color.x, color.y, color.z, 0)
end

local function get_node_index(group, id)
	if dgui.groups[group] then
		for key, value in ipairs(dgui.groups[group].nodes) do
			if value.id == id then
				return key
			end
		end
	end
end

local function get_next_selectable_index(group)
	if dgui.groups[group] then
		local index = dgui.groups[group].index + 1
		while index ~= dgui.groups[group].index do
			if index > #dgui.groups[group].nodes then
				index = 1
			end
			if dgui.groups[group].nodes[index].selectable then
				return index
			end
			index = index + 1
		end
	end
end

local function get_previous_selectable_index(group)
	if dgui.groups[group] then
		local index = dgui.groups[group].index - 1
		while index ~= dgui.groups[group].index do
			if index < 1 then
				index = #dgui.groups[group].nodes
			end
			if dgui.groups[group].nodes[index].selectable then
				return index
			end
			index = index - 1
		end
	end
end

function dgui.set_enabled(enabled)
	dgui.enabled = enabled
end

function dgui.set_input_bindings(next, previous, select)
	for _, value in ipairs(next) do
		dgui.input_bindings.next[value] = true
	end
	for _, value in ipairs(previous) do
		dgui.input_bindings.previous[value] = true
	end
	for _, value in ipairs(select) do
		dgui.input_bindings.select[value] = true
	end
end

function dgui.set_display_mode(display_mode, arguments)
	if display_mode == dgui.display_modes.color then
		dgui.display_mode = display_mode
		dgui.display_modes.color.idle = arguments.idle
		dgui.display_modes.color.selected = arguments.selected
	end
end

function dgui.get_group()
	return dgui.group
end

function dgui.add_group(group)
	if not dgui.groups[group] then
		dgui.groups[group] = { nodes = {}, index = 1 }
	end
end

function dgui.remove_group(group)
	if dgui.groups[group] then
		-- todo: handle if group == dgui.group
		dgui.groups[group] = nil
	end
end

function dgui.set_group(group, reset)
	if dgui.group then
		if reset then
			dgui.groups[dgui.group].index = 1
		end
		local volatile_nodes = {}
		for key, value in ipairs(dgui.groups[dgui.group].nodes) do
			if dgui.display_mode == dgui.display_modes.color then
				gui.set_color(gui.get_node(value.id), make_transparent(dgui.display_mode.idle))
			end
			if value.volatile then
				table.insert(volatile_nodes, value.id)
			end
		end
		for _, value in ipairs(volatile_nodes) do
			dgui.remove_node(dgui.group, value)
		end
	end
	dgui.group = group
	if dgui.group then
		for key, value in ipairs(dgui.groups[dgui.group].nodes) do
			if dgui.display_mode == dgui.display_modes.color then
				gui.set_color(gui.get_node(value.id), key == dgui.groups[dgui.group].index and dgui.display_mode.selected or dgui.display_mode.idle)
			end
		end
	end
end

function dgui.get_node_id()
	return dgui.groups[dgui.group].nodes[dgui.groups[dgui.group].index].id
end

function dgui.add_node(group, id, selectable, volatile)
	if dgui.groups[group] and not get_node_index(group, id) then
		table.insert(dgui.groups[group].nodes, { id = id, selectable = selectable, volatile = volatile })
		if dgui.group == group then
			if dgui.display_mode == dgui.display_modes.color then
				gui.set_color(gui.get_node(id), dgui.display_mode.idle)
			end
		end
	end
end

function dgui.remove_node(group, id)
	local index = get_node_index(group, id)
	if dgui.groups[group] and index then
		if dgui.group == group then
			-- todo: correct group index and currently selected node if needed
			if dgui.display_mode == dgui.display_modes.color then
				gui.set_color(gui.get_node(id), make_transparent(dgui.display_mode.idle))
			end
		end
		table.remove(dgui.groups[group].nodes, index)
	end
end

function dgui.swap_nodes(group, id_1, id_2)
	local index_1 = get_node_index(group, id_1)
	local index_2 = get_node_index(group, id_2)
	if dgui.groups[group] and index_1 and index_2 then
		local swap = dgui.groups[group].nodes[index_1]
		dgui.groups[group].nodes[index_1] = dgui.groups[group].nodes[index_2]
		dgui.groups[group].nodes[index_2] = swap
		if dgui.group == group then
			dgui.set_group(dgui.group)
		end
	end
end

function dgui.on_input(action, action_id)
	if dgui.enabled then
		if action.pressed then
			if dgui.input_bindings.next[action_id] then
				if dgui.display_mode == dgui.display_modes.color then
					gui.set_color(gui.get_node(dgui.groups[dgui.group].nodes[dgui.groups[dgui.group].index].id), dgui.display_mode.idle)
					dgui.groups[dgui.group].index = get_next_selectable_index(dgui.group)
					gui.set_color(gui.get_node(dgui.groups[dgui.group].nodes[dgui.groups[dgui.group].index].id), dgui.display_mode.selected)
				end
			elseif dgui.input_bindings.previous[action_id] then
				if dgui.display_mode == dgui.display_modes.color then
					gui.set_color(gui.get_node(dgui.groups[dgui.group].nodes[dgui.groups[dgui.group].index].id), dgui.display_mode.idle)
					dgui.groups[dgui.group].index = get_previous_selectable_index(dgui.group)
					gui.set_color(gui.get_node(dgui.groups[dgui.group].nodes[dgui.groups[dgui.group].index].id), dgui.display_mode.selected)
				end
			elseif dgui.input_bindings.select[action_id] then
				if dgui.display_mode == dgui.display_modes.color then
					-- todo
				end
			end
		elseif action.released then
			-- todo
		end
	end
end

return dgui