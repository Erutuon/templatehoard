-- This normalizes title to the "pretty" form with spaces,
-- because that is used in the entry_index.
local function normalize_title(title)
	return (title:gsub("_", " "))
end

local function eprint(...)
	io.stderr:write(...)
	io.stderr:write "\n"
end

local function get_entry_redirects(path)
	local title_to_redirects = {}
	local i = 0
	for line in io.lines(path) do
		local from, to = line:match "^([^\t]+)\t([^\t]+)$"
		i = i + 1
		if not from then
			eprint("Line #", i, " ,", line, ", didn't match pattern")
		else
			from, to = normalize_title(from), normalize_title(to)
			local redirects = title_to_redirects[to]
			if not redirects then
				redirects = {}
				title_to_redirects[to] = redirects
			end
			table.insert(redirects, from)
		end
	end
	return title_to_redirects
end

local function process_entry_index(path, title_to_redirects)
	local i = 0
	for line in io.lines(path) do
		local title, languages = line:match "^([^\t]+)\t(.+)$"
		i = i + 1
		if not title then
			eprint("Line #", i, " ,", line, ", didn't match pattern'")
		else
			title = normalize_title(title)
			local redirects = title_to_redirects[title]
			print(line)
			if redirects then
				for _, redirect in ipairs(redirects) do
					print(redirect, languages)
				end
			end
		end
	end
end

-- local HOME = os.getenv "HOME"
-- local entry_redirects = HOME .. "/enwikt-dump-rs/entry_redirects.txt"
-- local entry_index = HOME .. "/entry_index/20200101.txt"

local entry_index, entry_redirects = ...
process_entry_index(entry_index, get_entry_redirects(entry_redirects))
