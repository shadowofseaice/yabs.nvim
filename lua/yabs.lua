local M = {}
local api = vim.api
local ui = api.nvim_list_uis()[1]

-- YABS main popup
M.main_win = nil
M.main_buf = nil

-- Buffer preview popup
M.prev_win = nil
M.prev_buf = nil

M.bopen = {}
M.conf = {}
M.win_conf = {}
M.preview_conf = {}
M.keymap_conf = {}

M.cur_buf_line_num = 2
M.max_height= 1
M.buf_table = {}
M.cur_buf = 1
M.max_padding = 5
M.grp_padding = 0
M.num_padding = 0
M.grp_header = 1 -- 0 None, 1 only multiple files, 2 for everything

M.in_close = false
M.sortby = ''
M.toggleSortKey = ''
M.toggleSortCount = 0

M.key = -1
M.pinned = {}

M.position={'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N' ,'C'}

M.rnu = false

M.ntid = -1
M.nametype={'name', 'bufname', 'fullname'}

M.settings = {{'name','bufnr'}}

M.openOptions = {
    window = "b%s",
    vsplit = "vert sb %s",
    hsplit = "sb %s",
}

require "split"

-- find the first key containing the phrase
function M.find_key(list, phrase)
    for idx, v in ipairs(list) do
        local i, _ = string.find(v, phrase)
        if i ~= nil then
            return idx
        end
    end
    return -1
end

function M.setup(cc)
    local c = cc or {}

    -- If preview opts table not provided in config
    if not c.preview then
        c.preview = {}
    end

    -- If highlight opts table not provided in config
    if not c.highlight then
        c.highlight = {}
    end

    -- If symbol opts table not provided in config
    if not c.symbols then
        c.symbols = {}
    end

    -- If keymap opts table not provided in config
    if not c.keymap then
        c.keymap = {}
    end

    -- If offset opts table not provided in config
    if not c.offset then
        c.offset = {}
    end

    -- Highlight names
    M.highlight = {
        current = c.highlight.current   or "WarningMsg",
        edited  = c.highlight.edited    or "ModeMsg",
        split   = c.highlight.split     or "Normal",
        alter   = c.highlight.alternate or "Normal",
        grphead = c.highlight.grphead   or "Fold",
        unloaded= c.highlight.hidden    or "Comment",
    }

    -- Buffer info symbols
    M.bufinfo = {
        --      ﰳ   
        --│ ╭ ╮ ╯ ╰ ─
        current = c.symbols.current   or "",
        split   = c.symbols.split     or "",
        alter   = c.symbols.alternate or "",
        unloaded= c.symbols.unloaded  or " ",

        edited  = c.symbols.edited    or "",
        locked  = c.symbols.locked    or "",
        ro      = c.symbols.ro        or "",
        terminal= c.symbols.terminal  or "",

        more    = c.symbols.more      or "",
        grphead = c.symbols.grphead   or " ",
        grptop  = c.symbols.grptop    or "╭",
        grpmid  = c.symbols.grpmid    or "│",
        grpbot  = c.symbols.grpbot    or "╰",
        pinned  = c.symbols.pinned    or "",

        filedef = c.symbols.filedef or "",
    }

    -- Main window setup
    M.win_conf = {
        width    = c.width    or 50,
        height   = c.height   or 10,
        style    = c.style    or "minimal",
        border   = c.border   or "none",
        relative = c.relative or "editor",
    }

    M.sortby = c.sortby or M.sortby
    M.rnu    = c.rnu    or false

    M.position = c.position or M.position
    M.anchor = M.position[1]
    M.posid  = 0

    M.settings = c.settings or M.settings
    M.show     = M.settings[1]
    M.setid    = 0

    M.max_width={}
    for idx=1, #M.show do
        M.max_width[idx]=1
    end

    -- Use devicons file symbols
    M.use_devicons = false
    for idx=1, #M.show do
        if M.show[idx] == "icon" then
            M.use_devicons = true
            break
        end
    end

    M.key = M.find_key(M.show, "name")
    M.key = c.key    or M.key

    -- Preview window setup
    M.preview_conf = {
        width    = c.preview.width    or 70,
        height   = c.preview.height   or 30,
        style    = c.preview.style    or "minimal",
        border   = c.preview.border   or "double",
        -- anchor   = M.win_conf.anchor,
        anchor   = "NW",
        relative = c.preview.relative or "editor",
    }

    -- Keymap setup
    M.keymap_conf = {
        close    = c.keymap.close    or "D",
        jump     = c.keymap.jump     or "<cr>",
        h_split  = c.keymap.h_split  or "s",
        v_split  = c.keymap.v_split  or "v",
        -- preview  = c.keymap.preview  or "P",
        pinning  = c.keymap.pinning  or "p",
        cycset   = c.keymap.cycset   or "]",
        rcycset  = c.keymap.rcycset  or "[",
        cycname  = c.keymap.cycname  or "}",
        rcycname = c.keymap.rcycname or "{",
        cycpos   = c.keymap.cycpos   or ">",
        rcycpos  = c.keymap.rcycpos  or "<",
        cychdr   = c.keymap.cychdr   or "H",
        sortused = c.keymap.sortused or "u",
        sortpath = c.keymap.sortpath or "P",
        sortext  = c.keymap.sortext  or "t",
        sortbuf  = c.keymap.sortbuf  or "c",
        sortbase = c.keymap.sortbase or "f",
        sortfull = c.keymap.sortfull or "F",
        sortinit = c.keymap.sortinit or "i",
    }

    -- Position setup
    M.conf = {
        top_offset    = c.offset.top    or 0;
        bottom_offset = c.offset.bottom or 0;
        left_offset   = c.offset.left   or 0;
        right_offset  = c.offset.right  or 0;

        preview_position = c.preview_position or "top",
    }

    -- TODO: Convert to a table
    if M.conf.preview_position == "top" then
        M.preview_conf.col = M.win_conf.width / 2 - M.preview_conf.width / 2
        M.preview_conf.row = -M.preview_conf.height - 2
    elseif M.conf.preview_position == "bottom" then
        M.preview_conf.col = M.win_conf.width / 2 - M.preview_conf.width / 2
        M.preview_conf.row = M.win_conf.height
    elseif M.conf.preview_position == "right" then
        M.preview_conf.col = M.win_conf.width
        M.preview_conf.row = M.win_conf.height / 2 - M.preview_conf.height / 2
    elseif M.conf.preview_position == "left" then
        M.preview_conf.col = -M.preview_conf.width
        M.preview_conf.row = M.win_conf.height / 2 - M.preview_conf.height / 2
    end

