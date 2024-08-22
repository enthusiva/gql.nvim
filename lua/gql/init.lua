local M = {}

function M.setup(options)
	M.config = {
		servers = {},
		default_display_mode = "float", -- Options: "float", "horizontal", "vertical"
	}
	M.config = vim.tbl_deep_extend("force", M.config, options or {})

	if vim.tbl_isempty(M.config.servers) then
		vim.notify("No GraphQL servers configured.", vim.log.levels.ERROR)
	end
end

-- Function to display an error message in Neovim
local function show_error(msg)
	vim.api.nvim_err_writeln(msg)
end

-- Function to prompt for GraphQL server selection
local function select_server(callback)
	local servers = M.config.servers
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
local function prompt_for_params(callback)
	vim.ui.input({ prompt = "Enter query parameters (JSON format) or leave empty:" }, function(params)
		if params == "" then
			params = "{}"
		end

		local success, _ = pcall(vim.fn.json_decode, params)
		if not success then
			vim.api.nvim_err_writeln("Invalid JSON input")
			return nil
		end
		callback(params)
	end)
end

-- Function to execute the GraphQL query using curl
local function execute_curl_request(server, query, params)
	-- Construct the JSON payload
	local payload = vim.fn.json_encode({
		query = query,
		variables = vim.fn.json_decode(params),
	})
	-- Debug logs
	-- vim.api.nvim_out_write("Payload: " .. payload .. "\n")
	-- Construct the curl command
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

	-- Add Authorization header if available
	if server.auth then
		table.insert(cmd, 5, "-H")
		table.insert(cmd, 6, "Authorization: " .. server.auth)
	end

	-- Execute the curl command and capture the output
	local result = vim.fn.system(cmd)
	return result
end

-- Simple function to pretty-print JSON using Lua
local function pretty_print_json(json_string)
	local function indent(level)
		return string.rep("    ", level)
	end

	local function parse(value, level)
		local type_value = type(value)
		if type_value == "table" then
			local result = "{\n"
			for k, v in pairs(value) do
				result = result .. indent(level + 1) .. '"' .. tostring(k) .. '": ' .. parse(v, level + 1) .. ",\n"
			end
			result = result:sub(1, -3) .. "\n" .. indent(level) .. "}"
			return result
		elseif type_value == "string" then
			return '"' .. value:gsub('"', '\\"') .. '"'
		elseif type_value == "number" or type_value == "boolean" then
			return tostring(value)
		else
			return "null"
		end
	end

	local success, json = pcall(vim.json.decode, json_string)
	if not success then
		return json_string -- Return original if decoding fails
	end

	return parse(json, 0)
end
local function get_window_options()
	local width = math.floor(vim.o.columns * 0.9) -- 90% of the current editor's width
	local height = math.floor(vim.o.lines * 0.9)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	return {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	}
end

local function write_to_buffer(buf, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

local function create_window(mode, lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "filetype", "json")
	write_to_buffer(buf, lines)

	local win_opts = get_window_options()

	if mode == "float" then
		win_opts.relative = "editor"
		local win = vim.api.nvim_open_win(buf, true, win_opts)
		vim.api.nvim_win_set_option(win, "wrap", true)
		vim.api.nvim_win_set_option(win, "linebreak", true)
		vim.api.nvim_buf_set_keymap(buf, "n", "q", "<Cmd>q<CR>", { noremap = true, silent = true })
		vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<Cmd>q<CR>", { noremap = true, silent = true })
	elseif mode == "horizontal" then
		vim.cmd("split")
		local win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(win, buf)
		vim.api.nvim_win_set_option(win, "wrap", true)
		vim.api.nvim_win_set_option(win, "linebreak", true)
		vim.api.nvim_buf_set_keymap(buf, "n", "q", "<Cmd>q<CR>", { noremap = true, silent = true })
		vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<Cmd>q<CR>", { noremap = true, silent = true })
	elseif mode == "vertical" then
		vim.cmd("vsplit")
		local win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(win, buf)
		vim.api.nvim_win_set_option(win, "wrap", true)
		vim.api.nvim_win_set_option(win, "linebreak", true)
		vim.api.nvim_buf_set_keymap(buf, "n", "q", "<Cmd>q<CR>", { noremap = true, silent = true })
		vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<Cmd>q<CR>", { noremap = true, silent = true })
	else
		error("Unsupported mode: " .. mode)
	end
end

-- Function to display result in different window modes
local function display_result(result)
	local mode = M.config.default_display_mode
	local pretty_result = pretty_print_json(result)
	local lines = vim.split(pretty_result, "\n")

	create_window(mode, lines)
end
local function trim_empty_lines(text)
	-- Split the text into lines
	local lines = vim.split(text, "\n")

	-- Trim leading empty lines
	local start_index = 1
	while start_index <= #lines and lines[start_index]:match("^%s*$") do
		start_index = start_index + 1
	end

	-- Trim trailing empty lines
	local end_index = #lines
	while end_index >= start_index and lines[end_index]:match("^%s*$") do
		end_index = end_index - 1
	end

	-- Extract the non-empty lines
	local trimmed_lines = {}
	for i = start_index, end_index do
		table.insert(trimmed_lines, lines[i])
	end

	-- Return the trimmed text
	return table.concat(trimmed_lines, "\n")
end
-- Main function to execute the query
function M.execute_query(_, range_start, range_end)
	-- Capture the selected lines
	local lines = vim.fn.getline(range_start, range_end)

	-- Extract the selected text
	-- local query = table.concat(lines, "\n")
	local query = trim_empty_lines(lines)
	-- If no query is selected, show an error
	if not query or query == "" then
		show_error("No query selected!")
		return
	end

	-- Select the GraphQL server
	select_server(function(server)
		-- Prompt for query parameters
		prompt_for_params(function(params)
			-- Execute the query using curl
			local result = execute_curl_request(server, query, params)

			-- Display the result in a popup window
			display_result(result)
		end)
	end)
end

-- Register the :ExecuteQuery command with range enabled
vim.api.nvim_create_user_command("ExecuteQuery", function(opts)
	M.execute_query(opts.line1, opts.line1, opts.line2)
end, { range = true })

return M
