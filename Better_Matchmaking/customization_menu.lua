local imgui = imgui;
local imgui_button = imgui.button;
local imgui_set_next_window_pos = imgui.set_next_window_pos;
local imgui_set_next_window_size = imgui.set_next_window_size;
local imgui_begin_window = imgui.begin_window;
local imgui_end_window = imgui.end_window;
local imgui_text = imgui.text;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_pop = imgui.tree_pop;
local imgui_combo = imgui.combo;

local Vector2f = Vector2f;
local Vector2f_new = Vector2f.new;

local tostring = tostring;
local require = require;

local customization_menu = {};

local table_helpers;
local config;

customization_menu.is_opened = false;
customization_menu.status = "OK";

customization_menu.window_position = Vector2f_new(480, 200);
customization_menu.window_pivot = Vector2f_new(0, 0);
customization_menu.window_size = Vector2f_new(500, 480);
customization_menu.window_flags = 0x10120;

customization_menu.color_picker_flags = 327680;
customization_menu.decimal_input_flags = 33;

customization_menu.region_lock_filters = { "Close", "Default", "Far", "Worldwide" };

function customization_menu.draw()
	imgui_set_next_window_pos(customization_menu.window_position, 1 << 3, customization_menu.window_pivot);
	imgui_set_next_window_size(customization_menu.window_size, 1 << 3);

	if imgui_button("Better Matchmaking v" .. config.current_config.version) then
		customization_menu.is_opened = true;
	end

	if customization_menu.is_opened then
		local changed = false;
		if imgui_begin_window("Better Matchmaking v" .. config.current_config.version, true, customization_menu.window_flags) then
			local status_string = tostring(customization_menu.status);
			imgui_text("Status: " .. status_string);

			local index = 1;

			if imgui_tree_node("Timeout Fix") then
				changed, config.current_config.timeout_fix.enabled = imgui_checkbox("Enabled", config.current_config.timeout_fix.enabled);
				if imgui_tree_node("Quest Types") then
					changed, config.current_config.timeout_fix.quest_types.regular = imgui_checkbox("Regular", config.current_config.timeout_fix.quest_types.regular);
					changed, config.current_config.timeout_fix.quest_types.rampage = imgui_checkbox("Rampage", config.current_config.timeout_fix.quest_types.rampage);
					changed, config.current_config.timeout_fix.quest_types.random = imgui_checkbox("Random", config.current_config.timeout_fix.quest_types.random);
					changed, config.current_config.timeout_fix.quest_types.random_master_rank = imgui_checkbox("Random MR", config.current_config.timeout_fix.quest_types.random_master_rank);
					changed, config.current_config.timeout_fix.quest_types.random_anomaly = imgui_checkbox("Random Anomaly", config.current_config.timeout_fix.quest_types.random_anomaly);
					changed, config.current_config.timeout_fix.quest_types.anomaly_investigation = imgui_checkbox("Anomaly Investigation", config.current_config.timeout_fix.quest_types.anomaly_investigation);
					imgui_tree_pop();
				end
				imgui_tree_pop();
			end

			if imgui_tree_node("Region Lock Fix (Join Requests)") then
				local regionChanged = false;
				regionChanged, config.current_config.region_lock_fix.enabled = imgui_checkbox("Enabled", config.current_config.region_lock_fix.enabled);
				regionChanged, index = imgui_combo("Distance Filter", table_helpers.find_index(customization_menu.region_lock_filters, config.current_config.region_lock_fix.distance_filter), customization_menu.region_lock_filters);

				if regionChanged then
					config.current_config.region_lock_fix.distance_filter = customization_menu.region_lock_filters[index];
					config.save();
				end

				if imgui_tree_node("Explanation") then
					--k_ELobbyDistanceFilterClose	0	Only lobbies in the same immediate region will be returned.
					--k_ELobbyDistanceFilterDefault	1	Only lobbies in the same region or nearby regions will be returned.
					--k_ELobbyDistanceFilterFar	2	For games that don't have many latency requirements, will return lobbies about half-way around the globe.
					--k_ELobbyDistanceFilterWorldwide	3	No filtering, will match lobbies as far as India to NY (not recommended, expect multiple seconds of latency between the clients).

					imgui_text("Close - Only lobbies in the same immediate region will be returned.");
					imgui_text("Default - Only lobbies in the same region or nearby regions will be returned.");
					imgui_text("Far - Will return lobbies about half-way around the globe.");
					imgui_text("Worldwide - No filtering, will match lobbies as far as India to NY");
					imgui_text("(not recommended, expect multiple seconds of latency between the clients).");

					imgui_tree_pop();
				end

				imgui_tree_pop();
			end

			if imgui_tree_node("Hide Network Errors") then
				changed, config.current_config.hide_network_errors.enabled = imgui_checkbox("Enabled", config.current_config.hide_network_errors.enabled);
				if imgui_tree_node("When to hide") then
					changed, config.current_config.hide_network_errors.when_to_hide.on_quests = imgui_checkbox("On Quests", config.current_config.hide_network_errors.when_to_hide.on_quests);
					changed, config.current_config.hide_network_errors.when_to_hide.outside_quests = imgui_checkbox("Outside Quests", config.current_config.hide_network_errors.when_to_hide.outside_quests);
					imgui_tree_pop();
				end
				imgui_tree_pop();
			end

			if imgui_tree_node("Misc") then
				changed, config.current_config.hide_online_warning.enabled = imgui_checkbox("Hide Online Warning", config.current_config.hide_online_warning.enabled);
				imgui_tree_pop();
			end

			imgui_end_window();
		else
			customization_menu.is_opened = false;
			if changed then
				config.save();
			end
		end
	end
end

function customization_menu.init_module()
	table_helpers = require("Better_Matchmaking.table_helpers");
	config = require("Better_Matchmaking.config");
end

return customization_menu;
