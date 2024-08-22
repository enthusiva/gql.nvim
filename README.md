# gql.nvim

A Neovim plugin for executing GraphQL queries directly from your editor.

## Installation

Use with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  "enthusiva/gql.nvim",
  config = function()
    require("gql").setup({
      servers = {
        default = {
          url = "https://api.example.com/graphql",
          auth = "Bearer your-token-here" -- Optional
        },
        other_server = {
          url = "https://api.otherserver.com/graphql"
        }
      }
    })
  end,
  cmd = "ExecuteQuery",
}
```
