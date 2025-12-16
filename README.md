# Declarages
By initMayday 

## Introduction
#### Declarages (declarative packages) allows you to decelaratively manage your packages, through a simple lua configuration file!  

Each package manager is managed by a **core**. For example, arch packages are managed via the pacman core.
Cores are individual scripts that are located within the "cores" folder, allowing them to be easily extensible. Multiple cores can be enabled at one time, for example you can enable both the pacman and flatpak core in order to declaratively manage both pacman and flatpak packages.

## Usage
To run the program, please run declarages /the/directory/to/the/file/theconfigurationfile.lua. If no argument is provided, it will be assumed that there is a packages.lua file in the directory you are running the program from.

## Base Configuration
Your lua configuration file must return a table. From here on, that table will be referred to as the root table. The root table must contain a Settings table, specifying all of the following options:
```lua
return {
    Settings = {
        WarnOnPackageRemovalAbove = 5;
        SuperuserCommand = "sudo";
        AddPathConfirmation = true;
        RemovePathConfirmation = true;
        --> Never read, just a nudge to purchase the program if it useful to you
        Purchased = false; 
        --> Which cores you want to use. See the documentation below
        --> to see how to configure each core
        Cores = { "Pacman", "Flatpak", "Nix" }
    }
}
```

## Cores Configuration
Alongside the Settings table, you must also provide a table for the configuration of any core you use, in the root table. See the table below for information on how to configure each core, with examplles.
| Core | Configuration |
| :--: | :--: |
| Pacman | [Docs](cores/pacman/README.md) |
| Flatpak | [Docs](cores/flatpak/README.md) |
| Nix | [Docs](cores/nix/README.md) |


## Packages
| Repo | Source |
| :--: | :--: |
| Arch User Repository | [Link](https://aur.archlinux.org/packages/declarages) |

## Contributing
All cores run independently, meaning any additional core should be easily integrateable! Simply create a folder in cores with the [name], and then a subsequent [name].lua in that rolder with a README.md documenting it. That core can then be dynamically ran, for testing and management. Please keep dependencies (not including the package manager itself) minimal, and where possible re-utilise existing dependencies in the rockspec file. If you have any questions, feel free to contact me directly, or open a discussion. Thanks!

##  Licensing
The projects's source code is licensed under `AGPL-3.0-or-later`  

The branding (eg. project name, logos etc.) is not covered by the aforementioned license, and remains the sole property of initMayday. Please seek permission from myself before using it, if required, to determine if it is an acceptable use case. Reasonable descriptive use (eg. packaging, articles, etc.) is an example of an acceptable use case. If there are any queries regarding this, please ask.  

You can purchase the program for 5GBP (or equivalent) [here](https://github.com/initMayday/licensing/blob/master/payment.md)
