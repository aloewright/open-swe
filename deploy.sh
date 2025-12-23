#!/bin/bash
set -e

# Open SWE Deployment Script
# This script helps deploy Open SWE to a server

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Open SWE Deployment Script${NC}"
echo "================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Warning: .env file not found${NC}"
    echo "Creating .env from template..."
    cp .env.docker .env
    echo -e "${YELLOW}Please edit .env file and add your API keys before running again${NC}"
    exit 1
fi

# Validate required environment variables
required_vars=(
    "ANTHROPIC_API_KEY|OPENAI_API_KEY|GOOGLE_API_KEY"
    "SECRETS_ENCRYPTION_KEY"
)

echo "Validating environment variables..."
source .env

has_llm_key=false
if [ -n "$ANTHROPIC_API_KEY" ] || [ -n "$OPENAI_API_KEY" ] || [ -n "$GOOGLE_API_KEY" ]; then
    has_llm_key=true
fi

if [ "$has_llm_key" = false ]; then
    echo -e "${RED}Error: At least one LLM API key is required (ANTHROPIC_API_KEY, OPENAI_API_KEY, or GOOGLE_API_KEY)${NC}"
    exit 1
fi

if [ -z "$SECRETS_ENCRYPTION_KEY" ]; then
    echo -e "${YELLOW}Warning: SECRETS_ENCRYPTION_KEY is not set. Generating one...${NC}"
    ENCRYPTION_KEY=$(openssl rand -hex 32)
    echo "" >> .env
    echo "SECRETS_ENCRYPTION_KEY=$ENCRYPTION_KEY" >> .env
    echo -e "${GREEN}Generated and added SECRETS_ENCRYPTION_KEY to .env${NC}"
fi

# Parse command line arguments
COMMAND=${1:-up}

case $COMMAND in
    up)
        echo "Starting Open SWE..."
        docker-compose up -d
        echo ""
        echo -e "${GREEN}✓ Open SWE is starting!${NC}"
        echo "  Web UI: http://localhost:3000"
        echo "  Agent API: http://localhost:2024"
        echo ""
        echo "View logs with: ./deploy.sh logs"
        ;;
    down)
        echo "Stopping Open SWE..."
        docker-compose down
        echo -e "${GREEN}✓ Open SWE stopped${NC}"
        ;;
    restart)
        echo "Restarting Open SWE..."
        docker-compose restart
        echo -e "${GREEN}✓ Open SWE restarted${NC}"
        ;;
    build)
        echo "Building Docker images..."
        docker-compose build
        echo -e "${GREEN}✓ Images built successfully${NC}"
        ;;
    rebuild)
        echo "Rebuilding Docker images from scratch..."
        docker-compose build --no-cache
        echo -e "${GREEN}✓ Images rebuilt successfully${NC}"
        ;;
    logs)
        docker-compose logs -f
        ;;
    status)
        docker-compose ps
        ;;
    clean)
        echo "Cleaning up Docker resources..."
        docker-compose down -v
        echo -e "${GREEN}✓ Cleanup complete${NC}"
        ;;
    backup)
        echo "Backing up agent data..."
        mkdir -p backups
        BACKUP_FILE="backups/agent-data-$(date +%Y%m%d-%H%M%S).tar.gz"
        docker run --rm -v open-swe_agent-data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/$(basename $BACKUP_FILE) /data
        echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
        ;;
    *)
        echo "Usage: $0 {up|down|restart|build|rebuild|logs|status|clean|backup}"
        echo ""
        echo "Commands:"
        echo "  up       - Start Open SWE services"
        echo "  down     - Stop Open SWE services"
        echo "  restart  - Restart Open SWE services"
        echo "  build    - Build Docker images"
        echo "  rebuild  - Rebuild Docker images from scratch"
        echo "  logs     - View service logs"
        echo "  status   - Show service status"
        echo "  clean    - Remove all containers and volumes"
        echo "  backup   - Backup agent data"
        exit 1
        ;;
esac
