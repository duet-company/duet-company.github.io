# Nghiên Cứu: Giải Pháp Build Standalone Conversation cho AI Agent History

**Ngày:** 2026-03-15
**Tech Stack:** Cloudflare Workers, AI SDK, OpenRouter
**Mục tiêu:** Xây dựng hệ thống quản lý conversation history standalone cho AI agents

---

## Tóm Tắt Nghiên Cứu

Năm 2026, các giải pháp quản lý conversation history cho AI agents tập trung vào **kiến trúc phân tầng (tiered architecture)** kết hợp:
- **Vector Database** - cho semantic retrieval
- **Relational/NoSQL Database** - cho full logs và audit trails
- **Cache Layer** (Redis/KV) - cho session management nhanh
- **Summarization** - để giảm kích thước context

---

## 1. Kiến Trúc Storage Khuyến Nghị

### 1.1 Hybrid Architecture (Được khuyến nghị)

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                       │
│              (Cloudflare Workers / Agents)                  │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Redis/KV   │  │   Vector DB   │  │ PostgreSQL    │
│  (Cache)     │  │  (Memory)    │  │  (Audit Log) │
│              │  │              │  │              │
│ • Session    │  │ • Embeddings │  │ • Full logs  │
│ • Recent msg │  │ • Summaries  │  │ • Analytics  │
│ • TTL 24h    │  │ • Facts      │  │ • Backup     │
└──────────────┘  └──────────────┘  └──────────────┘
```

### 1.2 Chi Tiết Mỗi Layer

#### Layer 1: Redis/Cloudflare KV (Short-term Cache)
- **Mục đích:** Session management nhanh, recent messages
- **Storage:** Key-value với TTL (24-48 giờ)
- **Data structure:**
  ```json
  {
    "session_id": "user_123_session_456",
    "user_id": "user_123",
    "messages": [
      {"role": "user", "content": "...", "timestamp": "2026-03-15T10:00:00Z"},
      {"role": "assistant", "content": "...", "timestamp": "2026-03-15T10:00:01Z"}
    ],
    "metadata": {
      "last_active": "2026-03-15T10:00:01Z",
      "message_count": 50
    }
  }
  ```

#### Layer 2: Vector Database (Long-term Memory)
- **Mục đích:** Semantic retrieval, summaries, facts
- **Tools:** Qdrant, Pinecone, Weaviate, pgvector, Chroma
- **Storage pattern:**
  ```json
  {
    "id": "uuid",
    "user_id": "user_123",
    "content": "User prefers Python over JavaScript",
    "embedding": [0.1, 0.2, ...], // 1536-dim vector
    "metadata": {
      "type": "user_preference",
      "importance": 0.8,
      "timestamp": "2026-03-15T10:00:00Z"
    }
  }
  ```

#### Layer 3: PostgreSQL (Audit & Analytics)
- **Mục đích:** Full conversation logs, analytics, backup
- **Schema:**
  ```sql
  CREATE TABLE conversations (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    session_id UUID NOT NULL,
    messages JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );

  CREATE INDEX idx_conversations_user ON conversations(user_id);
  CREATE INDEX idx_conversations_session ON conversations(session_id);
  CREATE INDEX idx_conversations_created ON conversations(created_at);
  ```

---

## 2. Triển Khai Với Cloudflare Workers + OpenRouter

### 2.1 Basic Pattern (Cloudflare KV)

```javascript
// worker.js
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const sessionId = url.searchParams.get('session') || generateSessionId();
    const { message } = await request.json();

    // Load history from KV
    const history = await env.CHAT_HISTORY.get(sessionId, { type: 'json' }) || [];

    // Add user message
    history.push({ role: 'user', content: message, timestamp: new Date().toISOString() });

    // Call OpenRouter API
    const openRouterResponse = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'anthropic/claude-3.5-sonnet',
        messages: history.slice(-20), // Keep last 20 messages
        max_tokens: 1000
      })
    });

    const result = await openRouterResponse.json();
    const assistantMessage = result.choices[0].message.content;

    // Add assistant message to history
    history.push({ role: 'assistant', content: assistantMessage, timestamp: new Date().toISOString() });

    // Save to KV (prune if too long)
    await env.CHAT_HISTORY.put(sessionId, JSON.stringify(history.slice(-30)));

    return new Response(JSON.stringify({ message: assistantMessage }));
  }
};

