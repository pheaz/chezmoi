return {
  {
    dir = vim.fn.stdpath("config"),
    name = "osc52-clipboard",
    lazy = false,
    priority = 1000,
    config = function()
      vim.opt.clipboard = "unnamedplus"

      local osc52 = require("vim.ui.clipboard.osc52")

      vim.g.clipboard = {
        name = "OSC 52",
        copy = {
          ["+"] = osc52.copy("+"),
          ["*"] = osc52.copy("*"),
        },
        paste = {
          ["+"] = function()
            return { vim.fn.getreg('"') }, vim.fn.getregtype('"')
          end,
          ["*"] = function()
            return { vim.fn.getreg('"') }, vim.fn.getregtype('"')
          end,
        },
      }
    end,
  },
}
