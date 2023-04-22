local this = {};
local version = "2.3.2";

local utils;

local json = json;
local jsonAvailable = json ~= nil;
local json_load_file = jsonAvailable and json.load_file or nil;
local json_dump_file = jsonAvailable and json.dump_file or nil;

local require = require;

this.current_config = nil;
this.config_file_name = "Better Matchmaking/config.json";

this.default_config = {};

function this.init()
	this.default_config = {
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
			enabled = true,
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

function this.load()
	if json_load_file then
		local loaded_config = json_load_file(this.config_file_name);
		if loaded_config ~= nil then
			this.current_config = utils.table.merge(this.default_config, loaded_config);
		else
			this.current_config = utils.table.deep_copy(this.default_config);
		end
	end
end

function this.save()
	if json_dump_file then
		json_dump_file(this.config_file_name, this.current_config);
	end
end

function this.reset()
	this.current_config = utils.table.deep_copy(this.default_config);
	this.current_config.version = version;
end

function this.init_module()
	utils = require("Better_Matchmaking.utils");

	this.init();
	this.load();
	this.current_config.version = version;
end

return this;
