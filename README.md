# YABS.nvim


**Y**et **A**nother **B**uffer **S**witcher is another buffer switcher window for Neovim written in Lua. This is forked from [JABS.nvim by matbme](https://github.com/matbme/JABS.nvim). His code for JABS is compact and straightforward enough for noobs like me to understand what's going on. This is basically my customization, which may have gone a little too far. 

## What's the difference from JABS?

YABS inherits the basic principle of JABS for being minimal, and adds a few on-the-fly features like panel placement, sorting/grouping, setting display items, etc. The key here is that these can be switched around quickly through several short keys (instead of a fixed setting) for easy access of information regarding buffers. Check out images in the screenshots folder. Some features in JABS are removed, which include user-setting for the panel size and preview. 

![](https://raw.githubusercontent.com/shadowofseaice/yabs.nvim/main/screenshots/Screenshot_2022-08-06_12-35-33.jpg)

## Requirements

- Likely Neovim ≥ v0.5; only tested on v0.7.2 though
- A patched [nerd font](https://www.nerdfonts.com/) for the buffer icons
- [nvim-web-devicons](https://github.com/kyazdani42/nvim-web-devicons) for filetype icons (recommended)

## Installation

You can install YABS with your plugin manager of choice. If you use `packer.nvim`, simply add to your plugin list:

```lua
use 'shadowofseaice/yabs.nvim'
```

## Usage

The command `:YABSOpen` opens YABS' window.

By default, you can navigate between buffers with `j` and `k` as well as `<Tab>` and `<S-Tab>`, and jump to a buffer with `<CR>`. When switching buffers the window closes automatically, but it can also be closed with `<Esc>` or `q`. You can also pin a buffer with 'p'.
The preview feature is depreciated since I don't find it very useful.

## Configuration

All configuration happens within the setup function, which you *must* call inside your `init.lua` file even if you want to stick with the default values. Alternatively, you can redefine a number of parameters to tweak YABS to your liking such as the window's placement.

A minimal configuration keeping all the defaults would look like this:

```lua
require 'yabs'.setup {}
```
A more complex config changing every default value would look like this:

```lua
require 'yabs'.setup {

    -- 3 main options

    position = {'NE', 'E', 'SE', 'C'}, 
    -- 9 placement positions are available, The default is 
    -- {'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N', 'C'}
    -- NE for North-East, E for East, etc. and C for center. The list here
    -- enables quick cycling-through with a short key in case you want to keep
    -- a certain part of the main text visible. The first item in the list is
    -- the default value to start with. I like the panel to in the right hand
    -- side, which tends to be more free of the text in the main buffer. The panel
    -- size is now automatically adjusted and cannot be set or fixed by the user.
    -- The panel can grow as big as the half of the editor, but if the editor is
    -- narrower than 20 columns it can occupy the whole thing.

    settings = {
      {'name', 'bufnr'},
      {'icon', 'bufnr', 'bufname', 'lnum' ,'line'},
      {'path', 'name', 'bufid'},
    },
    -- This sets what to display. The first list is the default set to start with,
    -- which will show file base name and buffer number. Switching to the other
    -- sets can be done by a short key while yabs panel is open. The 2nd set in
    -- this example will list a lot more information. The available keys are
    --
    --  icon     : nvim-web-devicons
    --  bufnr    : buffer number
    --  bufid    : buffer load order 
    --  name     : file base name
    --  bufname  : buffer name, given by !ls 
    --  fullname : file name with full path
    --  path     : relative path to file
    --  fullpath : full path to file
    --  ext      : file extension
    --  lnum     : line number
    --  line     : total line count
    --  edited   : number indicating how many changes...
    --  ...

    -- Keymaps
    keymap = {
        close = "<c-d>", -- Close buffer. Default D
        jump = "<space>", -- Jump to buffer. Default <cr>
        h_split = "h", -- Horizontally split buffer. Default s
        v_split = "v", -- Vertically split buffer. Default v
        pinning = "p", -- Open buffer preview. Default p
        cycset  = ">", -- Cycle through settings, Default ]
        rcycset = "<", -- Reverse cycle through settings, Default [
        cycpos  = "}", -- Cycle through settings, Default >
        rcycpos = "{", -- Reverse cycle through panel placement, Default <
        cycname = "]", -- Cycle through file name type, Default n
        rcycname= "[", -- Reverse cycle through file name type, Default N
        cychdr  = "T", -- Cycle through group header options, Default H
        sortpath= "P", -- Sort by file path. Default P
        sortext = "e", -- Sort by file extension (type), Default t
        sortused= "l", -- Sort by last used, Default u
        sortbuf = "b", -- Sort clear = sort by  buffer #, default c
    },
    -- Short key for sorting/grouping, setting change can be also done by the usual
    -- keymaps in neovim. See the examples below for options using whichkey. For
    -- other normal keymaps, simply copy the commands in the examples below.

    -- the rest of options are simply minor tweaking for cosmetics

    rnu = true,  -- show relative line number, comes handy to quickly jump around buffers with usual #j or #k keys
    border = 'none', -- none, single, double, rounded, solid, shadow, (or an array or chars). Default shadow

    offset = { -- window position offset
        top = 1, -- default 0
        bottom = 1, -- default 0
        left = 1, -- default 0
        right = 1, -- default 0
    },

    -- Default highlights (must be a valid :highlight)
    highlight = {
        current  = "Title",         -- default WarningMsg
        edited   = "StatusLineNC",  -- default ModeMsg
        split    = "WarningMsg",    -- default Normal
        alter    = "StatusLine"     -- default Normal
        grphead  = "StatusLine"     -- default Fold
        unloaded = "StatusLine"     -- default Comment
    },

    -- Default symbols: some of these may not work since not all of them are
    -- tested. Since each icon seems to use 2 bytes, the simple text version,
    -- which is note tested yet, might not work right.
    symbols = {
        -- at most two of these icons can be shown for a given buffer
        current     = "C", -- default 
        split       = "S", -- default 
        alternate   = "A", -- default 
        unloaded    = "H", -- default 
        locked      = "L", -- default 
        ro          = "R", -- default 
        edited      = "E", -- default 
        terminal    = "T", -- default 

        more        = ">", -- default "", when the panel size is too small for file name

        grphead     = "-", -- default " ",
        grptop      = "+", -- default "╭",
        grpmid      = "|", -- default "│",
        grpbot      = "+", -- default "╰",
        pinned      = "P", -- default "",

        filedef     = "D", -- Filetype icon if not present in nvim-web-devicons. Default 
    },

}
```

Add this autocmd to exit yabs when mouse click the main buffer.

    autocmd BufEnter * lua if vim.bo.buflisted then require 'yabs'.leave() end


### Default Keymaps

| Key            | Action                          |
| -------------- | ------------------------------- |
| j or `<Tab>`   | navigate down                   |
| k or `<S-Tab>` | navigate up                     |
| D              | close buffer                    |
| `<CR>`         | jump to buffer                  |
| s              | open buffer in horizontal split |
| v              | open buffer in vertical split   |
| p              | toggle pinning buffer           |
| [              | cycle through settings          |
| ]              | reverse cycle through settings  |
| <              | cycle panel placement           |
| >              | reverse cycle through placement |
| n              | cycle through name type         |
| N              | reverse cycle through name type |
| H              | cycle through group header opt  |
| u              | sort by used                    |
| P              | sort by path:name               |
| t              | sort by file extension          |
| c              | sort clear = sort by buffer #   |

If you don't feel like manually navigating to the buffer you want to open, you
can type its number before `<CR>`, `s`, or `v` to quickly split or switch to it.

## Keymaps for sorting/grouping and setting change

Here is an example [whichkey](https://github.com/folke/which-key.nvim) setting for short keys for YABS.

```lua{
  ...
  b = {
    name = "Buffers",
    b = { "<cmd>lua require 'yabs'.toggleSort('bufnr')<cr>",           "Sort by Buffer #" },
    t = { "<cmd>lua require 'yabs'.toggleSort('ext:name')<cr>",        "Sort by File Type" },
    p = { "<cmd>lua require 'yabs'.toggleSort('path:name')<cr>",       "Sort by File Path" },
    P = { "<cmd>lua require 'yabs'.toggleSort('fullpath:name')<cr>",   "Sort by Full Path" },
    f = { "<cmd>lua require 'yabs'.toggleSort('name')<cr>",            "Sort by File Name" },
    e = { "<cmd>lua require 'yabs'.toggleSort('-edited:name')<cr>",    "Sort by Last Edit" },
    U = { "<cmd>lua require 'yabs'.toggleSort('-lastused:name')<cr>",  "Sort by Last Use" },
    u = { "<cmd>lua require 'yabs'.toggleSort('used:name')<cr>",       "Sort & Group by Last Use" },
    l = { "<cmd>lua require 'yabs'.toggleSort('line')<cr>",            "Sort by Total Line Count" },
    n = { "<cmd>lua require 'yabs'.toggleSort('-lnum')<cr>",           "Sort by Current Line Number" },
    h = { "<cmd>lua require 'yabs'.cycleGrpHeader()<cr>",              "Cycle Group Header" },
  },
  ...
}
```

The function "toogleSort" enables sorting by any key in "buf_table". e.g.,
    toggleSort('name') will sort by file base name. 
    toggleSort('path:name') will sort & group by file path first and then break the ties by file base name
    toggleSort('used:name') will sort by last use and group them by a set of intervals from 1 to 90 minutes.

Add "-" for reverse order. Sorting function usually go through ascending,
descending and no sorting, which means sorting by the buffer number.

The functions starting with "cycle" enables quick switching among a few settings.
    cycleNameType(1)  will cycle through file base name, buffer name, file name with full path.
    cycleGrpHeader(1) will cycle through group header options: none, only for multiple files or every buffer

The function "cyclePlacement" will rotate through the placement option given by
input "position". The width and height of the panel is automatically set based
on the buffer list, so the user setting for the panel size is removed from JABS.


## Future work

I'd like to have this as a more persistent side panel like nvim-tree, but given
being a noob in lua and neovim, I hope someone capable would fork this and develop
or incorporate some of the features here like sorting/grouping into their own
project. Perhaps it may be more useful if one can combine LSP symbols like
[aerial](https://github.com/stevearc/aerial.nvim).

- add marks?

