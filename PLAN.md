### Grid Provider Refactor Plan (mesh-generator + mesh_calculator)

#### Summary
Refactor the system so grid construction happens immediately after elevation download in `mesh-generator`, then `mesh_calculator` consumes a required `GridProvider` (provider-only mode) for all grid-dependent operations.  
Chosen architecture:
- Precompute and persist grid bundle for H3 resolutions `8, 9, 10, 11`.
- Keep a warm in-memory provider for active session.
- Provider decides effective resolution via hardcoded slope ladder:
  - `pXX > 100 m/km -> 11`
  - `pXX > 75 m/km -> 10`
  - `pXX > 50 m/km -> 9`
- Cover all flows (route optimization + runtime tower coverage + grid exports).

#### Key Interface Changes
1. `mesh_calculator` introduces a required `GridProvider` abstraction (single source of grid + terrain truth).
- Responsibilities:
  - multi-resolution cell lookup (`get_cell`, `get_cells`)
  - boundary/full-grid enumeration by resolution
  - road/corridor cell queries
  - metric buffer conversion (`radius_m -> ring count`) and disk expansion
  - terrain/elevation methods currently used by LOS (`get_elevation`, `get_h3_cell_max_elevation`, line/profile helpers)
- `run_route_pipeline(...)` signature changes from `elevation_path` to `grid_provider`.
- Runtime coverage path also takes `grid_provider` (no direct elevation-only path).

2. `mesh_generator` adds a grid-build stage right after elevation download.
- `POST /api/elevation` (or the download chain) triggers multi-resolution grid bundle build for `8..11`.
- Bundle is persisted to project output and loaded into in-memory provider.
- Optimization and runtime coverage pass this provider to `mesh_calculator`.

3. Config/API model updates.
- Add a grid-bundle reference in project status/config (path + metadata/version).
- Keep mesh settings UI mostly unchanged; effective resolution is provider-driven per run.
- `mesh_calculator` route CLI switches from `--elevation` to `--grid-bundle` (provider-only).

4. UI/UX updates in `mesh-generator` for provider-first flow.
- Add explicit grid/provider status block in UI (ready/pending/missing) separate from elevation checkbox.
- Keep optimization and runtime coverage controls aligned to provider readiness state (with backward-compatible fallback for old projects).
- Raise planning H3 setting control max to `11` to match effective-resolution ladder outputs.
- Add visible grid-resolution info for currently rendered data (`base`, `effective`, and per-layer min/max where applicable).
- Extend Search Hexes controls with quick presets and scope legend to make all-attempt debug output interpretable.

#### Implementation Plan
1. **Provider foundation in mesh_calculator**
- Add provider protocol + concrete file-backed implementation (with in-memory indices).
- Move grid-radius logic and resolution selection logic into provider.
- Move/adapter-wrap current elevation helper behavior into provider so LOS consumers remain stable.

2. **Route pipeline migration**
- Remove internal grid generation ownership from route pipeline.
- Replace direct calls to road/buffer/full-grid constructors with provider queries.
- Keep route semantics (city trimming, anchors, DP/greedy) but consume provider cells.
- Export `grid_cells` and `grid_cells_full` from provider-backed datasets.

3. **Coverage migration**
- Update standalone tower coverage to source candidate cells/elevations through provider.
- Remove duplicated ad-hoc cell creation from raw elevation in coverage path.
- Ensure same resolution/ring policy is used for optimization and coverage.

4. **mesh-generator build/load lifecycle**
- After elevation download, build and persist multi-resolution grid bundle (8..11), then hydrate in-memory provider.
- On project load, restore provider from bundle (or rebuild if missing/corrupt).
- Route optimization and tower coverage endpoints require provider readiness and fail with actionable errors if unavailable.

5. **Persistence format and versioning**
- Persist bundle as versioned artifact (metadata + per-resolution cell tables + optional road index).
- Include checksum/source metadata (elevation path hash, boundary hash, resolution set) for invalidation.
- Add backward-compat loader behavior for old projects (no bundle -> rebuild prompt/path).

6. **UI wiring and state lifecycle**
- Persist provider-aware UI state in local storage/project restore (`coverageSourceMode`, tower-coverage resolution, provider status).
- Ensure layer rerenders (`grid_cells`, `grid_cells_full`, `gap_repair_hexes`) are triggered on algorithm toggle, project load, and optimization-result load.
- Show actionable status messages for missing provider/bundle instead of silent layer failures.

#### Test Plan
1. **Provider unit tests**
- Multi-resolution build contains expected resolutions `8..11`.
- `radius_m -> ring` conversion is correct and monotonic per resolution.
- Cell/elevation retrieval matches prior `ElevationProvider` behavior where applicable.
- Resolution ladder returns expected target for representative slope percentiles.

2. **Route pipeline integration**
- Pipeline runs with `grid_provider` and no direct elevation path.
- DP/greedy outputs remain valid (towers, edges, coverage, search debug exports).
- Grid export layers (`grid_cells`, `grid_cells_full`) come from provider data.

3. **Runtime coverage integration**
- Coverage works with provider-backed cells for different selected resolutions.
- Covered/uncovered counts and serving-source fields remain valid.

4. **mesh-generator API/project lifecycle**
- `doDownloadData` builds bundle automatically after elevation.
- Load existing project restores provider from bundle.
- Missing bundle path gives clear error and guided rebuild behavior.

5. **Regression suites**
- Full `mesh_calculator` pytest suite.
- Full `mesh-generator` pytest suite.
- Add focused migration tests for new `run_route_pipeline(grid_provider=...)` call shape and provider-required behavior.

6. **Frontend behavior checks**
- `set-h3-resolution` accepts 6..11 and preserves loaded value 11.
- Grid status indicator updates after elevation download/load/clear and reflects provider readiness.
- Search Hexes quick presets apply expected filter tuples and still allow manual override.
- Grid resolution info updates when switching `DP/Greedy/Both` and when toggling `Grid Cells` layers.

#### Assumptions and Defaults
- Provider-only means no fallback to internal route-pipeline grid building.
- Effective resolution is provider-owned, but never downscales below user-configured base planning resolution.
- Grid bundle is persisted in project output and cached in memory for runtime speed.
- Refactor includes all grid-dependent flows now, not staged by feature.