end

-- Update window position
function M.updatePos()
    ui = api.nvim_list_uis()[1]

    M.win_conf.anchor = M.anchor
    if M.anchor == "NE" then
        M.win_conf.col = ui.width  - M.conf.right_offset
        M.win_conf.row = M.conf.top_offset
    elseif M.anchor == "E" then
        M.win_conf.anchor = "NE"
        M.win_conf.col = ui.width  - M.conf.right_offset
        M.win_conf.row = (ui.height / 2) + M.conf.top_offset  - (M.win_conf.height / 2 + M.conf.bottom_offset)
    elseif M.anchor == "SE" then
        M.win_conf.col = ui.width  - M.conf.right_offset
        M.win_conf.row = ui.height -2 - M.conf.bottom_offset
    elseif M.anchor == "NW" then
        M.win_conf.col = M.conf.left_offset
        M.win_conf.row = M.conf.top_offset
    elseif M.anchor == "SW" then
        M.win_conf.col = M.conf.left_offset
        M.win_conf.row = ui.height - 2 - M.conf.bottom_offset
    elseif M.anchor == "W" then
        M.win_conf.anchor = "NE"
        M.win_conf.col = M.conf.left_offset
        M.win_conf.row = (ui.height / 2) + M.conf.top_offset  - (M.win_conf.height / 2 + M.conf.bottom_offset)
    elseif M.anchor == "S" then
        M.win_conf.anchor = "SW"
        M.win_conf.col = (ui.width  / 2) + M.conf.left_offset - (M.win_conf.width  / 2 + M.conf.right_offset )
        M.win_conf.row = ui.height -2 - M.conf.bottom_offset
    elseif M.anchor == "N" then
        M.win_conf.anchor = "NW"
        M.win_conf.col = (ui.width  / 2) + M.conf.left_offset - (M.win_conf.width  / 2 + M.conf.right_offset )
        M.win_conf.row = M.conf.top_offset
    elseif M.anchor == "C" then
        M.win_conf.anchor = "NW"
        M.win_conf.col = (ui.width  / 2) + M.conf.left_offset - (M.win_conf.width  / 2 + M.conf.right_offset )
        M.win_conf.row = (ui.height / 2) + M.conf.top_offset  - (M.win_conf.height / 2 + M.conf.bottom_offset)
    else
        M.anchor = 'NE'
        M.win_conf.col = ui.width  - M.conf.right_offset
        M.win_conf.row = M.conf.top_offset
    end
