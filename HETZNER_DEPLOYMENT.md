# Deploying Open SWE to Hetzner Cloud

This guide walks you through deploying Open SWE on a Hetzner Cloud server for autonomous coding.

## Prerequisites

- Hetzner Cloud account with API token
- Domain name (optional, but recommended for production)
- SSH key pair
- Local machine with Docker installed

## Option 1: Automated Deployment (Recommended)

### Step 1: Prepare Your Server

You can use the Hetzner MCP tools or create a server via the web console:

**Server Requirements:**
- **Type**: CX21 or higher (2 vCPU, 4GB RAM minimum)
- **Image**: Ubuntu 22.04 or 24.04
- **Location**: Your preferred region (fsn1, nbg1, or hel1)
- **SSH Keys**: Add your SSH key during creation

### Step 2: Transfer Files to Server

```bash
# From your local machine
cd /Users/aloe/apps/open-swe

# Transfer to your Hetzner server
rsync -avz --exclude 'node_modules' --exclude '.git' \
  . root@YOUR_SERVER_IP:/opt/open-swe/
```

### Step 3: SSH Into Server and Install Docker

```bash
ssh root@YOUR_SERVER_IP

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Verify installation
docker --version
docker-compose --version
```

### Step 4: Configure Environment

```bash
cd /opt/open-swe

# Copy environment template
cp .env.docker .env

# Edit environment file
nano .env
```

Add your configuration:
```bash
# Required: LLM API Keys
ANTHROPIC_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here

# Required: Encryption key
SECRETS_ENCRYPTION_KEY=$(openssl rand -hex 32)

# Optional: GitHub App credentials
GITHUB_APP_NAME=your-app-name
GITHUB_APP_ID=123456
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----"
GITHUB_WEBHOOK_SECRET=your_secret

# Update app URL for your domain/IP
OPEN_SWE_APP_URL=https://openswe.yourdomain.com
# or
OPEN_SWE_APP_URL=http://YOUR_SERVER_IP:3000
```

### Step 5: Deploy

```bash
# Make deploy script executable
chmod +x deploy.sh

# Build and start services
./deploy.sh build
./deploy.sh up

# Check status
./deploy.sh status

# View logs
./deploy.sh logs
```

Your Open SWE instance is now running!
- Web UI: http://YOUR_SERVER_IP:3000
- Agent API: http://YOUR_SERVER_IP:2024

## Option 2: Manual Docker Commands

If you prefer not to use the deploy script:

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Setting Up SSL with Caddy (Recommended)

For production, use Caddy for automatic HTTPS:

### Install Caddy

```bash
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | \
  gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | \
  tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install caddy
```

### Configure Caddy

Create `/etc/caddy/Caddyfile`:

```caddy
openswe.yourdomain.com {
    reverse_proxy localhost:3000
}

api.openswe.yourdomain.com {
    reverse_proxy localhost:2024
}
```

### Start Caddy

```bash
systemctl enable caddy
systemctl start caddy
```

Caddy will automatically obtain SSL certificates from Let's Encrypt!

## Setting Up SSL with Nginx

Alternative to Caddy, using Nginx with Certbot:

### Install Nginx and Certbot

```bash
apt update
apt install -y nginx certbot python3-certbot-nginx
```

### Configure Nginx

Create `/etc/nginx/sites-available/openswe`:

```nginx
server {
    listen 80;
    server_name openswe.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name api.openswe.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:2024;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
ln -s /etc/nginx/sites-available/openswe /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

### Obtain SSL Certificate

```bash
certbot --nginx -d openswe.yourdomain.com -d api.openswe.yourdomain.com
```

## Firewall Configuration

### Using Hetzner Cloud Firewall (Recommended)

Create firewall rules to allow only necessary traffic:

```bash
# Allow SSH, HTTP, HTTPS
# Using Hetzner MCP or web console, create firewall with rules:
# - SSH (22) from your IP
# - HTTP (80) from anywhere (0.0.0.0/0, ::/0)
# - HTTPS (443) from anywhere (0.0.0.0/0, ::/0)
```

### Using UFW on Server

```bash
# Enable firewall
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw enable

# If not using reverse proxy, also allow:
# ufw allow 3000/tcp  # Web UI
# ufw allow 2024/tcp  # Agent API
```

## DNS Configuration

Point your domain to the server:

```
A    openswe.yourdomain.com    YOUR_SERVER_IP
A    api.openswe.yourdomain.com    YOUR_SERVER_IP
```

Wait for DNS propagation (usually 5-30 minutes).

## Auto-Start on Boot

Ensure Docker containers start automatically:

```bash
# Edit docker-compose.yml (already configured with restart: unless-stopped)
# Or manually enable:
docker update --restart=unless-stopped open-swe-agent
docker update --restart=unless-stopped open-swe-web
```

## Backup Strategy

### Automated Backups

Create backup script at `/opt/open-swe/backup-cron.sh`:

```bash
#!/bin/bash
cd /opt/open-swe
./deploy.sh backup
# Remove backups older than 30 days
find backups/ -name "*.tar.gz" -mtime +30 -delete
```

Make it executable and add to cron:

```bash
chmod +x /opt/open-swe/backup-cron.sh
crontab -e
```

Add daily backup at 2 AM:
```
0 2 * * * /opt/open-swe/backup-cron.sh
```

### Hetzner Volume for Data (Optional)

For better data persistence:

1. Create a Hetzner volume
2. Attach to your server
3. Mount at `/mnt/openswe-data`
4. Update docker-compose.yml to use mounted volume

## Monitoring

### View Logs

```bash
# All services
./deploy.sh logs

# Follow logs
docker-compose logs -f

# Specific service
docker-compose logs -f agent
```

### Check Resource Usage

```bash
docker stats
```

### Check Service Status

```bash
./deploy.sh status
```

## Updating Open SWE

```bash
cd /opt/open-swe
git pull origin main
./deploy.sh rebuild
./deploy.sh up
```

## Troubleshooting

### Container won't start
```bash
./deploy.sh logs
docker-compose ps
```

### High memory usage
Consider upgrading to CX31 (4GB RAM) or higher

### Connection refused
Check firewall rules and ensure ports are open

### SSL certificate issues
```bash
certbot renew --dry-run
systemctl status nginx
```

## Cost Optimization

- **Development**: CX11 ($4.50/mo) - Minimal testing
- **Production Light**: CX21 ($7.50/mo) - Light usage
- **Production Standard**: CX31 ($14/mo) - Standard usage
- **Production Heavy**: CX41 ($26/mo) - Heavy usage

Add Hetzner Volume if you need persistent storage beyond the root disk.

## Security Best Practices

1. **Keep system updated**: `apt update && apt upgrade`
2. **Use SSH keys only**: Disable password authentication
3. **Enable automatic security updates**
4. **Use Hetzner Cloud Firewall**
5. **Regular backups**: Use the automated backup script
6. **Monitor logs**: Check for suspicious activity
7. **Use strong secrets**: Generate with `openssl rand -hex 32`

## Support

For issues specific to this deployment:
- Check logs: `./deploy.sh logs`
- Hetzner Status: https://status.hetzner.com/
- Open SWE Issues: https://github.com/langchain-ai/open-swe/issues

## Next Steps

1. Configure GitHub App for repository integration
2. Set up webhook endpoints for issue automation
3. Configure LangSmith for agent monitoring
4. Add team members to NEXT_PUBLIC_ALLOWED_USERS_LIST
5. Set up monitoring/alerting
