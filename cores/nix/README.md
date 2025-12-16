**Nix Core**
```lua
return {
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
| Field | Description |
| :---: | :---------: |
| Nix Table | Contained within the root table |
Primary Table | List nix packages as strings that you want installed on the system. If the package has a different name on nixpkgs than when installed onto your system (as for example, with konsole, you need to do nix profile add kdePackages.konsole, but when on your system, it is just konsole), then use a table, with Base and Sub values. The Base should be set equal to the name of the package to install, and the Sub should be set equal to the package's name when installed.
Ignore Table | Packages that are unmanaged by this core. These packages will be ignored, and not processed. |

