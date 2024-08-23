local M = {}

local function load_yaml_params()
	local yaml_file = vim.fn.getcwd() .. "/gql_params.yaml"
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

-- Function to look up params by query name
local function get_params_for_query(query_name, yaml_params)
	if yaml_params and query_name and yaml_params[query_name] then
		return yaml_params[query_name]
	else
		print("No params found for query: " .. (query_name or ""))
		return nil
	end
end

-- Function to construct the query params JSON
local function construct_query_params_json(query_name, yaml_params)
	local params = get_params_for_query(query_name, yaml_params)

	if params then
		-- Convert Lua table (params) to JSON string
		local params_json = vim.fn.json_encode(params)
		return params_json
	else
		return "{}" -- Return empty JSON object if no params found
	end
end

-- Main logic to execute GraphQL query
M.get_params_from_config = function(query)
	-- Extract the query name
	local query_name = extract_query_name(query)

	-- Load the YAML parameters
	local yaml_params = load_yaml_params()

	-- Construct the query params JSON
	local params_json = construct_query_params_json(query_name, yaml_params)
	return params_json
end

return M
