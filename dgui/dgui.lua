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

local components = {}

local action_ids = {
	button_left = hash("button_left")
}

dgui.component = {
	button = 1
}

----------------------------------------------------------------------
-- FUNCTIONS
----------------------------------------------------------------------

function dgui.add_component(component, node_id, enabled, callback, group, data)
	components[node_id] = {
		component = component,
		node_id = node_id,
		enabled = enabled,
		callback = callback,
		group = group,
		data = data,
		state = {
			just_pressed = false,
			just_hovered = false,
			just_released = false,
			just_exited = false,
			is_pressed = false,
			is_hovered = false
		}
	}
end

function dgui.remove_group(group)
	for key, value in pairs(components) do
		if value.group == group then
			components[key] = nil
		end
	end
end

function dgui.set_node_enabled(node_id, enabled)
	components[node_id].enabled = enabled
end

function dgui.set_group_enabled(group, enabled)
	for _, value in pairs(components) do
		if value.group == group then
			value.enabled = enabled
		end
	end
end

function dgui.set_action_ids(button_left)
	action_ids.button_left = button_left
end

function dgui.on_input(action_id, action)
	for key, value in pairs(components) do
		local success, result = pcall(gui.get_node, key)
		if success then
			if gui.pick_node(result, action.x, action.y) then
				value.state.just_hovered = not value.state.is_hovered
				value.state.is_hovered = true
				if value.component == dgui.component.button then
					if action_id == action_ids.button_left then
						value.state.just_pressed = action.pressed
						value.state.just_released = action.released
						value.state.is_pressed = action.value == 1
					end
				end
			else
				value.state.just_exited = value.state.is_hovered
				value.state.is_pressed = false
				value.state.is_hovered = false
			end
		end
		if value.enabled and value.callback then
			value.callback(value.state, value.node_id, value.data)
		end
		value.state.just_pressed = false
		value.state.just_hovered = false
		value.state.just_released = false
		value.state.just_exited = false
	end
end

return dgui