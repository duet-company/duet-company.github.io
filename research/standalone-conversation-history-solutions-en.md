# Standalone Conversation History Solutions for AI Agents

**Date:** 2026-03-15
**Tech Stack:** Cloudflare Workers, AI SDK, OpenRouter
**Objective:** Build standalone conversation history system for AI agents

---

## Executive Summary

In 2026, conversation history solutions for AI agents focus on **tiered architecture** combining:
- **Vector Database** - for semantic retrieval
- **Relational/NoSQL Database** - for full logs and audit trails
- **Cache Layer** (Redis/KV) - for fast session management
- **Summarization** - to reduce context size

---

## 1. Recommended Storage Architecture

### 1.1 Hybrid Architecture (Recommended)

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

### Key Components

#### Layer 1: Redis/Cloudflare KV (Short-term Cache)
- **Purpose:** Fast session management, recent messages
- **Storage:** Key-value with TTL (24-48 hours)
- **Use case:** Last 20-50 messages for immediate context

#### Layer 2: Vector Database (Long-term Memory)
- **Purpose:** Semantic retrieval, summaries, facts
- **Tools:** Qdrant, Pinecone, Weaviate, pgvector, Chroma
- **Use case:** User preferences, conversation summaries, important facts
- **Search:** Semantic similarity search (cosine similarity)

#### Layer 3: PostgreSQL (Audit & Analytics)
- **Purpose:** Full conversation logs, analytics, backup
- **Use case:** Compliance, analytics, debugging, backup
- **Retention:** Long-term (months/years)

---

## 2. Implementation with Cloudflare Workers + OpenRouter

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

[vars]
OPENROUTER_API_KEY = "your-api-key"
```

### 2.2 Advanced Pattern (Cloudflare Agents + D1 + Vector DB)

```javascript
// agent.js
export class ChatAgent {
  constructor(env) {
    this.env = env;
    this.db = env.DB; // D1 database
    this.kv = env.CHAT_HISTORY; // KV for cache
    this.vector = env.VECTOR_DB; // Vector database
  }

  async onChatMessage(message, sessionId) {
    // 1. Load recent history from KV (fast)
    let recentHistory = await this.kv.get(sessionId, { type: 'json' }) || [];

    // 2. Load relevant long-term context from vector DB
    const queryEmbedding = await this.embed(message);
    const relevantMemories = await this.vector.search({
      vector: queryEmbedding,
      filter: { session_id: sessionId },
      limit: 3
    });

    // 3. Combine history
    const fullHistory = [
      ...recentHistory,
      ...relevantMemories.map(m => ({ role: 'system', content: m.content }))
    ];

    // 4. Call OpenRouter
    const response = await this.callOpenRouter(fullHistory, message);

    // 5. Update KV (short-term)
    recentHistory.push(
      { role: 'user', content: message, timestamp: new Date().toISOString() },
      { role: 'assistant', content: response, timestamp: new Date().toISOString() }
    );
    await this.kv.put(sessionId, JSON.stringify(recentHistory.slice(-20)));

    // 6. Save to D1 (long-term storage)
    await this.saveToD1(sessionId, message, response);

    // 7. Store in vector DB for future retrieval
    if (this.isImportant(response)) {
      await this.vector.insert({
        session_id: sessionId,
        content: response,
        embedding: await this.embed(response),
        metadata: {
          type: 'fact',
          timestamp: new Date().toISOString()
        }
      });
    }

    return response;
  }

