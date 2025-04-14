---@type vim.lsp.Config
return {
	cmd = { 'tailwindcss-language-server', '--stdio' },
	filetypes = {
		-- css
		'css',
		'less',
		'postcss',
		'sass',
		'scss',
		'stylus',
		'sugarss',
		-- js
		'javascript',
		'javascriptreact',
		'reason',
		'rescript',
		'typescript',
		'typescriptreact',
		-- mixed
		'vue',
		'svelte',
		'templ',
	},
	root_markers = {
		'tailwind.config.js',
		'tailwind.config.cjs',
		'tailwind.config.mjs',
		'tailwind.config.ts',
		'postcss.config.js',
		'postcss.config.cjs',
		'postcss.config.mjs',
		'postcss.config.ts',
		'package.json',
		'.git',
	},

	settings = {
		tailwindCSS = {
			validate = true,
			lint = {
				cssConflict = 'warning',
				invalidApply = 'error',
				invalidScreen = 'error',
				invalidVariant = 'error',
				invalidConfigPath = 'error',
				invalidTailwindDirective = 'error',
				recommendedVariantOrder = 'warning',
			},
			classAttributes = {
				'class',
				'className',
				'class:list',
				'classList',
				'ngClass',
			},
			includeLanguages = {
				eelixir = 'html-eex',
				eruby = 'erb',
				templ = 'html',
				htmlangular = 'html',
			},
		},
	},
}
