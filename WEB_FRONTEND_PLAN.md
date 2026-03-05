# Web Frontend Architecture Plan

## Overview

Transform the mesh-calculator into a web-hostable application with an interactive frontend for uploading geodata, configuring parameters, running optimization, and visualizing results.

---

## Architecture

### Technology Stack

**Backend (API)**:
- **FastAPI** - Modern Python web framework
- **Celery** - Distributed task queue for long-running jobs
- **Redis** - Message broker + result storage
- **PostgreSQL** - Job history, user data (optional)

**Frontend**:
- **React** - UI framework
- **Leaflet/MapLibre GL** - Interactive maps
- **Deck.gl** - H3 hexagon visualization
- **Tailwind CSS** - Styling
- **React Query** - API state management

**Deployment**:
- **Docker** - Containerization
- **Docker Compose** - Local development
- **nginx** - Reverse proxy
- **AWS/GCP/Azure** - Cloud hosting options

---

## Backend Architecture

### 1. FastAPI REST API

**Structure**:
```
mesh_calculator_web/
├── api/
│   ├── __init__.py
│   ├── main.py              # FastAPI app
│   ├── routes/
│   │   ├── jobs.py          # Job management
│   │   ├── upload.py        # File upload
│   │   ├── config.py        # Configuration
│   │   └── results.py       # Results retrieval
│   ├── models.py            # Pydantic models
│   ├── tasks.py             # Celery tasks
│   └── storage.py           # File storage
├── core/                    # Existing mesh_calculator
├── static/                  # Frontend build
└── docker/
    ├── Dockerfile.api
    ├── Dockerfile.worker
    └── docker-compose.yml
```

**Key Endpoints**:
```
POST   /api/upload/boundary      - Upload boundary GeoJSON
POST   /api/upload/roads         - Upload roads GeoJSON
POST   /api/upload/elevation     - Upload elevation GeoTIFF
POST   /api/upload/sites         - Upload sites GeoJSON

POST   /api/jobs                 - Create optimization job
GET    /api/jobs                 - List jobs
GET    /api/jobs/{job_id}        - Get job status
DELETE /api/jobs/{job_id}        - Cancel job

GET    /api/jobs/{job_id}/towers    - Download towers GeoJSON
GET    /api/jobs/{job_id}/coverage  - Download coverage GeoJSON
GET    /api/jobs/{job_id}/report    - Get report JSON

GET    /api/health               - Health check
```

### 2. Celery Task Queue

**tasks.py**:
```python
from celery import Celery
from mesh_calculator.core.elevation import ElevationProvider
from mesh_calculator.optimization.hierarchical import connect_sites_by_priority
# ... other imports

celery = Celery('mesh_calculator', broker='redis://redis:6379/0')

@celery.task(bind=True)
def run_optimization(self, job_id: str, config: dict):
    """
    Run mesh optimization as background task.

    Updates progress using:
    - self.update_state(state='PROGRESS', meta={'current': 50, 'total': 100})
    """
    try:
        # Load data
        self.update_state(state='PROGRESS', meta={'stage': 'Loading data', 'progress': 10})

        # Generate grid
        self.update_state(state='PROGRESS', meta={'stage': 'Generating grid', 'progress': 20})

        # Build routing graph
        self.update_state(state='PROGRESS', meta={'stage': 'Building graph', 'progress': 40})

        # Run optimization
        self.update_state(state='PROGRESS', meta={'stage': 'Optimizing', 'progress': 60})

        # Export results
        self.update_state(state='PROGRESS', meta={'stage': 'Exporting', 'progress': 90})

        return {'status': 'completed', 'job_id': job_id}

    except Exception as e:
        self.update_state(state='FAILURE', meta={'error': str(e)})
        raise
```

### 3. File Storage

**Storage Options**:
- **Local**: `/var/mesh_calculator/jobs/{job_id}/`
- **S3**: `s3://bucket/jobs/{job_id}/`
- **GCS**: `gs://bucket/jobs/{job_id}/`

**File Structure per Job**:
```
jobs/{job_id}/
├── inputs/
│   ├── boundary.geojson
│   ├── roads.geojson
│   ├── elevation.tif
│   └── sites.geojson
├── outputs/
│   ├── towers.geojson
│   ├── coverage.geojson
│   └── report.json
├── config.yaml
└── logs.txt
```

---

## Frontend Architecture

### 1. React Application Structure