  async callOpenRouter(history, message) {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://bot.duyet.net',
        'X-Title': 'AI Data Labs Chat'
      },
      body: JSON.stringify({
        model: 'anthropic/claude-3.5-sonnet',
        messages: [...history, { role: 'user', content: message }],
        max_tokens: 2000,
        temperature: 0.7
      })
    });

    if (!response.ok) {
      throw new Error(`OpenRouter API error: ${response.status}`);
    }

    const result = await response.json();
    return result.choices[0].message.content;
  }

  async embed(text) {
    const response = await fetch('https://openrouter.ai/api/v1/embeddings', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'openai/text-embedding-3-small',
        input: text
      })
    });

    const result = await response.json();
    return result.data[0].embedding;
  }

  isImportant(content) {
    // Simple heuristic - in production, use AI to classify
    const importantKeywords = ['remember', 'note', 'save', 'important', 'preference'];
    return importantKeywords.some(keyword => content.toLowerCase().includes(keyword));
  }
}
```

---

## 3. Memory Architecture Patterns

### 3.1 Three-Tier Memory System

```python
# Python pseudo-code for reference
class AgentMemory:
    def __init__(self):
        self.working_memory = []  # Short-term (RAM-like) - immediate context
        self.short_term = Redis()   # Redis (Cache) - recent history
        self.long_term = VectorDB()  # Qdrant/Pinecone - semantic memory

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
        """Retrieve relevant memories using hybrid search"""
        result = []

        # 1. Get from working memory (immediate context)
        result.extend(self.working_memory[-10:])

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

### 3.2 Conversation Summarization Strategy

```javascript
// Summarize every 50 messages to reduce context size
async function summarizeConversation(sessionId, env) {
  const messages = await env.CHAT_HISTORY.get(sessionId, { type: 'json' }) || [];

  if (messages.length >= 50) {
    const recentMessages = messages.slice(-20); // Keep last 20 verbatim
    const oldMessages = messages.slice(0, -20); // Summarize older ones

    // Call AI to summarize
    const summaryResponse = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'anthropic/claude-3.5-sonnet',
        messages: [
          {
            role: 'system',
            content: 'Summarize the following conversation in 2-3 sentences. Focus on key points, decisions, and user preferences.'
          },
          { role: 'user', content: JSON.stringify(oldMessages) }
        ],
        max_tokens: 500
      })
    });

    const summaryText = (await summaryResponse.json()).choices[0].message.content;

    // Store summary in vector DB
    const summaryEmbedding = await embed(summaryText);
    await env.VECTOR_DB.insert({
      session_id: sessionId,
      type: 'summary',
      content: summaryText,
      embedding: summaryEmbedding,
      timestamp: new Date().toISOString()
    });

    // Update KV with recent messages + summary reference
    const newHistory = [
      { role: 'system', content: `[Previous conversation summary: ${summaryText}]` },
      ...recentMessages
    ];
    await env.CHAT_HISTORY.put(sessionId, JSON.stringify(newHistory));
  }
}
```

---

## 4. Context Window Management

### 4.1 Smart Context Building

```javascript
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

  // 3. Estimate tokens (simplified)
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
    content: `Relevant context from past conversations:\n${relevantMemories.map(m => m.content).join('\n')}`
  });

  return finalHistory;
}

// Simple token estimation (for production, use tokenizer)
function estimateTokens(messages) {
  return messages.reduce((acc, msg) => {
    return acc + (msg.content.length / 4); // Rough estimate: 1 token ≈ 4 chars
  }, 0);
}
```

---

## 5. Recommended Tools & Frameworks

### 5.1 Vector Database Comparison

| Tool | Best For | Pricing | Notes |
|------|-----------|----------|-------|
| **Qdrant** | Self-hosted, high performance | Open-source | 75% cost savings vs managed |
| **Pinecone** | Managed, easy setup | From $70/mo | Excellent for startups |
| **Weaviate** | Hybrid search (vector + keyword) | From $110/mo | Good for RAG |
| **pgvector** | PostgreSQL integration | Free (if have PG) | Great for existing infra |
| **Chroma** | Local development, simple | Open-source | Good for prototyping |

### 5.2 Memory Frameworks

| Framework | Features | Best For |
|-----------|-----------|----------|
| **LangChain Memory** | Modular, multiple backends | Python agents |
| **Mem0** | Multi-tier, auto-summarization | Production systems |
| **Letta** | OS-inspired memory tiers | Advanced architectures |
| **Redis Agent Memory** | Fast, built for Redis | Redis-heavy stacks |

