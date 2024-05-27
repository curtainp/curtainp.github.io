return {
	default = {
		dir_path = "static/imgs",
	},
	filetypes = {
		markdown = {
			template = function(context)
				return "![" .. context.cursor .. "](" .. string.sub(context.file_path, 13) .. ")"
			end,
		},
	},
}
