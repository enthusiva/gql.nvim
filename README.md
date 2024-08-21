# gql.nvim

A Neovim plugin for executing GraphQL queries directly from your editor.

## Installation

Use with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
require('lazy').setup({
    {
        'enthusiva/gql.nvim',
        config = function()
            require('gql').setup({
                servers = {
                    {
                        name = "My GraphQL Server",
                        url = "https://example.com/graphql",
                        auth = {
                            type = "Bearer",
                            token = "your_token_here",
                        },
                    },
                },
            })
        end,
        keys = { "<leader>gq" },
    },
})
```
