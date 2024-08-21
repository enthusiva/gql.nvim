-- Load the configuration
local config = require("gql.config")

-- Plugin setup function, to be called from your Neovim configuration
local M = {}

M.setup = function(user_config)
	config.setup(user_config)

	-- Load the keybindings
	require("gql.keybindings")
end

return M
