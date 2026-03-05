# Change Summary

- 2026-03-05: Fixed `mesh-generator` export parameter drift where `routes.json` used hardcoded values (`h3_resolution=8`, `frequency_hz=868000000`, `mast_height_m=28`) instead of current run/export settings.
- 2026-03-05: Unified parameter propagation in `_save_project_to_dir` so `config.yaml`, `routes.json`, and `status.json` use the same merged parameter set.
- 2026-03-05: Added regression test `mesh-generator/tests/test_save_project.py` to verify runtime parameters are preserved in exported `routes.json`.
- 2026-03-05: Implemented runtime-only tower coverage flow across both repos: mesh_calculator no longer auto-exports `tower_coverage.geojson`, and mesh-generator computes tower coverage on demand via new API endpoints.
- 2026-03-05: Added standalone tower coverage compute module in mesh_calculator (`network/tower_coverage.py`) reusing shared LOS/path-loss policy.
- 2026-03-05: Added mesh-generator UI actions for runtime coverage (`Calc Selected`, `Calc All Shown`, `Point Coverage`) and algorithm-aware tower source selection.
- 2026-03-05: Added regression tests for runtime coverage API (`mesh-generator/tests/test_tower_coverage_api.py`) and standalone coverage behavior (`mesh_calculator/tests/test_tower_coverage_runtime.py`).
