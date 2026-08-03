
vim.cmd.syntax("on")


-- Basic settings
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.cursorline     = true
vim.opt.wrap           = false
vim.opt.scrolloff      = 10
vim.opt.sidescrolloff  = 8


-- Indentation
vim.opt.tabstop     = 2
vim.opt.shiftwidth  = 2
vim.opt.softtabstop = 2
vim.opt.expandtab   = true
vim.opt.smartindent = true
vim.opt.autoindent  = true


-- Search settings
vim.opt.ignorecase = true
vim.opt.smartcase  = true
vim.opt.hlsearch   = true
vim.opt.incsearch  = true


-- Visual settings
vim.opt.termguicolors = true
vim.opt.winborder     = "rounded"
--vim.opt.pumborder     = "bold"
vim.opt.signcolumn    = "yes:2"
vim.opt.colorcolumn   = "120"
vim.opt.showmatch     = false
vim.opt.matchtime     = 0
vim.opt.cmdheight     = 1
vim.opt.updatetime    = 3000


vim.opt.showmode      = false  -- Don't show mode in command line
vim.opt.pumheight     = 10  -- Popup menu height
vim.opt.pumblend      = 0  -- Popup menu transparency
vim.opt.winblend      = 0  -- Floating window transparency
vim.opt.conceallevel  = 0  -- Don't hide markup
vim.opt.concealcursor = ""  -- Don't hide cursor line markup
vim.opt.lazyredraw    = true  -- Don't redraw during macros
vim.opt.synmaxcol     = 300  -- Syntax highlighting limit

vim.opt.completeopt = "fuzzy,menuone,noselect,noinsert"
vim.opt.fillchars = "vert:┃,horiz:━,verthoriz:╋,horizup:┻,horizdown:┳,vertleft:┫,vertright:┣,eob:~"


-- File handling
vim.fn.mkdir(vim.fn.stdpath("cache") .. "/undo",   "p")
vim.fn.mkdir(vim.fn.stdpath("cache") .. "/backup", "p")
vim.fn.mkdir(vim.fn.stdpath("cache") .. "/swap",   "p")
vim.fn.mkdir(vim.fn.stdpath("cache") .. "/view",   "p")

vim.opt.undodir   = vim.fn.stdpath("cache") .. "/undo//"
vim.opt.backupdir = vim.fn.stdpath("cache") .. "/backup//"
vim.opt.directory = vim.fn.stdpath("cache") .. "/swap//"
vim.opt.viewdir   = vim.fn.stdpath("cache") .. "/view//"

vim.opt.backup      = true
vim.opt.writebackup = true
vim.opt.swapfile    = true
vim.opt.undofile    = true

vim.opt.timeoutlen  = 5000  -- Key timeout duration
vim.opt.ttimeoutlen = 5  -- Key code timeout
vim.opt.autoread    = true  -- Auto reload files changed outside vim
vim.opt.autowrite   = false  -- Don't auto save
vim.opt.viewoptions = "folds,cursor"
vim.opt.sessionoptions:remove("curdir")


-- Behavior settings
vim.opt.hidden     = true  -- Allow hidden buffers
vim.opt.errorbells = false  -- No error bells
vim.opt.backspace  = "indent,eol,start"  -- Better backspace behavior
vim.opt.autochdir  = false  -- Don't auto change directory
vim.opt.selection  = "inclusive"  -- Selection behavior
vim.opt.mouse      = "a"  -- Enable mouse support, hold Shift+mouse to disable
vim.opt.modifiable = true  -- Allow buffer modifications
vim.opt.encoding   = "UTF-8"
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.iskeyword:append("-")  -- Treat dash as part of word
vim.opt.clipboard:append("unnamedplus")  -- Use system clipboard


-- Folding settings
vim.opt.foldmethod = "expr"
vim.opt.foldlevel  = 99  -- Start with all folds open
vim.opt.formatexpr = ""


-- Command-line completion
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildignore:append({ "*.o", "*.obj", "*.pyc", "*.class", "*.jar" })


-- Better diff options
vim.opt.diffopt:append("linematch:60")


-- Performance improvements
vim.opt.redrawtime    = 10000
vim.opt.maxmempattern = 20000

-- CTags
vim.opt.tags = { ".tags;", "tags;", }
