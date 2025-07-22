# Declarages
By initMayday 

## Introduction
- Declarages (declarative packages) allows you to decelaratively manage your packages, through a simple lua configuration file!
- Each package manager is managed by a **core**. For example, arch packages are managed via the pacman core.
- Cores are individual scripts that are located within the "cores" folder, allowing them to be easily extensible. Multiple cores can be enabled at 1 time, for example you can enable both the pacman and flatpak core in order to declaratively manage both pacman and flatpak packages.

## Usage & Supported Cores
To run the program, please run declarages /the/directory/to/the/file/theconfigurationfile.lua. If no argument is provided, it will be assumed that there is a packages.lua file in the directory you are running the program from.

**Default (Base configuration)**
```lua
local Configuration = {
    Settings = {
        WarnOnPackageRemovalAbove = 5;
        SuperuserCommand = "sudo";
        AddPathConfirmation = true;
        RemovePathConfirmation = true;
        Cores = { "Pacman", "Flatpak" }
    }
}
```
- WarnOnPackageRemovalAbove: Will ask you to confirm removal of packages if the number of packages to remove is above the specified number (integer)
- AddPathConfirmation:  Will ask you to allow the creation of the path at the specified directory (bool: true / false)
- RemovePathConfirmation:  Will ask you to remove the creation of the path at the specified directory (bool: true / false)
- SuperuserCommand: Prepends the command to the bash commands that the program runs (string: eg. "sudo", "doas")
- RandomActivationMessage: Enables or disables the random message upon running the program to purchase a license (bool: true / false)
- Licensed: Bool you set to mark the program as licensed, disables activation message if true (bool: true / false) - Same functionality-wise to RandomActivationMessage
- Cores: List the cores you want to use & run, see the options for cores below (string: array)


**Pacman Core**
```lua
local Configuration = {
    Pacman = {
       Official = {
        "base",
        "base-devel",
        "git",
        "grub",
       },

       CustomLocation = "/home/user/.aur/",
       Custom = {
        --> Simple Custom
        "vscodium-bin",
 
        --> Advanced Custom
        { Base = "symlink-manager", Sub = {"symlink-manager-git"}, Url = "https://github.com/initMayday/symlink-manager.git"},
        { Base = "declarages", Sub = {"declarages-git"}, Url = "https://github.com/initMayday/declarages.git"},
       },
    },
}
```
- Pacman Table: Contained within Configuration
- Official Table: List packages as strings that you want installed on the system
- CustomLocation: Installation directory for AUR or Custom packages - **please change user to your username**
- Custom Table: Specifying the package just as a string assumes that that the string is the only package installed from the PKGBUILD it clones. It is assumed that the package is in the AUR. You can optionally choose to insert a table instead. This is required if the PKGBUILD that is cloned has multiple sub-packages that are installed, ie. you must list all the packages the PKGBUILD installs in sub-packages (including the base package name if applicable). The URL can also be specified to change where the PKGBUILD is pulled from, allowing packages from outside the AUR to be installed as depicted. Please note that this URL is only read from upon cloning - it is not used again and therefore if you wish to change the URL you should remove the package, rebuild and add the new package.

**Flatpak Core**
```lua
local Configuration = {
    Flatpak = {
        "com.valvesoftware.Steam",
    }
}
```
- Flatpak Table: Contained within configuration. Specify the flatpaks to install as strings.

## Packages
PKGBUILD (Arch)

##  Licensing
Declarages utilises the CC BY-NC-SA 4.0 license, where the share-alike term refers to also sharing the source code. Please see [REPO NAME] for more details.
You will be able to purchase a license at a later date.
