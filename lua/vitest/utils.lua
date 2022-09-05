local M = {}

local combine_string_array = function(arr)
    local combined_string = ""
    for _, next_string in ipairs(arr) do combined_string = combined_string .. next_string end
    return combined_string
end

M.parse_output = function(data)
    local loop_counter = 0

    -- Remove any output that isn't part of the json
    while data[1] ~= "{" and loop_counter < 100 do
        table.remove(data, 1)
        loop_counter = loop_counter + 1
    end

    local json_string = combine_string_array(data)
    local success, json = pcall(vim.json.decode, json_string)
    if success then return json end
end

M.find_root_dir = function(root_markers)
    local full_path = vim.fn.expand("%:p")
    return vim.fs.dirname(vim.fs.find(root_markers, {path = full_path, upward = true})[1])
end

M.find_matching_command = function(vitest_commands, root_dir)
    for _, command_tuple in ipairs(vitest_commands) do
        local path_regex = command_tuple[1]
        local vitest_command = command_tuple[2]

        if string.match(root_dir, path_regex) then return vitest_command end
    end
end

M.icons = {success = "✓", error = "✕", result = "●"}

return M
