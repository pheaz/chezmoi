return {
  {
    "vscode-neovim/vscode-multi-cursor.nvim",
    event = "VeryLazy",
    cond = not not vim.g.vscode,
    opts = {},
    keys = {
      {
        "<leader>a",
        function()
          require("vscode-multi-cursor").selectHighlights()
        end,
        mode = "x",
        desc = "Select all occurrences",
      },
    },
  },
}
