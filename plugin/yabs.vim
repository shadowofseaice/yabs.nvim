command! YABSOpen execute "lua require'yabs'.open()"
command! YABSCycSet execute "lua require'yabs'.cycleSettings(1)"
command! YABSRCycSet execute "lua require'yabs'.cycleSettings(-1)"
command! YABSCycPos execute "lua require'yabs'.cyclePlacement(1)"
command! YABSRCycPos execute "lua require'yabs'.cyclePlacement(-1)"
command! YABSCycName execute "lua require'yabs'.cycleNameType(1)"
command! YABSRCycName execute "lua require'yabs'.cycleNameType(-1)"
" this doesn't seem to work with trailing characters error
command! YABSSort -nargs=1 execute "lua require'yabs'.toggleSort(<f-args>)"
