# todo.lua

This project is heavily WIP. It is based on
[todo.txt](https://github.com/todotxt/todo.txt). I will not elaborate on how it
works further until it is fit for purpose. The TaskWarrior section may be
useful for someone already using TaskWarrior and looking to use a different
method of prioritizing their tasks.. it is incomplete as well, however.

## TaskWarrior

I might replace the intent of this project with just tools to work with
TaskWarrior. For now, I have implemented a hook to use Reddit's hot sorting
method to assign a custom urgency to a User Defined Attribute called `tanpri`
whenever a task is created or modified.

I have not figured out how to make TaskWarrior use this value for sorting yet.

- `on-add.tangent-priority.lua` and `on-modify.tangent-priority.lua` should be
  placed inside TaskWarriors' hooks directory (by default located in
  `~/.task/hooks`) and marked executable (`chmod +x <file>`). You can run `task
  diag` to see if they are installed properly.
- `recommended.taskrc` contains the modifications I made to my `.taskrc` file
  to make it more compatible with how todo.txt works. This includes changing
  how TaskWarrior prioritizes and some of the colors it uses.
- `minimal.taskrc` contains only what is needed to make your TaskWarrior config
  compatible with these hooks.

**Hooks are Lua scripts with a shebang configured for LuaJIT. They require
lua-cjson to be installed for JSON parsing.**

If there's a better way to structure a git repo for sharing TaskWarrior hooks,
please tell me!