from __future__ import annotations

from typing import Dict, List, Tuple, Optional
import math
# import torch
import heapq
import time
from dataclasses import dataclass


@dataclass
class RouteNode:
    """Represents a node in the route graph with real-time data"""
    id: str
    lat: float
    lng: float
    traffic_weight: float = 1.0
    weather_weight: float = 1.0
    real_time_traffic: float = 1.0
    last_updated: float = 0.0


@dataclass
class RouteEdge:
    """Represents an edge between two nodes with dynamic weights"""
    source: str
    target: str
    base_weight: float
    distance: float
    traffic_factor: float = 1.0
    weather_factor: float = 1.0
    priority_factor: float = 1.0
    real_time_factor: float = 1.0


def build_graph_tensors(edges: List[Tuple[str, str, float]]):
    node_to_idx: Dict[str, int] = {}
    for u, v, _ in edges:
        if u not in node_to_idx:
            node_to_idx[u] = len(node_to_idx)
        if v not in node_to_idx:
            node_to_idx[v] = len(node_to_idx)
    num_nodes = len(node_to_idx)

    src_idx = [node_to_idx[u] for u, _, _ in edges]
    dst_idx = [node_to_idx[v] for _, v, _ in edges]
    w = [w for _, _, w in edges]
    return node_to_idx, num_nodes, src_idx, dst_idx, w


def bellman_ford_enhanced(num_nodes: int, src_idx: List[int], dst_idx: List[int],
                         weights: List[float], start_idx: int, real_time_weights: Optional[List[float]] = None):
    """Enhanced Bellman-Ford with real-time weight updates"""
    dist = [float('inf')] * num_nodes
    pred = [-1] * num_nodes
    dist[start_idx] = 0.0

    # Use real-time weights if available, otherwise use base weights
    effective_weights = real_time_weights if real_time_weights is not None else weights

    for iteration in range(num_nodes - 1):
        updated = False
        # relaxation: for each edge u->v with weight w
        for e in range(len(effective_weights)):
            u = src_idx[e]
            v = dst_idx[e]
            w = effective_weights[e]
            if dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
                pred[v] = u
                updated = True
        if not updated:
            break

    # Negative cycle detection
    has_neg_cycle = False
    for e in range(len(effective_weights)):
        u = src_idx[e]
        v = dst_idx[e]
        w = effective_weights[e]
        if dist[u] + w < dist[v]:
            has_neg_cycle = True
            break

    return dist, pred, has_neg_cycle


def reconstruct_path(pred: List[int], start_idx: int, end_idx: int) -> List[int]:
    path: List[int] = []
    cur = end_idx
    visited = set()
    while cur != -1 and cur not in visited:
        path.append(cur)
        if cur == start_idx:
            break
        visited.add(cur)
        cur = pred[cur]
    path.reverse()
    if path and path[0] == start_idx:
        return path
    return []


def a_star_enhanced(start: int, goal: int, adjacency: Dict[int, List[Tuple[int, float]]],
                   heuristic: List[float], real_time_weights: Optional[Dict[int, float]] = None) -> Tuple[List[int], float]:
    """Enhanced A* with real-time weight updates and better heuristics"""
    open_set = [(0, start)]
    came_from: Dict[int, int] = {}
    g_score = {start: 0.0}
    f_score = {start: heuristic[start]}
    visited = set()

    while open_set:
        current_f, current = heapq.heappop(open_set)

        if current in visited:
            continue
        visited.add(current)

        if current == goal:
            # reconstruct path
            path = [current]
            while current in came_from:
                current = came_from[current]
                path.append(current)
            path.reverse()
            return path, g_score[path[-1]]

        for neighbor, base_weight in adjacency.get(current, []):
            # Apply real-time weight if available
            effective_weight = real_time_weights.get(neighbor, base_weight) if real_time_weights else base_weight

            tentative_g = g_score[current] + effective_weight
            if tentative_g < g_score.get(neighbor, math.inf):
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + heuristic[neighbor]
                heapq.heappush(open_set, (f_score[neighbor], neighbor))

    return [], float('inf')


