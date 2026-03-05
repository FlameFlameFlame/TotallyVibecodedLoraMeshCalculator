# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mesh network tower placement optimizer that connects user-specified sites (cities) along roads using hierarchical priority levels, H3 hexagonal grids, and line-of-sight physics (Fresnel clearance + path loss).

Based on an original PostgreSQL/PostGIS implementation in `h3-mesh-placement/`.

## Development Setup

```bash
# Requires Python 3.10+, GDAL system library (brew install gdal on macOS)
poetry install            # install all deps + dev group
poetry install --with viz # also install visualization extras (folium, matplotlib)
```

## Commands

```bash
# Run all tests
poetry run pytest -v

# Run a single test file
poetry run pytest mesh_calculator/tests/test_physics.py -v

# Run with coverage
poetry run pytest --cov=mesh_calculator --cov-report=html

# Generate synthetic test data (creates test_data/ directory)
poetry run python mesh_calculator/tests/generate_test_data.py

# Run the optimizer
poetry run mesh-calculator --config config.yaml --output output/
```

## Architecture

### Pipeline (9-step flow in `cli/main.py`)

1. Load YAML config → `MeshCalculatorConfig` dataclass (`core/config.py`)
2. Load boundary polygon, roads GeoDataFrame, sites with priorities (`data/loaders.py`, `data/sites.py`)
3. Initialize `ElevationProvider` from GeoTIFF (`core/elevation.py`)
4. Generate H3 grid cells restricted to road-containing cells (`core/grid.py`)
5. Create `MeshSurface` — central object holding cells, towers, and visibility graph (`network/graph.py`)
6. Initialize thread-safe `LOSCache` (`data/cache.py`)
7. Build directed routing graph (Dijkstra-ready) from H3 neighbor adjacency with elevation-based edge costs (`network/routing.py`)
8. **Hierarchical connectivity** (`optimization/hierarchical.py`): Priority 1 sites get full mesh (all-to-all), Priority 2+ sites connect to nearest higher-priority site. Each connection finds a road corridor via Dijkstra, then places tower nodes along it with LOS validation.
9. Export towers/coverage as GeoJSON + JSON report (`data/exporters.py`)

### Key Classes

- **`MeshSurface`** (`network/graph.py`): Central state object. Holds `cells` dict (H3→H3Cell), `towers` dict, `tower_by_h3` lookup, and a `VisibilityGraph` (NetworkX undirected graph of tower-to-tower LOS).
- **`LOSCache`** (`data/cache.py`): Thread-safe (uses `threading.Lock`) symmetric cache for LOS results. Cache keys are normalized so `(A,B)` == `(B,A)`.
- **`MeshConfig`** (`core/config.py`): Dataclass with physics constants and tunable parameters (H3 resolution, frequency, mast height, max visibility, hop limit, etc.).

### Node Placement Algorithm

`optimization/corridor.py`: `place_nodes_along_corridor()` walks the Dijkstra corridor and places towers ensuring consecutive towers have LOS to each other.

### Multithreading

`parallel/los_compute.py`: `ThreadPoolExecutor`-based batch LOS computation. Elevation data is read-only shared; `LOSCache` is thread-safe with locking.

### H3 Conventions

- Uses **h3 v4.x** API: `h3.latlng_to_cell()`, `h3.cell_to_latlng()`, `h3.grid_ring()`
- Default resolution 8 (~0.7 km² per cell)
- Coordinates are `(lat, lon)` order in H3 calls (reversed from Shapely's `(lon, lat)`)

### Input/Output Format

- **Inputs**: GeoJSON (boundary polygon, roads, sites with `priority` property), GeoTIFF (elevation)
- **Outputs**: GeoJSON (towers, coverage), JSON (report)
- Configuration via YAML (see `example_config.yaml`)
