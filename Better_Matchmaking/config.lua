local require = require;

local this = {
	current_config = nil,
	config_file_name = "Better Matchmaking/config.json",
	default_config = {}
};
local version = "2.3.2";

local utils;

local json = json;

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

function this.load()
	local loaded_config = json.load_file(this.config_file_name);
	if loaded_config ~= nil then
		this.current_config = utils.table.merge(this.default_config, loaded_config);
	else
		this.current_config = utils.table.deep_copy(this.default_config);
	end
end

function this.save()
	json.dump_file(this.config_file_name, this.current_config);
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
