local M = {}
M.extract_query = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = cursor[1]
	local col = cursor[2]

	-- Get the current buffer content
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	-- Search for the GraphQL query start and end
	local start_pattern = "gql`"
	local end_pattern = "`"

	local start_line = nil
	local end_line = nil

	-- Find the start of the GraphQL query
	for i = line, 1, -1 do
		local line_content = lines[i]
		local start_pos = line_content:find(start_pattern)
		if start_pos then
			start_line = i
			break
		end
	end

	-- Find the end of the GraphQL query
	for i = line, #lines do
		local line_content = lines[i]
		local end_pos = line_content:find(end_pattern)
		if end_pos then
			end_line = i
			break
		end
	end

	if not start_line or not end_line then
		print("GraphQL query not found")
		return
	end

	-- Extract the query content
	local query_lines = {}
	for i = start_line, end_line do
		local line_content = lines[i]
		if i == start_line then
			-- Extract part of the line after the start pattern
			local start_pos = line_content:find(start_pattern)
			table.insert(query_lines, line_content:sub(start_pos + #start_pattern))
		elseif i == end_line then
			-- Extract part of the line before the end pattern
			local end_pos = line_content:find(end_pattern)
			table.insert(query_lines, line_content:sub(1, end_pos - 1))
		else
			table.insert(query_lines, line_content)
		end
	end

	return table.concat(query_lines, "\n")
end

return M
