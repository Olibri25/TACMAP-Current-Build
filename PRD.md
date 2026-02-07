# TacMap V2 — Product Requirements Document

> **Purpose**: Single authoritative build document for TacMap V2. This PRD captures every architecture decision, feature spec, data model, and design token needed to rebuild from scratch. V2 corrects the critical implementation gaps from V1 (nothing rendered on map, Canvas overlays that didn't track, disconnected callbacks, janky panels) and establishes a shippable App Store product.

---

## 1. Product Overview

**TacMap** is a military tactical mapping iOS application built in SwiftUI. It provides real-time GPS tracking, MGRS/UTM coordinate systems, NATO APP-6 military symbology, tactical graphics, fire support planning, and a dark-themed map interface inspired by OnX Hunt.

| Key | Value |
|-----|-------|
| **Bundle ID** | `com.tacmap.app` |
| **Deployment Target** | iOS 17.0+ |
| **Swift Version** | 5.9 |
| **Xcode** | 15.0+ |
| **Devices** | iPhone-first; iPad runs same UI, scaled (TARGETED_DEVICE_FAMILY: 1,2) |
| **Color Scheme** | Dark mode only (`.preferredColorScheme(.dark)`) |
| **Project Generator** | XcodeGen (`project.yml`) |
| **Observation** | iOS 17 `@Observable` macro — no `ObservableObject` / `@Published` |

---

## 2. V2 Design Principles

1. **Everything on Mapbox** — Zero Canvas overlays. MGRS grid, tactical graphics, markers, range rings — all rendered as Mapbox style layers or annotation groups. Canvas overlays do not track with map pan/zoom/rotate reliably.
2. **Go To Grid is the north star** — The fastest MGRS navigator on iOS. Under 5 seconds from tap to grid. Recent history + favorites in the popup.
3. **If it's not on the map, it doesn't exist** — Every entity (waypoint, symbol, route, graphic, target) renders on the Mapbox map via annotation APIs. This was the #1 V1 gap.
4. **@Observable everywhere** — iOS 17's `@Observable` macro replaces `ObservableObject`/`@StateObject`/`@EnvironmentObject`. Simpler, fewer property wrappers, automatic dependency tracking.
5. **iPhone-first** — iPad scales naturally via adaptive layout. No special iPad UI (sidebar, split-view) in V2.
6. **Ship what works** — Clear in-scope vs. deferred. No stubs shipped as features.

---

## 3. Feature Scope

### In-Scope (V2 Launch)

- Mapbox map rendering (satellite / streets / outdoor / satellite-streets styles)
- MGRS grid overlay via Mapbox layers (zoom-adaptive, all zoom levels)
- Go To Grid with recent history, favorites, instant jump, custom MGRS keyboard
- Floating map controls (compass, location, map mode toggle, elevation slider)
- Layer toggle panel
- Center crosshair with live MGRS coordinate + elevation display
- Quick Drop FAB with radial menu (marker, symbol, draw)
- Waypoint placement + SwiftData persistence + Mapbox annotation rendering
- Military symbol placement + persistence + rendering
- Marker Detail Card (3-state drawer: header, appearance, overlays, actions)
- Range rings, RED circles, sector of fire overlays (rendered on map)
- Fire support planning (targets, target numbers, CFF data)
- Tactical graphics on map (phase lines, boundaries, objectives, assembly areas)
- Route creation + display
- Drawing mode (multi-point polyline/polygon)
- Symbol library (browse, search, favorites, recent, affiliation tabs)
- Bottom 5-tab navigation with slide-up panel
- Settings persistence (UserDefaults, debounced)
- Full design system (dark theme, orange accent, component library)
- CoordinateConverter (MGRS / UTM / DD / DMS)
- DistanceCalculator (Haversine)
- LocationService (GPS + heading)

### Deferred (Post-Launch)

| Feature | Target |
|---------|--------|
| Offline map downloads | V2.1 fast follow |
| Weather API integration | V2.1 |
| Sun/Moon calculator | V2.1 |
| Line of Sight analysis | V2.2 |
| Photo capture / attachment | V2.2 |
| Import/Export (KML, GPX) | V2.2 |
| Search (real implementation) | V2.1 |
| Onboarding flow | V2.1 |
| Multi-user sharing / sync | V3 |

---

## 4. Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **MapboxMaps** | 11.18.0+ (SPM) | Native SwiftUI map rendering, satellite/streets/outdoor styles, Puck2D location indicator, annotation APIs, style layers |

**Framework Dependencies**: SwiftUI, SwiftData, CoreLocation, Observation, Foundation

**No CocoaPods or Carthage.** SPM only.

**Mapbox Setup**: Access token loaded from `MBXAccessToken` key in Info.plist. Must be a public token (prefix `pk.`). Set on `MapboxOptions.accessToken` in `init()` before any `Map` view loads. Handle expired/invalid tokens via `onMapLoadingError` callback.

---

## 5. Architecture

### 5.1 Pattern: MVVM + Services

```
App/                    → Entry point, root view, DI setup
Core/Constants/         → AppSettings (UserDefaults persistence)
DesignSystem/           → Colors, Typography, Spacing, Icons, Animations, Components
Features/               → Feature modules (each with ViewModels/, Views/, Models/)
Models/Enums/           → Domain enums (Affiliation, Echelon, UnitType, etc.)
Models/SwiftData/       → Persistence entities
Services/               → Business logic (Location, Military, Analysis)
Resources/              → Info.plist, Assets.xcassets
UI/                     → View modifiers and reusable styles
```

### 5.2 @Observable Architecture (iOS 17)

All ViewModels and services use `@Observable` macro instead of `ObservableObject`:

```swift
@Observable
class MapViewModel {
    var centerCoordinate: CLLocationCoordinate2D = .init()
    var zoomLevel: Double = 14.0
    // No @Published needed — @Observable tracks access automatically
}
```

**Injection pattern**: Use `.environment()` instead of `.environmentObject()`:

```swift
// At app root
@State private var mapViewModel = MapViewModel()
@State private var settings = AppSettings()
@State private var locationService = LocationService()

WindowGroup {
    ContentView()
        .environment(mapViewModel)
        .environment(settings)
        .environment(locationService)
}
```

**In child views**:
```swift
@Environment(MapViewModel.self) private var mapViewModel
@Environment(AppSettings.self) private var settings
```

### 5.3 Dependency Injection

| Object | Type | Purpose |
|--------|------|---------|
| `mapViewModel` | `MapViewModel` | Map state, camera, layer toggles, annotation management |
| `locationService` | `LocationService` | GPS + heading tracking |
| `settings` | `AppSettings` | User preferences with UserDefaults persistence |
| `container` | `DependencyContainer` | Service locator (TargetNumberGenerator, CoordinateConverter) |

SwiftData's `ModelContainer` injected via `.modelContainer()` on `WindowGroup`.

### 5.4 State Management

| Pattern | Usage |
|---------|-------|
| `@Observable` classes | ViewModels, services, managers |
| `@State` | Local view state, @Observable instances at creation site |
| `@Binding` | Child-to-parent communication |
| `@Environment` | Accessing shared @Observable instances |
| `@Environment(\.modelContext)` | SwiftData operations |
| `UserDefaults` | Settings persistence (debounced 500ms) |
| `SwiftData` | Entity persistence |
| `AsyncStream` | Location updates, heading (replaces Combine) |

**No Combine.** Replace `AnyCancellable` subscriptions with `AsyncStream` and Swift concurrency (`Task`, `async/await`). Eliminates subscription accumulation bugs from V1.

### 5.5 Callback Replacement

V1 used fragile closure callbacks configured in `onAppear`. V2 replaces these with direct method calls on shared `@Observable` objects:

```swift
// V1 (fragile):
quickDropManager.onMarkerPlaced = { coord in ... }  // Configured in onAppear, can be nil/stale

// V2 (direct):
// QuickDropManager calls mapViewModel.placeWaypoint(at:) directly
// Both are @Observable, both accessible via @Environment
```

---

## 6. App Entry Point & Lifecycle

**File**: `App/TacMapApp.swift`

1. `init()` — Load Mapbox token from Info.plist, validate `pk.` prefix, set `MapboxOptions.accessToken`
2. `sharedModelContainer` — Create SwiftData schema with **all 11 entities** (see §10). Uses `VersionedSchema` and `SchemaMigrationPlan`. On unrecoverable failure: delete store at `URL.applicationSupportDirectory/default.store` and retry. Fatal on second failure.
3. `body` — `WindowGroup` with `ContentView()`, inject `.environment()` objects + `.modelContainer()`, force `.preferredColorScheme(.dark)`.

**SwiftData Schema Entities** (all registered):
1. `WaypointEntity`
2. `RouteEntity`
3. `FolderEntity`
4. `PhotoEntity`
5. `MilitarySymbolEntity`
6. `TacticalGraphicEntity`
7. `PlannedTargetEntity`
8. `MarkerOverlayEntity`
9. `FireMissionEntity`
10. `ObservationPostEntity`
11. `SavedGridEntity` *(new — Go To Grid favorites/recent)*

---

## 7. Navigation & Layout

**File**: `App/ContentView.swift`

### 7.1 Screen Layout (ZStack, bottom-up)

```
┌─────────────────────────────────────┐
│  [≡] Menu    MGRS Coordinate  [🔍] │  ← TopControlsBar
│                                     │
│         Full-Screen Map             │  ← MapContainerView
│    (Mapbox + annotation layers)     │
│                                     │
│  ┌─────────────────────────────┐    │
│  │    ─── (drag handle)        │    │  ← TabContentView (SlideUpPanel)
│  │    Panel Title              │    │
│  │    Panel Content            │    │
│  └─────────────────────────────┘    │
│  [Offline] [Content] [Tools] [Sym] [Set]│  ← BottomNavigationBar
└─────────────────────────────────────┘
```

### 7.2 Navigation Tabs

| Tab | Icon | Icon (Selected) | Title |
|-----|------|-----------------|-------|
| `.offlineMaps` | `square.and.arrow.down` | `.fill` | "Offline" |
| `.myContent` | `folder` | `.fill` | "Content" |
| `.tools` | `square.grid.2x2` | `.fill` | "Tools" (default) |
| `.symbols` | `shield` | `.fill` | "Symbols" |
| `.settings` | `gearshape` | `.fill` | "Settings" |

### 7.3 Panel System

| Detent | Fraction | Behavior |
|--------|----------|----------|
| `.hidden` | 0% | Panel invisible |
| `.partial` | 35% | Default open state |
| `.expanded` | 65% | Full content visible |

**Tab tap behavior**:
- Same tab → toggle `.hidden` ↔ `.partial`
- Different tab → switch content, open to `.partial` if hidden

**Panel drag**:
- Uses `DragGesture` with `predictedEndTranslation` for velocity detection
- Velocity threshold: **500 pt/s** (standardized — one threshold, not two)
  - Velocity > 500 downward → collapse one level
  - Velocity > 500 upward → expand one level
  - Below threshold → snap to nearest detent
- Spring animation: **`response: 0.35, dampingFraction: 0.85`**
- Safe area: Uses `GeometryReader` / `geometry.safeAreaInsets.top` — **no hardcoded 60pt values**

### 7.4 Modals

| Modal | Presentation |
|-------|-------------|
| Menu | `.sheet` (`MenuView`) |
| Search | `.sheet` (`SearchView`) — stub for V2 |
| Layer Panel | `.sheet` from map layer button |

---

## 8. Map Feature

### 8.1 MapContainerView (`Features/Map/Views/MapContainerView.swift`)

**Layer stack** (ZStack, bottom-up):
1. Mapbox `Map(viewport:)` with content builder containing all annotation groups
   - `Puck2D(bearing: .heading)` + accuracy ring
   - MGRS grid lines via `GeoJSONSource` + `LineLayer` + `SymbolLayer`
   - `PointAnnotationGroup` for waypoints
   - `PointAnnotationGroup` for military symbols
   - `PointAnnotationGroup` for planned targets
   - `PolylineAnnotationGroup` for routes
   - `PolylineAnnotationGroup` / `PolygonAnnotationGroup` for tactical graphics
   - `PolygonAnnotationGroup` for range rings / RED circles
   - `PolylineAnnotationGroup` for sectors of fire
2. `MapCrosshair` — Center crosshair (SwiftUI overlay, no map interaction)
3. `FloatingControlsStack` — Right-side vertical controls
4. `LayerButton` + `GoToGridOverlay` — Top-left controls
5. `CoordinateLabel` — Top-center MGRS + elevation display
6. `ScaleBar` — Bottom-left distance scale
7. `QuickDropView` — FAB + drawing mode controls
8. `MarkerDetailCard` — Slide-up marker editor
9. `GridEditPopup` — Conditional overlay for grid editing

**No Canvas overlays anywhere in the map stack.**

### 8.2 MapViewModel (`Features/Map/ViewModels/MapViewModel.swift`)

`@Observable` class. **Single source of truth for all map state** — the View binds to the ViewModel's viewport, eliminating V1's dual-source-of-truth problem.

**Key state**:
- `centerCoordinate`, `zoomLevel`, `mapHeading`, `mapPitch`
- `viewport: Viewport` — ViewModel owns this, View binds to it
- `mapMode`: `.twoD`, `.threeD`, `.hybrid`
- `terrainExaggeration`: 1.0–3.0
- `isFollowingLocation`: auto-disables when user pans >~50m from GPS
- Layer toggles: `showSatellite`, `showTerrain`, `showStreets`, `showMGRSGrid`, `showElevationContours`
- Annotation toggles: `showWaypoints`, `showRoutes`, `showSymbols`, `showGraphics`, `showTargets`, `showRangeRings`

**Map styles**:

| Mode | Style |
|------|-------|
| 2D + satellite | `.satellite` |
| 2D + streets | `.standard` |
| 3D | `.satelliteStreets` |
| Hybrid/Topo | `.outdoors` |

**Camera management**:
- Updates throttled to ~15fps (0.066s interval) with **trailing-edge debounce** to ensure the final camera position is always captured (fixes V1 dropped-update bug)
- Navigation methods (`navigateToCoordinate`, `centerOnLocation`, `resetNorth`) update `viewport` on the ViewModel
- Use Mapbox's `withViewportAnimation(.easeInOut(duration:))` for smooth camera transitions

**Meters per pixel**: `156543.03392 * cos(lat) / 2^zoom`

### 8.3 Mapbox-Native Annotation Rendering

All map entities render via Mapbox annotation APIs inside the `Map {}` content builder:

| Entity | Mapbox API | Details |
|--------|-----------|---------|
| Waypoints | `PointAnnotationGroup` | Custom icon image + label |
| Military Symbols | `PointAnnotationGroup` | `UIImage` rendered from protocol-based renderer (see §12) |
| Planned Targets | `PointAnnotationGroup` | Target icon + number label |
| Routes | `PolylineAnnotationGroup` | Colored lines with configurable width |
| Tactical Graphics | `LineAnnotation` / `PolygonAnnotation` | Type-dependent rendering (lines, areas) |
| Range Rings | `PolygonAnnotationGroup` | Circles approximated as 64-point polygons |
| RED Circles | `PolygonAnnotationGroup` | Same approach, weapon-system-specific radii |
| Sectors of Fire | `PolygonAnnotationGroup` | Wedge shape (direction + arc width + range) |

Annotations are rebuilt from SwiftData queries. Annotation groups use `id` from entity UUIDs for efficient diffing.

### 8.4 MGRS Grid Overlay (Mapbox Layers)

**Rendered as Mapbox `GeoJSONSource` + `LineLayer` + `SymbolLayer`** — not Canvas. Grid lines are generated as GeoJSON `LineString` features and added as a Mapbox style layer. Labels use `SymbolLayer`. Grid recalculates **on camera idle** (not every frame).

Zoom-adaptive spacing:

| Zoom | Grid Spacing |
|------|-------------|
| 0–8 | 100km |
| 8–11 | 10km |
| 11–14 | 1km |
| 14–17 | 100m |
| 17+ | 10m |

Grid lines are UTM-aligned. Major lines (every 10x) get 1.5x width and 2x opacity. Labels shown at zoom >= 10 on every 5th line intersection.

**Performance**: Since grid renders as a Mapbox layer, it moves with the map natively — no per-frame recalculation. GeoJSON source updates only on camera idle events, not during pan/zoom gestures.

### 8.5 Floating Controls (right side, vertical stack)

All controls are **44x44pt minimum** touch targets.

1. **Compass** (`location.north.fill`) — rotates with map heading, tap resets to north. Orange when rotated, white when north.
2. **Elevation slider** (3D mode only) — 1.0x–3.0x terrain exaggeration
3. **Map mode toggle** — cycles 2D → 3D → Hybrid
4. **Location button** (`location`/`location.fill`) — centers on GPS, filled icon when following

### 8.6 Top Controls

- **Layer button** (pill shape: icon + "Layers" text) → opens LayerTogglePanel sheet
- **Go To Grid** button → opens Go To Grid popup (see §9)
- **Coordinate label** (top center) → shows crosshair MGRS + elevation (via Mapbox terrain query)
- Uses `GeometryReader` for safe area insets — **no hardcoded padding values**

---

## 9. Go To Grid Feature — North Star

Go To Grid is TacMap's signature interaction. Goal: **under 5 seconds from button tap to standing on the grid.**

### 9.1 GoToGridViewModel

`@Observable` class.

**MGRS Input Fields**:

| Field | Max Chars | Type |
|-------|-----------|------|
| Zone | 3 | Alphanumeric ("18T") |
| Square | 2 | Letters ("WL") |
| Easting | 5 | Digits |
| Northing | 5 | Digits |

**Behavior**:
- Zone/Square optional — defaults to current location's zone/square (shown as ghost text)
- Auto-advance after threshold: zone at 3 chars, square at 2 chars, easting at 4 chars
- 5th easting/northing digit requires manual advance
- Validates coordinate before navigation
- Haptic feedback: success on valid navigation, error on invalid coordinate

### 9.2 Go To Grid Popup Layout

When the Go To Grid button is tapped, a popup opens with this layout:

```
┌──────────────────────────────────┐
│  Go To Grid                  [✕] │
│                                  │
│  ★ Favorites                     │
│  ┌──────┐ ┌──────┐ ┌──────┐    │  ← Horizontal scroll of saved grids
│  │OBJ Cu│ │OP1   │ │Phase │    │
│  │18TWL │ │18TWL │ │18TWL │    │
│  │12345 │ │67890 │ │11111 │    │
│  └──────┘ └──────┘ └──────┘    │
│                                  │
│  🕐 Recent                       │
│  18T WL 12345 67890          → │  ← Tap any recent grid to instant-jump
│  18T WL 98765 43210          → │
│  18T WL 55555 55555          → │
│                                  │
│  ┌────┐ ┌────┐ ┌─────┐ ┌─────┐ │
│  │Zone│ │ Sq │ │East │ │North│ │  ← MGRS input fields
│  │18T │ │ WL │ │12345│ │67890│ │
│  └────┘ └────┘ └─────┘ └─────┘ │
│                                  │
│  ┌──────────────────────────┐   │
│  │   Custom MGRS Keyboard   │   │
│  └──────────────────────────┘   │
│                                  │
│       [ ★ Save ]  [ GO → ]      │
└──────────────────────────────────┘
```

### 9.3 Recent Grids

- Persist last **20** navigated grids
- Stored via `SavedGridEntity` with `isFavorite: false`
- Displayed in reverse chronological order in the popup
- Tap on any recent grid → **instant jump** (camera snaps, no fly-to animation)
- Automatically deduplicated — re-navigating to a grid moves it to top of recents

### 9.4 Grid Favorites

- Tap **★ Save** to save the currently entered grid as a favorite
- Favorites have an editable **name** (e.g., "OBJ Copper", "OP1", "Rally Point")
- Stored via `SavedGridEntity` with `isFavorite: true`
- Displayed as cards in a horizontal scroll at top of popup
- Tap a favorite card → instant jump
- Long-press to edit name or delete
- No limit on favorites count

### 9.5 Instant Jump

- Navigation uses **camera snap** — no fly-to animation, no smooth transition
- Camera moves immediately to the target coordinate
- Zoom level: maintains current zoom, or defaults to **zoom 14** if current zoom < 10
- Popup dismisses on successful navigation
- Haptic: success notification

### 9.6 Custom MGRS Keyboard

Context-sensitive keys based on focused field:
- **Zone**: numbers 0-9, letters C-X (valid UTM latitude bands)
- **Square**: letters A-Z (excluding I, O per MGRS spec)
- **Easting/Northing**: digits 0-9
- **Backspace** and **Next Field** buttons on all keyboards
- Keyboard appears inline in the popup (not system keyboard)

### 9.7 SavedGridEntity

```swift
@Model
class SavedGridEntity {
    var id: UUID
    var mgrsString: String       // Full MGRS string "18TWL1234567890"
    var zone: String             // "18T"
    var square: String           // "WL"
    var easting: String          // "12345"
    var northing: String         // "67890"
    var name: String?            // User-assigned name (favorites only)
    var isFavorite: Bool         // true = favorite, false = recent
    var lastUsedAt: Date         // For sorting recents
    var createdAt: Date
    // Future sync fields
    var userId: String?
    var syncStatus: String       // "local" for V2
}
```

---

## 10. Data Models

### 10.1 SwiftData Entities

All entities use `UUID` identifiers. All include optional `userId: String?` (nil for V2) and `syncStatus: String` (default `"local"`) fields for future sharing/sync support.

**WaypointEntity**:
`id: UUID`, `name: String`, `latitude: Double`, `longitude: Double`, `altitude: Double?`, `notes: String?`, `color: String`, `icon: String`, `createdAt: Date`, `updatedAt: Date`, `folder: FolderEntity?`, `userId: String?`, `syncStatus: String`

**RouteEntity**:
`id: UUID`, `name: String`, `routeType: String`, `color: String`, `lineWidth: Double`, `notes: String?`, `pointsData: Data` (JSON-encoded coordinates), `createdAt: Date`, `updatedAt: Date`, `folder: FolderEntity?`, `userId: String?`, `syncStatus: String`

**MilitarySymbolEntity**:
`id: UUID`, `symbolCode: String`, `name: String`, `latitude: Double`, `longitude: Double`, `altitude: Double?`, `affiliation: String`, `echelon: String?`, `modifier: String?`, `uniqueDesignator: String?`, `notes: String?`, `createdAt: Date`, `updatedAt: Date`, `userId: String?`, `syncStatus: String`

**TacticalGraphicEntity**:
`id: UUID`, `graphicTypeRaw: String`, `name: String`, `pointsData: Data` (JSON), `colorHex: String?`, `createdAt: Date`, `updatedAt: Date`, `folder: FolderEntity?`, `userId: String?`, `syncStatus: String`

**PlannedTargetEntity**:
`id: UUID`, `targetNumber: String`, `name: String`, `latitude: Double`, `longitude: Double`, `altitude: Double?`, `targetDescription: String?`, `targetType: String`, `priority: Int`, `createdAt: Date`, `updatedAt: Date`, `userId: String?`, `syncStatus: String`

**FolderEntity**:
`id: UUID`, `name: String`, `color: String`, `createdAt: Date`, `updatedAt: Date`, `userId: String?`, `syncStatus: String`
Relationships (cascade delete): `waypoints`, `photos`, `routes`, `graphics`

**PhotoEntity**:
`id: UUID`, `fileName: String`, `caption: String?`, `latitude: Double?`, `longitude: Double?`, `altitude: Double?`, `bearing: Double?`, `createdAt: Date`, `folder: FolderEntity?`, `userId: String?`, `syncStatus: String`

**MarkerOverlayEntity**:
`id: UUID`, `markerId: UUID`, `markerType: String`, `configJSON: Data`, `updatedAt: Date`, `userId: String?`, `syncStatus: String`

**FireMissionEntity**:
`id: UUID`, `missionNumber: String`, `targetId: UUID?`, `weaponSystem: String`, `ammoType: String?`, `volume: Int`, `method: String?`, `status: String`, `createdAt: Date`, `updatedAt: Date`, `userId: String?`, `syncStatus: String`

**ObservationPostEntity**:
`id: UUID`, `name: String`, `latitude: Double`, `longitude: Double`, `altitude: Double?`, `observerId: String?`, `createdAt: Date`, `updatedAt: Date`, `userId: String?`, `syncStatus: String`

**SavedGridEntity** *(new)*:
See §9.7 above.

### 10.2 SwiftData Configuration

- Use `VersionedSchema` and `SchemaMigrationPlan` from day one
- All 11 entities registered in `Schema([...])` array
- Migration strategy: lightweight migration for additive changes, custom migration for breaking changes
- Fallback: delete and recreate store only on unrecoverable corruption

### 10.3 Domain Enums

**Affiliation** *(single canonical enum — no duplicates)*:
`friendly`, `hostile`, `neutral`, `unknown`
- Colors from MIL-STD-2525D
- Symbol prefix: F/H/N/U
- `Codable`, `CaseIterable`

> **V1 Bug Fix**: V1 had duplicate `MilitaryAffiliation` (in TacMapColors.swift) and `Affiliation` (in Models/Enums/) enums. V2 uses **only** the `Affiliation` enum. Delete `MilitaryAffiliation` entirely. Colors for affiliations are defined in `TacMapColors` as static properties keyed by `Affiliation` cases.

**Echelon**: `team`, `squad`, `section`, `platoon`, `company`, `battalion`, `brigade`
- Military unit sizes with standard symbols (Ø, •, ••, •••, I, II, X)

**UnitType**: `infantry`, `armor`, `artillery`, `cavalry`, `engineer`, `signal`, `medical`, `aviation`, `airDefense`, `supply`, `maintenance`, `reconnaissance`, `specialOperations`, `headquarters`
- SF Symbol mappings, symbol modifiers, category assignments

**CoordinateFormat**: `mgrs`, `utm`, `decimalDegrees`, `degreesMinutesSeconds`
- Each with example string and placeholder

**MapMode**: `twoD`, `threeD`, `hybrid`
- Properties: `is3DEnabled`, `showContours`, `next` (for cycling)

**GraphicType**: Phase lines, boundaries, objectives, assembly areas, checkpoints, ambush, block, etc.

**TargetType**: `point`, `linear`, `area`, `groupOfTargets`, `series`

**WeaponSystem**: `mortars`, `fieldArtillery`, `MLRS`, `HIMARS`, `NGF`, `CAS`, `AC130`
- Max range and RED (Risk Estimate Distance) data per system

---

## 11. Quick Drop Feature

### 11.1 State Machine

```
collapsed → (tap FAB) → radialOpen → (select action) → drawMode | symbolLibrary | collapsed
drawMode → (complete/cancel) → collapsed
symbolLibrary → (select/close) → collapsed
```

### 11.2 QuickDropManager

`@Observable` class. Accessed via `@Environment`. **No closure callbacks** — calls methods directly on `MapViewModel` and uses `modelContext` for SwiftData persistence.

**Actions**:
- `.marker` — Place waypoint at crosshair coordinate → creates `WaypointEntity` via `modelContext`, annotation appears on map immediately
- `.symbol` — Open symbol library → user selects → creates `MilitarySymbolEntity`
- `.draw` — Enter multi-point drawing mode → creates `TacticalGraphicEntity` or `RouteEntity`

**Drawing mode** (points rendered as Mapbox `PointAnnotation` during drawing, line as `PolylineAnnotation`):
- `addDrawPoint(at:)` — Append coordinate + light haptic
- `undoLastPoint()` — Remove last point
- `completeDraw()` — Requires 2+ points, success haptic, persist to SwiftData
- `cancelDraw()` — Warning haptic, clear points

### 11.3 FAB UI

- Pulsing "+" button when collapsed (44x44pt minimum)
- Radial menu with 3 options around center (spring animation)
- Draw mode toolbar: Undo, Cancel, Complete buttons (bottom-right)
- Placement feedback: pulse animation at crosshair on successful placement

### 11.4 Symbol Library Drawer

- Full-screen modal with drag-to-dismiss
- **Affiliation tabs**: Friendly, Hostile, Neutral, Unknown
- **Search**: Filters across all affiliations
- **Categories**: Maneuver, Fire Support, Aviation, Combat Support, Combat Service Support, Special Operations, Command & Control
- **Favorites**: Pin/unpin symbols, tracks recent (max 20), shows top 8
- **Persistence**: UserDefaults for favorites and recent symbols

**SymbolDefinition struct**:
```swift
struct SymbolDefinition: Codable, Identifiable {
    let id: String  // Computed from affiliation + unitType
    let affiliation: Affiliation
    let unitType: UnitType
    let echelon: Echelon?
    var isPinned: Bool
    // Computed: displayName, abbreviation, category
}
```

---

## 12. Symbol Rendering — Protocol-Based

### 12.1 MilitarySymbolRenderer Protocol

```swift
protocol MilitarySymbolRenderer {
    func render(symbol: SymbolDefinition, size: CGSize) -> UIImage
}
```

### 12.2 V2 Implementation: SFSymbolRenderer

- Conforms to `MilitarySymbolRenderer`
- Renders military symbols using SF Symbols as visual proxies
- Applies affiliation color (friendly blue, hostile red, neutral green, unknown yellow)
- Applies echelon indicator
- Returns `UIImage` for use in Mapbox `PointAnnotation.image`

### 12.3 Future: SVGSymbolRenderer

- Swap in later without changing annotation code
- Renders from APP-6D SVG assets
- Same protocol, different implementation

### 12.4 Caching

- Symbol images generated once per unique `(affiliation, unitType, echelon, size)` tuple
- Cached in memory (`NSCache`) for reuse across annotation rebuilds
- Cache cleared on memory warning

---

## 13. Marker Detail Feature

### 13.1 MarkerSelection (unified type)

```swift
enum MarkerSelection: Identifiable {
    case waypoint(WaypointEntity)
    case militarySymbol(MilitarySymbolEntity)

    var id: UUID { /* entity id */ }
    var name: String { /* entity name */ }
    var coordinate: CLLocationCoordinate2D { /* from entity */ }
    var iconName: String { /* SF Symbol name */ }
    var iconColor: Color { /* from entity color/affiliation */ }
    var notes: String? { /* from entity */ }
    var mgrsGrid: String { /* computed via CoordinateConverter */ }
    var markerType: String { /* "waypoint" or "symbol" */ }
}
```

### 13.2 MarkerDetailCard (3-state drawer)

| Detent | Height | Content |
|--------|--------|---------|
| `.hidden` | 0% | Not visible |
| `.collapsed` | 20% | Header only |
| `.expanded` | 60% | All sections |
| `.full` | 90% | Full scrollable |

**Sections**:
1. **Header**: Icon, editable name, MGRS grid (tappable to copy), distance/bearing from user
2. **Appearance** (waypoints only): Color picker, icon picker
3. **Overlays**: Range rings (up to 5, presets 100m–5km), RED circle (weapon-system presets), Sector of fire (direction, arc width, range)
4. **Actions**: Go To Grid, Move Marker, Delete (with confirmation dialog)

### 13.3 MarkerOverlayConfig

```swift
struct MarkerOverlayConfig: Codable {
    var rangeRings: RangeRingsConfig      // rings: [Double], max 5
    var redCircle: REDCircleConfig        // radius: Double, presets per weapon system
    var sectorOfFire: SectorOfFireConfig  // direction: Double, arcWidth: Double, range: Double
}
```

Persisted via `MarkerOverlayEntity` (`configJSON` Data field). Overlays render as Mapbox `PolygonAnnotation` groups.

---

## 14. Services

### 14.1 LocationService

`@Observable` class. Wraps `CLLocationManager`.

**Published state**: `currentLocation`, `heading`, `authorizationStatus`, `accuracy` (GPSAccuracy enum), `isUpdating`, `isAcquiring`

**Streaming**: `AsyncStream<CLLocation>` for reactive consumption (replaces Combine). Heading updates throttled.

**Setup idempotency**: `start()` is guarded — calling multiple times does not create duplicate streams.

### 14.2 CoordinateConverter

Static utility. WGS84 ellipsoid math:
- `toMGRS(_:precision:)` / `fromMGRS(_:)` — Full MGRS encode/decode
- `toUTM(_:)` / `fromUTM(_:)` — UTM coordinate conversion
- `format(_:as:)` — Format coordinate in any CoordinateFormat
- `formatDMS(_:)` — Degrees/Minutes/Seconds
- Handles Norway/Svalbard special UTM zones

### 14.3 DistanceCalculator

Haversine-based static utility:
- `distance(from:to:)`, `bearing(from:to:)`, `destination(from:bearing:distance:)`
- `routeDistance(points:)`, `polygonArea(vertices:)`
- Formatting helpers for display

### 14.4 TargetNumberGenerator

Sequential fire support target numbers (AA0001, AA0002, etc.). Persists sequence state.

---

## 15. Design System

### 15.1 Colors (`DesignSystem/Colors/TacMapColors.swift`)

**Backgrounds**:
| Token | Hex | Usage |
|-------|-----|-------|
| `backgroundPrimary` | `#0D0D0F` | App background |
| `backgroundSecondary` | `#1A1A1E` | Cards, sections |
| `backgroundTertiary` | `#252529` | Nested elements |
| `backgroundElevated` | `#2C2C31` | Floating panels |

**Surfaces**:
| Token | Value | Usage |
|-------|-------|-------|
| `surfaceOverlay` | `#1E1E22` | Modal backgrounds |
| `surfaceTranslucent` | `#1E1E22` at 85% | Blur backgrounds |
| `surfaceGlass` | white at 8% | Glass morphism |

**Text**:
| Token | Value |
|-------|-------|
| `textPrimary` | white |
| `textSecondary` | `#A0A0A5` |
| `textTertiary` | `#6B6B70` |
| `textInverse` | `#0D0D0F` |

**Accents**:
| Token | Hex | Usage |
|-------|-----|-------|
| `accentPrimary` | `#FF6B35` | Primary orange (OnX-style) |
| `accentSecondary` | `#3B9EFF` | Secondary blue |

**Affiliations** (MIL-STD-2525D):
| Affiliation | Color | Fill (30% opacity) |
|-------------|-------|-----|
| `.friendly` | `#80C0FF` | `#80C0FF4D` |
| `.hostile` | `#FF8080` | `#FF80804D` |
| `.neutral` | `#80FF80` | `#80FF804D` |
| `.unknown` | `#FFFF80` | `#FFFF804D` |

**Tactical Graphics**: Phase line `#80C0FF`, Objective `#FF8080`, Assembly `#80FF80`, Fire support `#FF6B35`, Danger `#FF3333`, Caution `#FFAA00`

**Semantic**: Success `#4CAF50`, Warning `#FF9800`, Error `#F44336`, Info `#2196F3`

**GPS Accuracy**: Accurate `#4CAF50`, Fair `#FF9800`, Poor `#F44336`, None `#6B6B70`

**Map Overlays**: Crosshair white, Grid lines white 40%, Contours `#8B7355`, Route `#3B9EFF`, LOS visible `#4CAF50` / blocked `#F44336`

**Borders**: Default `#3A3A3F`, Subtle `#2A2A2F`, Focus = accent color

**Hex Color Extension**: `Color(hex: String)` supports 3, 6, and 8 character hex strings.

> **V1 Bug Fix**: `MilitaryAffiliation` enum removed. Affiliation colors are static properties on `TacMapColors` keyed by the canonical `Affiliation` enum.

### 15.2 Typography (`DesignSystem/Typography/TacMapTypography.swift`)

| Scale | Size | Weight |
|-------|------|--------|
| Display Large / Medium / Small | 34 / 28 / 24 | bold / bold / semibold |
| Headline Large / Medium / Small | 20 / 17 / 15 | semibold |
| Body Large / Medium / Small | 17 / 15 / 13 | regular |
| Label Large / Medium / Small | 15 / 13 / 11 | medium |
| Monospace Large / Medium / Small / Caption / Display | 17 / 15 / 13 / 11 / 20 | medium / medium / medium / regular / bold |
| Caption / Caption Small | 12 / 10 | regular |

Convenience view modifiers: `.displayLarge()`, `.monoMedium()`, etc.

### 15.3 Spacing (`DesignSystem/Spacing/TacMapSpacing.swift`)

| Token | Value |
|-------|-------|
| `xxxs` | 2 |
| `xxs` | 4 |
| `xs` | 8 |
| `sm` | 12 |
| `md` | 16 |
| `lg` | 20 |
| `xl` | 24 |
| `xxl` | 32 |
| `xxxl` | 40 |
| `xxxxl` | 48 |

**TacMapLayout constants**: `floatingControlSize` = 44, `floatingControlCornerRadius` = 12, `floatingControlSpacing` = 12, `floatingControlMargin` = 16, `panelCornerRadius` = 20, `bottomNavIconSize` = 24

### 15.4 Icons (`DesignSystem/Icons/TacMapIcons.swift`)

All SF Symbols. Categories: Navigation, Map Controls, Content, Tools, Military, Settings, Actions, Status. Sizes: small = 14, medium = 18, large = 22, extraLarge = 28.

### 15.5 Animations (`DesignSystem/Animation/TacMapAnimation.swift`)

| Token | Value |
|-------|-------|
| `quick` | 0.15s easeOut |
| `standard` | 0.25s easeInOut |
| `panel` | spring(response: 0.35, dampingFraction: 0.85) |
| `camera` | 0.5s easeInOut |
| `fade` | 0.2s easeInOut |
| `bounce` | spring(response: 0.4, dampingFraction: 0.6) |

### 15.6 Component Library

**Buttons**: PrimaryButton (orange), SecondaryButton (gray), IconButton (floating), FloatingButtonStyle

**Cards**: ContentCard (icon + title/subtitle + trailing), ToolCard (grid tool item)

**Inputs**: TacMapTextField, TacMapSearchField, CoordinateInput, SegmentedControl (animated underline)

**Panels**: SlideUpPanel (3-state with drag, spring animation, GeometryReader for safe areas)

**Overlays**: FullScreenModal, ConfirmationDialog, Toast (success/warning/error)

**Lists**: ListItem, toggle items, section headers, empty states

**Map UI**: MapCrosshair, CoordinateLabel, ScaleBar, GPSIndicator, FloatingControlsStack

---

## 16. Settings (`Core/Constants/AppSettings.swift`)

`@Observable` class with UserDefaults persistence (replaces `ObservableObject`).

| Category | Settings |
|----------|----------|
| **Units** | distanceUnit (m/km/ft/mi/nm), speedUnit, elevationUnit, temperatureUnit |
| **Coordinates** | coordinateFormat (MGRS/UTM/DD/DMS) |
| **Map** | defaultTacMapStyle, defaultGridOverlay, contourInterval, northReference, magneticDeclination, autoMagneticDeclination |
| **Display** | symbolSize (small/medium/large → 24/36/48pt), labelSize, show3DBuildings, showContourLines, showHillshade |
| **GPS** | gpsUpdateFrequency (fast=1m / normal=5m / batterySaver=10m), showAccuracyCircle |

Debounced saves (500ms). `saveNow()` for immediate persistence. `resetToDefaults()` available. Call `saveNow()` on `scenePhase` change to `.background`/`.inactive`.

---

## 17. Permissions (Info.plist)

```
NSLocationWhenInUseUsageDescription: "to display position on map"
NSLocationAlwaysAndWhenInUseUsageDescription: "for background route tracking"
NSCameraUsageDescription: "for geotagged photos"
NSPhotoLibraryUsageDescription: "to attach images to waypoints"
UIBackgroundModes: [location]
```

---

## 18. Haptic Feedback Strategy

| Interaction | Haptic |
|-------------|--------|
| Minor interactions (button tap, toggle) | Light impact |
| Selection (picker, tab, list item) | Selection changed |
| Successful action (marker placed, grid navigated) | Success notification |
| Warning (draw cancel, delete confirmation) | Warning notification |
| Error (invalid coordinate, failed action) | Error notification |
| Drawing point added | Light impact |
| FAB radial open | Medium impact |

---

## 19. Build Phases

### Phase 1 — Foundation (Week 1-2)
- Xcode project setup with XcodeGen
- Mapbox integration + token loading + error handling
- Design system (colors, typography, spacing, icons, animations, all components)
- `@Observable` architecture setup
- `AppSettings` with UserDefaults persistence
- `LocationService` (GPS + heading via AsyncStream)
- SwiftData schema (all 11 entities, `VersionedSchema`)
- Dark mode enforcement
- `DependencyContainer` + `.environment()` injection

### Phase 2 — Core Map (Week 2-3)
- `MapContainerView` with Mapbox `Map` + content builder
- MGRS grid overlay as Mapbox `GeoJSONSource` + `LineLayer` + `SymbolLayer` (zoom-adaptive)
- Crosshair + coordinate display (MGRS + elevation via Mapbox terrain query)
- Floating controls (compass, location, map mode toggle, elevation slider)
- Layer toggle panel
- Scale bar
- Camera state management (ViewModel-owned viewport, trailing-edge debounce)
- Safe area handling via `GeometryReader`

### Phase 3 — Go To Grid (Week 3)
- Go To Grid popup with custom MGRS keyboard
- Instant jump navigation (camera snap, no animation)
- `SavedGridEntity` CRUD
- Recent grids persistence + display in popup (last 20)
- Grid favorites (save, name, tap-to-navigate, horizontal scroll)
- Coordinate validation + haptic feedback

### Phase 4 — Markers & Placement (Week 3-4)
- Quick Drop FAB with radial menu
- Waypoint placement → SwiftData persistence → Mapbox `PointAnnotation` rendering
- Military symbol placement → persistence → protocol-based rendering → `PointAnnotation`
- Drawing mode → polyline/polygon via Mapbox annotations during draw → persist on complete
- `MilitarySymbolRenderer` protocol + `SFSymbolRenderer` implementation + image cache
- Marker Detail Card (header, appearance, overlays, actions)
- Marker editing (name, color, icon, notes) + deletion with confirmation

### Phase 5 — Overlays & Fire Support (Week 4-5)
- Range rings (Mapbox `PolygonAnnotation`, 64-point circle approximation)
- RED circles with weapon system presets
- Sector of fire overlays (wedge geometry)
- Fire support target placement + target number generation
- Target detail editing
- `PlannedTargetEntity` rendering on map as `PointAnnotation`

### Phase 6 — Tactical Graphics & Routes (Week 5-6)
- Phase line creation + rendering (Mapbox `PolylineAnnotation`)
- Boundary, objective area, assembly area rendering (`PolygonAnnotation`)
- Route creation + rendering (`PolylineAnnotation`)
- Graphic editing (color, name, type)
- Symbol library (browse, search, favorites, affiliation tabs, recent tracking)

### Phase 7 — Navigation & Polish (Week 6-7)
- Bottom 5-tab navigation bar
- Slide-up panel with standardized spring animations (500 pt/s velocity threshold)
- Tab content panels (Tools, Content, Symbols, Settings, Offline placeholder)
- Menu view
- Settings panel (units, coordinates, map, display, GPS)
- Haptic feedback throughout (per §18 strategy)
- Performance optimization (annotation clustering at low zoom, throttled camera updates)
- iPad layout verification (no clipping, adequate touch targets)

---

## 20. Project Configuration (`project.yml`)

```yaml
name: TacMap
options:
  bundleIdPrefix: com.tacmap
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "15.0"
  generateEmptyDirectories: true
  developmentLanguage: en

settings:
  base:
    MARKETING_VERSION: "2.0.0"
    CURRENT_PROJECT_VERSION: "1"
    SWIFT_VERSION: "5.9"
    TARGETED_DEVICE_FAMILY: "1,2"
    INFOPLIST_KEY_UIStatusBarStyle: UIStatusBarStyleLightContent

targets:
  TacMap:
    type: application
    platform: iOS
    sources: [App, Core, DesignSystem, Features, Models, Services, UI]
    dependencies:
      - package: MapboxMaps
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.tacmap.app
        INFOPLIST_FILE: Resources/Info.plist
        CODE_SIGN_STYLE: Automatic

packages:
  MapboxMaps:
    url: https://github.com/mapbox/mapbox-maps-ios.git
    from: "11.18.0"

schemes:
  TacMap:
    run:
      commandLineArguments:
        "-com.apple.CoreData.ConcurrencyDebug 1": true
```

---

## 21. File Structure (Estimated ~85 Swift files)

### App (3)
- `App/TacMapApp.swift` — @main entry, @Observable DI, SwiftData schema
- `App/ContentView.swift` — Root layout + tab navigation + panel system
- `App/DependencyContainer.swift` — Service locator

### Core (1)
- `Core/Constants/AppSettings.swift` — @Observable UserDefaults settings

### Design System (~26)
- `DesignSystem/TacMapDesignSystem.swift` — Central registry
- `DesignSystem/Colors/TacMapColors.swift` — Single `Affiliation` color source
- `DesignSystem/Typography/TacMapTypography.swift`
- `DesignSystem/Spacing/TacMapSpacing.swift`
- `DesignSystem/Icons/TacMapIcons.swift`
- `DesignSystem/Animation/TacMapAnimation.swift`
- `DesignSystem/MapUI/` — Crosshair, FloatingControls, GPSIndicator, ScaleBar
- `DesignSystem/Components/Buttons/` — PrimaryButton, SecondaryButton, IconButton
- `DesignSystem/Components/Cards/` — ContentCard, ToolCard
- `DesignSystem/Components/Inputs/` — TacMapTextField, SegmentedControl, CoordinateInput
- `DesignSystem/Components/Lists/` — ListItem
- `DesignSystem/Components/Overlays/` — ConfirmationDialog, FullScreenModal, Toast
- `DesignSystem/Components/Panels/` — SlideUpPanel (spring animation, GeometryReader safe areas)

### Features (~33)
- `Features/Map/` — MapContainerView, MapViewModel, LayerTogglePanel
- `Features/MarkerDetail/` — MarkerDetailCard, MarkerDetailViewModel, MarkerSelection, MarkerOverlayConfig, sections
- `Features/QuickDrop/` — QuickDropManager, QuickDropView, QuickDropFAB, DrawModeToolbar, SymbolLibraryViewModel, SymbolLibraryDrawer, SymbolCard
- `Features/GoToGrid/` — GoToGridViewModel, GoToGridOverlay, GoToGridPopup, MGRSKeyboard
- `Features/Search/` — MenuView, SearchView (stub)
- `Features/Symbols/` — SymbolsPanel, SymbolPickerView
- `Features/Tools/` — ToolsPanel, ToolStubViews
- `Features/Settings/` — SettingsPanel
- `Features/Content/` — MyContentPanel
- `Features/OfflineMaps/` — OfflineMapsPanel (placeholder)
- `Features/Waypoints/` — WaypointViews
- `Features/FireSupport/` — TargetEditorView
- `Features/Graphics/` — GraphicEditorView

### Models (~17)
- `Models/Enums/` — CoordinateFormat, TargetType, GraphicType, UnitType, WeaponSystem, Affiliation (single canonical), Echelon
- `Models/SwiftData/` — WaypointEntity, RouteEntity, FolderEntity, PhotoEntity, MilitarySymbolEntity, TacticalGraphicEntity, PlannedTargetEntity, MarkerOverlayEntity, FireMissionEntity, ObservationPostEntity, SavedGridEntity

### Services (5)
- `Services/Location/LocationService.swift` — @Observable, AsyncStream
- `Services/Military/CoordinateConverter.swift` — Static utility
- `Services/Military/TargetNumberGenerator.swift` — Sequential numbers
- `Services/Analysis/DistanceCalculator.swift` — Haversine math
- `Services/Rendering/SFSymbolRenderer.swift` — MilitarySymbolRenderer protocol + SF Symbol implementation

### UI (1+)
- `UI/` — View modifiers, styles

**Key structural differences from V1:**
- No `GridOverlayView.swift` (Canvas) — MGRS grid via Mapbox layers in MapViewModel
- No `DrawingOverlay.swift` (Canvas) — drawing points/lines as Mapbox annotations
- New `SavedGridEntity.swift` for Go To Grid favorites/recent
- New `SFSymbolRenderer.swift` + `MilitarySymbolRenderer` protocol
- `@Observable` classes replace `ObservableObject` throughout
- `.environment()` replaces `.environmentObject()`
- `AsyncStream` replaces Combine subscriptions

---

## 22. V1 Lessons Applied

This section documents what went wrong in V1 and how V2's architecture addresses each issue. These are **resolved in the spec above**, not open issues.

| # | V1 Issue | V2 Resolution |
|---|----------|---------------|
| 1 | Canvas grid overlay didn't track with map | MGRS grid rendered as Mapbox `LineLayer` + `SymbolLayer` (§8.4) |
| 2 | No annotations rendered on map | All entities render via Mapbox annotation groups (§8.3) |
| 3 | QuickDrop callbacks were `print()` stubs | Direct `@Observable` method calls + `modelContext` persistence (§11.2) |
| 4 | Duplicate `Affiliation` / `MilitaryAffiliation` enums | Single `Affiliation` enum, colors as `TacMapColors` statics (§10.3) |
| 5 | `MarkerOverlayEntity` not in SwiftData schema | All 11 entities registered in schema (§6) |
| 6 | `FireMissionEntity` / `ObservationPostEntity` not in schema | Registered (§6) |
| 7 | Viewport dual source of truth (View vs ViewModel) | ViewModel owns `viewport`, View binds to it (§8.2) |
| 8 | Fragile closure callbacks via `onAppear` | Replaced with direct method calls on shared `@Observable` objects (§5.5) |
| 9 | Panel drag had two different velocity thresholds | Single threshold: 500 pt/s (§7.3) |
| 10 | Hardcoded 60pt safe area padding | `GeometryReader` / `safeAreaInsets.top` (§8.6) |
| 11 | Camera throttle dropped final update | Trailing-edge debounce (§8.2) |
| 12 | `setup()` could accumulate Combine subscriptions | No Combine; `AsyncStream` with idempotent `start()` guard (§14.1) |
| 13 | `@StateObject` ViewModels in child views recreated on parent rebuild | `@State` + `@Observable` at creation site, `@Environment` for sharing (§5.2) |
| 14 | SwiftData migration: delete-and-recreate lost data | `VersionedSchema` + `SchemaMigrationPlan` (§10.2) |
| 15 | Panel system inconsistency (two implementations) | Single `SlideUpPanel` component with standardized spring animation (§7.3) |

---

## 23. Verification Checklist

Before shipping, verify:

- [ ] MGRS grid lines track perfectly with map pan/rotate/pitch at all zoom levels
- [ ] Go To Grid: enter coordinate → instant jump in under 5 seconds
- [ ] Go To Grid: recent history persists across app launches (20 max)
- [ ] Go To Grid: save and recall named favorites
- [ ] Waypoint placement via Quick Drop: appears on map + persists in SwiftData
- [ ] Military symbol placement: correct affiliation color, renders on map, persists
- [ ] Tactical graphics: draw phase line → renders as Mapbox line annotation, tracks with map
- [ ] Range rings: add to marker → circular overlay renders correctly at various zoom levels
- [ ] Panel drag: smooth spring animation through all 3 detents, no jank
- [ ] iPad: run on iPad simulator, no clipped content, adequate touch targets
- [ ] Performance: 50+ markers, smooth map pan/zoom without frame drops
- [ ] Persistence: create entities, force-quit app, relaunch → everything restored
- [ ] No Canvas overlay code anywhere in the project
- [ ] All 11 SwiftData entities registered in schema
- [ ] No `ObservableObject` / `@Published` / `@StateObject` / `@EnvironmentObject` in codebase
