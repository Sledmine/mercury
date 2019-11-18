local _M = {}

local printString = [[
    %{red bright}usage%{reset}: %{green}mercury %{reset}<action> <params>

    %{yellow}PARAMETERS INSIDE "[ ]" ARE OPTIONAL!!!%{reset}

    %{blue bright}install%{reset}   : Search for packages hosted in Mercury repos to download and install into the game.
            <package> [<parameters>]

            -f      Force installation, will remove old packages and erase existing backupfiles.

            -nb     Avoid creation of backup files.
            
    %{blue bright}remove%{reset}    : Delete previously installed packages in the game.
            <package> [<parameters>]

            -nb     Avoid restoration of backup files.
            
            -eb     This will erase previously created backup files of the package.

    %{blue bright}list%{reset}    : List and show info about all the previously installed packages in the game.
            <package> [<parameters>] -- use "all" as package to show all the installed packages.
 
            -l      Only shows package name.

            -d      Print detailed info about the package.

    %{blue bright}merc%{reset}    : Manually install a specified .merc package.
            <mercPath>

    %{blue bright}update%{reset}  : Update an existent package in the game.
            <package> -- use "all" as package to update all the installed packages.

    %{blue bright}mitosis%{reset} : Create a new instance of Halo Custom Edition with only neccesary base files to run.
            <instanceName>

    %{blue bright}set%{reset}  : Define Mercury current Halo Custom Edition instance to work.
            <instanceName> -- Use "default" to use the default Halo Custom Edition path of the game.

    %{blue bright}version%{reset} : Throw version and related info about Mercury.]]

local function printUsage()
    cprint(printString)
end

-- %{blue bright}setup%{reset}   : Set all the needed values to introduce Mercury into Windows OS.

local function printVersion()
    cprint("About Mercury:\nPackage Manager for Halo Custom Edition")
    cprint("GNU General Public License v3.0")
    cprint("Developed by Jerry Brick, Sledmine")
    cprint("Lua rocks ma dudeee!\n")
end

_M.printUsage = printUsage
_M.printVersion = printVersion

return _M