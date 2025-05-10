# Scalable System Architectures

A collection of system design projects demonstrating scalable architecture patterns and implementations.

## Overview

This repository showcases practical approaches to building high-scale systems through hands-on projects. Each project focuses on specific scalability challenges and architectural patterns.

## System Design Projects

### [Ticket Booking System](./ticket-booking-system/README.md)
**Challenge**: Handle high-concurrency ticket reservations and prevent double booking  
**Technologies**: PostgreSQL, Redis, Kafka, WebSockets, Elasticsearch  
**Focus**: Optimistic concurrency control, real-time seatmap updates, virtual waiting rooms  
**Scale**: 10M+ concurrent users for popular events

### [Social News Feed System](./social-news-feed/README.md)
**Challenge**: Efficiently distribute posts to millions of followers with real-time updates  
**Technologies**: DynamoDB, Cassandra, Redis, Kafka, WebSockets  
**Focus**: Fan-out optimization, timeline management, hot user handling  
**Scale**: 2B+ users, millions of followers per celebrity

### [Cloud File Storage System](./cloud-file-storage/README.md)
**Challenge**: Handle large file uploads, cross-device sync, and secure sharing  
**Technologies**: S3, DynamoDB, CDN, signed URLs, chunked uploads  
**Focus**: Large file handling, deduplication, multi-device synchronization  
**Scale**: 50GB+ files, global file distribution

## Tech Stack

- **Cloud**: AWS, Aazure, GCP
- **Containers**: Docker, Kubernetes  
- **Databases**: PostgreSQL, MongoDB, Redis, Elasticsearch
- **Message Queues**: Apache Kafka, RabbitMQ
- **Monitoring**: Prometheus, Grafana, Jaeger
- **Infrastructure**: Terraform, Helm

## Project Structure

```
├── ticket-booking-system/      # High-concurrency ticket reservation system
│   └── README.md               # Complete system design and architecture
├── social-news-feed/           # Social media feed with fan-out challenges
│   └── README.md               # Complete system design and architecture  
├── cloud-file-storage/         # File storage with sync and sharing
│   └── README.md               # Complete system design and architecture
└── README.md                   # This overview document
```

## Learning Objectives

- **Horizontal Scalability**: Design systems that scale across multiple servers
- **Fault Tolerance**: Build resilient systems that handle failures gracefully  
- **Performance Optimization**: Implement caching and load balancing strategies
- **Trade-off Analysis**: Balance consistency, latency, and throughput requirements

## Getting Started

Each project includes:
- Architecture diagrams and design decisions
- Implementation code (where applicable)
- Deployment configurations
- Performance benchmarks
- Lessons learned

## Author

**Daniel G. de la Morena**  
[LinkedIn](https://www.linkedin.com/in/daniel-gonzalez-de-la-morena/)

---

*Building scalable systems, one architecture at a time*