local json = json;
local json_load_file = nil;
local json_dump_file = nil;
local jsonAvailable = json ~= nil;
if jsonAvailable then
	json_load_file = json.load_file;
	json_dump_file = json.dump_file;
end

local require = require;

local config = {};
local table_helpers;

config.current_config = nil;
config.config_file_name = "Better Matchmaking/config.json";
config.default_config = {};

function config.init()
	config.default_config = {
		timeout_fix = {
			enabled = true,

			quest_types = {
				regular = true,
				random = true,
				rampage = true,
				random_master_rank = true,
				random_anomaly = true,
				anomaly_investigation = true
			}
		},

		hide_online_warning = {
			enabled = true
		},

		hide_network_errors = {
			enabled = true,
			when_to_hide = {
				on_quests = true,
				outside_quests = false
			}
		},

		region_lock_fix = {
			enabled = true,
			distance_filter = "Far"
		}
	};
end

function config.load()
	if jsonAvailable then
		local loaded_config = json_load_file(config.config_file_name);
		if loaded_config then
			config.current_config = table_helpers.merge(config.default_config, loaded_config);
		else
			config.current_config = table_helpers.deep_copy(config.default_config);
		end
	end
end

function config.save()
	if jsonAvailable then
		json_dump_file(config.config_file_name, config.current_config);
	end
end

function config.init_module()
	table_helpers = require("Better_Matchmaking.table_helpers");

	config.init();
	config.load();
	config.current_config.version = "2.3.1";
end

return config;