// wrangler.toml
name = "ai-chat-worker"
compatibility_date = "2026-03-15"

[[kv_namespaces]]
binding = "CHAT_HISTORY"
id = "your-kv-namespace-id"
preview_id = "your-preview-kv-id"

[vars]
OPENROUTER_API_KEY = "your-api-key"
```

### 2.2 Advanced Pattern (Cloudflare Agents + D1)

```javascript
// agent.js
export class ChatAgent {
  constructor(env) {
    this.env = env;
    this.db = env.DB; // D1 database
    this.kv = env.CHAT_HISTORY; // KV for cache
  }

  async onChatMessage(message, sessionId) {
    // 1. Load recent history from KV (fast)
    let recentHistory = await this.kv.get(sessionId, { type: 'json' }) || [];

    // 2. Load relevant long-term context from D1
    const relevantContext = await this.loadRelevantContext(sessionId, message);

    // 3. Combine history
    const fullHistory = [...recentHistory, ...relevantContext];

    // 4. Call OpenRouter
    const response = await this.callOpenRouter(fullHistory, message);

    // 5. Update KV (short-term)
    recentHistory.push(
      { role: 'user', content: message, timestamp: new Date().toISOString() },
      { role: 'assistant', content: response, timestamp: new Date().toISOString() }
    );
    await this.kv.put(sessionId, JSON.stringify(recentHistory.slice(-20)));

    // 6. Update D1 (long-term storage)
    await this.saveToD1(sessionId, message, response);

    return response;
  }

  async loadRelevantContext(sessionId, query) {
    // Semantic search using vector similarity
    // Or simple keyword search for MVP
    const result = await this.db.prepare(`
      SELECT content, timestamp
      FROM conversation_history
      WHERE session_id = ?
      ORDER BY timestamp DESC
      LIMIT 5
    `).bind(sessionId).all();

    return result.map(row => ({ role: 'system', content: row.content }));
  }

  async callOpenRouter(history, message) {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json'
      },
      DB: JSON.stringify({
        model: 'anthropic/claude-3.5-sonnet',
        messages: [...history, { role: 'user', content: message }]
      })
    });

    const result = await response.json();
    return result.choices[0].message.content;
  }

  async saveToD1(sessionId, userMessage, assistantMessage) {
    await this.db.prepare(`
      INSERT INTO conversation_history (session_id, user_message, assistant_message, timestamp)
      VALUES (?, ?, ?, ?)
    `).bind(sessionId, userMessage, assistantMessage, new Date().toISOString())
      .run();
  }
}

// wrangler.toml
name = "ai-chat-agent"
main = "src/agent.js"

[[d1_databases]]
binding = "DB"
database_name = "chat-history"
database_id = "your-database-id"

[[kv_namespaces]]
binding = "CHAT_HISTORY"
id = "your-kv-id"
```

---

## 3. Memory Architecture Patterns

### 3.1 Three-Tier Memory System

```python
# Python pseudo-code cho reference
class AgentMemory:
    def __init__(self):
        self.working_memory = []  # Short-term (RAM-like)
        self.short_term = Redis()   # Redis (Cache)
        self.long_term = VectorDB()  # Qdrant/Pinecone

    async def store(self, user_id, content, memory_type):
        """Store message based on type"""
        if memory_type == 'current_context':
            self.working_memory.append(content)
        elif memory_type == 'recent':
            await self.short_term.setex(
                f"{user_id}:recent",
                3600,  # 1 hour TTL
                json.dumps(content)
            )
        elif memory_type == 'long_term':
            embedding = await self.embed(content)
            await self.long_term.insert({
                'user_id': user_id,
                'content': content,
                'embedding': embedding,
                'type': 'memory',
                'timestamp': datetime.now()
            })

    async def retrieve(self, user_id, query, limit=5):
        """Retrieve relevant memories"""
        # 1. Get from working memory
        result = self.working_memory[-10:]

        # 2. Get from short-term cache
        cached = await self.short_term.get(f"{user_id}:recent")
        if cached:
            result.extend(json.loads(cached))

        # 3. Semantic search from long-term
        query_embedding = await self.embed(query)
        memories = await self.long_term.search(
            vector=query_embedding,
            filter={'user_id': user_id},
            limit=limit
        )
        result.extend(memories)

        return result

    async def summarize_session(self, user_id, messages):
        """Summarize long sessions to save tokens"""
        summary = await llm.summarize(messages)
        await self.store(user_id, summary, 'long_term')
        self.working_memory = []  # Clear working memory
