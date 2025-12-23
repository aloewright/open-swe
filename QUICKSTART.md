# Open SWE Docker - Quick Start Guide

Get Open SWE running in Docker in 5 minutes!

## Prerequisites

- Docker & Docker Compose installed
- At least one LLM API key (Anthropic, OpenAI, or Google)

## Quick Start

### 1. Set up environment

```bash
# Copy environment template
cp .env.docker .env

# Edit .env and add your API keys
nano .env  # or vim, code, etc.
```

**Minimum required variables:**
```bash
# Add at least one of these:
ANTHROPIC_API_KEY=sk-ant-...
# OR
OPENAI_API_KEY=sk-...
# OR  
GOOGLE_API_KEY=...

# Encryption key (generate with: openssl rand -hex 32)
SECRETS_ENCRYPTION_KEY=your_generated_key
```

### 2. Deploy with one command

```bash
./deploy.sh up
```

That's it! Open SWE is now running at:
- **Web UI**: http://localhost:3000
- **Agent API**: http://localhost:2024

## Common Commands

```bash
# View logs
./deploy.sh logs

# Check status
./deploy.sh status

# Stop services
./deploy.sh down

# Restart services
./deploy.sh restart

# Rebuild images
./deploy.sh rebuild
```

## Configure GitHub Integration (Optional)

For full functionality with GitHub repositories:

1. Create a GitHub App at https://github.com/settings/apps/new
2. Add these to your `.env`:
   ```bash
   GITHUB_APP_NAME=your-app-name
   GITHUB_APP_ID=123456
   GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
   ...your key here...
   -----END RSA PRIVATE KEY-----"
   GITHUB_WEBHOOK_SECRET=your_webhook_secret
   ```
3. Restart: `./deploy.sh restart`

## Troubleshooting

### Container won't start
```bash
./deploy.sh logs
```

### Reset everything
```bash
./deploy.sh clean
./deploy.sh build
./deploy.sh up
```

### Update images
```bash
git pull
./deploy.sh rebuild
```

## Next Steps

- Read [DOCKER_DEPLOYMENT.md](./DOCKER_DEPLOYMENT.md) for full documentation
- Configure GitHub webhooks for automatic issue handling
- Set up a reverse proxy for production deployment
- Enable LangSmith tracing for debugging

## Support

- Documentation: [apps/docs](./apps/docs)
- Issues: https://github.com/langchain-ai/open-swe/issues
- Discussions: https://github.com/langchain-ai/open-swe/discussions