def calculate_heuristic_distance(node1_lat: float, node1_lng: float, 
                               node2_lat: float, node2_lng: float) -> float:
    """Calculate Haversine distance between two points for heuristic"""
    R = 6371  # Earth's radius in kilometers
    
    lat1_rad = math.radians(node1_lat)
    lat2_rad = math.radians(node2_lat)
    delta_lat = math.radians(node2_lat - node1_lat)
    delta_lng = math.radians(node2_lng - node1_lng)
    
    a = (math.sin(delta_lat / 2) ** 2 + 
         math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lng / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    return R * c


def hybrid_route_enhanced(edges: List[Tuple[str, str, float]], start: str, end: str, 
                         nodes_data: Optional[Dict[str, RouteNode]] = None,
                         traffic_factor: float = 1.0, weather_factor: float = 1.0, 
                         priority_factor: float = 1.0, real_time_factor: float = 1.0):
    """Enhanced hybrid routing with real-time data integration"""
    node_to_idx, num_nodes, src_idx, dst_idx, w = build_graph_tensors(edges)
    if start not in node_to_idx or end not in node_to_idx:
        return [], float('inf'), node_to_idx

    start_idx = node_to_idx[start]
    end_idx = node_to_idx[end]

    # Apply real-time factors to weights
    enhanced_weights = w[:]
    if nodes_data:
        for i, (u, v, base_w) in enumerate(edges):
            u_node = nodes_data.get(u)
            v_node = nodes_data.get(v)

            if u_node and v_node:
                # Calculate real-time weight based on traffic, weather, and priority
                real_time_weight = (base_w * traffic_factor * weather_factor *
                                  priority_factor * real_time_factor *
                                  u_node.real_time_traffic * v_node.real_time_traffic)
                enhanced_weights[i] = real_time_weight

    # Step 1: Enhanced Bellman-Ford for robustness
    dist, pred, has_neg_cycle = bellman_ford_enhanced(
        num_nodes, src_idx, dst_idx, enhanced_weights, start_idx
    )

    # Build adjacency for A* with enhanced weights
    adjacency: Dict[int, List[Tuple[int, float]]] = {}
    real_time_adjacency: Dict[int, float] = {}

    for e in range(len(enhanced_weights)):
        u = src_idx[e]
        v = dst_idx[e]
        weight = enhanced_weights[e]
        adjacency.setdefault(u, []).append((v, weight))
        real_time_adjacency[v] = weight

    # Enhanced heuristic with geographic distance
    heuristic = [0.0] * num_nodes
    idx_to_node = {idx: node for node, idx in node_to_idx.items()}

    if nodes_data:
        end_node = nodes_data.get(end)
        if end_node:
            for node_name, node_data in nodes_data.items():
                if node_name in node_to_idx:
                    idx = node_to_idx[node_name]
                    distance = calculate_heuristic_distance(
                        node_data.lat, node_data.lng,
                        end_node.lat, end_node.lng
                    )
                    heuristic[idx] = distance

    # Step 2: Enhanced A* with real-time guidance
    path_idx, cost = a_star_enhanced(start_idx, end_idx, adjacency, heuristic, real_time_adjacency)

    if not path_idx:
        # Fallback to Bellman-Ford path reconstruction
        path_idx = reconstruct_path(pred, start_idx, end_idx)
        cost = dist[end_idx] if path_idx else float('inf')

    # Map back to node names
    path_names = [idx_to_node[i] for i in path_idx]
    return path_names, cost, node_to_idx


def real_time_route_update(current_path: List[str], current_location: str, 
                          nodes_data: Dict[str, RouteNode], 
                          edges: List[Tuple[str, str, float]]) -> Tuple[List[str], float]:
    """Update route in real-time based on current location and traffic conditions"""
    if not current_path or current_location not in current_path:
        return current_path, float('inf')
    
    # Find current position in path
    try:
        current_index = current_path.index(current_location)
        remaining_path = current_path[current_index:]
        
        if len(remaining_path) < 2:
            return remaining_path, 0.0
            
        # Recalculate remaining route with updated real-time data
        start = remaining_path[0]
        end = remaining_path[-1]
        
        updated_path, cost, _ = hybrid_route_enhanced(
            edges, start, end, nodes_data, 
            real_time_factor=1.0  # Use current real-time data
        )
        
        return updated_path, cost
        
    except ValueError:
        return current_path, float('inf')


def calculate_route_metrics(path: List[str], nodes_data: Dict[str, RouteNode], 
                          edges: List[Tuple[str, str, float]]) -> Dict[str, float]:
    """Calculate comprehensive route metrics"""
    if len(path) < 2:
        return {"distance": 0.0, "duration": 0.0, "cost": 0.0, "traffic_delay": 0.0}
    
    total_distance = 0.0
    total_duration = 0.0
    total_cost = 0.0
    traffic_delay = 0.0
    
    for i in range(len(path) - 1):
        current_node = path[i]
        next_node = path[i + 1]
        
        # Find edge between current and next node
        edge_weight = None
        for u, v, w in edges:
            if u == current_node and v == next_node:
                edge_weight = w
                break
        
        if edge_weight is not None:
            # Calculate metrics
            current_data = nodes_data.get(current_node)
            next_data = nodes_data.get(next_node)
            
            if current_data and next_data:
                # Distance calculation
                distance = calculate_heuristic_distance(
                    current_data.lat, current_data.lng,
                    next_data.lat, next_data.lng
                )
                total_distance += distance
                
                # Duration calculation (assuming average speed of 30 km/h in city)
                base_duration = distance / 30.0  # hours
                traffic_multiplier = current_data.real_time_traffic * next_data.real_time_traffic
                actual_duration = base_duration * traffic_multiplier
                total_duration += actual_duration
                
                # Cost calculation (₹10 per km base + traffic surcharge)
                base_cost = distance * 10
                traffic_surcharge = base_cost * (traffic_multiplier - 1) * 0.5
                total_cost += base_cost + traffic_surcharge
                
                # Traffic delay
                traffic_delay += (actual_duration - base_duration) * 60  # minutes
    
    return {
        "distance": total_distance,
        "duration": total_duration * 60,  # convert to minutes
        "cost": total_cost,
        "traffic_delay": traffic_delay
    }


