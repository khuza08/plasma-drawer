# Issue: Dependency on Private Plasma APIs

## Summary
The plasmoid relies heavily on KDE Plasma's private `Kicker` API, which is not part of the stable public API and could change or be removed in future Plasma versions.

## Location
Multiple files, primarily `contents/ui/main.qml`

## Private API Usage

### 1. Kicker.AppsModel
```qml
readonly property Kicker.AppsModel appsModel: Kicker.AppsModel {
    autoPopulate: true
    flat: false
    showTopLevelItems: true
    sorted: false
    // ...
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

## Proposed Mitigations

### Short-term
1. **Pin Plasma Version**: Specify compatible Plasma versions in metadata.json
2. **Add Version Checks**: Detect API changes at runtime
3. **Monitor KDE Changes**: Track Plasma Framework changelogs

### Long-term
1. **Migrate to Public APIs**: Use public Plasma APIs where available
2. **Abstraction Layer**: Create wrapper components that can be updated independently
3. **Upstream Contribution**: Work with KDE to expose needed functionality publicly

## Impact
- **Severity**: High (potential for complete breakage)
- **User Impact**: Plasmoid may stop working after Plasma updates
- **Current Status**: Works with Plasma 6.0.x

## Related Projects
Similar launchers facing this issue:
- Tiled Menu
- App Launchers using Kicker

## References
- KDE Plasma Source: `plasma-workspace/applets/kicker/`
- KDE Frameworks Documentation: https://api.kde.org/frameworks/
