# Conda Environment Setup for embed-rerank

This guide covers running embed-rerank with conda environments on macOS (particularly Apple Silicon).

## Quick Start

### 1. Create Conda Environment

```bash
conda create -n embed-rerank python=3.13
conda activate embed-rerank
cd /path/to/embed-rerank
pip install -e .
pip install mlx>=0.4.0 mlx-lm>=0.2.0 psutil
```

### 2. Configure Environment

Copy `.env.example` to `.env` and configure:

```bash
# Backend Configuration
BACKEND=auto                                            # Uses MLX on Apple Silicon
MODEL_NAME=mlx-community/Qwen3-Embedding-8B-4bit-DWQ   # 4096-dim embeddings
DIMENSION_STRATEGY=hidden_size

# Reranker Configuration
RERANKER_BACKEND=torch                                  # Use torch for stable reranker
RERANKER_MODEL_ID=cross-encoder/ms-marco-MiniLM-L-6-v2
RERANK_MAX_SEQ_LEN=512
RERANK_BATCH_SIZE=16

# OpenAI Compatibility
OPENAI_RERANK_AUTO_SIGMOID=true                        # Auto-normalize scores

# Server
HOST=0.0.0.0
PORT=9000
LOG_LEVEL=INFO
LOG_FORMAT=json
```

### 3. Server Management Scripts

#### Start Server
```bash
./tools/server-start-conda.sh
```

**Output:**
```
✅ Loaded .env configuration
🚀 Starting embed-rerank server...
   Environment: conda (embed-rerank)
   Backend: auto
   Embedding Model: mlx-community/Qwen3-Embedding-8B-4bit-DWQ
   Reranker Model: cross-encoder/ms-marco-MiniLM-L-6-v2
   Listen: http://0.0.0.0:9000
   Logs: /tmp/embed-rerank.log
✅ Server started successfully (PID 12345)
```

#### Check Status
```bash
./tools/server-status-conda.sh
```

**Output:**
```
🔍 embed-rerank Server Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Server is RUNNING
   PID: 12345
   HTTP: ✅ Responding on port 9000

📊 Health Check:
{
    "status": "healthy",
    "backend": {
        "name": "MLXBackend",
        "model_name": "mlx-community/Qwen3-Embedding-8B-4bit-DWQ",
        "embedding_dimension": 4096
    },
    "reranker": {
        "name": "TorchCrossEncoderBackend",
        "model_name": "cross-encoder/ms-marco-MiniLM-L-6-v2",
        "device": "mps"
    }
}
```

#### Stop Server
```bash
./tools/server-stop-conda.sh
```

**Output:**
```
🛑 Stopping embed-rerank server (PID 12345)...
✅ Server stopped successfully
```

### 4. View Logs

```bash
# Real-time logs
tail -f /tmp/embed-rerank.log

# Last 50 lines
tail -50 /tmp/embed-rerank.log
```

## Troubleshooting

### Server Won't Start

**Check if port is already in use:**
```bash
lsof -i :9000
```

**Kill existing process:**
```bash
kill <PID>
```

### Check for Stale Processes

```bash
ps aux | grep uvicorn | grep embed-rerank
```

### Manual Start (for debugging)

```bash
conda activate embed-rerank
cd /path/to/embed-rerank
python -m uvicorn app.main:app --host 0.0.0.0 --port 9000
```

Press `Ctrl+C` to stop.

### Verify Configuration

```bash
conda activate embed-rerank
python -c "from app.config import settings; print(f'Backend: {settings.BACKEND}'); print(f'Model: {settings.MODEL_NAME}')"
```

## Integration with ChunkHound

Once the server is running, ChunkHound can use it via OpenAI-compatible API:

**Global ChunkHound config:** `~/.chunkhound.json`
```json
{
  "embedding": {
    "provider": "openai",
    "base_url": "http://localhost:9000/v1",
    "model": "mlx-community/Qwen3-Embedding-8B-4bit-DWQ",
    "api_key": "dummy-key",
    "dimensions": 4096,
    "rerank_model": "cross-encoder/ms-marco-MiniLM-L-6-v2",
    "rerank_url": "http://localhost:9000",
    "rerank_format": "tei"
  }
}
```

**Test ChunkHound integration:**
```bash
# Index a project
cd /path/to/your/project
chunkhound index

# Search semantically
chunkhound search "reranking backend" --page-size 5
```

## Script Locations

| Script | Purpose | Location |
|--------|---------|----------|
| `server-start-conda.sh` | Start server in background | `tools/` |
| `server-stop-conda.sh` | Stop running server | `tools/` |
| `server-status-conda.sh` | Check server status and health | `tools/` |

## Architecture

```
┌─────────────────────────────────────────────┐
│  ChunkHound CLI / IDE (MCP)                │
└──────────────┬──────────────────────────────┘
               │
               │ HTTP (OpenAI API / TEI format)
               │
┌──────────────▼──────────────────────────────┐
│  embed-rerank Server (localhost:9000)      │
│  ├─ /v1/embeddings (OpenAI format)         │
│  └─ /rerank (TEI format)                   │
└──────────────┬──────────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼─────┐  ┌──────▼──────────┐
│  MLX       │  │  Torch          │
│  Backend   │  │  CrossEncoder   │
│  (4096-dim)│  │  Reranker       │
└────────────┘  └─────────────────┘
    Apple            Apple MPS
   Silicon          (GPU accel)
```

## Performance Considerations

### Apple Silicon Optimization

- **MLX Backend**: Sub-millisecond inference on unified memory
- **Batch Size**: 32 optimal for MLX
- **Memory**: ~2.8GB for Qwen3-Embedding-8B-4bit + 512MB for reranker
- **Device**: MLX uses Apple Silicon unified memory, Torch uses MPS (Metal Performance Shaders)

### Recommended Settings

```env
# For maximum performance on Apple Silicon
BACKEND=auto                    # Auto-detects MLX
DIMENSION_STRATEGY=hidden_size  # Use full model dimensions
RERANKER_BACKEND=torch          # Stable cross-encoder
RERANK_BATCH_SIZE=16            # Good balance for MPS
```

## Next Steps

- [MCP Integration](./MCP_SETUP.md) - Connect to IDEs via Model Context Protocol
- [API Documentation](./ENHANCED_OPENAI_API.md) - Full API reference
- [Troubleshooting](./TROUBLESHOOTING.md) - Common issues and solutions
