local config = require("gql.config")

-- Function to select a GraphQL server from the configured list
local function select_server()
	local servers = config.config.servers
	local server_names = {}
	for i, server in ipairs(servers) do
		table.insert(server_names, server.name)
	end
	local choice = vim.fn.inputlist(server_names)
	return servers[choice]
end

-- Function to get the selected query from the buffer
local function get_selected_query()
	local start_line, _, end_line, _ = unpack(vim.fn.getpos("'<"))
	local query_lines = vim.fn.getline(start_line, end_line)
	return table.concat(query_lines, "\n")
end

-- Function to prompt for query parameters
local function get_query_params()
	local params = vim.fn.input("Enter query parameters (JSON): ")
	return vim.fn.json_decode(params)
end

-- Function to execute the GraphQL query
local function execute_query()
	local server = select_server()
	if not server then
		print("No server selected")
		return
	end

	local query = get_selected_query()
	local params = get_query_params()

	local json_body = {
		query = query,
		variables = params,
	}

	local command = string.format(
		'curl -s -X POST -H "Content-Type: application/json" -H "Authorization: %s %s" -d \'%s\' %s',
		server.auth.type,
		server.auth.token,
		vim.fn.json_encode(json_body),
		server.url
	)

	local result = vim.fn.system(command)
	vim.api.nvim_echo({ { result, "Normal" } }, false, {})
end

return {
	execute_query = execute_query,
}