end

------------------------------------------------------------------------------
-- Open buffer from line
function M.selBufNum(win, opt, count)
    local linenr = api.nvim_win_get_cursor(M.main_win)[1]
    local bufnr = 1
    -- this may not work any more
    if count ~=0 then
        for idx=1, #M.buf_table do
            local buf = M.buf_table[idx]
            if buf["bufid"] == count then
                bufnr = buf["bufnr"]
                break
            end
        end
    else
        bufnr=M.buf_table[linenr]["bufnr"]
    end

    -- now action
    if bufnr >=0 then
        M.close()
        api.nvim_set_current_win(win)
        vim.cmd(string.format(M.openOptions[opt], bufnr))
    end
end

-- Preview buffer
function M.previewBuf()
    local linenr = api.nvim_win_get_cursor(M.main_win)[1]
    local bufnr=M.buf_table[linenr]["bufnr"]

    -- Create the buffer for preview window
    M.prev_win = api.nvim_open_win(bufnr, 1, M.preview_conf)
    M.update()
end

-- Close buffer from line
function M.closeBufNum(win)
    local linenr = api.nvim_win_get_cursor(M.main_win)[1]
    local bufnr = 1
    if linenr-1 <= #M.buf_table then
        if linenr >= 2 then
            bufnr=M.buf_table[linenr-1]["bufnr"]
        end
    end
    -- print(linenr, bufnr)
    api.nvim_set_current_win(win)
    vim.cmd(string.format("bd %s", bufnr))

    -- this is not the only route that the buffer can be deleted
    -- so zombie pin can linger
    -- a spearate sweep would be cleaner
    if M.pinned[bufnr] == true then
        M.pinned[bufnr] = false
    end
    M.update()
end

------------------------------------------------------------------------------
function M.compare(key1, key2, r1, r2)
    return function(a, b)
        if r1 then
            if r2 then
                if a[key1] == b[key1] then
                     return a[key2] < b[key2]
                else
                     return a[key1] < b[key1]
                end
            else
                if a[key1] == b[key1] then
                     return a[key2] > b[key2]
                else
                     return a[key1] < b[key1]
                end
            end
        else
            if r2 then
                if a[key1] == b[key1] then
                     return a[key2] < b[key2]
                else
                     return a[key1] > b[key1]
                end
            else
                if a[key1] == b[key1] then
                     return a[key2] > b[key2]
                else
                     return a[key1] > b[key1]
                end
            end
        end
    end
end

-- sort the list
function M.sort(method)
    -- shouldn't this be a recursion but 
    -- do we really need to sort by more than 2 keys?

    local keys = method:split(':',true)
    local key1 = keys[1]
    local r1
    if key1:sub(1,1) ~= '-' then
        r1 = true
    else
        r1 = false
        key1 = key1:sub(2,key1:len())
    end
    -- print(method)
    -- print(key1,r1)
    if #keys == 1 then
        if key1 == '' then
            return
        end
        if r1 then
            table.sort(M.buf_table, function(a, b) return a[key1] < b[key1] end)
        else
            table.sort(M.buf_table, function(a, b) return a[key1] > b[key1] end)
        end
    else
        local key2 = keys[2]
        local r2
        if key2:sub(1,1) ~= '-' then
            r2 = true
        else
            r2 = false
            key2 = key2:sub(2,key2:len())
        end
        -- print(key2,r2)
        table.sort(M.buf_table, M.compare(key1, key2, r1,r2) )
    end

end

-- Get file symbol from devicons
function M.getFileSymbol(basename, ext)

    local devicons = pcall(require, "nvim-web-devicons")
    if devicons then
        -- do not take its own highlight
        local icon, hl = require("nvim-web-devicons").get_icon(basename, ext)
        if icon == nil then
            return M.bufinfo.filedef
        end
        return icon , hl --, basename
    else
        return M.bufinfo.filedef , nil --, basename
    end
end

