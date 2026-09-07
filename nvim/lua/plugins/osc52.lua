return {
  {
    dir = vim.fn.stdpath("config"),
    name = "osc52-clipboard",
    lazy = false,
    priority = 1000,
    config = function()
      vim.opt.clipboard = "unnamedplus"

      if vim.g.vscode and vim.g.vscode_clipboard then
        vim.g.clipboard = vim.g.vscode_clipboard
        return
      end

      if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
        local osc52 = require("vim.ui.clipboard.osc52")

        vim.g.clipboard = {
          name = "OSC 52",
          copy = {
            ["+"] = osc52.copy("+"),
            ["*"] = osc52.copy("*"),
          },
          paste = {
            ["+"] = osc52.paste("+"),
            ["*"] = osc52.paste("*"),
          },
        }
        return
      end

      vim.g.clipboard = false
    end,
  },
}
