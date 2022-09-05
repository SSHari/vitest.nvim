<div align="center">

# vitest.nvim

###### Run your vitest tests and get results from the comfort of neovim

</div>

## Note

This plugin is pretty rough. It's a WIP and was put together quickly to solve a problem I had. If you run into problems, feel free to open an issue.

## The Problem

You can run vitest in watch mode in a second terminal. Any time you save a file, vitest re-runs the tests and you can see the results. Nothing wrong with that. I just wanted faster results when I ran vitest.

## The Solution

This plugin executes vitest when you write a test file.

It passes the current file as an argument to vitest so only that file is run. Once vitest has finished, errors are reported next to the relevant failure in a test. If there are any errors, additional diagnostic information is provided for the failed line.

This lets you run vitest without having to worry about using another tool (terminal).

That's all it does.

Nothing more. Nothing less (hopefully).

## Installation

- A nightly neovim build is required because this plugin makes use of the `vim.fs` api.
- Install using your favorite plugin manager:

```vim
Plug TheSSHGuy/vitest.nvim
```

## Configuration

### `init_type`

- `autocmd` - this tells neovim to create the user command `VitestStart`. Running the user command will create an autocmd that executes vitest on file save.
- `startup` - this skips the user command and sets up the autocmd when neovim starts.

**Note:** When the autocmd is created a one time user command `VitestStop` is created to clear any existing diagnostic information and stop the process.

### `pattern`

This is the pattern that is used for the autocmd. It's an array of strings that represent filename patterns that should run the autocmd.

It's set to the following by default:

```lua
-- Set to common vitest test filename patterns
local pattern = {
  "**/__tests__/**.{js,jsx,ts,tsx}",
  "*.spec.{js,jsx,ts,tsx}",
  "*.test.{js,jsx,ts,tsx}"
}
```

### `root_markers`

`vitest.nvim` executes the test command from the root directory of your project. This allows you to pass commands like: `./node_modules/vitest/vitest.mjs`.

It's set to the following by default:

```lua
-- Set to common JS project root directory files
local root_markers = {".git", "package.json"}
```

### `vitest_commands`

This is an array of `{path_regex, vitest_command}` tuples that `vitest.nvim` uses to determine which command should be run. This lets you have different commands for different folders.

For example, I might want to target `./node_modules/vitest/vitest.mjs` for one project, but `npm t --` for another project.

`vitest.nvim` loops through this array until a match is found which means patterns that are higher in the list have a higher priority. If you want a catch-all command to be run so you don't have to set things up per project, you can pass `".*"` as the `path_regex` which should catch all paths.

It's set to the following by default:

```lua
-- Set to a catch-all `path_regex` that runs vitest from `node_modules`
local vitest_commands = {{".*", "./node_modules/vitest/vitest.mjs"}}
```

## Usage

```lua
require("vitest").setup({
    init_type = "startup",
    vitest_commands = {{"~/code/proj", "npm t --"}, {".*", "./node_modules/vitest/vitest.mjs"}}
})
```

## Other

You can find out more information about [how a jest version of this plugin was built](https://blog.thesshguy.com/vitest-nvim-a-neovim-plugin) here.
