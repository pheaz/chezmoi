-- User Interface (UX / UI) Improvements

vim.o.number = true           -- Enable line numbers
vim.o.relativenumber = true   -- Relative line numbers
vim.o.signcolumn = "yes"      -- Persistent sign column
vim.o.cursorline = true       -- Highlight current line
vim.o.mouse = "a"             -- Mouse support
vim.o.termguicolors = true    -- True color support
vim.o.laststatus = 3          -- Global statusline
vim.o.pumheight = 10          -- Popup menu height
vim.o.wildmenu = true         -- Improved command-line completion
vim.o.wildmode = "longest:full,full"  -- Improved command-line completion

-- Performance Tweaks

vim.o.lazyredraw = true       -- Lazy redraw
vim.o.updatetime = 300        -- Faster refresh interval
vim.o.timeoutlen = 300        -- Shorter mapping timeout
vim.o.ttimeoutlen = 50        -- Reduce timeout for escape sequences

-- Navigation & Editing Enhancements

vim.o.scrolloff = 8           -- Keep at least 8 lines visible above and below the cursor
vim.o.sidescrolloff = 8       -- Keep at least 8 columns visible left and right of the cursor
vim.o.wrap = false            -- Disable line wrap
vim.o.sidescroll = 1          -- Fine-grained horizontal
vim.opt.ignorecase = true     -- Ignore case when searching
vim.opt.smartcase = true      -- Override ignorecase if uppercase letters are used
vim.o.inccommand = "nosplit"	-- Live substitution preview
vim.o.splitright = true       -- Vertical splits to the right
vim.o.splitbelow = true       -- Horizontal splits below
vim.opt.hlsearch = true       -- Keep search matches highlighted after searching

-- Quality-of-Life Settings

vim.opt.clipboard = "unnamedplus" -- System clipboard integration
-- vim.o.selection = "inclusive" -- Include last character always
vim.o.undofile = true         -- Persistent undo history
vim.o.confirm = true          -- Safe quit prompts
vim.o.swapfile = false        -- Disable swapfile creation
vim.o.backup = true           -- Enable file backups
vim.o.writebackup = true      -- Keep backup while writing
vim.o.backupdir = vim.fn.stdpath("data") .. "/backup"     -- Change backup directory
vim.o.autoread = true
vim.api.nvim_create_autocmd({"BufEnter", "FocusGained"}, {
  pattern = "*",
  command = "if mode() != 'c' | checktime | endif"
})                            -- Automatically reload a file if it was changed outside Neovim
vim.o.completeopt = "menuone,noselect"    -- Makes the popup menu work better when using <Tab> to cycle through completion suggestions
vim.o.visualbell = true       -- Use a visual indicator instead of beeping
vim.o.errorbells = false      -- Disable sound on errors
vim.o.hidden = true           -- Allows you to switch buffers without saving
vim.o.history = 1000          -- Retain a larger history of commands


-- Identation Settings

vim.o.expandtab = true        -- Use spaces instead of tabs
vim.o.smartindent = true      -- Smarter indentation handling
vim.api.nvim_create_autocmd("FileType", {
  pattern = {"javascript", "typescript", "html", "css", "lua", "yaml", "json"},
  command = "setlocal shiftwidth=2 tabstop=2 softtabstop=2"
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {"python", "c", "cpp", "java"},
  command = "setlocal shiftwidth=4 tabstop=4 softtabstop=4"
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {"go"},
  command = "setlocal noexpandtab shiftwidth=8 tabstop=8 softtabstop=8"
})
-- vim.o.shiftwidth = 4       -- Indentation width (adjust per language)
-- vim.o.tabstop = 4          -- How many spaces a real tab looks like
-- vim.o.softtabstop = 4      -- Keeps backspace working correctly
vim.o.shiftround = true       -- Round indentation to multiple of shiftwidth

-- Keymaps

vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { noremap = true, silent = true })    -- Esc to quickly remove highlights after searching
vim.api.nvim_set_keymap('n', '<C-Z>', 'u', { noremap = true, silent = true })         -- Remaps Ctrl Z to undo

-- send deletes to register d
vim.keymap.set({"n","v"}, "d", '"dd', { noremap = true })
vim.keymap.set("n", "D", '"dD', { noremap = true })

-- send changes to register c
vim.keymap.set({"n","v"}, "c", '"cc', { noremap = true })
vim.keymap.set("n", "C", '"cC', { noremap = true })

-- single-char delete → black hole
vim.keymap.set("n", "x", '"_x', { noremap = true })
vim.keymap.set("n", "X", '"_X', { noremap = true })

-- send puts to register p
vim.keymap.set("v", "p", '"pdp', { noremap = true, silent = true })
vim.keymap.set("v", "P", '"pdP', { noremap = true, silent = true })

-- send substitutes to register s
vim.keymap.set({"n","v"}, "s", '"ss', { noremap = true })
vim.keymap.set({"n","v"}, "S", '"sS', { noremap = true })