```
frontend/
├── src/
│   ├── components/
│   │   ├── Map/
│   │   │   ├── MapViewer.tsx       # Main map component
│   │   │   ├── H3Layer.tsx         # H3 hexagon layer
│   │   │   ├── TowerLayer.tsx      # Tower markers
│   │   │   └── RoadLayer.tsx       # Road overlay
│   │   ├── Upload/
│   │   │   ├── FileUpload.tsx      # Drag-drop upload
│   │   │   ├── UploadZone.tsx      # Individual file zone
│   │   │   └── FilePreview.tsx     # Upload preview
│   │   ├── Config/
│   │   │   ├── ConfigPanel.tsx     # Parameter configuration
│   │   │   ├── SiteEditor.tsx      # Edit site priorities
│   │   │   └── AdvancedOptions.tsx # Advanced params
│   │   ├── Results/
│   │   │   ├── ResultsPanel.tsx    # Results summary
│   │   │   ├── TowerList.tsx       # Tower table
│   │   │   ├── Statistics.tsx      # Stats dashboard
│   │   │   └── DownloadButtons.tsx # Export buttons
│   │   └── Layout/
│   │       ├── Navbar.tsx
│   │       ├── Sidebar.tsx
│   │       └── Footer.tsx
│   ├── pages/
│   │   ├── Home.tsx                # Landing page
│   │   ├── Wizard.tsx              # Step-by-step wizard
│   │   ├── JobStatus.tsx           # Job monitoring
│   │   └── Results.tsx             # Results viewer
│   ├── hooks/
│   │   ├── useJob.ts               # Job management
│   │   ├── useUpload.ts            # File upload
│   │   └── useMap.ts               # Map state
│   ├── services/
│   │   └── api.ts                  # API client
│   └── types/
│       └── index.ts                # TypeScript types
├── public/
└── package.json
```

### 2. User Flow

**Step-by-Step Wizard**:

```
1. Upload Data
   ├─ Drag-drop boundary GeoJSON
   ├─ Drag-drop roads GeoJSON
   ├─ Drag-drop elevation GeoTIFF
   └─ Drag-drop sites GeoJSON
          ↓
2. Configure Parameters
   ├─ H3 Resolution (slider: 6-10)
   ├─ Max Visibility (slider: 50-100 km)
   ├─ Max Nodes per Road (slider: 5-20)
   ├─ Mast Height (input: meters)
   └─ Frequency (dropdown: 868 MHz, 915 MHz, etc.)
          ↓
3. Edit Sites
   ├─ Map preview of uploaded sites
   ├─ Edit site priorities (drag-drop reorder)
   ├─ Add/remove sites
   └─ Validate connectivity
          ↓
4. Run Optimization
   ├─ Review configuration
   ├─ Submit job
   └─ Monitor progress (real-time updates)
          ↓
5. View Results
   ├─ Interactive map with towers
   ├─ Coverage visualization (H3 hexagons)
   ├─ Statistics dashboard
   └─ Download outputs (GeoJSON, report)
```

### 3. Key Components

#### MapViewer.tsx
```tsx
import { MapContainer, TileLayer } from 'react-leaflet';
import H3Layer from './H3Layer';
import TowerLayer from './TowerLayer';

export default function MapViewer({ towers, coverage, sites }) {
  return (
    <MapContainer center={[40.0, -74.0]} zoom={10}>
      <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />

      {/* H3 Coverage Hexagons */}
      <H3Layer cells={coverage} colorBy="clearance" />

      {/* Tower Markers */}
      <TowerLayer towers={towers} />

      {/* Site Markers */}
      <SiteLayer sites={sites} />
    </MapContainer>
  );
}
```

#### H3Layer.tsx (using Deck.gl)
```tsx
import { H3HexagonLayer } from '@deck.gl/geo-layers';
import { DeckGL } from '@deck.gl/react';

export default function H3Layer({ cells, colorBy }) {
  const layer = new H3HexagonLayer({
    id: 'h3-coverage',
    data: cells,
    getHexagon: d => d.h3_index,
    getFillColor: d => getColorScale(d[colorBy]),
    getElevation: 0,
    elevationScale: 0,
    pickable: true,
    autoHighlight: true,
  });

  return <DeckGL layers={[layer]} />;
}
```

#### JobStatus.tsx
```tsx
import { useQuery } from 'react-query';
import { Progress } from '@/components/ui/progress';

export default function JobStatus({ jobId }) {
  const { data: job } = useQuery(['job', jobId],
    () => fetchJob(jobId),
    { refetchInterval: 2000 } // Poll every 2 seconds
  );

  return (
    <div>
      <h2>Job Status: {job.status}</h2>
      <Progress value={job.progress} />
      <p>{job.stage}</p>

      {job.status === 'completed' && (
        <button onClick={() => navigate(`/results/${jobId}`)}>
          View Results
        </button>
      )}
    </div>
  );
}
```

---

## Deployment

### 1. Docker Setup

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  # FastAPI Backend
  api:
    build:
      context: .
      dockerfile: docker/Dockerfile.api
    ports:
      - "8000:8000"
    environment:
      - REDIS_URL=redis://redis:6379/0
      - DATABASE_URL=postgresql://user:pass@db:5432/mesh_calculator
    volumes:
      - ./jobs:/app/jobs
    depends_on:
      - redis
      - db

  # Celery Worker
  worker:
    build:
      context: .
      dockerfile: docker/Dockerfile.worker
    environment:
      - REDIS_URL=redis://redis:6379/0
    volumes:
      - ./jobs:/app/jobs
    depends_on:
      - redis

  # Redis
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  # PostgreSQL (optional)
  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=mesh_calculator
    volumes:
      - postgres_data:/var/lib/postgresql/data

  # nginx (production)
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./frontend/build:/usr/share/nginx/html
    depends_on:
      - api

