# Mercury Lua Bundler

Mercury can be used to create a distributable script from a modular lua project that has pure lua
modules, resulting in a single script with modules built inside, all what is needed is a simple
bundle.json file on the root of our lua project and that will do the magic.

# Code Project Structure

Let's see a simple example of how to bundle a modular lua project, here is a short structure of
our code project:

```
modules\
    - json.lua
    stuff\
        - mymodule.lua
- bundle.json
- myscript.lua
```

Let's take a look to every file:

 - `modules\json.lua`

This is a lua module that can be imported in order to add json decoding/encoding support in our lua
script, it has no other module dependencies and it is made in pure lua, so no weird DLLs or other
stuff is required, this is what is called a pure lua module.

- `modules\stuff\mymodule.lua`

This is another example of a pure lua module that we can ship with our final script, the difference
now is that this is a module made by us, we decide where it is placed and how it should work, this
type of module can be bundled too.

-  `myscript.lua`

This is almost the most important file in the project structure, our main script
that ignites the script entry point, this file would be bundled too.

- `bundle.json`

Finally this is the file that will tell Mercury how our project would be bundled in single script
output, all the info required for that is here.

# Bundle File

As explained above, the bundle.json file has all the requirements to bundle our project, the content
of a bundle.json file could be something like this:

```json
{
    "name": "My Project",
    "target": "lua53",
    "include": [
        "modules\\"
    ],
    "modules": [
        "json",
        "stuff\\mymodule"
    ],
    "main":"myscript",
    "output": "dist\\myscriptbundled.lua"
}
```

Let's take a deeper look at the properties in the bundle.json:

`name`

Name of the project, it does not have a real use right now, it just makes simpler to understand
which project you are bundling.

`target`

This is the lua version compiler target, if you would like to compile your final script using the
`luac` compiler you have to place the name of the lua executable compiler here, an example could be
luac53, luajitc, lua5.3c, etc.

**NOTE:** It is not neccessary to set this property but if you definitely want to compile your
output script then your compiler should be available in the `PATH` environment variable to make this
work.

`include`

This is an array/list of folders where your modules can be found, similar to the includes folder
in compilers like C or C++.

`modules`

Similar to the `include` property this one is an array/list of the modules that will be added into
your final bundled script.

`main`

A really important property, this is the main script to run as the main entry of the bundled script
it should be named just as the name of the script without the .lua extension on it, it can also be
the relative or the entire path to the main script.

`output` 

At last but not least is the output file name of your bundled script, here you can define the name
of the resulting script using an entire or relative path as well, this property must include the
extension result of the file.

# Create or Bundle a Project

After all the explanation from above we now should be able to start creating modular lua projects
using Mercury, there are a few tools available on the `luabundle` command from Mercury, here are
a few examples of how to use them:

## Create a bundle.json template file
```
cd MySuperProjectFolder
mercury luabundle -t
```
This command will create `bundle.json` file with common properties by default, this will help you to start the creation of a modular lua project, the `-t` flag stands for the short version of the `--template` flag, meaning this command will create an example of a `bundle.json` file

## Bundle a project directly
```
cd MySuperProjectFolder
mercury luabundle
```
This should read our `bundle.json` file and generate a single output script based on the information
from this file, it will keep all our comments and modules in the exact same source form.

## Bundle a project and compiling the resultant file
```
cd MySuperProjectFolder
mercury luabundle -c
```
The `-c` flag stands for the short version of the `--compile` flag, meaning that this bundle would
be compiled **AFTER** gathering and bundling all the modules required in the `bundle.json` file.


## Bundle a project using a different bundle.json file
```
cd MySuperProjectFolder
mercury luabundle server
```
This command will look for a file called `serverBundle.json` and will read the properties from there
instead of looking at the default `bundle.json` file, the name parameter can be any kind of name,
the only requirement is to add the word "**Bundle**" at the end of our target file, some examples are:
**clientBundle.json**, **old_versionBundle.json**, **oldVersionBundle.json**,
**weird_snake_case_file_nameBundle.json**.

# FAQ

## Is Mercury trying to be some kind of package manager for lua code?

Nope, not at all, but I'm not really sure about that in the future, I mean Mercury is already
working as a package manager for Halo Custom Edition mods so getting support for specific
Halo Custom Edition lua modules is not that crazy but is definitely out of the scope right now.

# Join us on Discord
Feel free to join the [Shadowmods Discord Server](https://discord.shadowmods.net) if you want to
have some assistance at using Mercury! 