```

### 3.2 Conversation Summary Pattern

```javascript
// Summarization worker
async function summarizeConversation(sessionId, env) {
  const messages = await env.CHAT_HISTORY.get(sessionId, { type: 'json' }) || [];

  // Trigger summarization every 50 messages
  if (messages.length >= 50) {
    const recentMessages = messages.slice(-20); // Keep last 20 verbatim
    const oldMessages = messages.slice(0, -20); // Summarize older ones

    // Call AI to summarize
    const summary = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'anthropic/claude-3.5-sonnet',
        messages: [
          { role: 'system', content: 'Summarize the following conversation concisely.' },
          { role: 'user', content: JSON.stringify(oldMessages) }
        ]
      })
    });

    const summaryText = (await summary.json()).choices[0].message.content;

    // Store summary in vector DB
    await env.VECTOR_DB.insert({
      session_id: sessionId,
      type: 'summary',
      content: summaryText,
      timestamp: new Date().toISOString()
    });

    // Update KV with recent messages + summary reference
    const newHistory = [
      { role: 'system', content: `[Summary of previous conversation: ${summaryText}]` },
      ...recentMessages
    ];
    await env.CHAT_HISTORY.put(sessionId, JSON.stringify(newHistory));
  }
}
```

---

## 4. Best Practices 2026

### 4.1 Context Window Management

```javascript
// Smart context management
async function buildContext(sessionId, userMessage, env) {
  const MAX_TOKENS = 128000; // Claude 3.5 context limit
  const RESERVE_TOKENS = 4000; // Reserve for response

  // 1. Get recent messages
  const recent = await env.CHAT_HISTORY.get(sessionId, { type: 'json' }) || [];

  // 2. Get relevant long-term memories
  const queryEmbedding = await embed(userMessage);
  const relevantMemories = await env.VECTOR_DB.search({
    vector: queryEmbedding,
    limit: 3,
    filter: { session_id: sessionId }
  });

  // 3. Estimate tokens
  const recentTokens = estimateTokens(recent);
  const memoryTokens = estimateTokens(relevantMemories);

  // 4. Trim if needed
  let finalHistory = [];
  if (recentTokens + memoryTokens + RESERVE_TOKENS > MAX_TOKENS) {
    // Keep most recent messages
    finalHistory = recent.slice(-10);
  } else {
    finalHistory = recent;
  }

  // 5. Add relevant memories as system messages
  finalHistory.unshift({
    role: 'system',
    content: `Relevant context: ${relevantMemories.map(m => m.content).join('\n')}`
  });

  return finalHistory;
}
```

### 4.2 Session Expiration & Cleanup

```javascript
// Cron worker for cleanup
export default {
  async scheduled(event, env) {
    // 1. Clean up old KV entries
    const allSessions = await listAllSessions(env.KV);

    for (const session of allSessions) {
      const data = await env.KV.get(session, { type: 'json' });

      // Delete sessions inactive for 30 days
      const lastActive = new Date(data.metadata.last_active);
      const daysSinceActive = (Date.now() - lastActive) / (1000 * 60 * 60 * 24);

      if (daysSinceActive > 30) {
        await env.KV.delete(session);

        // Archive to D1 before deletion
        await env.DB.prepare(`
          INSERT INTO archived_sessions (session_id, data, archived_at)
          VALUES (?, ?, ?)
        `).bind(session, JSON.stringify(data), new Date().toISOString())
          .run();
      }
    }

    // 2. Optimize vector DB
    await env.VECTOR_DB.cleanup_old_vectors({
      days: 90 // Delete vectors older than 90 days
    });
  }
};