---

## 6. Production Best Practices

### 6.1 Session Management
- ✅ Use unique session IDs (UUID v4)
- ✅ Separate sessions by user_id for multi-tenancy
- ✅ Implement session expiration (TTL)
- ✅ Add rate limiting per session

### 6.2 Data Privacy
- ✅ Implement GDPR compliance (data deletion on request)
- ✅ Encrypt sensitive data at rest
- ✅ Add consent tracking for data usage
- ✅ Anonymize logs for analytics

### 6.3 Performance
- ✅ Use CDN for static assets
- ✅ Implement caching at multiple levels
- ✅ Use connection pooling for databases
- ✅ Add load balancing for high traffic

### 6.4 Monitoring & Observability
- ✅ Track token usage per session
- ✅ Monitor API latency and errors
- ✅ Set up alerts for failures
- ✅ Log conversation analytics (length, topics)

---

## 7. Implementation Roadmap

### Phase 1: MVP (Week 1-2)
- [ ] Setup Cloudflare Workers with KV
- [ ] Integrate OpenRouter API
- [ ] Implement basic session management
- [ ] Add message storage (last 50 messages)
- [ ] Build simple chat UI

### Phase 2: Enhanced Memory (Week 3-4)
- [ ] Add D1 database for long-term storage
- [ ] Integrate vector database (Qdrant or Pinecone)
- [ ] Implement semantic retrieval
- [ ] Add conversation summarization
- [ ] Build admin dashboard

### Phase 3: Production Hardening (Month 2)
- [ ] Add authentication (OAuth/JWT)
- [ ] Implement rate limiting
- [ ] Add monitoring and analytics
- [ ] Set up backups and disaster recovery
- [ ] Add multi-agent support
- [ ] GDPR compliance features

### Phase 4: Advanced Features (Month 3+)
- [ ] Multi-agent conversations
- [ ] Real-time collaboration
- [ ] Advanced memory (episodic, semantic)
- [ ] Custom model fine-tuning
- [ ] Enterprise features (SSO, audit logs)

---

## 8. Example: Complete Worker with All Features