-- collect buf info
function M.getBufTable()

    -- print('getBufTable<-',M.win_conf.width,M.max_width,M.max_padding,M.grp_padding, M.num_padding)
    M.bopen = api.nvim_exec(":ls", true):split("\n", true)
    if #M.bopen == 1 and M.bopen[1] == "" then
        return
    end

    local deco={}
    local bufname={}
    local bufpath={}

    for _, buf in ipairs(M.bopen) do
        -- local fields = buf:split(" ", true)
        local fields = vim.split(buf, '"', false)
        -- local name = fields[2]

        local cdeco = fields[1]:gsub("^%s+([0-9]+)%s+","")
        local fields_ = vim.split(fields[1]:gsub("^%s+","")," ",false)
        local bufnr= tonumber(fields_[1])

        bufname[bufnr] = fields[2]
        -- local name     = fields[2]:split("/",true)
        local name     = vim.split(fields[2],"/",false)
        bufpath[bufnr] = fields[2]:gsub("[^/]*$","")

        if string.find(cdeco,'#') ~= nil then
            deco['#' .. bufnr] = true
        end
        if string.find(cdeco,'=') ~= nil then
            deco['=' .. bufnr] = true
        end
        if string.find(cdeco,'-') ~= nil then
            deco['-' .. bufnr] = true
        end
    end

    if M.key >0 then
        M.max_width[M.key] = 10
    end
    M.bopen=vim.fn.getbufinfo()
    M.buf_table = {}
    local nbuf=0
    local max_lastused=0
    for _, buf in ipairs(M.bopen) do
        if buf["listed"] == 0 then
            goto continue
        end
        nbuf = nbuf+1

        -- local name = buf["name"]:split("/", true)
        local name = vim.split(buf["name"],"/", false)
        local basename= name[#name]
        local path = buf["name"]:gsub("[^/]*$","")
        path  = path:gsub("/$","")
        local bufnr= buf["bufnr"]
        local ext  = basename:split(".",true)
        ext = ext[#ext]

        -- name the keys carefully since they are used for 
        -- "sortby" variables
        -- e.g., M.sortby="ext:-lastused"
        -- sort first by "ext" and then break the ties by reverse sorting by "lastused"
        local row = {
            bufnr   = buf["bufnr"       ],
            bufid   = nbuf,
            fullname= buf["name"],
            bufname = bufname[bufnr],
            name    = basename,
            initial = basename:sub(1,1),
            ext     = ext,
            fullpath= path,
            path    = bufpath[bufnr],
            edited  = buf["changed"     ],
            tick    = buf["changedtick" ],
            loaded  = buf["loaded"      ],
            line    = buf["linecount"   ],
            lastused= buf["lastused"    ],
            lnum    = buf["lnum"        ],
            hidden  = buf["hidden"      ],
            pinned  = M.pinned[buf["bufnr"]],
            alter   = deco[ "#" .. bufnr ] == true,
            locked  = deco[ "-" .. bufnr ] == true,
            readonly= deco[ "=" .. bufnr ] == true,
            grpid   = 2,     -- 2 not in a group, 1 group leader, 3 group followers, 4 group ends
        }

        if M.use_devicons then
            row["icon"], row["hl_icon"] = M.getFileSymbol(basename, ext)
        end

        table.insert(M.buf_table, row)

        -- if M.max_width < fname:len() then
        --     M.max_width = fname:len()
        -- end

        if max_lastused < buf["lastused"] then
            max_lastused = buf["lastused"]
        end

        ::continue::
    end

    for _, buf in ipairs(M.buf_table) do
        local elapsed = max_lastused - buf["lastused"]
        elapsed = elapsed / 60
        if elapsed > 99 then
            elapsed = 99
        end
        elapsed = (elapsed .. ""):gsub("%.[0-9]*","")
        elapsed = tonumber(elapsed)
        buf["elapsed"] = elapsed

        if elapsed < 1 then
            buf["used"] = "<  1 min ago"
        elseif elapsed < 5 then
            buf["used"] = "<  5 min ago"
        elseif elapsed < 10 then
            buf["used"] = "< 10 min ago"
        elseif elapsed < 30 then
            buf["used"] = "< 30 min ago"
        elseif elapsed < 60 then
            buf["used"] = "< 60 min ago"
        elseif elapsed < 90 then
            buf["used"] = "< 90 min ago"
        elseif buf["lastused"] == 0 then
            buf["used"] = "not yet"
        else
            buf["used"] = "> 90 min ago"
        end

        for idx=1, #M.show do
            local curlen = (buf[M.show[idx]] .. " "):len()
            if M.max_width[idx] < curlen then
                 M.max_width[idx] = curlen
            end
        end
    end
    M.max_height=nbuf
    M.max_width_sum = 0
    for idx=1, #M.show do
        M.max_width_sum = M.max_width_sum + M.max_width[idx]
    end
    -- print(vim.inspect(M.buf_table[1]))
    -- print(M.max_width, M.max_height)
    -- print(vim.inspect(vim.api.nvim_get_current_buf()))
    -- print(vim.inspect(vim.api.nvim_list_bufs()))

    -- print('getBufTable->',M.win_conf.width,M.max_width,M.max_padding,M.grp_padding, M.num_padding)
end

-- add decoration by putting (group) title and grouping
function M.decoBufTable()

    -- handle pinned
    local pin_counter=1
    for idx=1, #M.buf_table do
        local buf_row=M.buf_table[idx]
        if buf_row["pinned"] == true then
            buf_row=table.remove(M.buf_table, idx)
            -- this is safer, but reverses the any sorting order
            -- table.insert(M.buf_table,1,buf_row)  
            table.insert(M.buf_table,pin_counter,buf_row)
            pin_counter = pin_counter+1
        end
    end

    if M.rnu then
        M.num_padding=4
    else
        M.num_padding=0
    end
    local width = M.max_width_sum + M.max_padding + M.grp_padding + M.num_padding
    local max_width_sum = M.max_width_sum

    M.grp_padding = 0
    local grpid={}
    local key = M.sortby:split(':',true)
    key = key[1]
    if key ~= "" then
        key = key:gsub("-","")
        for idx=2, #M.buf_table do
            local buf_row = M.buf_table[idx]
            local buf_pre = M.buf_table[idx-1]
            if buf_row[key] == buf_pre[key] then
                if buf_pre.grpid == 2 then
                    buf_pre.grpid = 1
                else
                    buf_pre.grpid = 3
                end
                buf_row.grpid = 3
                M.grp_padding = 1
                width = max_width_sum + M.max_padding + M.grp_padding + M.num_padding
            else
                if buf_pre.grpid == 3 then
                    buf_pre.grpid = 4
                end
            end
        end
        if M.buf_table[#M.buf_table].grpid == 3 then
            M.buf_table[#M.buf_table].grpid = 4
        end

        for idx=1, #M.buf_table do
            table.insert(grpid, M.buf_table[idx].grpid)
        end

        -- group header
        for idx=#grpid, 1, -1 do
            if grpid[idx] <= M.grp_header then
                local buf_row = M.buf_table[idx]
                local row={
                    bufnr = -1,
                    text = M.bufinfo.grphead .. key .. ": " .. buf_row[key],
                    highlight = M.highlight.head,
                    grpid = 2,
                }
                if row.text:len() > width - M.num_padding then
                    max_width_sum = row.text:len() - M.max_padding -M.grp_padding
                    width = max_width_sum + M.max_padding + M.grp_padding +M.num_padding
                elseif row.text:len() < width -M.num_padding then
                    row.text = row.text .. string.rep(' ', width - row.text:len() - M.num_padding)
                end
                table.insert(M.buf_table, idx, row)
            end
        end
    end

    -- Draw title
    local title = " " .. #M.buf_table .. " buffers"
    if M.sortby ~= "" then
        title = title .. " by " .. M.sortby
    else
        title = title .. " unsorted"
    end
    local row={
        bufnr = -1,
        text = title,
        highlight = M.highlight.head,
        grpid = 2,
    }
    table.insert(M.buf_table, 1, row)

    M.win_conf.width = 20
    if M.win_conf.width < (width) then
        M.win_conf.width = width
    end
    if M.win_conf.width > (ui.width/2) then
        M.win_conf.width = ui.width/2
    end
    if M.win_conf.width < 20 then
        M.win_conf.width = ui.width
    end
    max_width_sum = M.win_conf.width -M.max_padding - M.grp_padding - M.num_padding
    M.win_conf.height = #M.buf_table
    if M.key >0 then
        M.max_width[M.key] = M.max_width[M.key]+max_width_sum-M.max_width_sum
    end
    M.max_width_sum = max_width_sum
    -- print('deco->',M.win_conf.width,M.max_width,M.max_padding,M.grp_padding, M.num_padding, M.bufnrlen)
end

-- Parse ls string
function M.parseLs(buf)

    -- Quit immediately if ls output is empty
    if #M.bopen == 1 and M.bopen[1] == "" then
        return
    end

    for idx=1, #M.buf_table do
        local buf_row = M.buf_table[idx]

        local linenr = idx-1
        local line   = ""
        local highlight = "Normal"
        local hlstart = 0
        local icon  = {}

        if buf_row['bufnr'] >=0 then
            -- set icons
            -- set highlight

            -- the order of these is important
            -- unloaded
            if buf_row["loaded"] == 0 then
                highlight = M.highlight.unloaded
            else
                -- split
                if buf_row["hidden"] == 0 then
                    if buf_row["bufnr"] ~= M.cur_buf then
                        table.insert(icon, M.bufinfo.split)
                        highlight = M.highlight.split
                    end
                end
            end
            -- alter
            if buf_row["alter"] then
                 table.insert(icon,1, M.bufinfo.alter)
                 highlight = M.highlight.alter
            end

            if buf_row["locked"] then
                table.insert(icon,1, M.bufinfo.locked)
            end
            if buf_row["readonly"] then
                table.insert(icon,1, M.bufinfo.ro)
            end

            -- current buffer supercede the above
            if buf_row["bufnr"] == M.cur_buf then
                table.insert(icon,1, M.bufinfo.current)
                highlight = M.highlight.current
                M.cur_buf_line_num = linenr+1
            end

            -- edited?
            if buf_row["edited"] == 1 then
                table.insert(icon, M.bufinfo.edited)
                highlight = M.highlight.edited
            end

            -- pinned?
            if buf_row["pinned"] == true then
                table.insert(icon, 1, M.bufinfo.pinned)
            end

            -- icons 
            if #icon >=2 then
                line = icon[1] .. " " .. icon[2] .. " "
            elseif  #icon == 1 then
                line = " " .. icon[1] .. "  "
            else
                line = "    "
            end

            -- combine the items
            -- M.key points the item, the width of which can be adjusted
            -- This should be one of name, bufname or fullname
            for jdx=1, #M.show do
                if jdx == M.key then
                    local item=buf_row[M.show[jdx]]
                    local dwidth = M.max_width[jdx] - item:len()
                    if dwidth > 0 then
                        item = item .. string.rep(" ",dwidth)
                    elseif dwidth < 0 then
                        item = item:sub(1, M.max_width[jdx]-1) .. M.bufinfo.more
                    end
                    line = line .. item
                else
                    local item = "       " .. buf_row[M.show[jdx]] .. " "
                    line = line .. item:sub(-M.max_width[jdx])
                end
            end

            -- add grouping icons
            if M.grp_padding >0 then
                local grp = " "
                if buf_row.grpid == 1 then
                    grp = M.bufinfo.grptop
                elseif buf_row.grpid == 3 then
                    grp = M.bufinfo.grpmid
                elseif buf_row.grpid == 4 then
                    grp = M.bufinfo.grpbot
                end
                line = grp .. line:sub(1, M.max_width_sum + M.max_padding+ 2) .. " "
                hlstart=3
            end
        else
            highlight = buf_row.highlight or "Normal"
            line      = buf_row.text
        end

        -- Write the line
        -- cut the line first before write, otherwise the text goes beyond the window size
        line = line:sub(1,M.win_conf.width+10)
        api.nvim_buf_set_text(buf, linenr, 0, linenr, M.win_conf.width+1, { line })

        -- Highlight line and icon
        api.nvim_buf_add_highlight(buf, -1, highlight, linenr, hlstart, -1)
        if buf_row['loaded'] == 1 then
            if buf_row['hl_icon'] then
                local pos = line:find(buf_row['icon'], 1, true)
                if pos ~= nil then
                    api.nvim_buf_add_highlight(buf, -1, buf_row['hl_icon'], linenr, pos, pos + buf_row['icon']:len())
                end
            end
        end
    end
end

------------------------------------------------------------------------------
-- cycle through user-pickable lists of positions
function M.cyclePlacement(inc)
    -- just do this once, there should be a better way to do this
    if M.posid < 0 then
        for i=1, #M.position do
            if M.anchor == M.position[i] then
                M.posid = i-1
                break
            end
        end
    end
    M.posid = (M.posid + inc) % (#M.position)
    M.anchor = M.position[M.posid+1]
    M.update()
end

-- cycle through file name types: (base)name, buffer name, full name
function M.cycleNameType(inc)
    -- just do this once, there should be a better way to do this
    if M.key < 0 then
        return
    end
    if M.ntid < 0 then
        for i=1, #M.nametype do
            if M.show[M.key] == M.nametype[i] then
                M.ntid = i-1
                break
            end
        end
    end
    M.ntid = (M.ntid + inc) % (#M.nametype)
    M.show[M.key] = M.nametype[M.ntid+1]
    M.update()
end

-- cycle through group header options 
-- (none, only for group, everything)
function M.cycleGrpHeader()
    M.grp_header = (M.grp_header +1 ) % 3
    M.update()
end

-- toggle (actually cycle) through sort direction options
-- ascending, descending, no sorting
function M.toggleSort(key)
    if M.toggleSortKey:gsub('-','') == key:gsub('-','') then
        key = M.toggleSortKey
        if key:sub(1,1) ~= '-' then
            key = '-' .. key
        else
            key = key:sub(2,key:len())
        end
    else
        M.toggleSortCount = 0
    end
    M.toggleSortCount = (M.toggleSortCount + 1) % 3
    M.toggleSortKey = key
    if M.toggleSortCount == 0 then
        M.sortby = ''
    else
        M.sortby = M.toggleSortKey
    end
    M.update()
end

-- toggling pinning
function M.togglePinned()
    local linenr = api.nvim_win_get_cursor(M.main_win)[1]
    local bufnr=M.buf_table[linenr]["bufnr"]
    if M.pinned[bufnr] == true then
        M.pinned[bufnr] = false
    else
        M.pinned[bufnr] = true
    end
    M.update()
end

-- toggle relative line number
function M.toggleRnu()
    if M.rnu == true then
        M.rnu = false
    else
        M.rnu = true
    end
end

-- Set floating window keymaps
function M.setKeymaps(win, buf)
    -- Basic window buffer configuration
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.jump,
        string.format([[:<C-U>lua require'yabs'.selBufNum(%s, 'window', vim.v.count)<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.h_split,
        string.format([[:<C-U>lua require'yabs'.selBufNum(%s, 'hsplit', vim.v.count)<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.v_split,
        string.format([[:<C-U>lua require'yabs'.selBufNum(%s, 'vsplit', vim.v.count)<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.close,
        string.format([[:lua require'yabs'.closeBufNum(%s)<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    -- api.nvim_buf_set_keymap(
    --     buf,
    --     "n",
    --     M.keymap_conf.preview,
    --     string.format([[:lua require'yabs'.previewBuf()<CR>]], win),
    --     { nowait = true, noremap = true, silent = true }
    -- )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.pinning,
        string.format([[:lua require'yabs'.togglePinned()<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.cycset,
        string.format([[:YABSCycSet<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.rcycset,
        string.format([[:YABSRCycSet<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.cycpos,
        string.format([[:YABSCycPos<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.rcycpos,
        string.format([[:YABSRCycPos<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.cycname,
        string.format([[:YABSCycName<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.rcycname,
        string.format([[:YABSRCycName<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    -- Navigation keymaps
    api.nvim_buf_set_keymap(
        buf,
        "n",
        "q",
        ':lua require"yabs".close()<CR>',
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        "<Esc>",
        ':lua require"yabs".close()<CR>',
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.sortused,
        string.format([[:lua require'yabs'.toggleSort('used:name')<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.sortpath,
        string.format([[:lua require'yabs'.toggleSort('path:name')<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.sortext,
        string.format([[:lua require'yabs'.toggleSort('ext:name')<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.sortbuf,
        string.format([[:lua require'yabs'.toggleSort('bufnr')<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.sortbase,
        string.format([[:lua require'yabs'.toggleSort('name')<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.sortfull,
        string.format([[:lua require'yabs'.toggleSort('fullname')<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.sortinit,
        string.format([[:lua require'yabs'.toggleSort('initial:name')<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(
        buf,
        "n",
        M.keymap_conf.cychdr,
        string.format([[:lua require'yabs'.cycleGrpHeader()<CR>]], win),
        { nowait = true, noremap = true, silent = true }
    )
    api.nvim_buf_set_keymap(buf, "n", "<Tab>",   "j", { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, "n", "<S-Tab>", "k", { nowait = true, noremap = true, silent = true })

    -- Prevent cursor from going to buffer title
    vim.cmd(string.format("au CursorMoved <buffer=%s> if line(\".\") == 1 | call feedkeys('j', 'n') | endif", buf))
end

-- Cycle through user-picked setttings of items to display
function M.cycleSettings(inc)
    -- just do this once, there should be a better way to do this
    if #M.settings < 1 then
        return
    end
    M.setid = (M.setid + inc) % (#M.settings)
    M.show  = M.settings[M.setid+1]

    -- print(vim.inspect(M.settings))
    -- print(M.setid)
    -- print(vim.inspect(M.show))
    M.key   = M.find_key(M.show,"name")

    M.max_width={}
    for idx=1, #M.show do
        M.max_width[idx]=1
    end

    -- Use devicons file symbols
    M.use_devicons = false
    for idx=1, #M.show do
        if M.show[idx] == "icon" then
            M.use_devicons = true
            break
        end
    end
    M.update()
end

------------------------------------------------------------------------------
function M.close()
    -- If YABS is closed using :q the window and buffer indicator variables
    -- are not reset, so we need to take this into account
    M.in_close=true
    xpcall(function()
        -- print('=')
        api.nvim_win_close (M.main_win, false)
        -- print('===')
        api.nvim_buf_delete(M.main_buf, {})
        M.main_win = nil
        M.main_buf = nil
    end, function()
        M.main_win = nil
        M.main_buf = nil
        M.open()
    end)
    M.in_close=false
end

function M.refresh(buf)
    local empty = {}

    local delx1=0
    local delx2=0
    if M.bufinfo.grptop:len() >1 then
        delx1 = 1
        delx2 = 3
    end

    for _ = 1, #M.buf_table do
        empty[#empty + 1] = string.rep(" ", M.win_conf.width+delx1)
    end

    api.nvim_buf_set_option(buf, "modifiable", true)
    api.nvim_buf_set_lines(buf, 0, -1, false, empty)

    M.parseLs(buf)

    -- set the cursor
    vim.cmd("set cursorline")
    if M.rnu then
        vim.cmd("set rnu")
        vim.cmd("set nu")
    end
    api.nvim_win_set_cursor(M.main_win, { M.cur_buf_line_num, M.win_conf.width+delx2})
    vim.opt_local["scrolloff"] = 0
    vim.opt_local["sidescrolloff"] = 0

    -- Disable modifiable when done
    api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Floating buffer list
function M.open()
    M.cur_buf = api.nvim_get_current_buf()

    M.getBufTable()
    M.sort(M.sortby)
    M.decoBufTable()

    local back_win = api.nvim_get_current_win()
    -- Create the buffer for the window
    if not M.main_buf and not M.main_win then
        M.updatePos()
        M.main_buf = api.nvim_create_buf(false, true)
        vim.bo[M.main_buf]["filetype"] = "YABSwindow"
        M.main_win = api.nvim_open_win(M.main_buf, 1, M.win_conf)
        if M.main_win ~= 0 then
            M.refresh(M.main_buf)
            M.setKeymaps(back_win, M.main_buf)
        end
    else
        M.close()
    end
end

function M.update()
    -- don't update while closing, a bit clumsy
    if M.in_close then
        return
    end
    if not M.main_buf and not M.main_win then
    else
        M.close()
        M.cur_buf = api.nvim_get_current_buf()

        M.getBufTable()
        M.sort(M.sortby)
        M.decoBufTable()

        M.updatePos()
        local back_win = api.nvim_get_current_win()
        M.main_buf = api.nvim_create_buf(false, true)
        vim.bo[M.main_buf]["filetype"] = "YABSwindow"
        M.main_win = api.nvim_open_win(M.main_buf, 1, M.win_conf)
        if M.main_win ~= 0 then
            M.refresh(M.main_buf)
            M.setKeymaps(back_win, M.main_buf)
        end
    end
end

-- Close YABS when a main buffer is selected before closing YABS
function M.leave()
    if M.in_close then
        return
    end
    if M.main_buf and M.main_win then
        M.close()
    end
end

return M
