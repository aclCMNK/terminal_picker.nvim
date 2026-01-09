local API = {
	trim = function(s)
		return string.gsub(s, "^%s*(.-)%s*$", "%1")
	end,
	IDGen = function()
		local usedIDs = {}
		local timestamp = os.time()
		local random = math.random(10000, 99999)
		local id = string.format("%d_%d", timestamp, random)
		-- Asegurar unicidad en caso de colisión
		while usedIDs[id] do
			random = math.random(10000, 99999)
			id = string.format("%d_%d", timestamp, random)
		end
		usedIDs[id] = true
		return id
	end,
	split = function(str, sep)
		local result = {}
		local pattern = "([^" .. sep .. "]+)"
		for part in string.gmatch(str, pattern) do
			table.insert(result, part)
		end
		return result
	end,
}
local M = {
	Regular_terminal = function(path, props, cmd)
		cmd = cmd or ""
		path = path or vim.loop.cwd()
		if API.trim(path) == "" then
			path = vim.loop.cwd()
		end
		if API.trim(cmd) ~= "" then
			cmd = " " .. cmd
		end
		props = props or {}
		return "FloatermNew! --width=" ..
			(props.width or "0.9") ..
			" --height=" ..
			(props.height or "0.9") ..
			" --position=" ..
			(props.position or "center") ..
			" --wintype=" ..
			(props.wintype or "float") ..
			" --autoclose=" ..
			(props.autoclose or 0) ..
			" --titleposition=" .. (props.titleposition or "left") ..
			" --borderchars=" .. (props.borderchars or "─│─│┌┐┘└") ..
			" --shell=" .. (props.shell or "&shell") ..
			" --name={%name_id%} --title=[{%icon%}{%name%}][$1/$2]" ..
			" cd '" .. path .. "' && clear" .. cmd
	end,
	External_tool = function(path, tool, props)
		path = path or vim.loop.cwd()
		tool = tool or ""
		if API.trim(path) == "" then
			path = vim.loop.cwd()
		end
		if API.trim(tool) == "" then
			return nil
		end
		if API.trim(path) == "" then
			path = vim.loop.cwd()
		end
		props = props or {}
		return "FloatermNew --name={%name_id%} --title=[{%icon%}{%name%}][$1/$2]" ..
			" --width=" .. (props.width or "0.9") ..
			" --height=" .. (props.height or "0.9") ..
			" --position=" ..
			(props.position or "center") ..
			" --wintype=" ..
			(props.wintype or "float") ..
			" --autoclose=" ..
			(props.autoclose or 0) ..
			" --titleposition=" .. (props.titleposition or "left") ..
			" --borderchars=" .. (props.borderchars or "─│─│┌┐┘└") ..
			" --shell=" .. (props.shell or "&shell") ..
			" --cwd=" .. path .. " " .. tool
	end
}

local _PATH = ""
local _config = {}
local _fzf = nil
local _fzf_props = {}
local _terms = {}

