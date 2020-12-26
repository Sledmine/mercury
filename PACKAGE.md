# Mercury Packages

Mercury packages are simple zip files with `.merc` extension, they can contain any kind of files required to install a Halo Custom Edition mod, the purpose of a Mercury package is to provide and easy and automated way to install mods without suffering in the attempt, every package has [semantic versioning](https://www.jvandemo.com/a-simple-guide-to-semantic-versioning/) to keep track of every mod, also giving a way to provide updates between packages via binary of text difference, more info about this later on this documentation.

# Package Structure

As mentioned above, a Mercury package is just a zip file with extension `.merc` that contains all the files needed to install a mod, here is an example of a Mercury package content:

```
- maps\forge_island.map
- forge_island.lua
- manifest.json
```

Let's take a look to every file:

 - `maps\forge_island.mp`

This file is a really common file in Halo Custom Edition, we have a `.map` file that we can place
on our `Halo Custom Edition\maps\` folder to play it as always.

- `forge_island.lua`

This is a more modern file in mods for Halo Custom Edition, the `forge_island.map` requires
 a lua script to work, this file should be placed in a path like `Documents\My Games\Halo CE\chimera\lua\scripts\map\` this sometimes can be kind of hard to install for some users, it can result in problems like the user placing it in the wrong folder and similar scenarios, nobody wants angry people complaining about our mod not working by their mistakes.

-  `manifest.json`

This is the most important file for a Mercury package, this json file contains all the data about the package, it has in it different properties to tell Mercury where to place all the files in the `.merc` file, giving a easy way to install any kind of mod, leaving the installation process to a program instead of leaving it to users.

***Note:*** There are some plans to support `.yml` files in the future as manifest files. 

# Manifest Structure

As explained above, a manifest file has different properties to tell Mercury how to install our mod, here is an example of a manifest.json below:

```json
{
    "label": "forgeisland",
    "name": "Forge Island",
    "description": "Forge Island for Halo Custom Edition",
    "version": "1.0.0-beta-1",
    "author": "Shadowmods Team",
    "internalVersion": "1.0.0-beta-1",
    "manifestVersion": "1.0",
    "files": [
        {
            "path": "maps\\forge_island.map",
            "outputPath": "$haloce\\",
            "type": "binary"
        },
        {
            "path": "forge_island.lua",
            "outputPath": "$mygames\\chimera\\lua\\scripts\\map\\",
            "type": "binary"
        }
    ],
    "dependencies": [
        {
            "label": "chimera",
            "version": "1.0.757"
        }
    ]
}
```

Let's take a deeper look at the properties in the manifest.json:

`label`

This is the name used to identify the package in the respository, it's unique to the package, this name should be selected carefully because with a simple name every user will be able to remember it and install it without problems.

`name`

This is the "large" name of the package, you can feel free to make it as big as you want, this is only for interface purposes, it does not affect the installation process.

`description`

This is the description for your package as the name you can feel free to leave here whatever you want, it is only used for interface purposes.

`version`

This value is really important because it represents the version of the package stored in the repository, for practical purposes your mods and software should used the same version, this version value should be always based on [semantic versioning](https://www.jvandemo.com/a-simple-guide-to-semantic-versioning/), it is used to provide forward updates for the package.

`author`

This is really obvious, just the name of the author of the package/mod.

`internalVersion` 

This value is optional and is not designed to be used directly, you can use it to represent a really specific version of a mod or software in another format that is not [semantic versioning](https://www.jvandemo.com/a-simple-guide-to-semantic-versioning/), it is used for interface purposes.

`manifestVersion` 

This value represents which version of the current manifest is being used, manifests are supposed to receive simple changes so this number should not change too often.


`files`

Here is another important property, this is the list of files inside the package to be installed in the game, every **file** has different important properties to use:

```jsonc
{
    // Represents the relative path to a file inside the package
    "path": "examplemod.dll",
    // This is important for updates purposes, this tells Mercury how to update this file
    "type": "binary",
    // This is the final path of the file after installation
    "outputPath": "$haloce\\"
}

```

There are currently 2 different values to use in the "type" property of every file:

- `optional`: This means that this file will not be updated between updates.

- `binary`: This file will be updated by binary difference.

- ~~- `text`: This file will be updated by text difference.~~

***Note:*** Updating files by text difference is not supported yet, files with another type that is not in this list wiil be updated by sending the entire file.

There are some variables you can use in your outputPath properties:

- `$haloce`: This is translated to the current Halo Custom Edition installation path:

```jsonc
{
    "outputPath": "$haloce\\controls\\"
    // The $haloce string part will be replaced at installation time into: "C:\Halo Custom Edition\controls\"
    ...
```

- `$mygames`: This is your default Halo CE folder in the My Games folder Windows entry:

```jsonc
{
    "outputPath": "$mygames\\chimera"
    // The $mygames string part will be replaced at installation time into: "C:\Users\MasterChief117\Documents\My Games\Halo CE\chimera"
    ...
```

`dependencies`

This is the list of dependencies required by this package, a dependency is another package hosted in the Mercury repository, every **dependency** has some properties to use:

```jsonc
{
    // Label name of the dependency package
    "label": "chimera",
    // Version of the dependency package
    "version": "3.14.16",
    // This value can be nil resulting into getting the latest package available
    // It is not recommended as it can result into uncompatible dependencies
}
```

# FAQ

## I created my package already, how can I upload it to the Mercury repository?

We are working on a platform to allow different creators to upload their own packages, being honest there are not too much packages available right now for Halo Custom Edition, instead you can contact us to upload them for you.

## How I can provide an update for my Mercury package?

You don't have to create an update for every package you create, if your package has all the properties mentioned here correctly set and all the required files inside your `.merc` file our repository or platform should be able to create the update automatically between your last package and your new ones, however an update for different builds can't be created automatically due to [semantic versioning](https://www.jvandemo.com/a-simple-guide-to-semantic-versioning/) guidelines, check the [detailed semantic version specifications](https://semver.org/) for more information.

## Can I host my own packages repository?

For sure, Mercury is using an internal api called Vulcano to provide access to different packages, select newest package from repository and more, if you want to host your own packages you can contact us and add your repository to Vulcano as an available mirror for package downloading.

## Is there a tool to create an automated package build process?

Sadly nope, but we are working on a new action for Mercury, someting like:

```
cd MySuperModFolder\
mercury pack --nextMajor
```
Something like this should do the trick,  however it is not that hard to build your own packages via bash scripting or someting similar.

# TODO

```json
{
  "path": "test2.txt",
  "diffPath": "test2.txt.xd3",
  "type": "text",
  "outputPath": "$haloce\\test\\"
}
```