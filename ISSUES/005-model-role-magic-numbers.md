# Issue: Magic Numbers for Model Role Constants

## Status: RESOLVED (as part of Issue #4)

The magic numbers were removed when the `logModelChildren` debug function was deleted during the commented code cleanup (Issue #4).

---

## Summary
The `logModelChildren` function in `main.qml` used hardcoded numeric constants for QML model roles, making the code difficult to understand and maintain.

## Location
~~`contents/ui/main.qml` (lines 58-72)~~ - **Function removed**

## Original Implementation (REMOVED)
```qml
function logModelChildren(model, leadingSpace = 0) {
    var count = ("count" in model ? model.count : 1);

    for (let i = 0; i < count; i++) {
        let hasChildren = model.data(model.index(i, 0), 0x0107);

        console.log(spacing + `${model.data(model.index(i, 0), 0)} - `
                        + `${model.data(model.index(i, 0), 0x0101)}, `
                        + `Deco: ${model.data(model.index(0, 0), 1)}, `
                        + `IsParent: ${model.data(model.index(i, 0), 0x0106)}, `
                        + `HasChildren: ${hasChildren}, `
                        + `Group: ${model.data(model.index(i, 0), 0x0102)}`
                    );
    }
}
```

## Magic Number Mapping (for reference)

| Hex Value | Role Name | Description |
|-----------|-----------|-------------|
| `0x0000` | `DisplayRole` | Text display |
| `0x0001` | `DecorationRole` | Icon/decoration |
| `0x0101` | `UserRole` | Custom user data |
| `0x0102` | `GroupRole` | Group/category info |
| `0x0106` | `IsParentRole` | Item has children |
| `0x0107` | `HasChildrenRole` | Children availability |

## Resolution

The function was **removed entirely** during Issue #4 (Commented Code Cleanup) because:

1. **Debug-only function** - Not used in production
2. **No callers** - Function was never invoked
3. **Better alternatives exist** - Use Qt Creator's model inspector for debugging

## If Re-added in Future

If similar debugging functionality is needed, use named constants:

```qml
// Example for future reference
QtObject {
    id: modelRoles
    readonly property int DisplayRole:      0x0000
    readonly property int DecorationRole:   0x0001
    readonly property int UserRole:         0x0101
    readonly property int GroupRole:        0x0102
    readonly property int IsParentRole:     0x0106
    readonly property int HasChildrenRole:  0x0107
}
```

Or use Qt's built-in constants (if available):
```qml
model.data(model.index(i, 0), Qt.DisplayRole)
```

## Impact
- **Severity**: Low → None (function removed)
- **Code Quality**: Improved (removed unused debug code)
- **Maintenance**: No longer a concern

## Related
- Issue #004: Excessive Commented-Out Code (function removed as part of cleanup)
