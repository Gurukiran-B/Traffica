import asyncio
import httpx


async def main():
    async with httpx.AsyncClient(base_url="http://localhost:8000") as client:
        payload = {
            "edges": [
                {"source": "A", "target": "B", "weight": 1.0},
                {"source": "B", "target": "C", "weight": 2.0},
                {"source": "A", "target": "C", "weight": 4.0},
                {"source": "C", "target": "D", "weight": 1.0},
                {"source": "B", "target": "D", "weight": 5.0},
            ],
            "start": "A",
            "end": "D",
            "heuristic": {"A": 3, "B": 2, "C": 1, "D": 0},
        }
        r = await client.post("/route", json=payload)
        print("Status:", r.status_code)
        print(r.json())


if __name__ == "__main__":
    asyncio.run(main())