```javascript
// Complete implementation combining all patterns
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // Route handling
    if (path === '/api/chat') {
      return this.handleChat(request, env);
    } else if (path === '/api/history') {
      return this.getHistory(request, env);
    } else if (path === '/api/clear') {
      return this.clearHistory(request, env);
    }

    return new Response('Not Found', { status: 404 });
  },

  async handleChat(request, env) {
    const { message, session_id } = await request.json();

    // Validate input
    if (!message || !session_id) {
      return new Response('Missing message or session_id', { status: 400 });
    }

    try {
      // 1. Load history
      const history = await this.loadHistory(session_id, env);

      // 2. Build context
      const context = await this.buildContext(session_id, message, env);

      // 3. Call OpenRouter
      const response = await this.callOpenRouter(context, message, env);

      // 4. Store message and response
      await this.storeMessage(session_id, message, response, env);

      // 5. Check if summarization is needed
      await this.checkSummarization(session_id, env);

      return new Response(JSON.stringify({ response }), {
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      console.error('Chat error:', error);
      return new Response('Internal Server Error', { status: 500 });
    }
  },

  async loadHistory(sessionId, env) {
    return await env.CHAT_HISTORY.get(sessionId, { type: 'json' }) || [];
  },

  async buildContext(sessionId, userMessage, env) {
    const history = await this.loadHistory(sessionId, env);

    // Get relevant memories
    const queryEmbedding = await this.embed(userMessage, env);
    const relevantMemories = await env.VECTOR_DB.search({
      vector: queryEmbedding,
      filter: { session_id: sessionId },
      limit: 3
    });

    // Combine
    return [
      {
        role: 'system',
        content: this.buildSystemPrompt(relevantMemories)
      },
      ...history.slice(-20)
    ];
  },

  buildSystemPrompt(memories) {
    if (memories.length === 0) {
      return 'You are a helpful AI assistant.';
    }
    return `You are a helpful AI assistant. Here is relevant context from past conversations:\n${memories.map(m => m.content).join('\n')}`;
  },

  async callOpenRouter(context, message, env) {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://bot.duyet.net',
        'X-Title': 'AI Data Labs'
      },
      body: JSON.stringify({
        model: 'anthropic/claude-3.5-sonnet',
        messages: [...context, { role: 'user', content: message }],
        max_tokens: 2000,
        temperature: 0.7
      })
    });

    if (!response.ok) {
      throw new Error(`OpenRouter error: ${response.status}`);
    }

    const result = await response.json();
    return result.choices[0].message.content;
  },

  async storeMessage(sessionId, userMessage, assistantMessage, env) {
    const history = await this.loadHistory(sessionId, env);
    const timestamp = new Date().toISOString();

    history.push(
      { role: 'user', content: userMessage, timestamp },
      { role: 'assistant', content: assistantMessage, timestamp }
    );

    // Prune to last 50 messages
    await env.CHAT_HISTORY.put(sessionId, JSON.stringify(history.slice(-50)));

    // Store in D1 for long-term
    await env.DB.prepare(`
      INSERT INTO messages (session_id, role, content, timestamp)
      VALUES (?, ?, ?, ?)
    `).bind(sessionId, 'user', userMessage, timestamp).run();
    await env.DB.prepare(`
      INSERT INTO messages (session_id, role, content, timestamp)
      VALUES (?, ?, ?, ?)
    `).bind(sessionId, 'assistant', assistantMessage, timestamp).run();
  },

  async checkSummarization(sessionId, env) {
    const history = await this.loadHistory(sessionId, env);

    if (history.length >= 50) {
      await this.summarizeConversation(sessionId, history, env);
    }
  },

  async summarizeConversation(sessionId, history, env) {
    const recent = history.slice(-20);
    const old = history.slice(0, -20);

    const summaryResponse = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'anthropic/claude-3.5-sonnet',
        messages: [
          { role: 'system', content: 'Summarize concisely in 2-3 sentences.' },
          { role: 'user', content: JSON.stringify(old) }
        ],
        max_tokens: 500
      })
    });

    const summary = (await summaryResponse.json()).choices[0].message.content;

    // Store summary in vector DB
    const embedding = await this.embed(summary, env);
    await env.VECTOR_DB.insert({
      session_id: sessionId,
      type: 'summary',
      content: summary,
      embedding: embedding,
      timestamp: new Date().toISOString()
    });

    // Update KV with summary reference
    const newHistory = [
      { role: 'system', content: `[Summary: ${summary}]` },
      ...recent
    ];
    await env.CHAT_HISTORY.put(sessionId, JSON.stringify(newHistory));
  },

  async embed(text, env) {
    const response = await fetch('https://openrouter.ai/api/v1/embeddings', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'openai/text-embedding-3-small',
        input: text
      })
    });

    const result = await response.json();
    return result.data[0].embedding;
  },

  async getHistory(request, env) {
    const { session_id } = await request.json();
    const history = await this.loadHistory(session_id, env);
    return new Response(JSON.stringify(history));
  },

  async clearHistory(request, env) {
    const { session_id } = await request.json();
    await env.CHAT_HISTORY.delete(session_id);
    return new Response(JSON.stringify({ success: true }));
  }
};
```

---

## References

1. Cloudflare Workers AI - https://developers.cloudflare.com/workers-ai/
2. OpenRouter API - https://openrouter.ai/docs
3. Contextual Conversation Worker - https://github.com/tom-log/contextual-conversation-worker
4. Redis Agent Memory - https://redis.io/blog/ai-agent-architecture/
5. Mem0 Memory Framework - https://mem0.ai/
6. LangChain Memory - https://python.langchain.com/docs/modules/memory/
7. AI SDK (Vercel) - https://sdk.vercel.ai/

---

**Contact:** duyet.cs@gmail.com
**Updated:** 2026-03-15
