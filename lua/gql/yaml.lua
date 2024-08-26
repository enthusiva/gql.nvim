local M = {}

local gql_params_yaml_file = "gql_config.yaml"

function M.setup(opts)
	gql_params_yaml_file = opts.gql_params_yaml_file
end

M.pretty_print_json = function(json_string)
	return vim.fn.system("echo '" .. json_string .. "' | yq -o=json -P")
end

local function load_yaml_params()
	local yaml_file = vim.fn.getcwd() .. "/" .. gql_params_yaml_file
	if vim.fn.filereadable(yaml_file) == 1 then
		-- Use yq to parse YAML file into JSON
		local yaml_content = vim.fn.system({ "yq", "-o=json", ".", yaml_file })
		-- Decode JSON content into Lua table
		return vim.fn.json_decode(yaml_content)
	end
	return nil
end

-- Function to extract the query name
local function extract_query_name(query)
	local query_name = query:match("query%s+(%w+)")
	return query_name
end

-- Function to replace placeholders in params with global variables and trim variable names
local function replace_globals(params, globals)
	for key, value in pairs(params) do
		if type(value) == "table" then
			-- Recursively replace globals in nested tables
			replace_globals(value, globals)
		elseif type(value) == "string" and value:match("{{(.-)}}") then
			-- Extract the global variable name from the placeholder and trim it
			local var_name = value:match("{{(.-)}}"):gsub("^%s*(.-)%s*$", "%1")
			if globals[var_name] then
				-- Replace placeholder with the corresponding global variable
				params[key] = globals[var_name]
			end
		end
	end
end
local function get_param_sets_for_query(query_name, yaml_params)
	if yaml_params and query_name and yaml_params.queries and yaml_params.queries[query_name] then
		return yaml_params.queries[query_name]
	else
		return nil
	end
end

local function pick_param_set(param_sets, callback)
	local choices = {}
	for _, set in ipairs(param_sets) do
		table.insert(choices, set.name)
	end

	vim.ui.select(choices, { prompt = "Select a parameter set:" }, function(choice)
		for _, set in ipairs(param_sets) do
			if set.name == choice then
				callback(set.params)
				break
			end
		end
	end)
end

-- Main logic to execute GraphQL query
M.get_params_from_config = function(query, callback)
	-- Extract the query name
	local query_name = extract_query_name(query)

	-- Load the YAML parameters
	local yaml_params = load_yaml_params()

	-- Get the parameter sets for the query
	local param_sets = get_param_sets_for_query(query_name, yaml_params)

	if param_sets then
		-- Prompt the user to pick a parameter set
		pick_param_set(param_sets, function(params)
			if params then
				-- Get the global variables
				local globals = yaml_params.globals or {}
				replace_globals(params, globals)
				-- Convert Lua table (params) to JSON string
				local params_json = vim.fn.json_encode(params)
				callback(params_json)
			else
				callback("{}") -- Return empty JSON object if no params found
			end
		end)
	else
		callback("{}")
	end
end

return M
