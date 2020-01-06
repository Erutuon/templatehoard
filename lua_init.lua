local HOME = os.getenv 'HOME'
package.path = HOME .. '/share/lua/5.3/?.lua;' .. HOME .. '/share/lua/5.3/?/init.lua;' .. package.path
package.cpath = HOME .. '/lib/lua/5.3/?.so;' .. package.cpath
pcall(function()
	dofile "./lua_init.lua"
end)
