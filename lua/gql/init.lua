local yaml = require("gql.yaml")
local window = require("gql.window")
local graphql = require("gql.graphql")
local config = {
	servers = {},
	last_selected_server = "",
}

local M = {}

function M.setup(options)
	yaml.setup(options)
	window.setup(options)
	config = vim.tbl_deep_extend("force", config, options or {})
	if vim.tbl_isempty(config.servers) then
		vim.notify("No GraphQL servers configured.", vim.log.levels.ERROR)
	end
end
local function show_error(msg)
	vim.api.nvim_err_writeln(msg)
end

-- Function to prompt for GraphQL server selection
local function select_server(callback)
	local servers = config.servers
	if not servers or vim.tbl_isempty(servers) then
		show_error("No GraphQL servers configured!")
		return
	end

	local server_names = vim.tbl_keys(servers)

	vim.ui.select(server_names, { prompt = "Select GraphQL server:" }, function(choice)
		if not choice then
			show_error("No server selected!")
			return
		end
		callback(servers[choice])
	end)
end

-- Function to prompt for query parameters
local function prompt_for_params(callback, default_params)
	vim.ui.input(
		{ prompt = "Enter query parameters (JSON format) or leave empty:", default = default_params },
		function(params)
			if params == "" then
				params = "{}"
			end

			local success, _ = pcall(vim.fn.json_decode, params)
			if not success then
				vim.api.nvim_err_writeln("Invalid JSON input")
				return nil
			end
			callback(params)
		end
	)
end

-- Function to execute the GraphQL query using curl
local function execute_curl_request(server, query, params)
	local payload = vim.fn.json_encode({
		query = query,
		variables = vim.fn.json_decode(params),
	})
	local cmd = {
		"curl",
		"-s",
		"-X",
		"POST",
		"-H",
		"Content-Type: application/json",
		"-d",
		payload,
		server.url,
	}

	if server.auth then
		table.insert(cmd, 5, "-H")
		table.insert(cmd, 6, "Authorization: " .. server.auth)
	end

	local result = vim.fn.system(cmd)
	return result
end

-- Function to display result in different window modes
local function display_result(result)
	local pretty_result = yaml.pretty_print_json(result)
	window.write_to_buffer(pretty_result)
end

function M.execute_query(_, range_start, range_end)
	local query = nil
	local mode = vim.api.nvim_get_mode().mode
	if mode == "v" or mode == "V" then
		-- Capture the selected lines
		local lines = vim.fn.getline(range_start, range_end)
		query = table.concat(lines, "\n")
	else
		query = graphql.extract_query()
	end

	-- If no query is selected, show an error
	if not query or query == "" then
		show_error("No query selected!")
		return
	end
	yaml.get_params_from_config(query, function(params)
		local params_json = params
		if config.last_selected_server == "" then
			select_server(function(server)
				config.last_selected_server = server
				prompt_for_params(function(param)
					local result = execute_curl_request(server, query, param)
					display_result(result)
				end, params_json)
			end)
		else
			prompt_for_params(function(param_json)
				local result = execute_curl_request(config.last_selected_server, query, param_json)
				display_result(result)
			end, params_json)
		end
	end)
end
M.change_server = function()
	select_server(function(server)
		config.last_selected_server = server
	end)
end

vim.api.nvim_create_user_command("ExecuteQuery", function(opts)
	M.execute_query(opts.line1, opts.line1, opts.line2)
end, { range = true })

vim.api.nvim_create_user_command("SelectServer", function()
	M.change_server()
end, { range = true })
return M
