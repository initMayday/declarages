**Flatpak Core**
```lua
return {
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
| Field | Description |
| :---: | :---------: |
| Flatpak Table | Contained within the root table |
| Primary Table | List flatpaks as strings that you want installed on the system. |
| Ignore Table | Packages that are unmanaged by this core. These packages will be ignored, and not processed. |


