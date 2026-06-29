# Traffica Backend (FastAPI + PyTorch)

Async REST API for intelligent mobility and route optimization, designed for Flutter/Android clients.

## Features
- POST `/route`: Hybrid Bellman-Ford + A* pathfinding (handles negative weights; fast with heuristics)
- GET `/health`: Health status
- PyTorch tensors for graph/weights; extendable for DL fusion
- CORS enabled; mobile-friendly

## Install
```bash
cd /home/b-gurukiran/projects/Mini_project/backend
python -m venv .venv && source .venv/bin/activate
pip install -U pip
pip install -r requirements.txt
```

## Run
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## Example
```bash
python client.py
```
Or POST JSON:
```json
{
  "edges": [
    {"source": "A", "target": "B", "weight": 1.0},
    {"source": "B", "target": "C", "weight": 2.0},
    {"source": "A", "target": "C", "weight": 4.0},
    {"source": "C", "target": "D", "weight": 1.0},
    {"source": "B", "target": "D", "weight": 5.0}
  ],
  "start": "A",
  "end": "D",
  "heuristic": {"A": 3, "B": 2, "C": 1, "D": 0}
}
```

## Contract
- Request: edges (or adjacency), start, end, optional heuristic and factors
- Response:
```json
{ "path": ["A","C","D"], "total_cost": 5.0, "eta_minutes": 7.5 }
```

## Structure
- `app/models.py` — pydantic schemas
- `app/algorithms.py` — Bellman-Ford, A*, hybrid orchestration
- `app/main.py` — FastAPI app, CORS, routes
- `examples/sample_route.json` — example payload
- `client.py` — async test client

## Notes
- Replace ETA with real speed models later
- Negative cycles are detected but not returned; can expose a flag if needed