local function Choice_terminal(choice)
	local split_spaces = API.split(choice, " ")
	local preID = split_spaces[#split_spaces]
	local id = string.gsub(preID, "]", "")
	local item = _terms[id]
	vim.fn["floaterm#terminal#open_existing"](item.bufnr)
	vim.defer_fn(function()
		if vim.api.nvim_get_mode().mode ~= 't' then
			vim.cmd('startinsert')
		end
	end, 10)
end

local function Select()
	local buffer = {}
	local list = {}
	local buflist = vim.fn['floaterm#buflist#gather']()
	for _, v in ipairs(buflist) do
		local name = vim.fn.getbufvar(v, 'floaterm_name', '')
		table.insert(buffer, { bufnr = v, id = name })
		_terms[name].bufnr = v
		table.insert(list, _terms[name].key .. " [" .. _terms[name].name .. "] [ID: " .. name .. "]")
	end
	local title = "Choice a terminal"
	if _fzf ~= nil then
		_fzf_props["prompt"] = title
		_fzf_props["cwd"] = _PATH
		_fzf_props["actions"] = {
			["default"] = function(selected)
				local choice = selected[1]
				if choice then
					Choice_terminal(choice)
				end
			end
		}
		if _fzf_props["winopts"] == nil then
			_fzf_props["winopts"] = {
				height = 0.35,
				width = 0.50,
				border = "rounded",
			}
		end
		_fzf.fzf_exec(list, _fzf_props)
		return
	end
	vim.ui.select(list, { prompt = title }, function(choice)
		if choice then
			Choice_terminal(choice)
		end
	end)
end


local function Input_name(hook)
	vim.ui.input({ prompt = "Terminal name: " }, function(input)
		if input then
			if type(hook) == "function" then
				hook(input)
			end
		else
			return
		end
	end)
end

local function Chioce_cmd(choice, name, dicc, hook)
	local id = API.IDGen()
	local item = dicc[choice]
	local icon = item.icon or ""
	if API.trim(icon) ~= "" then
		icon = icon .. "__"
	end
	name = string.gsub(name, " ", "_")
	item.cmd = string.gsub(item.cmd, "{%%name%%}", name)
	item.cmd = string.gsub(item.cmd, "{%%name_id%%}", id)
	item.cmd = string.gsub(item.cmd, "{%%icon%%}", icon)
	if type(hook) == "function" then
		hook(id, item)
	end
end

local function Input_cmd(name, hook)
	local term_tools = {
		{ icon = "", name = "terminal", cmd = M.Regular_terminal(_PATH) },
	}
	for _, v in pairs(_config.tools or {}) do
		local vdata = { icon = v.icon, name = v.name }
		if type(v.cmd) == "function" then
			vdata.cmd = v.cmd()
		elseif type(v.cmd) == "string" then
			vdata.cmd = v.cmd
		end
		if type(vdata.cmd) ~= "nil" then
			table.insert(term_tools, vdata)
		end
	end
	local list = {}
	local dicc = {}
	for _, v in pairs(term_tools) do
		table.insert(list, v.name)
		dicc[v.name] = { icon = v.icon, name = v.name, cmd = v.cmd }
	end
	local title = "Choice a tool to run in a terminal"
	if _fzf ~= nil then
		_fzf_props["prompt"] = title
		_fzf_props["cwd"] = _PATH
		_fzf_props["actions"] = {
			["default"] = function(selected)
				local choice = selected[1]
				if choice then
					Chioce_cmd(choice, name, dicc, hook)
				end
			end
		}
		if _fzf_props["winopts"] == nil then
			_fzf_props["winopts"] = {
				height = 0.35,
				width = 0.50,
				border = "rounded",
			}
		end
		_fzf.fzf_exec(list, _fzf_props)
		return
	end
	vim.ui.select(list, { prompt = title }, function(choice)
		if choice then
			Chioce_cmd(choice, name, dicc, hook)
		end
	end)
end

local function Create_new_terminal(id, name, item)
	local success, resp = pcall(vim.cmd, item.cmd)
	vim.defer_fn(function()
		if vim.api.nvim_get_mode().mode ~= 't' then
			vim.cmd('startinsert')
		end
	end, 10)
	item.key = string.gsub(name, " ", "_")
	_terms[id] = item
end

local function New_terminal()
	_PATH = vim.g.projpath or vim.loop.cwd()
	if type(_PATH) == "string" and _PATH == "" then
		_PATH = vim.loop.cwd()
	end

	vim.defer_fn(function()
		vim.cmd(":FloatermHide")
		Input_name(function(name)
			name = string.gsub(name, " ", "_")
			Input_cmd(name, function(id, cmd)
				Create_new_terminal(id, name, cmd)
			end)
		end)
	end, 10)
end

local function Kill_all()
	local buflist = vim.fn['floaterm#buflist#gather']()
	_terms = {}
	for _, v in ipairs(buflist) do
		vim.fn['floaterm#terminal#kill'](v)
	end
end

M.setup = function(props)
	props = props or {}
	_config = props.config or {}
	local has_fzflua, _ = pcall(require, "fzf-lua")
	if has_fzflua == true then
		_fzf_props = props.fzf_lua or {}
		_fzf = require("fzf-lua")
	end

	vim.api.nvim_create_user_command("TerminalPicker", Select, {})
	vim.api.nvim_create_user_command("TerminalPickerNew", New_terminal, {})
	vim.api.nvim_create_user_command("TerminalPickerKillAll", Kill_all, {})
end

return M
