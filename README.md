Note: All of the code was written by LLMs: Claude Code and ChatGPT.

# Project Description
LoraMeshPlanner is a multi-repository workspace for planning radio mesh networks. It combines a frontend application, a backend API, and a mesh optimization engine maintained as git submodules.

# How to Run It
```bash
git submodule update --init --recursive
```

```bash
cd mesh_calculator
uv sync
```

```bash
cd ../mesh-backend
uv sync
```

```bash
cd ../mesh-generator
npm install
npm run build
```

```bash
cd ../mesh-backend
FRONTEND_DIST_DIR=../mesh-generator/dist uv run uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Open http://127.0.0.1:8000.

# High-Level Implementation Details
The frontend lives in `mesh-generator` and provides the browser UI. The backend lives in `mesh-backend` and exposes `/api/v2/*` APIs, manages project state, and serves built frontend assets. The optimization and radio-planning logic lives in `mesh_calculator`, which is consumed by the backend as a local Python dependency.
