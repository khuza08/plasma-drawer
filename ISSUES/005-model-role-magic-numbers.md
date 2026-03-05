# Issue: Magic Numbers for Model Role Constants

## Summary
The `logModelChildren` function in `main.qml` uses hardcoded numeric constants for QML model roles, making the code difficult to understand and maintain.

## Location
`contents/ui/main.qml` (lines 58-72)

## Current Implementation
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

## Magic Number Mapping
These hex values are Qt/QML ModelRole constants:

| Hex Value | Role Name | Description |
|-----------|-----------|-------------|
| `0x0000` | `DisplayRole` | Text display |
| `0x0001` | `DecorationRole` | Icon/decoration |
| `0x0101` | `UserRole` | Custom user data |
| `0x0102` | `GroupRole` | Group/category info |
| `0x0106` | `IsParentRole` | Item has children |
| `0x0107` | `HasChildrenRole` | Children availability |

## Problems
1. **Unreadable**: Developers must look up role constants to understand the code
2. **Error-Prone**: Easy to mistype hex values
3. **Fragile**: Role constants may change between Qt versions
4. **No Type Safety**: No compile-time checking of role values

## Proposed Fix
Define named constants for model roles:

```qml
QtObject {
    id: modelRoles
    readonly property int DisplayRole:      0x0000
    readonly property int DecorationRole:   0x0001
    readonly property int UserRole:         0x0101
    readonly property int GroupRole:        0x0102
    readonly property int IsParentRole:     0x0106
    readonly property int HasChildrenRole:  0x0107
}

// Then use in function:
function logModelChildren(model, leadingSpace = 0) {
    for (let i = 0; i < count; i++) {
        let hasChildren = model.data(model.index(i, 0), modelRoles.HasChildrenRole);
        console.log(`${model.data(model.index(i, 0), modelRoles.DisplayRole)} - `
                    + `${model.data(model.index(i, 0), modelRoles.UserRole)}, `
                    + `Deco: ${model.data(model.index(i, 0), modelRoles.DecorationRole)}, `
                    + `IsParent: ${model.data(model.index(i, 0), modelRoles.IsParentRole)}, `
                    + `HasChildren: ${hasChildren}, `
                    + `Group: ${model.data(model.index(i, 0), modelRoles.GroupRole)}`
                   );
    }
}
```

## Alternative: Use Qt Constants
If Qt exposes these constants publicly:
```qml
import QtQuick

// Use built-in constants
model.data(model.index(i, 0), Qt.DisplayRole)
```

## Impact
- **Severity**: Low (debug/utility function only)
- **Code Quality**: Affects maintainability
- **Note**: This function appears to be debug-only and could be removed entirely (see Issue #004)

## Related
- Issue #004: Excessive Commented-Out Code (this function may be unused)
