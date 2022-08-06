command! YABSOpen execute "lua require'yabs'.open()"
command! YABSCycSet execute "lua require'yabs'.cycleSettings(1)"
command! YABSRCycSet execute "lua require'yabs'.cycleSettings(-1)"
command! YABSCycPlace execute "lua require'yabs'.cyclePlacement(1)"
command! YABSRCycPlace execute "lua require'yabs'.cyclePlacement(-1)"
" this doesn't seem to work with trailing characters error
command! YABSSort -nargs=1 execute "lua require'yabs'.toggleSort(<f-args>)"
