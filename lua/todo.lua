local M = {}

local state = {
	todo_win = nil,
}

local function expand_path(path)
	if path:sub(1, 1) == "~" then
		return os.getenv("HOME") .. path:sub(2)
	end
	return path
end

local function win_config()
	local width = math.max(math.floor(vim.o.columns * 0.8), 64)
	local height = math.floor(vim.o.lines * 0.8)

	local outer_col = math.floor((vim.o.columns - width) / 2)
	local outer_row = math.floor((vim.o.lines - height) / 2)

	return {
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		col = outer_col,
		row = outer_row,
		title = "TODO LIST",
		title_pos = "center",
		border = "rounded",
	}
end

local function open_floating_file(target_file)
	local expanded_path = expand_path(target_file)

	if vim.fn.filereadable(expanded_path) == 0 then
		vim.notify("todo file does not exist at directory: " .. expanded_path, vim.log.levels.ERROR)
		return
	end

	local buf = vim.fn.bufnr(expanded_path, true)

	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_name(buf, expanded_path)
	end

	vim.bo[buf].swapfile = false

	local win = vim.api.nvim_open_win(buf, true, win_config())
	vim.api.nvim_set_option_value("relativenumber", true, { win = win })

	vim.api.nvim_create_autocmd("BufWinLeave", {
		callback = function()
			state.todo_win = nil
		end,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		noremap = true,
		silent = true,
		callback = function()
			if vim.api.nvim_get_option_value("modified", { buf = buf }) then
				vim.notify("Save your changes", vim.log.levels.WARN)
			else
				state.todo_win = nil
				vim.api.nvim_win_close(0, true)
			end
		end,
	})

	return win
end

local function setup_user_commands(opts)
	local target_file = opts.target_file or "todo.md"
	vim.api.nvim_create_user_command("Td", function()
		if state.todo_win and vim.api.nvim_win_is_valid(state.todo_win) then
			vim.api.nvim_win_close(state.todo_win, true)
			state.todo_win = nil
			return
		end

		state.todo_win = open_floating_file(target_file)
	end, {})
end

M.setup = function(opts)
	setup_user_commands(opts)
end
return M
