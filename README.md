# Similar Media Grouping - Apple

Automatically groups visually similar media using Apple's [Vision](https://developer.apple.com/documentation/vision) framework.
Each asset is converted into a feature print (vector representation), and similarity is determined by computing the distance between these vectors.

> This project started as a technical interview assignment for an undisclosed company.

## Architecture

### Similar Media Grouping

Fetches, filters and processes media from the photo library. Results are stored persistently between sessions.

```
1. Request photo library access
         │
         ▼
2. Load saved groups & processed identifiers
         │
         ▼
3. Fetch unprocessed assets from library
         │
         ▼
4. Load image for each asset
         │
         ▼
5. Extract feature print via Vision framework
         │
         ▼
6. Compute distances between feature prints
         │
         ▼
7. Group similar assets using union-find algorithm
         │
         ▼
8. Save groups & processed identifiers
```

## Author
[Dmytrii Golovanov](https://github.com/dmytriigolovanov)
