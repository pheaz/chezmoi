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
        vim.opt.clipboard = ""

        local osc52 = require("vim.ui.clipboard.osc52")
        local copy = osc52.copy("+")

        vim.api.nvim_create_autocmd("TextYankPost", {
          callback = function()
            if vim.v.event.operator == "y" and vim.v.event.regname == "" then
              copy(vim.v.event.regcontents, vim.v.event.regtype)
            end
          end,
        })
        return
      end

      vim.g.clipboard = false
    end,
  },
}
