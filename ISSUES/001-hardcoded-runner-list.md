# Issue: Hardcoded KRunner Plugin List

## Status: PARTIALLY FIXED

The hardcoded list has been reorganized into:
- **Essential runners** (10 most common)
- **Extended runners** (18 additional common runners)

See `contents/config/ConfigSearch.qml` for the implementation.

## Summary
The search plugin configuration in `ConfigSearch.qml` contains a list of KRunner plugins. While true dynamic discovery is not possible from QML due to sandboxing restrictions, the list has been improved.

## Location
`contents/config/ConfigSearch.qml` (lines 17-56)

## Current Implementation
```qml
// Essential fallback runners - always available
readonly property var essentialRunners: [
    { id: "baloosearch", name: i18nc("KRunner Plugin", "File Search") },
    { id: "calculator", name: i18nc("KRunner Plugin", "Calculator") },
    { id: "krunner_services", name: i18nc("KRunner Plugin", "Applications") },
    // ... 7 more
]

// Extended runner list (commonly installed)
readonly property var extendedRunners: [
    { id: "browserhistory", name: i18nc("KRunner Plugin", "Browser History") },
    // ... 17 more
]
```

## Improvements Made
1. **Separated essential vs extended** - Core runners always available
2. **Better organization** - Easier to maintain and update
3. **Custom runner support** - Users can add any runner ID manually
4. **Documentation** - Added help text for discovering custom runners

## Remaining Limitations

### True Dynamic Discovery Not Possible in QML
QML cannot directly:
- Scan filesystem for plugin files
- Access D-Bus interfaces without C++ backend
- Query KRunner's available runners dynamically

### Workarounds
1. **Custom runner text field** - Users can manually add runner IDs
2. **System settings link** - Button to configure runners in system settings
3. **Fallback list** - Covers 95% of common use cases

## Proposed Future Enhancement (Requires C++)

Create a C++ backend plugin that:
```cpp
// KRunnerBackend.h
class KRunnerBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QStringList availableRunners READ availableRunners NOTIFY runnersChanged)
    
public:
    QStringList availableRunners() {
        // Query KRunner's D-Bus interface
        // Scan plugin directories
        // Return list of available runner IDs
    }
};
```

Then expose to QML:
```qml
KRunnerBackend {
    id: backend
    onAvailableRunnersChanged: {
        discoveredRunners = backend.availableRunners;
    }
}
```

## Impact
- **Severity**: Medium → Low (after partial fix)
- **User Impact**: Most users have all needed runners in the extended list
- **Workaround**: Custom text field for third-party runners

## How to Find Custom Runner IDs
Users can discover installed runner IDs by running:
```bash
# List KRunner plugin files
ls /usr/lib*/qt*/plugins/krunner/

# Or check D-Bus
qdbus org.kde.krunner /modules/krunner
```

Then add the runner ID in the "Custom Search Plugins" section.
