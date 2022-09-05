local loader = require("vitest.loader")
local utils = require("vitest.utils")

local M = {}

local ns = vim.api.nvim_create_namespace("TheSSHGuy_vitest.nvim")

local create_vitest_run_autocmd = function(config)
    local autocmd_nr = vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("TheSSHGuy_vitest.nvim", {clear = true}),
        pattern = config.pattern,
        callback = function()
            -- Skip trying to run the tests if a root dir can't be found
            local root_dir = utils.find_root_dir(config.root_markers)
            if not root_dir then return end

            local bufnr = vim.api.nvim_get_current_buf()
            local bufnm = vim.api.nvim_buf_get_name(bufnr)

            -- Clear previous diagnostics
            vim.diagnostic.reset(ns, bufnr)

            -- Clear previous namespace highlights
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

            local append_data = function(_, data)
                if data then
                    local json = utils.parse_output(data)
                    if not json then return end

                    local testResults = json.testResults[1]
                    local assertionResults = testResults.assertionResults

                    -- Keep track of diagnostics for any test that failed
                    local diagnostics = {}

                    for _, result in ipairs(assertionResults) do
                        -- lines are 0 based in nvim_buf_set_extmark but 1 based in vitest
                        local line = result.location and result.location.line - 1 or nil

                        if result.status == "failed" then
                            -- Set status icon
                            local text = {utils.icons.error, "DiagnosticError"}
                            vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {virt_text = {text}})

                            -- Create diagnostics for test error
                            for _, message in ipairs(result.failureMessages) do
                                local diagnostic_structure = {
                                    bufnr = bufnr,
                                    lnum = line,
                                    end_lnum = line,
                                    col = 0,
                                    message = utils.icons.result .. " " .. message,
                                    source = "vitest.nvim diagnostics"
                                }

                                table.insert(diagnostics, diagnostic_structure)
                            end

                        end
                    end

                    -- Set the diagnostics
                    vim.diagnostic.set(ns, bufnr, diagnostics, {virtual_text = false})
                end
            end

            -- Skip trying to run the tests if a matching command can't be found
            local command = utils.find_matching_command(config.vitest_commands, root_dir)
            if not command then return end

            command = command .. " --run --reporter json " .. bufnm

            local stop_loader = loader.start();

            vim.fn.jobstart(command, {
                cwd = root_dir,
                stdout_buffered = true,
                on_stdout = append_data,
                on_stderr = append_data,
                on_exit = stop_loader
            })
        end
    })

    -- Create a one time user command to stop the process
    vim.api.nvim_create_user_command("VitestStop", function()
        -- Clear plugin display information
        local bufnr = vim.api.nvim_get_current_buf()
        vim.diagnostic.reset(ns, bufnr)
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

        -- Remove the autocmd and user command
        vim.api.nvim_del_autocmd(autocmd_nr)
        vim.api.nvim_del_user_command("VitestStop")
    end, {})
end

M.setup = function(config)
    local base_config = {
        init_type = "autocmd",
        pattern = {"**/__tests__/**.{js,jsx,ts,tsx}", "*.spec.{js,jsx,ts,tsx}",
                   "*.test.{js,jsx,ts,tsx}"},
        root_markers = {".git", "package.json"},
        vitest_commands = {{".*", "./node_modules/vitest/vitest.mjs"}}
    }

    local merged_config = vim.tbl_deep_extend("force", base_config, config)

    -- Verify config is valid
    vim.validate({
        init_type = {merged_config.init_type, function(arg)
            return arg == "autocmd" or arg == "startup"
        end, "autocmd or startup"},
        pattern = {merged_config.pattern, "table"},
        root_markers = {merged_config.root_markers, "table"},
        vitest_commands = {merged_config.vitest_commands, "table"}
    })

    if merged_config.init_type == "startup" then create_vitest_run_autocmd(merged_config) end
    if merged_config.init_type == "autocmd" then
        vim.api.nvim_create_user_command("VitestStart", function()
            create_vitest_run_autocmd(merged_config)
        end, {})
    end
end

return M
