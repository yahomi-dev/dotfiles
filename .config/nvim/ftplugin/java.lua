-- Java専用の設定
local jdtls = require('jdtls')

-- jdtlsの設定
local config = {
	cmd = { 'jdtls' },

	root_dir = jdtls.setup.find_root { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' },

	settings = {
		java = {
			eclipse = {
				downloadSources = true,
			},
			configuration = {
				updateBuildConfiguration = 'interactive',
				runtimes = {
					{
						name = 'JavaSE-21',
						path = vim.fn.expand('~/.local/share/mise/installs/java/21.0.2'), -- mise Java path
					},
				},
			},
			maven = {
				downloadSources = true,
			},
			implementationsCodeLens = {
				enabled = true,
			},
			referencesCodeLens = {
				enabled = true,
			},
			references = {
				includeDecompiledSources = true,
			},
			inlayHints = {
				parameterNames = {
					enabled = 'all',
				},
			},
			format = {
				enabled = false, -- conform.nvimを使用
			},
		},
		signatureHelp = { enabled = true },
		contentProvider = { preferred = 'fernflower' },
		completion = {
			favoriteStaticMembers = {
				-- 'java.util.Objects.requireNonNull',
				-- 'org.mockito.Mockito.*',
			},
			importOrder = {
				'java',
				'javax',
				'com',
				'org',
			},
		},
		sources = {
			organizeImports = {
				starThreshold = 9999,
				staticStarThreshold = 9999,
			},
		},
		codeGeneration = {
			toString = {
				template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
			},
			useBlocks = true,
		},
	},

	on_attach = function(client, bufnr)
		-- 既存のLSP共通設定を継承
		-- attach.luaのLspAttachオートコマンドが自動実行される

		-- Java専用のキーマップを追加
		local opts = { buffer = bufnr, silent = true }

		-- リファクタリング機能
		vim.keymap.set('n', '<leader>jo', function()
			jdtls.organize_imports()
		end, opts)
		vim.keymap.set('n', '<leader>jv', function()
			jdtls.extract_variable()
		end, opts)
		vim.keymap.set('n', '<leader>jc', function()
			jdtls.extract_constant()
		end, opts)
		vim.keymap.set('n', '<leader>jm', function()
			jdtls.extract_method()
		end, opts)

		-- ビジュアルモード用
		vim.keymap.set('v', '<leader>jv', function()
			jdtls.extract_variable(true)
		end, opts)
		vim.keymap.set('v', '<leader>jc', function()
			jdtls.extract_constant(true)
		end, opts)
		vim.keymap.set('v', '<leader>jm', function()
			jdtls.extract_method(true)
		end, opts)
	end,

	capabilities = require('cmp_nvim_lsp').default_capabilities(),

	flags = {
		allow_incremental_sync = true,
	},

	init_options = {
		bundles = {},
	},
}

-- jdtlsを起動
jdtls.start_or_attach(config)
