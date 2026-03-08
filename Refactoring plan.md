## UI Restructure Plan: Projects, Preparation, Results, and Split Layers

### Summary
- Rework the current single-toolbar UI into a sectioned layout with four clear areas:
  1. `Projects`
  2. `Preparation` (site management, data download, P2P, settings)
  3. `Calculation Results`
  4. `Layers` with preparation/result layers visually separated
- Keep backend/API behavior unchanged and preserve current JS function wiring.
- Preserve existing critical DOM IDs where possible to avoid breaking current automation and handlers.

### Implementation Changes
- **Layout shell (`index.html`)**
  - Replace the dense top toolbar with section cards in the sidebar:
    - `Projects`: project select, refresh/new/rename/open/save.
    - `Preparation`: site-management entry (site list button + site editor panel), draw bbox, download data, P2P filter, settings toggle.
    - `Calculation Results`: run controls (run/cancel), runs dropdown/load run, report, optimization log/progress.
    - `Layers`: split into two labeled groups:
      - `Preparation Layers` (roads, boundary, cities, elevation, grid cells).
      - `Result Layers` (towers, visibility links, coverage, runtime tower coverage, search hexes).
  - Keep existing IDs for controls used by JS and tests (`btn-download`, `btn-p2p`, `btn-optimize`, `project-select`, `chk-*`, etc.).
- **Behavior layer (`app.js`)**
  - Add section-state management (expand/collapse and simple open/closed persistence in localStorage).
  - Add a dedicated `Site Management` toggle button that shows/hides the existing site table + editor block.
  - Update initialization to bind new section toggles and ensure current data/state updates still target moved elements.
  - Keep existing action functions (`doDownloadData`, `doFilterP2P`, `doRunOptimization`, `toggleLayer`, etc.) unchanged in signature.
- **Styling (`app.css`)**
  - Implement card-based section styling, stronger visual hierarchy, and spacing for scanability.
  - Add distinct visual treatments for preparation vs results layer groups.
  - Improve responsive behavior:
    - Desktop: map + sectioned sidebar.
    - Narrow screens: collapsible sections and reduced vertical density.
  - Remove/neutralize old toolbar-only styling rules no longer used.

### Public Interfaces / Contracts
- Backend HTTP API: no changes.
- Frontend DOM contract:
  - Existing IDs for core controls/layer checkboxes remain stable.
  - New IDs/classes added only for section wrappers and collapse toggles.
- State persistence:
  - Add UI-only localStorage keys for section open/closed state.
  - Keep existing project/state keys intact.

### Test Plan
- **Manual UX checks**
  - Verify all four sections render and are usable without hidden dependencies.
  - Confirm site management works via the new button flow (list/edit/add/delete).
  - Confirm preparation actions (bbox/download/P2P/settings) still function end-to-end.
  - Confirm results actions (run/cancel/load run/report/log) still function.
  - Confirm layers toggles work and map overlays match the split grouping.
- **Automation compatibility**
  - Re-run existing Playwright smoke and ensure selectors relying on current IDs still pass.
  - Add/extend one UI smoke check that validates:
    - presence of all four section headers,
    - presence of both layer subgroups,
    - core buttons still reachable by existing IDs.
- **Regression**
  - Verify no JS runtime errors on load and after switching projects/runs.
  - Validate dark/light theme still applies across new section containers.

### Assumptions
- Current stack stays vanilla HTML/CSS/JS (no React/framework migration).
- This is an IA/layout rewrite; no change to optimization logic or APIs.
- Existing control IDs should be preserved unless technically impossible; if one must change, an alias/shim ID will be added to keep tests stable.
