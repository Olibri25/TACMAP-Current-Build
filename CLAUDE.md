# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Regenerate Xcode project from project.yml (required after adding/removing files)
xcodegen generate

# Build for simulator
xcodebuild -project TacMap.xcodeproj -scheme TacMap \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' build

# Install to running simulator
xcrun simctl install booted build/Debug-iphonesimulator/TacMap.app
```

No tests exist yet. No linter is configured.

## Build Gotchas

- **SWIFT_ENABLE_EXPLICIT_MODULES: NO** — required for MapboxMaps 11.x compatibility
- **EXCLUDED_ARCHS[sdk=iphonesimulator*]: x86_64** — Mapbox binary is arm64-only
- **LD_RUNPATH_SEARCH_PATHS** must include both `@executable_path/Frameworks` and `@loader_path/Frameworks` — without these, simulator install crashes with "Library not loaded: @rpath/Turf.framework/Turf"
- XcodeGen does NOT add LD_RUNPATH_SEARCH_PATHS automatically — they're set explicitly in project.yml
- Mapbox token loaded from Info.plist key `MBXAccessToken` at app init; must start with `pk.`

## Architecture

**iOS 17 @Observable only** — no ObservableObject, @Published, @StateObject, or @EnvironmentObject anywhere. All ViewModels are `@Observable` classes, created with `@State` at the root and passed down via `.environment()`.

**Zero Canvas overlays** — all map content (MGRS grid, symbols, routes, waypoints, range rings) renders via Mapbox annotation groups and style layers. Canvas overlays don't track with map pan/zoom/rotate.

**ViewModel owns viewport** — `MapViewModel` is the single source of truth for camera state (center, zoom, heading, pitch). Camera updates are throttled to ~15fps with trailing-edge debounce.

**AsyncStream replaces Combine** — `LocationService` uses `AsyncStream<CLLocation>`, not publishers.

### Key Files

| File | Role |
|------|------|
| `TACMAP_Current_BuildApp.swift` | App entry, creates all @Observable instances, injects via .environment() |
| `ContentView.swift` | Root layout: 5-tab nav, SlideUpPanel, map container |
| `Features/Map/Views/MapContainerView.swift` | Mapbox Map view, crosshair, floating controls |
| `Features/Map/ViewModels/MapViewModel.swift` | Map state: camera, layers, selections, mode |
| `Features/GoToGrid/` | MGRS grid navigation (north star feature) |
| `Core/Constants/AppSettings.swift` | User preferences via @Observable + UserDefaults |
| `Services/Location/LocationService.swift` | GPS + heading via AsyncStream |

### Design System

All visual constants are centralized — never use hardcoded values:
- **Colors**: `TacMapColors` (backgrounds, accents, affiliation colors)
- **Spacing**: `TacMapSpacing` (xxxs=2 through xxxxl=48)
- **Layout**: `TacMapLayout` (touch targets, corner radii)
- **Typography**: `TacMapTypography` (display, headline, body, label, mono, caption)
- **Animation**: `TacMapAnimation` (quick, standard, panel spring, camera)

Affiliation colors always via `TacMapColors.affiliationColor(_:)`, not inline switches.

### SwiftData

11 entities registered in schema: WaypointEntity, RouteEntity, FolderEntity, PhotoEntity, MilitarySymbolEntity, TacticalGraphicEntity, PlannedTargetEntity, MarkerOverlayEntity, FireMissionEntity, ObservationPostEntity, SavedGridEntity.

Use `@Query` in views only, never in ViewModels. All entities include `userId: String?` and `syncStatus: String` for future sync.

## Conventions

- Feature folders: `Features/Name/ViewModels/` + `Features/Name/Views/`
- Panel/card suffix for container views: `SettingsPanel`, `MarkerDetailCard`
- Dark mode only (`.preferredColorScheme(.dark)` at root)
- Haptic feedback on user actions (success/warning/error/light)
- MapboxMaps 11.18+ API: use `onCameraChanged` (not `onMapIdle`)

## PRD Reference

`PRD.md` is the authoritative spec for all features, data models, and design tokens. Consult it for detailed requirements before implementing new features.
