vim.api.nvim_set_keymap(
	"n",
	"<leader>gq",
	':lua require("gql.graphql").execute_query()<CR>',
	{ noremap = true, silent = true }
)