volumes:
  postgres_data:
```

**Dockerfile.api**:
```dockerfile
FROM python:3.11-slim

# Install GDAL dependencies
RUN apt-get update && apt-get install -y \
    gdal-bin \
    libgdal-dev \
    libspatialindex-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2. Cloud Deployment Options

#### AWS
```
- ECS/Fargate: Run containers
- S3: File storage
- ElastiCache: Redis
- RDS: PostgreSQL
- ALB: Load balancer
- CloudFront: CDN for frontend
```

#### GCP
```
- Cloud Run: Run containers
- Cloud Storage: File storage
- Memorystore: Redis
- Cloud SQL: PostgreSQL
- Cloud Load Balancer
- Cloud CDN
```

#### DigitalOcean
```
- App Platform: Easy deployment
- Spaces: Object storage
- Managed Redis
- Managed PostgreSQL
```

---

## Security Considerations

1. **File Upload Limits**: Max 100 MB per file
2. **Validation**: Validate GeoJSON/GeoTIFF formats
3. **Rate Limiting**: Limit API requests per IP
4. **Authentication** (optional): JWT tokens for user accounts
5. **CORS**: Configure allowed origins
6. **Input Sanitization**: Validate all parameters

---

## Monitoring & Logging

1. **Application Logs**: Structured logging (JSON)
2. **Job Metrics**: Track success/failure rates
3. **Performance**: Monitor optimization runtime
4. **Error Tracking**: Sentry or similar
5. **Uptime Monitoring**: Health check endpoint

---

## Cost Estimation

**Monthly Costs (AWS, moderate usage)**:
- ECS Fargate (2 tasks): ~$50
- ElastiCache (t3.micro): ~$15
- RDS (t3.micro): ~$20
- S3 Storage (100 GB): ~$2
- Data Transfer: ~$10
- **Total**: ~$100/month

**Cost Optimization**:
- Use spot instances for workers
- Implement job timeout limits
- Clean up old job data
- Use CDN for frontend

---

## Implementation Roadmap

### Phase 1: Backend API (Week 1)
- [ ] Set up FastAPI project
- [ ] Implement file upload endpoints
- [ ] Create job management endpoints
- [ ] Integrate existing mesh_calculator core

### Phase 2: Task Queue (Week 2)
- [ ] Set up Celery + Redis
- [ ] Create optimization task
- [ ] Implement progress tracking
- [ ] Add error handling

### Phase 3: Frontend (Week 3-4)
- [ ] Set up React project with TypeScript
- [ ] Build upload UI
- [ ] Implement configuration panel
- [ ] Create map viewer with Leaflet

### Phase 4: Visualization (Week 5)
- [ ] Integrate Deck.gl for H3 visualization
- [ ] Add tower markers and info panels
- [ ] Create results dashboard
- [ ] Implement download functionality

### Phase 5: Deployment (Week 6)
- [ ] Dockerize application
- [ ] Set up Docker Compose
- [ ] Deploy to cloud
- [ ] Configure domain and SSL

### Phase 6: Polish (Week 7)
- [ ] Add authentication (optional)
- [ ] Improve error messages
- [ ] Add usage analytics
- [ ] Write user documentation

---

## Example API Usage

### Create and Monitor Job

```javascript
// 1. Upload files
const formData = new FormData();
formData.append('file', boundaryFile);
await fetch('/api/upload/boundary', { method: 'POST', body: formData });

// 2. Create job
const response = await fetch('/api/jobs', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    boundary_id: 'boundary-123',
    roads_id: 'roads-456',
    elevation_id: 'elevation-789',
    sites_id: 'sites-012',
    config: {
      h3_resolution: 8,
      max_visibility_m: 70000,
      max_nodes_per_road: 10
    }
  })
});

const { job_id } = await response.json();

// 3. Poll for status
const pollStatus = setInterval(async () => {
  const status = await fetch(`/api/jobs/${job_id}`).then(r => r.json());

  if (status.state === 'completed') {
    clearInterval(pollStatus);
    // Fetch results
    const towers = await fetch(`/api/jobs/${job_id}/towers`).then(r => r.json());
    displayResults(towers);
  }
}, 2000);
```

---

## Next Steps

1. **Prototype API**: Start with FastAPI skeleton
2. **Test Upload**: Implement file upload with validation
3. **Mock Frontend**: Create React app with mock data
4. **Integrate**: Connect frontend to backend
5. **Deploy**: Test on cloud platform

Would you like me to start implementing any of these components?
