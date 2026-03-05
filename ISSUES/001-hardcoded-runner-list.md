# Issue: Hardcoded KRunner Plugin List

## Summary
The search plugin configuration in `ConfigSearch.qml` contains a hardcoded list of 28 KRunner plugins instead of dynamically discovering installed plugins.

## Location
`contents/ui/ConfigSearch.qml` (lines 28-55)

## Current Implementation
```qml
readonly property var defaultRunners: [
    { id: "baloosearch", name: i18nc("KRunner Plugin", "File Search") },
    { id: "browserhistory", name: i18nc("KRunner Plugin", "Browser History") },
    { id: "browsertabs", name: i18nc("KRunner Plugin", "Browser Tabs") },
    // ... 25 more hardcoded entries
].sort((a, b) => a.name.localeCompare(b.name))
```

## Problems
1. **Incomplete Coverage**: Users with third-party KRunner plugins cannot enable them through the UI
2. **Maintenance Burden**: New Plasma runners must be manually added to the list
3. **Stale Entries**: Removed/uninstalled runners still appear in the list
4. **Localization Gaps**: Plugin names may not match system settings

## Proposed Solution
Dynamically discover available KRunner plugins using one of these approaches:

### Option A: Query KRunner directly
```qml
// Use KRunner's D-Bus interface to list available runners
RunnerModel {
    id: runnerModel
    onCountChanged: {
        for (let i = 0; i < count; i++) {
            // Extract runner IDs from model
        }
    }
}
```

### Option B: Scan plugin directories
```javascript
// Scan standard KRunner plugin locations
const runnerPaths = [
    "/usr/lib/qt5/plugins/plasma/runners/",
    "/usr/lib64/qt5/plugins/plasma/runners/",
    "~/.local/share/plasma/runners/"
];
```

### Option C: Use KConfig to read system settings
```qml
// Read currently enabled runners from system-wide KRunner config
KConfig.ConfigGroup {
    groupName: "Runners"
    // Parse available runners from krunnerrc
}
```

## Impact
- **Severity**: Medium
- **User Impact**: Users cannot manage custom/third-party runners through the GUI
- **Workaround**: Users can manually add plugin IDs via the "Custom Search Plugins" text field

## Related
The code already acknowledges this issue with a TODO comment:
```qml
// TODO: Find some way to load installed plugins dynamically instead of hard-coding the defaults
```
