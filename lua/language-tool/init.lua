--Types
---@class UseCommands
---@field LanguageToolCheck string

---@class LanguageToolOptions
---@field default_language string
---@field api_type "hestapi" | "commandline"
---@field commandline? string
---@field hestapi? string
---@field words? table
---@field user_commands? UseCommands
---@field languagetool_commandline_jar? string

---@class Software
---@field name string
---@field version string
---@field buildDate string
---@field apiVersion integer
---@field status string
---@field premium boolean

---@class DetectedLanguage
---@field name string
---@field code string

---@class Language
---@field name string
---@field code string
---@field detectedLanguage DetectedLanguage

---@class Replacement
---@field value string

---@class Context
---@field text string
---@field offset integer
---@field length integer

---@class Category
---@field id string
---@field name string

---@class Rule
---@field id string
---@field subId string
---@field description string
---@field urls Replacement[]
---@field issueType string
---@field category Category

---@class Match
---@field message string
---@field shortMessage string
---@field offset integer
---@field length integer
---@field replacements Replacement[]
---@field context Context
---@field sentence string
---@field rule Rule

---@class Response
---@field software Software
---@field language Language
---@field matches Match[]
local M = {}
local file_cache_text = vim.fn.stdpath("cache") .. "/LanguageToolText.txt"
local languagetool_commandline = "languagetool-commandline.sh"
local path_languagetool_commandline = vim.fn.stdpath("data") .. "/" .. languagetool_commandline
M.opts =
---@type LanguageToolOptions
{
	default_language = "pt-BR",
	api_type = "restapi",
	hestapi = "https://api.languagetoolplus.com/",
	words = {
		notify_invalid_api_type = "api_type: valor inesperado!",
		notify_curl_required = "Error: comando 'curl' nao encontrado!",
		user_command_check_description = "Raliza uma consulta a api language tool",
		user_command_check_required_args = "Error: comando chedk requer dois argumentos <language> <text>",
		notify_no_write_cache_text = "Error: nao foi possivel salvar o arquivo de texto",
		notify_no_write_commandline = "Error: nao foi possivel salvar o arquivo executavel",
		notify_command_error = "Error: commandline nao encontrado",
	},
	commandline = "languagetool_commandline",
	languagetool_commandline_jar = "",
	user_commands = {
		LanguageToolCheck = "LanguageToolCheck",
	},
}
local function write_in_path(path, data, on_success, on_error)
	local file = io.open(path, "w")
	if file then
		file:write(data)
		file:close()
		on_success()
	else
		on_error()
	end
end
local function write_in_file_commandline(data, callback)
	write_in_path(path_languagetool_commandline, data, function()
		callback()
	end, function()
		vim.notify(M.opts.words.notify_no_write_commandline, vim.log.levels.ERROR)
	end)
end
local function write_in_file_text_cache(data, callback)
	write_in_path(file_cache_text, data, function()
		callback()
	end, function()
		vim.notify(M.opts.words.notify_no_write_cache_text, vim.log.levels.ERROR)
	end)
end

M.languagetool_check = function(lang, text, callback)
	local handleData = function(_, lines)
		local response = vim.json.decode(table.concat(lines, "\n"):match("{.*}"))
		callback(response)
	end

	if M.opts.api_type == "restapi" then
		vim.fn.jobstart({
			"curl",
			"-X",
			"POST",
			"--header",
			"Content-Type: application/x-www-form-urlencoded",
			"--header",
			"Accept: application/json",
			"-d",
			"text=" .. text,
			"-d",
			"language=" .. lang,
			M.opts.hestapi .. "v2/check",
		}, {
			on_stdout = handleData,
		})
	elseif M.opts.api_type == "commandline" then
		write_in_file_text_cache(text, function()
			vim.fn.jobstart({
				M.opts.commandline,
				"--language",
				lang,
				"--json",
				file_cache_text,
			}, { on_stdout = handleData })
		end)
	else
		vim.notify(M.opts.words.notify_invalid_api_type, vim.log.levels.ERROR)
	end
end
local function write_commandline()
	local data = string.format(
		[[#!/bin/bash
	java -jar %s $@
	]],
		M.opts.languagetool_commandline_jar
	)
	write_in_file_commandline(data, function() end)
	vim.fn.system(string.format("ln -s %s /usr/bin", path_languagetool_commandline))
end

function M.valid_opts()
	if M.opts.api_type == "restapi" then
		if not vim.fn.executable("curl") == 0 then
			vim.notify(M.opts.words.notify_curl_required, vim.log.levels.ERROR)
			return
		end
	elseif M.opts.api_type == "commandline" then
		if vim.fn.executable(M.opts.commandline) == 0 then
			if M.opts.languagetool_commandline_jar then
				if not vim.fn.executable("java") == 0 then
					vim.notify(M.opts.words.notify_java_required, vim.log.levels.ERROR)
					return
				else
					write_commandline()
					M.opts.commandline = path_languagetool_commandline
					-- M.opts.commandline = languagetool_commandline
				end
			else
				vim.notify(M.opts.words.notify_command_error, vim.log.levels.ERROR)
				return
			end
		end
	end
end

local function load_opts(defaults, custom)
	if type(custom) ~= "table" then
		return defaults
	end
	local merged = vim.deepcopy(defaults)
	for k, v in pairs(custom) do
		if type(v) == "table" and type(merged[k]) == "table" then
			merged[k] = load_opts(merged[k], v)
		else
			merged[k] = v
		end
	end
	return merged
end

function M.get_selected_text()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_line, start_col = start_pos[2] - 1, start_pos[3] - 1
	local end_line, end_col = end_pos[2] - 1, end_pos[3]
	local lines = vim.api.nvim_buf_get_text(0, start_line, start_col, end_line, end_col, {})
	local text = table.concat(lines, "\n")
	return text
end

function M.languagetool_check_in_virtal_mode()
	local lang = M.opts.default_language
	local text = M.get_selected_text()
	M.languagetool_check(lang, text, function(data)
		vim.notify(vim.inspect(data))
	end)
end

function M.setup(opts)
	M.opts = load_opts(M.opts, opts or {})
	M.valid_opts()
	vim.api.nvim_create_user_command(M.opts.user_commands.LanguageToolCheck, function(event)
		local lang = ""
		local text = ""
		if #event.fargs == 0 then
			lang = M.opts.default_language
			text = M.get_selected_text()
		elseif #event.fargs == 1 then
			lang = event.fargs[1]
			text = M.get_selected_text()
		else
			lang = event.fargs[1]
			text = event.fargs[2]
		end
		print(lang, text)
		M.languagetool_check(lang, text, function(data)
			vim.notify(vim.inspect(data))
		end)
	end, {
		nargs = "*",
		desc = M.opts.words.user_command_check_description,
	})
	vim.api.nvim_set_keymap(
		"v",
		"<Leader>lt",
		":lua require('language-tool').languagetool_check_in_virtal_mode()<CR>",
		{ silent = true }
	)
end

return M
