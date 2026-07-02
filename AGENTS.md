# AGENTS.md — FreeMovedFileSync

## Build
```sh
cd FreeFileSync/Source && make -j$(nproc)          # release (default)
cd FreeFileSync/Source && make BUILD=debug -j$(nproc) # debug
```
- Compiler: `clang++-20` (hardcoded in `Makefile`), C++23.
- Dependencies: wxWidgets 3.3.2, GTK3, OpenSSL, libcurl, libssh2, libidn2, libselinux. All installed system-wide.
- Binary output: `FreeFileSync/Build/{Release,Debug}/Bin/FreeFileSync_$(arch)`.

## Architecture
- **`base/file_hierarchy.h`** — class hierarchy: `PathInformation` → `FileSystemObject` (template Mv methods) + `ContainerObject` (has `filesMv()`); `FilePair`, `FolderPair`, `SymlinkPair` derive from `FileSystemObject`.
- **`base/algorithm.cpp`** — comparison + move detection (`findAndSetMovePair`).
- **`base/synchronization.cpp`** — file sync operations.
- **`ui/file_view.cpp`** — grid data model: dual `sortedRefL_`/`sortedRefR_` for left/right panels, `serializeHierarchy()` builds flat list.
- **`ui/file_grid.cpp`** — main center/rim grid rendering.
- **`ui/tree_grid.cpp`** — overview tree panel.
- **`ui/main_dlg.cpp`** — context menus, sync selection, file ops.

## Move-Mode Changes (Mv Pattern)

All display/filter/sort code uses `*Mv()` methods; operational sync/comparison code uses originals.

### Global state
- `extern SelectSide moveMode` (`SelectSide::left` or `SelectSide::right`) in `file_hierarchy.h`.
- Controls which side's view to show in both panels simultaneously.

### Method dispatch
- `FileSystemObject` base declares template Mv methods (`isEmptyMv<side>`, `getItemNameMv<side>`, `getRelativePathMv<side>`, `parentMv<side>`, etc.).
- `FilePair` overrides `getMovePair()` (returns `moveFileRef_`). Both sides of a move pair point to each other.
- `FolderPair`/`SymlinkPair` never participate in move pairs — their Mv methods delegate to originals.
- `ContainerObject::filesMv()` returns visible-side FilePairs only (skips hidden side of move pairs).
- `FilePair` additionally provides type-specific Mv: `getFileSizeMv`, `getLastWriteTimeMv`, `isFollowedSymlinkMv`, `getAttributesMv`, `setActiveMv`, `setSyncDirMv`, `isActiveMv`.

### Key rule for serializeHierarchy
`serializeHierarchy` in `file_view.cpp` uses `filesMv()` (not `files()`) and no additional isEmpty filter. Do NOT add `isEmpty<side>()` filtering here — `filesMv()` already handles skipping hidden sides.

### Conversion rule
When editing any `ui/` file: prefer `*Mv()` methods for display/filter/sort. Leave original methods for operational/sync code in `base/` and for raw hierarchy iteration that needs both sides (e.g., comparison, synchronization).

### Remaining non-Mv calls (intentional)
- `SymlinkPair` methods — no Mv versions exist (symlinks don't participate in move pairs). Use original methods.
- `ContainerObject::parent()` in `isMarked()` (`file_grid.cpp:276`) — no `side` context; real parent chain needed for nav markers.

## Key files
- `base/file_hierarchy.h` — all Mv declarations + inline implementations
- `base/file_hierarchy.cpp` — `moveMode` def, `filesMv()` impl
- `ui/file_view.h` / `file_view.cpp` — grid data model entrypoint
- `CONVERSATION.md` — detailed implementation log
