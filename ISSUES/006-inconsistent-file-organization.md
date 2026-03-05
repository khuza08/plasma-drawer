# Issue: Inconsistent File Organization

## Summary
Configuration QML files are placed in `contents/ui/` instead of `contents/config/`, creating an inconsistent project structure.

## Current Structure
```
contents/
├── code/
│   └── tools.js
├── config/
│   ├── config.qml          # Config model definition
│   └── main.xml            # Config schema
├── locale/
│   └── [translations]
└── ui/
    ├── ActionMenu.qml
    ├── AppsGridView.qml
    ├── CompactRepresentation.qml
    ├── ConfigGeneral.qml   # ← Should be in config/
    ├── ConfigSearch.qml    # ← Should be in config/
    ├── DrawerTheme.qml
    ├── ItemGridDelegate.qml
    ├── ItemGridView.qml
    ├── ItemListDelegate.qml
    ├── ItemListView.qml
    ├── main.qml
    ├── MenuRepresentation.qml
    └── RunnerResultsView.qml
```

## Expected Structure
```
contents/
├── code/
│   └── tools.js
├── config/
│   ├── config.qml
│   ├── main.xml
│   ├── ConfigGeneral.qml   # ✓ Moved from ui/
│   └── ConfigSearch.qml    # ✓ Moved from ui/
├── locale/
│   └── [translations]
└── ui/
    ├── ActionMenu.qml
    ├── AppsGridView.qml
    ├── CompactRepresentation.qml
    ├── DrawerTheme.qml
    ├── ItemGridDelegate.qml
    ├── ItemGridView.qml
    ├── ItemListDelegate.qml
    ├── ItemListView.qml
    ├── main.qml
    ├── MenuRepresentation.qml
    └── RunnerResultsView.qml
```

## Problems
1. **Confusing Navigation**: Developers expect config files in `config/` directory
2. **Inconsistent with KDE Conventions**: Most plasmoids place config QML in `contents/config/`
3. **Path Complexity**: Requires relative path traversal (`../ui/`) in config.qml references
4. **Discovery Issues**: Harder to identify which files are configuration-related

## Proposed Fix
Move configuration files:
```bash
cd /home/huza/repository/plasma-drawer
mv contents/ui/ConfigGeneral.qml contents/config/
mv contents/ui/ConfigSearch.qml contents/config/
```

Update `contents/config/config.qml`:
```qml
ConfigCategory {
     name: i18n("General")
     icon: "kde"
     source: "ConfigGeneral.qml"  // Now works without path traversal
}
ConfigCategory {
     name: i18n("Search Plugins")
     icon: "search"
     source: "ConfigSearch.qml"
}
```

## Impact
- **Severity**: Low (organizational only)
- **Breaking Change**: None (internal restructuring)
- **Effort**: Low (move files + update 2 paths)

## KDE Plasmoid Conventions
Standard plasmoid structure per KDE documentation:
- `contents/ui/` - Visual components and representations
- `contents/config/` - Configuration UI and schema
- `contents/code/` - JavaScript utilities and libraries
- `contents/locale/` - Translation files

## Examples from Other Plasmoids
- `plasma-desktop/applets/org.kde.plasma.kickoff/`
- `plasma-desktop/applets/org.kde.plasma.taskmanager/`

Both place config QML files in `contents/config/`.
