local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end

local this = {
	is_opened = false,
	status = "OK",

	window_position = Constants.VECTOR2f.new(480, 200),
	window_pivot = Constants.VECTOR2f.new(0, 0),
	window_size = Constants.VECTOR2f.new(535, 480),
	window_flags = 0x10120,

	color_picker_flags = 327680,
	decimal_input_flags = 33,

	region_lock_filters = {"Close", "Default", "Far", "Worldwide"}
};
local utils;
local config;

function this.draw()
	Constants.IMGUI.set_next_window_pos(this.window_position, 1 << 3, this.window_pivot);
	Constants.IMGUI.set_next_window_size(this.window_size, 1 << 3);

	this.is_opened = imgui.begin_window("Better Matchmaking v" .. config.current_config.version, this.is_opened, this.window_flags);

	if not this.is_opened then
		Constants.IMGUI.end_window();
		return;
	end

	Constants.IMGUI.text("Status: " .. Constants.LUA.tostring(this.status));

	if Constants.IMGUI.tree_node("Timeout Fix") then
		local config_changed = false;
		config_changed, config.current_config.timeout_fix.enabled = Constants.IMGUI.checkbox("Enabled", config.current_config.timeout_fix.enabled);
		if Constants.IMGUI.tree_node("Quest Types") then
			local changed = false;
			changed, config.current_config.timeout_fix.quest_types.regular = Constants.IMGUI.checkbox("Regular", config.current_config.timeout_fix.quest_types.regular);
			config_changed = config_changed or changed;
			changed, config.current_config.timeout_fix.quest_types.rampage = Constants.IMGUI.checkbox("Rampage", config.current_config.timeout_fix.quest_types.rampage);
			config_changed = config_changed or changed;
			changed, config.current_config.timeout_fix.quest_types.random = Constants.IMGUI.checkbox("Random", config.current_config.timeout_fix.quest_types.random);
			config_changed = config_changed or changed;
			changed, config.current_config.timeout_fix.quest_types.random_master_rank = Constants.IMGUI.checkbox("Random MR", config.current_config.timeout_fix.quest_types.random_master_rank);
			config_changed = config_changed or changed;
			changed, config.current_config.timeout_fix.quest_types.random_anomaly = Constants.IMGUI.checkbox("Random Anomaly", config.current_config.timeout_fix.quest_types.random_anomaly);
			config_changed = config_changed or changed;
			changed, config.current_config.timeout_fix.quest_types.anomaly_investigation = Constants.IMGUI.checkbox("Anomaly Investigation", config.current_config.timeout_fix.quest_types.anomaly_investigation);
			config_changed = config_changed or changed;
			Constants.IMGUI.tree_pop();
		end
		Constants.IMGUI.tree_pop();
		if config_changed then
			config.save();
		end
	end

	if Constants.IMGUI.tree_node("Region Lock Fix (Join Requests)") then
		local config_changed = false;
		config_changed, config.current_config.region_lock_fix.enabled = Constants.IMGUI.checkbox("Enabled", config.current_config.region_lock_fix.enabled);
		local changed, index = Constants.IMGUI.combo("Distance Filter", utils.table.find_index(this.region_lock_filters, config.current_config.region_lock_fix.distance_filter), this.region_lock_filters);
		config_changed = config_changed or changed;
		if changed then
			config.current_config.region_lock_fix.distance_filter = this.region_lock_filters[index];
		end

		if Constants.IMGUI.tree_node("Explanation") then
			--k_ELobbyDistanceFilterClose	0	Only lobbies in the same immediate region will be returned.
			--k_ELobbyDistanceFilterDefault	1	Only lobbies in the same region or nearby regions will be returned.
			--k_ELobbyDistanceFilterFar	2	For games that don't have many latency requirements, will return lobbies about half-way around the globe.
			--k_ELobbyDistanceFilterWorldwide	3	No filtering, will match lobbies as far as India to NY (not recommended, expect multiple seconds of latency between the clients).

			Constants.IMGUI.text("Close - Only quest sessions in the same immediate region will be returned.");
			Constants.IMGUI.text("Default - Only quest sessions in the same region or nearby regions will be returned.");
			Constants.IMGUI.text("Far - Will return quest sessions about half-way around the globe.");
			Constants.IMGUI.text("Worldwide - No filtering, will match quest sessions as far as India to NY");
			Constants.IMGUI.text("(not recommended, expect multiple seconds of latency between the clients).");
			Constants.IMGUI.tree_pop();
		end
		Constants.IMGUI.tree_pop();
		if config_changed then
			config.save();
		end
	end

	if Constants.IMGUI.tree_node("Hide Network Errors") then
		local config_changed = false;
		config_changed, config.current_config.hide_network_errors.enabled = Constants.IMGUI.checkbox("Enabled", config.current_config.hide_network_errors.enabled);
		if Constants.IMGUI.tree_node("When to hide") then
			local changed = false;
			changed, config.current_config.hide_network_errors.when_to_hide.on_quests = Constants.IMGUI.checkbox("On Quests", config.current_config.hide_network_errors.when_to_hide.on_quests);
			config_changed = config_changed or changed;
			changed, config.current_config.hide_network_errors.when_to_hide.outside_quests = Constants.IMGUI.checkbox("Outside Quests", config.current_config.hide_network_errors.when_to_hide.outside_quests);
			config_changed = config_changed or changed;
			Constants.IMGUI.tree_pop();
		end
		Constants.IMGUI.tree_pop();
		if config_changed then
			config.save();
		end
	end

	if Constants.IMGUI.tree_node("Misc") then
		local config_changed = false;
		config_changed, config.current_config.hide_online_warning.enabled = Constants.IMGUI.checkbox("Hide Online Warning", config.current_config.hide_online_warning.enabled);
		Constants.IMGUI.tree_pop();
		if config_changed then
			config.save();
		end
	end
	Constants.IMGUI.end_window();
end

function this.init_module()
	utils = require("Better_Matchmaking.utils");
	config = require("Better_Matchmaking.config");
end

return this;
