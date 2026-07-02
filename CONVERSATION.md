# FreeMovedFileSync — Conversation Log

## Goal
Modify FreeFileSync to display moved/renamed files as a single combined row per move pair instead of two separate rows (one for "from", one for "to").

## Design Decisions

### Global moveMode
- One global `moveMode` variable (`SelectSide::left` or `SelectSide::right`) controls both panels simultaneously.
- No "none" mode — always left or right.
- Defined in `file_hierarchy.h`, defaults to `SelectSide::left`.

### Mv Method Pattern
- All new methods end with `Mv` suffix (e.g., `isEmptyMv`, `getItemNameMv`).
- Original methods unchanged — operational/sync code continues using originals.
- `FileSystemObject` base class has template Mv methods that use `getMovePair()` for dispatch.
- `FilePair` overrides `getMovePair()` and provides type-specific Mv logic.
- `FolderPair`, `SymlinkPair` do NOT override Mv methods — they delegate to originals (no move pair participation).

### Move Pair Dispatch
- `FilePair::getMovePair()` returns `moveFileRef_` (a `SharedRef<FilePair>` to the counterpart).
- Both sides of a move pair point to each other (bidirectional links).
- Mv methods on visible side: `isEmptyMv<right>()` returns `false` (right side "exists in combined view").
- Mv methods on hidden side: similarly returns combined view.

### Filtering
- `ContainerObject::filesMv()` returns only visible-side FilePairs (skips hidden side).
- `serializeHierarchy()` uses `filesMv()` to build the flat item list.
- Original `files()` still used in operational code (sync, comparison).

## Files Changed

### Core (`base/`)
- **`file_hierarchy.h`**: Added `moveMode` extern, `getMovePair()` virtual, Mv method declarations/implementations, `filesMv()`.
- **`file_hierarchy.cpp`**: Added `moveMode` definition, `filesMv()` implementation.

### UI Layer (`ui/`)
- **`file_view.h`**: Added `sortedRefL_`/`sortedRefR_`, `getDrawInfo<side>()` template.
- **`file_view.cpp`**: serializeHierarchy, updateView, predicates (lessFileName, lessFilePath, lessFilesize, lessFiletime, lessExtension), addNumbers, applyDifferenceFilter, applyActionFilter, sorting comparators, getDrawInfo — all use Mv methods.
- **`file_grid.cpp`**: GridDataRim/GridDataCenter rendering — Mv methods for isEmpty, getItemName, getFileSize, getLastWriteTime, getRelativePath, isActive, isFollowedSymlink, parent, getSyncOperation, getCategory.
- **`tree_grid.cpp`**: Overview panel — Mv methods for isEmpty, getItemName, getFileSize, isActive, getCategory, getSyncOperation.
- **`main_dlg.cpp`**: Context menus, selection expansion, sync operations — Mv methods for getSyncOperation, isActive, setActive, isEmpty, getItemName, getRelativePath, parent, getAttributes.

### Methods Converted to Mv
| Method | Non-Mv remaining in ui/ |
|---|---|
| `isEmpty` → `isEmptyMv` | 0 (all converted) |
| `getItemName` → `getItemNameMv` | 0 |
| `getFileSize` → `getFileSizeMv` | 0 |
| `getLastWriteTime` → `getLastWriteTimeMv` | 0 (SymlinkPair uses original — no Mv) |
| `getRelativePath` → `getRelativePathMv` | 0 (ContainerObject uses original — no Mv) |
| `isActive` → `isActiveMv` | 0 |
| `setActive` → `setActiveMv` | 0 |
| `getCategory` → `getCategoryMv` | 0 |
| `getSyncOperation` → `getSyncOperationMv` | 0 |
| `testSyncOperation` → `testSyncOperationMv` | 0 |
| `parent` → `parentMv` | 0 (file_grid.cpp:276 uses parent() — no side context) |
| `getAttributes` → `getAttributesMv` | 0 |

### Intentionally Non-Mv (in ui/)
- `file_grid.cpp:276` — `isMarked()` uses `parent()` (no `side` parameter; real parent chain needed for nav markers).
- `tree_grid.cpp:79,82,83` — inside `#if 0` dead code (already updated for consistency).

## Build
- Compiles with clang++-20, C++23, no errors.
- Pre-existing warnings only (typeid side effects, switch-enum, abs float).

## Key Files
- `/FreeFileSync/Source/base/file_hierarchy.h` — all class declarations + Mv implementations
- `/FreeFileSync/Source/base/file_hierarchy.cpp` — `moveMode`, `filesMv()`
- `/FreeFileSync/Source/ui/file_view.h` — FileView with dual sortedRefs
- `/FreeFileSync/Source/ui/file_view.cpp` — grid data view logic
- `/FreeFileSync/Source/ui/file_grid.cpp` — center/rim grid rendering
- `/FreeFileSync/Source/ui/tree_grid.cpp` — overview tree panel
- `/FreeFileSync/Source/ui/main_dlg.cpp` — main dialog (context menus, sync operations)

## Session Timeline
1. Initial plan and architecture design
2. Added Mv methods to file_hierarchy.h/cpp
3. Updated file_view.cpp with moveMode-aware serialization and sorting
4. Updated file_grid.cpp rendering with Mv calls
5. Updated tree_grid.cpp overview panel
6. Updated main_dlg.cpp context menus/preview
7. Added filesMv() to ContainerObject
8. Added getRelativePathMv<side>()
9. Fixed compilation errors (parentMv const, SymlinkPair getLastWriteTimeMv, FolderPair isFollowedSymlinkMv)
10. Comprehensive ui/ sweep to convert all remaining non-Mv calls
11. Final verification — build succeeds, no non-Mv calls remain in display/filter/sort code
