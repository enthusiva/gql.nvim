local M = {}

M.config = {
	servers = {
		{
			name = "Default Server",
			url = "https://graphql-server.com/graphql",
			auth = {
				type = "Bearer",
				token = "your_token_here",
			},
		},
	},
}

-- Function to set user configuration
M.setup = function(user_config)
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

return M
