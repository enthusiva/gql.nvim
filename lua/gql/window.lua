local M = {}

local result_buffer = nil
local display_win = nil
local display_mode = "float"

function M.setup(opts)
	display_mode = opts.display_mode or "float"
end

local function get_float_window_options()
	local width = math.floor(vim.o.columns * 0.9)
	local height = math.floor(vim.o.lines * 0.8)
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

local function create_float_window()
	result_buffer = vim.api.nvim_create_buf(false, true)
	local win_opts = get_float_window_options()
	display_win = vim.api.nvim_open_win(result_buffer, true, win_opts)
end

local function create_split_window(split_cmd)
	vim.cmd(split_cmd .. " gql.nvim")
	display_win = vim.api.nvim_get_current_win()
	result_buffer = vim.api.nvim_get_current_buf()
end

local function set_keymaps(buffer)
	local opts = { noremap = true, silent = true }
	vim.api.nvim_buf_set_keymap(buffer, "n", "<Esc>", "<cmd>quit<CR>", opts)
	vim.api.nvim_buf_set_keymap(buffer, "n", "q", "<cmd>quit<CR>", opts)
end

local function close_window()
	if display_win and vim.api.nvim_win_is_valid(display_win) then
		vim.api.nvim_win_close(display_win, true)
	end
	if result_buffer and vim.api.nvim_buf_is_valid(result_buffer) then
		vim.api.nvim_buf_delete(result_buffer, { force = true })
	end
	result_buffer = nil
	display_win = nil
end

local function create_window()
	if result_buffer and vim.api.nvim_buf_is_valid(result_buffer) then
		close_window()
	end

	if display_mode == "float" then
		create_float_window()
	elseif display_mode == "horizontal" then
		create_split_window("split")
	elseif display_mode == "vertical" then
		create_split_window("vsplit")
	else
		error("Invalid display mode: " .. display_mode)
	end
	if result_buffer == nil or display_win == nil then
		return
	end

	vim.api.nvim_buf_set_option(result_buffer, "filetype", "json")
	vim.api.nvim_buf_set_option(result_buffer, "buftype", "nofile")
	vim.api.nvim_win_set_option(display_win, "wrap", true)
	vim.api.nvim_win_set_option(display_win, "linebreak", true)

	set_keymaps(result_buffer)
end

function M.write_to_buffer(content)
	if
		display_mode == "float"
		or not M.is_window_open()
		or not result_buffer
		or not vim.api.nvim_buf_is_valid(result_buffer)
	then
		create_window()
	end

	-- Clear the buffer
	vim.api.nvim_buf_set_lines(result_buffer, 0, -1, false, {})

	-- Write new content
	local lines = vim.split(content, "\n")

	vim.api.nvim_buf_set_lines(result_buffer, 0, -1, false, lines)

	-- Move cursor to the top of the buffer
	vim.api.nvim_win_set_cursor(display_win, { 1, 0 })
end

function M.is_window_open()
	return display_win ~= nil and vim.api.nvim_win_is_valid(display_win)
end

return M
