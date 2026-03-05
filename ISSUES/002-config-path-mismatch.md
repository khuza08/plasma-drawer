# Issue: Configuration File Path Mismatch

## Summary
The `config.qml` file references configuration QML files with incorrect paths. Files are located in `contents/ui/` but are referenced without the `ui/` subdirectory prefix.

## Location
`contents/config/config.qml`

## Current Implementation
```qml
ConfigModel {
    ConfigCategory {
         name: i18n("General")
         icon: "kde"
         source: "ConfigGeneral.qml"  // ❌ Incorrect path
    }
    ConfigCategory {
         name: i18n("Search Plugins")
         icon: "search"
         source: "ConfigSearch.qml"   // ❌ Incorrect path
    }
}
```

## Actual File Locations
```
contents/
├── config/
│   └── config.qml          ← References ConfigGeneral.qml directly
└── ui/
    ├── ConfigGeneral.qml   ← Actual location
    └── ConfigSearch.qml    ← Actual location
```

## Problem
The `source` property should reference files relative to the config directory:
- Current: `"ConfigGeneral.qml"`
- Expected: `"../ui/ConfigGeneral.qml"`

## Impact
- **Severity**: Low (appears to work in practice)
- **Possible Explanation**: QML import paths may automatically include `contents/ui/` as a search path
- **Risk**: May cause issues on some systems or future Plasma versions

## Proposed Fix
Update `contents/config/config.qml`:
```qml
ConfigModel {
    ConfigCategory {
         name: i18n("General")
         icon: "kde"
         source: "../ui/ConfigGeneral.qml"  // ✓ Corrected path
    }
    ConfigCategory {
         name: i18n("Search Plugins")
         icon: "search"
         source: "../ui/ConfigSearch.qml"   // ✓ Corrected path
    }
}
```

## Verification
Test configuration dialog opens correctly after path correction:
```bash
# Right-click widget → Configure Plasma Drawer
# Verify both "General" and "Search Plugins" tabs load without errors
```
