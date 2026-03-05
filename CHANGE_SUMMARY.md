# Change Summary

- 2026-03-05: Fixed `mesh-generator` export parameter drift where `routes.json` used hardcoded values (`h3_resolution=8`, `frequency_hz=868000000`, `mast_height_m=28`) instead of current run/export settings.
- 2026-03-05: Unified parameter propagation in `_save_project_to_dir` so `config.yaml`, `routes.json`, and `status.json` use the same merged parameter set.
- 2026-03-05: Added regression test `mesh-generator/tests/test_save_project.py` to verify runtime parameters are preserved in exported `routes.json`.
