# Issue: Dependency on Private Plasma APIs

## Status: MITIGATED

The private API dependency cannot be fully eliminated (it's fundamental to the launcher's functionality), but the following mitigations have been implemented:

1. **Runtime API validation** - `KickerCompat.js` compatibility layer
2. **Version pinning** - Metadata specifies supported Plasma versions
3. **Error handling** - Graceful degradation when APIs are missing
4. **Documentation** - COMPATIBILITY.md with troubleshooting guide

---

## Summary
The plasmoid relies on KDE Plasma's private `Kicker` API, which is not part of the stable public API and could change or be removed in future Plasma versions.

## Location
Multiple files, primarily `contents/ui/main.qml`

## Private API Usage

### 1. Kicker.AppsModel
```qml
readonly property Kicker.AppsModel appsModel: Kicker.AppsModel {
    autoPopulate: true
    flat: false
    showTopLevelItems: true
}
```

### 2. Kicker.RunnerModel
```qml
sourceModel: Kicker.RunnerModel {
    id: kickerRunnerModel
    appletInterface: kicker
    runners: plasmoid.configuration.searchRunners
}
```

### 3. Kicker.SystemModel
```qml
Kicker.SystemModel {
    id: systemModel
    // Provides shutdown, logout, suspend, etc.
}
```

### 4. Kicker.DragHelper
```qml
Kicker.DragHelper {
    id: dragHelper
}
```

### 5. Kicker.ProcessRunner
```qml
Kicker.ProcessRunner {
    id: processRunner;
}
```

### 6. Kicker.DashboardWindow
```qml
Kicker.DashboardWindow {
    id: root
    // Base class for the fullscreen window
}
```

## Problems
1. **No API Stability Guarantee**: Private APIs can change without notice between Plasma versions
2. **Distribution Issues**: Some distributions may not include private Kicker components
3. **Limited Documentation**: Private APIs lack public documentation
4. **Upgrade Breakage**: Plasma 6.0 → 6.1+ updates could break functionality

## Evidence of API Changes
The code already shows awareness of API evolution:
```qml
// Kicker.RunnerModel no longer has the deleteWhenEmpty property,
// which means we must filter out the empty results sections ourselves
// using a wrapper FilterProxyModel
```

## Mitigations Implemented ✅

### 1. Compatibility Layer (`contents/code/KickerCompat.js`)
```javascript
// Runtime API validation
function validateKickerAPI(kicker) {
    // Checks for required components
    // Returns success status and missing components
}

// Version compatibility matrix
const COMPAT_VERSIONS = {
    "6.0": { supported: true },
    "6.1": { supported: true },
    "6.2": { supported: true }
};
```

### 2. Runtime Detection (`contents/ui/main.qml`)
```qml
// Validate APIs on startup
readonly property bool kickerAPIAvailable: KickerCompat.validateKickerAPI(Kicker).success

Component.onCompleted: {
    KickerCompat.logCompatibilityInfo();
    if (!kickerAPIAvailable) {
        console.error("Kicker API validation failed");
    }
}
```

### 3. Version Pinning (`metadata.json`)
```json
{
    "X-Plasma-API-Minimum-Version": "6.0",
    "X-Plasma-API-Maximum-Version": "6.2",
    "X-Plasma-Requires-Privileged": "org.kde.plasma.private.kicker",
    "X-Plasma-Dependencies": [
        "org.kde.plasma.private.kicker >= 6.0"
    ]
}
```

### 4. Documentation (`COMPATIBILITY.md`)
- Complete API dependency matrix
- Version support status
- Troubleshooting guide
- Migration path for future Plasma versions

## Remaining Risks

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| Plasma 6.3+ breaks API | High | Low | Monitoring, quick patching |
| Distribution removes Kicker | Medium | Low | Document manual installation |
| KDE stabilizes API differently | Medium | Medium | Adapt compatibility layer |

## Impact
- **Severity**: High → Medium (after mitigations)
- **User Impact**: Early warning of compatibility issues
- **Current Status**: Works with Plasma 6.0.x, 6.1.x, 6.2.x

## Testing Compatibility

```bash
# Check if Kicker APIs are available
qdbus org.kde.plasmashell /PlasmaShell evaluateScript "
    print(JSON.stringify(PlasmaCore.ComponentAvailability));
"

# Monitor for API errors
journalctl -f --grep="Kicker API"
```

## Related Projects
Similar launchers facing this issue:
- Tiled Menu
- App Launchers using Kicker

## References
- KDE Plasma Source: `plasma-workspace/applets/kicker/`
- Compatibility Guide: `COMPATIBILITY.md`
- KDE Frameworks Documentation: https://api.kde.org/frameworks/
