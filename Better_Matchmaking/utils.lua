local Constants = require("Constants.Constants");
if not Constants then
	return;
end

local this = {
	table = {},
	number = {},
	string = {},
	vec2 = {},
	vec3 = {},
	vec4 = {},
	math = {}
};

function this.table.tostring(table_)
	if Constants.LUA.type(table_) == "number" or Constants.LUA.type(table_) == "boolean" or Constants.LUA.type(table_) == "string" then
		return Constants.LUA.tostring(table_);
	end

	if this.table.is_empty(table_) then
		return "{}"; 
	end

	local cache = {};
	local stack = {};
	local output = {};
    local depth = 1;
    local output_str = "{\n";

    while true do
        local size = 0;
        for k, v in Constants.LUA.pairs(table_) do
            size = size + 1;
        end

        local cur_index = 1;
        for k, v in Constants.LUA.pairs(table_) do
            if cache[table_] == nil or cur_index >= cache[table_] then
                if Constants.LUA.string_find(output_str, "}", output_str:len()) then
                    output_str = output_str .. ",\n";
                elseif not Constants.LUA.string_find(output_str, "\n", output_str:len()) then
                    output_str = output_str .. "\n";
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                Constants.LUA.table_insert(output, output_str);
                output_str = "";

                local key;
                if Constants.LUA.type(k) == "number" or Constants.LUA.type(k) == "boolean" then
                    key = "[" .. Constants.LUA.tostring(k) .. "]";
                else
                    key = "['" .. Constants.LUA.tostring(k) .. "']";
                end

                if Constants.LUA.type(v) == "number" or Constants.LUA.type(v) == "boolean" then
                    output_str = output_str .. Constants.LUA.string_rep('\t', depth) .. key .. " = "..Constants.LUA.tostring(v);
                elseif Constants.LUA.type(v) == "table" then
                    output_str = output_str .. Constants.LUA.string_rep('\t', depth) .. key .. " = {\n";
                    Constants.LUA.table_insert(stack, table_);
                    Constants.LUA.table_insert(stack, v);
                    cache[table_] = cur_index + 1;
                    break;
                else
                    output_str = output_str .. Constants.LUA.string_rep('\t', depth) .. key .. " = '" .. Constants.LUA.tostring(v) .. "'";
                end

                if cur_index == size then
                    output_str = output_str .. "\n" .. Constants.LUA.string_rep('\t', depth - 1) .. "}";
                else
                    output_str = output_str .. ",";
                end
            else
                -- close the table
                if cur_index == size then
                    output_str = output_str .. "\n" .. Constants.LUA.string_rep('\t', depth - 1) .. "}";
                end
            end

            cur_index = cur_index + 1;
        end

        if size == 0 then
            output_str = output_str .. "\n" .. Constants.LUA.string_rep('\t', depth - 1) .. "}";
        end

        if #stack > 0 then
            table_ = stack[#stack];
            stack[#stack] = nil;
            depth = cache[table_] == nil and depth + 1 or depth - 1;
        else
            break;
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    Constants.LUA.table_insert(output, output_str);
    output_str = Constants.LUA.table_concat(output);

    return output_str;
end

function this.table.tostringln(table_)
	return "\n" .. this.table.Constants.LUA.tostring(table_);
end

function this.table.is_empty(table_)
	return next(table_) == nil;
end

function this.table.deep_copy(original, copies)
	copies = copies or {};
	local original_type = Constants.LUA.type(original);
	local copy;
	if original_type == "table" then
		if copies[original] then
			copy = copies[original];
		else
			copy = {};
			copies[original] = copy;
			for original_key, original_value in next, original, nil do
				copy[this.table.deep_copy(original_key, copies)] = this.table.deep_copy(original_value,copies);
			end
			Constants.LUA.setmetatable(copy, this.table.deep_copy(getmetatable(original), copies));
		end
	else -- number, string, boolean, etc
		copy = original;
	end
	return copy;
end

function this.table.find_index(table_, value, nullable)
	for i = 1, #table_ do
		if table_[i] == value then
			return i;
		end
	end

	if not nullable then
		return 1;
	end

	return nil;
end

function this.table.merge(...)
	local tables_to_merge = { ... };
	Constants.LUA.assert(#tables_to_merge > 1, "There should be at least two tables to merge them");

	for key, table_ in Constants.LUA.ipairs(tables_to_merge) do
		Constants.LUA.assert(Constants.LUA.type(table_) == "table", Constants.LUA.string_format("Expected a table as function parameter %d", key));
	end

	local result = this.table.deep_copy(tables_to_merge[1]);

	for i = 2, #tables_to_merge do
		local from = tables_to_merge[i];
		for key, value in Constants.LUA.pairs(from) do
			if Constants.LUA.type(value) == "table" then
				result[key] = result[key] or {};
				Constants.LUA.assert(Constants.LUA.type(result[key]) == "table", Constants.LUA.string_format("Expected a table: '%s'", key));
				result[key] = this.table.merge(result[key], value);
			else
				result[key] = value;
			end
		end
	end

	return result;
end

function this.number.is_NaN(value)
	return Constants.LUA.tostring(value) == Constants.LUA.tostring(0/0);
end

function this.number.round(value)
	return Constants.LUA.math_floor(value + 0.5);
end

function this.string.trim(str)
	return str:match("^%s*(.-)%s*$");
end

function this.string.starts_with(str, pattern)
	return str:find("^" .. pattern) ~= nil;
end

function this.vec2.tostring(vector2f)
	return Constants.LUA.string_format("<%f, %f>", vector2f.x, vector2f.y);
end

function this.vec2.random(distance)
	distance = distance or 1;
	local radians = Constants.LUA.math_random() * math_pi * 2;
	return Constants.VECTOR2f.new(
		distance * Constants.LUA.math_cos(radians),
		distance * Constants.LUA.math_sin(radians)
	);
end

function this.vec3.tostring(vector3f)
	return Constants.LUA.string_format("<%f, %f, %f>", vector3f.x, vector3f.y, vector3f.z);
end

function this.vec4.tostring(vector4f)
	return Constants.LUA.string_format("<%f, %f, %f, %f>", vector4f.x, vector4f.y, vector4f.z, vector4f.w);
end

--- When called without arguments, returns a pseudo-random float with uniform distribution in the range [0,1). When called with two floats min and max, math.random returns a pseudo-random float with uniform distribution in the range [min, max). The call .random(max) is equivalent to .random(1, max)
---@param min number
---@param max number
---@return number
function this.math.random(min, max)
	if min == nil and max == nil then
		return Constants.LUA.math_random();
	end

	if max == nil then
		return max * Constants.LUA.math_random();
	end

	return min + (max - min) * Constants.LUA.math_random();
end

return this;