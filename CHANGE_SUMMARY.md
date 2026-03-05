# Change Summary

- 2026-03-05: Fixed `mesh-generator` export parameter drift where `routes.json` used hardcoded values (`h3_resolution=8`, `frequency_hz=868000000`, `mast_height_m=28`) instead of current run/export settings.
- 2026-03-05: Unified parameter propagation in `_save_project_to_dir` so `config.yaml`, `routes.json`, and `status.json` use the same merged parameter set.
- 2026-03-05: Added regression test `mesh-generator/tests/test_save_project.py` to verify runtime parameters are preserved in exported `routes.json`.
- 2026-03-05: Implemented runtime-only tower coverage flow across both repos: mesh_calculator no longer auto-exports `tower_coverage.geojson`, and mesh-generator computes tower coverage on demand via new API endpoints.
- 2026-03-05: Added standalone tower coverage compute module in mesh_calculator (`network/tower_coverage.py`) reusing shared LOS/path-loss policy.
- 2026-03-05: Added mesh-generator UI actions for runtime coverage (`Calc Selected`, `Calc All Shown`, `Point Coverage`) and algorithm-aware tower source selection.
- 2026-03-05: Added regression tests for runtime coverage API (`mesh-generator/tests/test_tower_coverage_api.py`) and standalone coverage behavior (`mesh_calculator/tests/test_tower_coverage_runtime.py`).
- 2026-03-05: Added LOS/NLOS edge-state visibility improvements: mesh_calculator now exports `is_nlos`/`los_state` on edges, and mesh-generator can filter/render NLOS links explicitly.
- 2026-03-05: Improved tower coverage UX so enabling the Tower Coverage layer auto-triggers runtime batch coverage calculation when data is not yet cached.
- 2026-03-05: Removed two stale mesh-generator tests that asserted old absolute-path config export and old `SiteStore.to_list()` shape; mesh-generator suite is now green again.
- 2026-03-05: Implemented strict-LOS-by-default in mesh-generator (UI + backend normalization) while keeping mesh_calculator library defaults backward compatible.
- 2026-03-05: Added low-mast optimization warnings and edge-level mast-height propagation to keep link-analysis profiles consistent with the mast used during optimization.
- 2026-03-05: Added cluster-count propagation (`num_clusters`) from route pipeline summaries and strict-LOS disconnect guidance in mesh-generator status/report output.
- 2026-03-05: Fixed greedy tail behavior in mesh_calculator: unreachable route endpoints are no longer force-appended, reducing artificial endpoint tower clustering.
- 2026-03-05: Fixed mesh-generator project load parameter precedence so `config.yaml` settings (e.g., `mast_height_m`) override stale `status.json` values; prevents DP/greedy reruns from silently using old low-mast parameters.
