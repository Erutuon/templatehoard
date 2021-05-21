local count = 0
local language_names_path, limit_arg = ...
assert(type(language_names_path) == "string", "supply path to language names Lua module in first argument")
local limit = limit_arg and (tonumber(limit_arg) or error(limit_arg .. " is not an integer"))
	or math.maxinteger

local language_name_to_code = dofile(language_names_path)

local language_printer_mt = {
	__index = table,
	__gc = function(self)
		if self[1] then
			if self[2] then
				self:sort()
			end
			print(self.title, self:unpack())
		else
			io.stderr:write(("No language headers found on [[%s]]\n"):format(self.title))
		end
	end,
}

local function make_language_printer(title)
	return setmetatable({ title = title }, language_printer_mt)
end

local languages

local prev_title

local function memoize(func)
	local memo = {}
	return function(val)
		local res = memo[val]
		if not res then
			res = func(val)
			memo[val] = res
		end
		return res
	end
end

local is_entry = memoize(function (title)
	local namespace, language_name = title:match "^(%u%l+):([^/]*)/?"
	return
		not (namespace == "Reconstruction" or namespace == "Appendix") or
		language_name_to_code[language_name:gsub("_", " ")] ~= nil
end)

return function(header, title)
	if is_entry(title) then
		if title ~= prev_title then
			languages = make_language_printer(title)
			prev_title = title
		end
		
		if header.level == 2 then
			local code = language_name_to_code[header.text]
			if code then
				languages:insert(code)
				count = count + 1
			end
		end
	end
	
	return count < limit
end