// wrangler.toml
[triggers]
crons = ["0 0 * * *"]  # Run daily at midnight
```

---

## 5. Framework & Tools Khuyến Nghị

### 5.1 For Cloudflare Workers

| Tool | Use Case | Link |
|------|----------|------|
| **Cloudflare KV** | Session cache, recent messages | https://developers.cloudflare.com/kv/ |
| **Cloudflare D1** | SQL database for logs | https://developers.cloudflare.com/d1/ |
| **Cloudflare Agents** | Real-time chat with Durable Objects | https://developers.cloudflare.com/agents/ |
| **AI SDK** | Type-safe AI function calls | https://sdk.vercel.ai/ |

### 5.2 Vector Database Options

| Tool | Best For | Pricing | Notes |
|------|-----------|----------|-------|
| **Qdrant** | Self-hosted, high performance | Open-source | 75% cost savings vs managed |
| **Pinecone** | Managed, easy setup | From $70/mo | Excellent for startups |
| **Weaviate** | Hybrid search (vector + keyword) | From $110/mo | Good for RAG |
| **pgvector** | PostgreSQL integration | Free (if have PG) | Great for existing infra |
| **Chroma** | Local development, simple | Open-source | Good for prototyping |

### 5.3 Memory Frameworks

| Framework | Features | Best For |
|-----------|-----------|----------|
| **LangChain Memory** | Modular, multiple backends | Python agents |
| **Mem0** | Multi-tier, auto-summarization | Production systems |
| **Letta** | OS-inspired memory tiers | Advanced architectures |
| **Redis Agent Memory** | Fast, built for Redis | Redis-heavy stacks |

---

## 6. Production Checklist

- [ ] **Implement session isolation** by user_id/session_id
- [ ] **Add rate limiting** to prevent abuse
- [ ] **Implement token estimation** before API calls
- [ ] **Set up monitoring** (Cloudflare Analytics, custom dashboards)
- [ ] **Add error handling** for API failures
- [ ] **Implement retry logic** with exponential backoff
- [ ] **Set up backup strategy** for all data
- [ ] **Add analytics** for conversation insights
- [ ] **Implement GDPR compliance** (data deletion on request)
- [ ] **Load test** before production deployment
- [ ] **Set up alerts** for failures and anomalies
- [ ] **Document API endpoints** and session flow

---

## 7. Next Steps cho Duet Company

### Immediate (Week 1-2)
1. **Setup Cloudflare Workers** with KV for basic chat
2. **Integrate OpenRouter API** for model routing
3. **Implement basic session management** with session IDs
4. **Add D1 database** for long-term storage

### Short-term (Week 3-4)
1. **Add vector database** (Qdrant or pgvector)
2. **Implement semantic retrieval** for long-term memory
3. **Add summarization** for long conversations
4. **Build admin dashboard** for conversation analytics

### Long-term (Month 2-3)
1. **Advanced memory architecture** with multi-tier system
2. **Multi-agent support** with shared memory
3. **Real-time features** via Cloudflare Agents
4. **Production hardening** (monitoring, alerts, scaling)

---

## References

1. Cloudflare Workers AI - https://developers.cloudflare.com/workers-ai/
2. OpenRouter API - https://openrouter.ai/docs
3. Contextual Conversation Worker - https://github.com/tom-log/contextual-conversation-worker
4. Redis Agent Memory - https://redis.io/blog/ai-agent-architecture/
5. Mem0 Memory Framework - https://mem0.ai/
6. LangChain Memory - https://python.langchain.com/docs/modules/memory/

---

**Liên hệ:** duyet.cs@gmail.com
**Cập nhật:** 2026-03-15
