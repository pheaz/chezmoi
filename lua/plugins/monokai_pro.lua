-- plugins.lua
return {
    {
        "tanvirtin/monokai.nvim",
        config = function()
            require('monokai').setup {
                palette = require('monokai').pro,  -- use the Pro palette
                style = "octagon"                  -- select Octagon skin
            }
            vim.cmd("colorscheme monokai")
        end
    }
}
