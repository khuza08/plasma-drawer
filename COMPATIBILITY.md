# Kicker API Compatibility

## Overview

Plasma Drawer depends on KDE Plasma's private Kicker API (`org.kde.plasma.private.kicker`). This document describes the compatibility layer and mitigation strategies implemented to handle API changes.

## Private API Dependencies

The plasmoid uses the following private Kicker components:

| Component | Usage | Critical |
|-----------|-------|----------|
| `Kicker.AppsModel` | Application listing with folder support | Yes |
| `Kicker.RunnerModel` | KRunner search integration | Yes |
| `Kicker.SystemModel` | System actions (shutdown, logout, etc.) | Yes |
| `Kicker.DragHelper` | Drag-and-drop support | No |
| `Kicker.ProcessRunner` | Launch external processes | No |
| `Kicker.DashboardWindow` | Fullscreen window behavior | Yes |

## Compatibility Layer

### Runtime Validation

The `KickerCompat.js` module provides runtime API validation:

```javascript
import "../code/KickerCompat.js" as KickerCompat

// Check if all required APIs are available
readonly property bool kickerAPIAvailable: KickerCompat.validateKickerAPI(Kicker).success

// Get detailed validation results
readonly property var kickerValidation: KickerCompat.validateKickerAPI(Kicker)
```

### Version Support Matrix

| Plasma Version | Status | Notes |
|----------------|--------|-------|
| 5.x | ❌ Unsupported | Different API structure |
| 6.0 | ✅ Supported | Initial Plasma 6 support |
| 6.1 | ✅ Supported | RunnerModel API changes handled |
| 6.2 | ✅ Supported | Current tested version |
| 6.3+ | ⚠️ Untested | May work, not verified |

## Mitigation Strategies

### 1. Runtime Detection
- API availability checked on startup
- Missing components logged to console
- Graceful degradation where possible

### 2. Abstraction Layer
All Kicker API calls go through `KickerCompat.js`:
- Centralized compatibility logic
- Easier to update for new Plasma versions
- Fallback implementations when possible

### 3. Version Pinning
`metadata.json` specifies version requirements:
```json
{
    "X-Plasma-API-Minimum-Version": "6.0",
    "X-Plasma-API-Maximum-Version": "6.2",
    "X-Plasma-Dependencies": [
        "org.kde.plasma.private.kicker >= 6.0"
    ]
}
```

### 4. Error Handling
```qml
Component.onCompleted: {
    if (!kickerAPIAvailable) {
        console.error("[Plasma Drawer] Kicker API validation failed");
        // Fallback behavior or user notification
    }
}
```

## Known API Changes

### Plasma 6.0 → 6.1
- `Kicker.RunnerModel.deleteWhenEmpty` property removed
- **Fix**: Use `KSortFilterProxyModel` to filter empty results

### Plasma 5.x → 6.0
- Complete API restructure
- QML imports changed from `org.kde.plasma` to `org.kde.plasma.private.kicker`
- **Impact**: Plasma 5.x not supported

## Monitoring API Changes

### Check Plasma Version
```bash
plasmashell --version
```

### View Kicker API
```bash
# List available Kicker QML types
qmlplugindump org.kde.plasma.private.kicker 1.0

# Check Kicker source code
git clone https://github.com/KDE/plasma-workspace.git
cd plasma-workspace/applets/kicker
```

### Test for Breakage
```bash
# Enable QML debugging
export QML_DEBUGGING_ENABLED=1

# Run plasmashell with debug output
plasmashell --replace 2>&1 | grep -i kicker
```

## Future Improvements

### Short-term
- [ ] Add automatic Plasma version detection
- [ ] Implement feature detection instead of version checks
- [ ] Add user-facing error messages for missing APIs

### Long-term
- [ ] Migrate to public Plasma APIs where available
- [ ] Contribute to upstream Kicker API stabilization
- [ ] Create C++ backend for plugin discovery

## Reporting Issues

If you encounter compatibility issues:

1. **Check Plasma version**: `plasmashell --version`
2. **Enable debug logging**: Monitor `journalctl -f --grep=plasma-drawer`
3. **Report on GitHub**: https://github.com/p-connor/plasma-drawer/issues
4. **Include**: Plasma version, error messages, steps to reproduce

## Related Projects

Similar launchers using Kicker API:
- **Tiled Menu**: https://github.com/Zren/plasma-applet-tiledmenu
- **Simple Menu**: https://github.com/linuxmint/hypnotix (different approach)

## References

- [KDE Plasma Source](https://github.com/KDE/plasma-workspace)
- [Kicker Applet](https://github.com/KDE/plasma-workspace/tree/master/applets/kicker)
- [Plasma Framework Docs](https://api.kde.org/frameworks/plasma-framework/html/index.html)
