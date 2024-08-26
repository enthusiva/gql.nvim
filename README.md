# gql.nvim

A Neovim plugin for executing GraphQL queries directly from your editor.

## Installation

Use with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  'enthusiva/gql.nvim',
  opts = {
    servers = {
        default = {
          url = "https://api.example.com/graphql",
          auth = "Bearer your-token-here" -- Optional
        },
        other_server = {
          url = "https://api.otherserver.com/graphql"
        }
    },
    default_display_mode = 'vertical', --horizontal, vertical, float
  },
  config = function(_, opts)
    -- Check if yq is installed
    if vim.fn.executable 'yq' == 0 then
      vim.notify('yq utility is not installed. Please install yq from (https://github.com/mikefarah/yq) to use YAML configurations.', vim.log.levels.ERROR)
      return
    end
    require('gql').setup(opts)
  end,
  cmd = {"ExecuteQuery","SelectServer"}
}
```

# To-do List

- [ ] Server specific gql params file
