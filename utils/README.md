# `beacon2-cbi-tools` - Utilities

This directory contains utility tools for data management, validation, and interaction with the Beacon Friendly Format (BFF).

## Utilities Overview

### 1. **bff-browser**
A lightweight, client-based tool for browsing and interacting with BFF data.

- **Purpose:** Provides a user-friendly frontend for querying and visualizing Beacon datasets.  
- **Key Features:**  
  - User-friendly web interface  
  - Data visualization and search functionality  
  - Intended for researchers and non-technical users  

### 2. **bff-portal**
An API and web-based portal interface for browsing and querying Beacon v2 data **stored in MongoDB**.

- **Purpose:** Enables quick and flexible exploration of the MongoDB database through a web-based interface or API.  
- **Key Features:**  
  - Simple REST-like queries  
  - Supports collection browsing  
  - Designed for quick data inspection  

### 3. **bff-queue**
A utility for managing and monitoring CLI tasks.

- **Purpose:** Handles asynchronous operations and task queues for data processing or integration workflows.  
- **Key Features:**  
  - Queue management for bulk operations in a workstation  
  - Monitors background jobs  
  - Enhances system scalability  

## How BFF Browser Differs from BFF Portal

The **BFF Browser** and **BFF Portal** serve different purposes within the BFF ecosystem. Below is a detailed comparison to clarify their distinct functionalities:

| Feature                      | **BFF Browser**                           | **BFF Portal**                        |
|------------------------------|-------------------------------------------|--------------------------------------|
| **Data Source**              | Static JSON files (`genomicVariations`, `individuals`) | Live data from MongoDB database |
| **Technology Stack**         | Python + Flask (Client-Side)              | Perl + Mojolicious (Backend API + UI) |
| **Data Handling**            | Precomputed HTML pages                    | Dynamic, real-time data querying     |
| **Query Capability**         | No live queries, only filtering of static data | Supports flexible, live queries via API |
| **Cross-Collection Queries** | ❌ Only combined JSON files data         | ✅ Supported (e.g., individuals ↔ genomicVariations) |
| **Pagination**               | Static, loaded in full                   | Dynamic, with `limit` and `skip` support |
| **Scalability**              | Best for small/medium datasets (~5 million variants) | Handles larger datasets efficiently via MongoDB |
| **Usage**                    | Quick data exploration with static files  | Interactive data exploration with live queries |
| **Deployment**               | Lightweight, no database required         | Requires MongoDB backend for live data |
| **Intended Users**           | Users needing quick, offline browsing     | Users needing live, flexible data querying |

### When to Use Each Tool

- **Use BFF Browser if:**  
  - You need a lightweight, client-side tool for browsing precomputed data.  
  - Your datasets are static and do not change frequently.  
  - You want a simple setup without needing a database.  

- **Use BFF Portal if:**  
  - You need to perform live queries on dynamic datasets stored in MongoDB.  
  - You require cross-collection querying and pagination for large datasets.  
  - You need a web interface that allows flexible data exploration and visualization.  

### Future Integration

While the BFF Browser and BFF Portal currently serve separate use cases, there are plans to merge their functionalities in the future. This would combine the simplicity of static data browsing with the flexibility and power of dynamic, database-driven queries into a single, unified platform.
