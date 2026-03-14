# Similar Photos Detection Architecture

## Overview

The system processes a photo library of N assets to find groups of visually similar photos. Processing runs entirely in the background, persists across app launches, and streams incremental results to the UI.

---

## Components

```
┌─────────────────────────────────────────────────────┐
│                  Photo Library                      │
│                  (PHAsset, N photos)                │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│                Similarity Engine                    │
│                 (Background Process)                │
│                                                     │
│  ┌──────────────┐        ┌───────────────────────┐  │
│  │  Embedding   │        │   Distance Calculator │  │
│  │   Cache      │───────▶│        (N²)           │  │
│  │ (CoreData)   │        │   (parallelized)      │  │
│  └──────────────┘        └───────────┬───────────┘  │
│                                      │              │
│                                      ▼              │
│                          ┌───────────────────────┐  │
│                          │   Similarity Graph    │  │
│                          │  (edges above thresh) │  │
│                          │     (CoreData)        │  │
│                          └───────────┬───────────┘  │
└──────────────────────────────────────┼──────────────┘
                                       │
                          snapshot every second
                                       │
                                       ▼
┌─────────────────────────────────────────────────────┐
│             Clustering Snapshot                     │
│          (connected components)                     │
└──────────────────────┬──────────────────────────────┘
                       │ AsyncStream
                       ▼
┌─────────────────────────────────────────────────────┐
│                      UI                             │
│            (groups + progress)                      │
└─────────────────────────────────────────────────────┘
```

---

## Data Flow

**Embedding Cache** stores `VNFeaturePrintObservation` per asset in CoreData. On each run only new or modified assets are recomputed, the rest are loaded from cache.

**Distance Calculator** computes pairwise distances across all N assets (N² pairs) in parallel chunks. Only pairs below the similarity threshold are kept as graph edges.

**Similarity Graph** is a persistent edge list stored in CoreData. Each edge represents two similar photos and their distance. The graph is append-only during processing and survives app restarts — processing resumes from where it stopped.

**Clustering Snapshot** is computed from the current graph state every second, entirely in the background. It finds connected components and packages them as a result without involving the UI thread.

**UI** subscribes to an `AsyncStream` of clustering snapshots. It only renders — never participates in computation.

---

## Persistence & Resumability

```
App closed mid-processing
        │
        ▼
Graph partially saved in CoreData

App reopened
        │
        ▼
Load existing graph → resume from last processed asset
No recomputation of already processed pairs
```

---

## Performance Characteristics

| Stage | First Launch | Subsequent Launch |
|---|---|---|
| Embedding extraction | ~30-40 sec | ~2 sec (cache) |
| Distance calculation | ~4-8 min | skipped if library unchanged |
| Clustering snapshot | ~1-2 sec | ~1-2 sec |
| **Total** | **~5-9 min** | **~2-3 sec** |

---

## Key Design Decisions

**Graph over distance matrix** — storing only edges above the similarity threshold reduces memory from ~3-6 GB (full N×N matrix) to ~30-300 MB depending on threshold and library content.

**Snapshot-based UI updates** — the background process never directly updates the UI. Instead it publishes a snapshot of current clustering state every second, decoupling computation speed from render cycles.

**Clique-aware grouping** — a photo joins an existing group only if it is similar to a sufficient percentage of its members, preventing transitive grouping of dissimilar photos through intermediate matches.
