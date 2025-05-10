# Social News Feed System Architecture

## System Overview

A social network news feed that displays recent posts from users in your social graph in chronological order. This system handles massive scale with billions of users and must efficiently manage fan-out scenarios where popular users have millions of followers.

### Functional Requirements

1. Users should be able to create posts
2. Users should be able to follow/unfollow other users
3. Users should be able to view a chronological feed of posts from people they follow
4. Users should be able to page through their feed

### Non-Functional Requirements

1. The system should prioritize availability over consistency (eventual consistency with up to 1 minute staleness)
2. Posting and viewing feeds should be fast (< 500ms)
3. The system should handle 2 billion users
4. Users should be able to follow unlimited users and have unlimited followers

## Data Models

1. **User**: Represents users in the system
2. **Follow**: Uni-directional relationship between users (follower → following)
3. **Post**: Content created by users with timestamp and metadata

## Service Interfaces

### Create Post
```
POST /posts
{
  "content": "Post content here",
  "authorId": "user123"
}
→ 200 OK
{
  "postId": "post456",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

### Follow User
```
PUT /users/{userId}/followers
{
  "followerId": "user789"
}
→ 200 OK
```

### Get News Feed
```
GET /feed?pageSize=20&cursor=2024-01-15T10:30:00Z
→ 200 OK
{
  "items": [
    {
      "postId": "post456",
      "content": "Post content",
      "authorId": "user123",
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ],
  "nextCursor": "2024-01-15T09:45:00Z"
}
```

## System Architecture

### 1) Users should be able to create posts

**Components:**
- **API Gateway**: Handle routing and load balancing
- **Post Service**: Process post creation requests
- **DynamoDB**: Store posts with high scalability
- **Message Queue**: Handle async processing

**Data Flow:**
1. User creates post via API
2. API Gateway routes to Post Service
3. Post Service validates and stores in DynamoDB
4. Async notification sent to followers via message queue

### 2) Users should be able to follow/unfollow users

**Components:**
- **Follow Service**: Manage user relationships
- **Graph Database**: Store follow relationships efficiently
- **Cache Layer**: Cache popular follow relationships

**Implementation:**
- Store follow relationships as edges in graph structure
- Use Cassandra for high write throughput
- Cache frequently accessed relationships in Redis

### 3) Users should be able to view their news feed

**Components:**
- **Feed Service**: Generate personalized feeds
- **Fan-out Engine**: Distribute posts to followers
- **Cache Layer**: Store pre-computed feeds
- **Timeline Service**: Handle chronological ordering

**Feed Generation Approaches:**
- **Pull Model**: Query posts from followed users on demand
- **Push Model**: Pre-compute and store feeds for users
- **Hybrid Model**: Combine both approaches based on user activity

## Implementation Details

### Fan-out Strategy

**Write Fan-out (Push Model):**
```python
def create_post_with_fanout(post_data, author_id):
    # Create post
    post = create_post(post_data, author_id)
    
    # Get all followers
    followers = get_followers(author_id)
    
    # Distribute to follower timelines
    for follower_id in followers:
        add_to_timeline(follower_id, post)
    
    return post
```

**Read Fan-out (Pull Model):**
```python
def get_feed_pull(user_id, cursor=None, page_size=20):
    # Get followed users
    followed_users = get_following(user_id)
    
    # Query recent posts
    posts = query_recent_posts(followed_users, cursor, page_size)
    
    # Sort chronologically
    return sort_by_timestamp(posts)
```

### Database Schema Design

**Posts Table (DynamoDB):**
```sql
CREATE TABLE Posts (
    postId STRING PRIMARY KEY,
    authorId STRING,
    content STRING,
    createdAt TIMESTAMP,
    updatedAt TIMESTAMP
);
```

**Follows Table (Cassandra):**
```sql
CREATE TABLE Follows (
    followerId STRING,
    followingId STRING,
    createdAt TIMESTAMP,
    PRIMARY KEY (followerId, followingId)
);
```

**Timeline Table (Cassandra):**
```sql
CREATE TABLE Timeline (
    userId STRING,
    postId STRING,
    authorId STRING,
    createdAt TIMESTAMP,
    PRIMARY KEY (userId, createdAt)
);
```

## Technical Challenges

### Problem 1: Handling Fan-out at Scale

**Problem**: Users with millions of followers create massive fan-out operations that can overwhelm the system.

**Solution: Asynchronous Fan-out with Batching**
```python
class FanOutService:
    def __init__(self, message_queue, batch_size=1000):
        self.queue = message_queue
        self.batch_size = batch_size
    
    def fan_out_post(self, post_id, author_id):
        # Get followers in batches
        followers = get_followers_batch(author_id, self.batch_size)
        
        # Send to message queue for async processing
        for batch in followers:
            self.queue.send_message({
                'type': 'add_to_timeline',
                'post_id': post_id,
                'user_ids': batch
            })
    
    def process_timeline_updates(self, message):
        user_ids = message['user_ids']
        post_id = message['post_id']
        
        # Batch insert into timeline
        batch_insert_timeline(user_ids, post_id)
```
- Asynchronous processing prevents blocking
- Batching reduces database load
- Message queues provide reliability

### Problem 2: Feed Generation Performance

**Problem**: Generating feeds for active users requires efficient data retrieval and sorting.

**Solution: Hybrid Feed Generation**
```python
class FeedService:
    def __init__(self, timeline_cache, post_cache):
        self.timeline_cache = timeline_cache
        self.post_cache = post_cache
    
    def get_feed(self, user_id, cursor=None, page_size=20):
        # Try cache first
        cached_feed = self.timeline_cache.get(user_id, cursor)
        if cached_feed:
            return cached_feed
        
        # Generate feed from timeline
        timeline_posts = get_timeline_posts(user_id, cursor, page_size)
        
        # Enrich with post details
        post_ids = [post['postId'] for post in timeline_posts]
        posts = self.post_cache.batch_get(post_ids)
        
        # Cache result
        feed = self.enrich_timeline_with_posts(timeline_posts, posts)
        self.timeline_cache.set(user_id, cursor, feed, ttl=300)
        
        return feed
```
- Cache pre-computed feeds for active users
- Batch retrieval for post details
- 300-second TTL balances freshness and performance

### Problem 3: Managing Timeline Storage

**Problem**: Timeline tables grow exponentially and become difficult to manage.

**Solution: Timeline Partitioning and TTL**
```python
class TimelineManager:
    def __init__(self, cassandra_client):
        self.db = cassandra_client
    
    def add_to_timeline(self, user_id, post_id, author_id, created_at):
        # Partition by user_id for even distribution
        timeline_key = f"timeline:{user_id}"
        
        # Store with TTL for automatic cleanup
        self.db.insert_timeline(
            user_id=user_id,
            post_id=post_id,
            author_id=author_id,
            created_at=created_at,
            ttl=7 * 24 * 3600  # 7 days
        )
    
    def get_timeline_posts(self, user_id, cursor=None, page_size=20):
        # Query with pagination
        return self.db.query_timeline(
            user_id=user_id,
            cursor=cursor,
            page_size=page_size
        )
```
- Partition by user_id for scalability
- TTL automatically removes old posts
- Efficient pagination with cursor-based queries

### Problem 4: Hot User Problem

**Problem**: Celebrities with millions of followers create hot partitions and overwhelm specific servers.

**Solution: Fan-out Optimization for Hot Users**
```python
class HotUserFanOut:
    def __init__(self, message_queue, cache):
        self.queue = message_queue
        self.cache = cache
    
    def handle_hot_user_post(self, post_id, author_id):
        # Check if user is hot (high follower count)
        follower_count = get_follower_count(author_id)
        
        if follower_count > HOT_USER_THRESHOLD:
            # Use lazy loading for hot users
            self.cache.set(f"hot_post:{post_id}", {
                'author_id': author_id,
                'created_at': datetime.now()
            }, ttl=3600)
            
            # Notify only active followers
            active_followers = get_active_followers(author_id)
            self.fan_out_to_active_users(active_followers, post_id)
        else:
            # Normal fan-out for regular users
            self.normal_fan_out(post_id, author_id)
    
    def fan_out_to_active_users(self, active_followers, post_id):
        # Batch process active followers only
        for batch in chunks(active_followers, 1000):
            self.queue.send_message({
                'type': 'hot_user_fanout',
                'post_id': post_id,
                'user_ids': batch
            })
```
- Lazy loading for hot users
- Only fan-out to active followers
- Separate processing pipeline for celebrities

### Problem 5: Real-time Feed Updates

**Problem**: Users expect to see new posts from followed users in real-time.

**Solution: WebSocket-based Real-time Updates**
```python
class RealTimeFeedService:
    def __init__(self, websocket_manager, message_queue):
        self.ws_manager = websocket_manager
        self.queue = message_queue
    
    def setup_real_time_feed(self, user_id, websocket_connection):
        # Subscribe to user's timeline updates
        self.queue.subscribe(f"timeline_updates:{user_id}", self.handle_timeline_update)
        
        # Store WebSocket connection
        self.ws_manager.register_connection(user_id, websocket_connection)
    
    def handle_timeline_update(self, message):
        user_id = message['user_id']
        new_posts = message['posts']
        
        # Send real-time update to user
        self.ws_manager.send_to_user(user_id, {
            'type': 'new_posts',
            'posts': new_posts
        })
    
    def broadcast_new_post(self, post_id, author_id, followers):
        # Send to all online followers
        for follower_id in followers:
            if self.ws_manager.is_online(follower_id):
                self.ws_manager.send_to_user(follower_id, {
                    'type': 'new_post',
                    'post_id': post_id,
                    'author_id': author_id
                })
```
- WebSocket connections for real-time updates
- Selective broadcasting to online users
- Efficient message routing

## Complete System Design

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Client    │    │  Mobile App     │    │  Admin Panel    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │      API Gateway          │
                    │    (Authentication,       │
                    │     Rate Limiting,        │
                    │     Load Balancing)       │
                    └─────────────┬─────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
    ┌─────▼─────┐         ┌───────▼───────┐       ┌──────▼──────┐
    │Post Svc   │         │ Follow Svc    │       │Feed Svc     │
    │(Create)   │         │(Relationships)│       │(Timeline)   │
    └─────┬─────┘         └───────┬───────┘       └──────┬──────┘
          │                       │                       │
          └───────────────────────┼───────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │    Message Queue (Kafka) │
                    └─────────────┬─────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
    ┌─────▼─────┐         ┌───────▼───────┐       ┌──────▼──────┐
    │DynamoDB   │         │ Cassandra     │       │Redis Cache  │
    │(Posts)    │         │(Timelines)    │       │(Feeds)      │
    └───────────┘         └───────────────┘       └─────────────┘
```

### Component Responsibilities

**API Gateway:**
- Request routing and load balancing
- Authentication and rate limiting
- Request/response transformation

**Post Service:**
- Create and manage posts
- Handle post validation and storage
- Trigger fan-out operations

**Follow Service:**
- Manage user relationships
- Handle follow/unfollow operations
- Maintain social graph data

**Feed Service:**
- Generate personalized feeds
- Handle timeline queries and pagination
- Manage feed caching strategies

**Fan-out Engine:**
- Distribute posts to followers
- Handle hot user optimization
- Manage async processing

**Data Storage:**
- **DynamoDB**: Post storage with high scalability
- **Cassandra**: Timeline and follow relationships
- **Redis**: Feed caching and real-time updates
- **Kafka**: Asynchronous message processing

## Architecture Summary

**Key Design Principles:**
- **Hybrid Fan-out**: Push model for active users, pull model for inactive users
- **Asynchronous Processing**: Message queues for reliable fan-out operations
- **Multi-Database Strategy**: DynamoDB (posts), Cassandra (timelines), Redis (caching)
- **Hot User Optimization**: Special handling for users with massive followings
- **Real-time Updates**: WebSocket connections for live feed updates
- **Timeline Partitioning**: Efficient data distribution and cleanup

This design handles the core challenges of a social media news feed while maintaining high performance, scalability, and real-time user experience.
