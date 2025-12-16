**Pacman Core**
```lua
return {
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
| Field | Description |
| :---: | :---------: |
| Pacman Table | Contained within the root table |
| Primary Table | List packages (to be installed via pacman directly) as strings that you want installed on the system. |
| Custom Table | Specify the packages you want to install that are not from pacman (ie. from the AUR). Specifying just the name will assume the package is in the AUR, and installs no sub-packages other than itself. If this is not the case, see how to do more complex installations in the example above. |
| Ignore Table | Packages that are unmanaged by this core. These packages will be ignored, and not processed. |
| Settings Table | CustomLocation: Installation directory for AUR or Custom packages - **please change user to your username**. Note that this settings table is not the same as the settings table the root table. This settings table is stored within the pacman table, and the pacman table is a child of the root table. |


