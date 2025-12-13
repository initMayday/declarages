# Declarages
By initMayday 

## Introduction
- Declarages (declarative packages) allows you to decelaratively manage your packages, through a simple lua configuration file!
- Each package manager is managed by a **core**. For example, arch packages are managed via the pacman core.
- Cores are individual scripts that are located within the "cores" folder, allowing them to be easily extensible. Multiple cores can be enabled at one time, for example you can enable both the pacman and flatpak core in order to declaratively manage both pacman and flatpak packages.

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
        Purchased = false;
        Cores = { "Pacman", "Flatpak", "Nix" }
    }
}
```
- WarnOnPackageRemovalAbove: Will ask you to confirm removal of packages if the number of packages to remove is above the specified number (integer)
- AddPathConfirmation:  Will ask you to allow the creation of the path at the specified directory (bool: true / false)
- RemovePathConfirmation:  Will ask you to remove the creation of the path at the specified directory (bool: true / false)
- SuperuserCommand: Prepends the command to the bash commands that the program runs (string: eg. "sudo", "doas")
- RandomActivationMessage: Enables or disables the random message upon running the program to purchase a license (bool: true / false)
- Purchased: Nudge to purchase the program, if it is useful to you. This is purely visual and the program never reads this variable.
- Cores: List the cores you want to use & run, see the options for cores below (string: array)

**Pacman Core**
```lua
local Configuration = {
    Pacman = {
       Primary = {
        "base",
        "base-devel",
        "git",
        "grub",
       },

       Custom = {
            --> Simple Custom
            "vscodium-bin",
 
            --> Advanced Custom

            -- Here are all the possible configuration options to set.
            -- Setting any variable listed below RPC, sets RPC to false. RPC is
            -- enabled by default. You will not commonly need to set these commands
            -- these overrides exist for extreme cases
            {
                Base = "",
                Sub = {},
                RPC = true,
                VersionCmd = "",
                UpdateRemoteCmd = "",
                PrepareCmd = "",
                CloneCmd = "",
                BuildCmd = "",
            },]]

            -- An example where RPC isn't being used since CloneCmd is being set. You may
            -- also want to disable RPC for -git packages as maintainers on the AUR aren't
            -- required to keep the AUR package version up to date.
	        { Base = "Rust-VPN-Handler", Sub = {"vpn-handler-git"}, CloneCmd = "git clone https://github.com/initMayday/Rust-VPN-Handler"},
        },

        Ignore = {
            "kicad",
        },

        Settings = {
            CustomLocation = "/home/user/.aur/",
        },
    },
}
```
- Pacman Table: Contained within Configuration
- Primary Table: List packages (to be installed via pacman directly) as strings that you want installed on the system.
- Custom Table: Specifying the package just as a string assumes that that the string is the only package installed from the PKGBUILD it clones. It is assumed that the package is in the AUR. You can optionally choose to insert a table instead. This is required if the PKGBUILD that is cloned has multiple sub-packages that are installed, ie. you must list all the packages the PKGBUILD installs in sub-packages (including the base package name if applicable. This also works for the primary table, but I have not seen a situation where it is needed, but it is there). The URL can also be specified to change where the PKGBUILD is pulled from, allowing packages from outside the AUR to be installed as depicted. Please note that this URL is only read from upon cloning - it is not used again and therefore if you wish to change the URL you should remove the package, rebuild and add the new package.
- Ignore Table: Packages that are unmanaged by this core. These packages will be ignored, and not processed.
- Settings Table: CustomLocation: Installation directory for AUR or Custom packages - **please change user to your username**

**Flatpak Core**
```lua
local Configuration = {
    Flatpak = {
        Primary = {
            "com.valvesoftware.Steam",
        },

        Ignore = {
            "org.kicad.KiCad",
        },
    }
}
```
- Flatpak Table: Contained within Configuration.
- Primary Table: List flatpaks as strings that you want installed on the system.
- Ignore Table: Packages that are unmanaged by this core. These packages will be ignored, and not processed.

**Nix Core**
```lua
local Configuration = {
    Nix = {
        Primary = {
            "librewolf",
            { Base = "kdePackages.konsole", Sub  = "konsole" }
        },

        Ignore = {
            "firefox"
        },
    }
}
```
- Nix Table: Contained within Configuration.
- Primary Table: List nix packages as strings that you want installed on the system. If the package has a different name on nixpkgs than when installed onto your system (as for example, with konsole, you need to do nix profile add kdePackages.konsole, but when on your system, it is just konsole), then use a table, with Base and Sub values. The Base should be set equal to the name of the package to install, and the Sub should be set equal to the package's name when installed. Note that the value of Sub is a string, and not a table like in the pacman core.
- Ignore Table: Packages that are unmanaged by this core. These packages will be ignored, and not processed.

## Packages
[Arch User Repository](https://aur.archlinux.org/packages/declarages)

##  Licensing
Declarages is licensed under `AGPL-3.0-or-later`  
You can purchase the program for 5GBP (or equivalent) [here](https://github.com/initMayday/licensing/blob/master/payment.md)
