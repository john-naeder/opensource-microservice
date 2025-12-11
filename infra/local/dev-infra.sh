#!/bin/bash
# Helper scripts for local development infrastructure

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Local Development Infrastructure Manager ===${NC}\n"

# Function to check if docker-compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}docker-compose not found. Please install Docker Compose.${NC}"
        exit 1
    fi
}

# Start infrastructure
start() {
    echo -e "${GREEN}Starting infrastructure...${NC}"
    docker-compose -f docker-compose.infra.yml up -d
    echo -e "${GREEN}Infrastructure started!${NC}"
    status
}

# Stop infrastructure
stop() {
    echo -e "${YELLOW}Stopping infrastructure...${NC}"
    docker-compose -f docker-compose.infra.yml down
    echo -e "${GREEN}Infrastructure stopped!${NC}"
}

# Restart infrastructure
restart() {
    echo -e "${YELLOW}Restarting infrastructure...${NC}"
    docker-compose -f docker-compose.infra.yml restart
    echo -e "${GREEN}Infrastructure restarted!${NC}"
}

# Status
status() {
    echo -e "${GREEN}Infrastructure status:${NC}"
    docker-compose -f docker-compose.infra.yml ps
}

# Logs
logs() {
    service=${1:-}
    if [ -z "$service" ]; then
        docker-compose -f docker-compose.infra.yml logs -f
    else
        docker-compose -f docker-compose.infra.yml logs -f "$service"
    fi
}

# Clean (remove volumes)
clean() {
    echo -e "${RED}WARNING: This will remove all data!${NC}"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        docker-compose -f docker-compose.infra.yml down -v
        echo -e "${GREEN}Infrastructure cleaned!${NC}"
    else
        echo -e "${YELLOW}Clean cancelled.${NC}"
    fi
}

# Health check
health() {
    echo -e "${GREEN}Checking services health...${NC}\n"
    
    # MySQL
    echo -n "MySQL: "
    if docker exec dev-mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
        echo -e "${GREEN}✓ Running${NC}"
    else
        echo -e "${RED}✗ Down${NC}"
    fi
    
    # MongoDB
    echo -n "MongoDB: "
    if docker exec dev-mongodb mongosh --quiet --eval "db.adminCommand('ping')" 2>/dev/null | grep -q "ok"; then
        echo -e "${GREEN}✓ Running${NC}"
    else
        echo -e "${RED}✗ Down${NC}"
    fi
    
    # Redis
    echo -n "Redis: "
    if docker exec dev-redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
        echo -e "${GREEN}✓ Running${NC}"
    else
        echo -e "${RED}✗ Down${NC}"
    fi
    
    # Kafka
    echo -n "Kafka: "
    if docker exec dev-kafka kafka-topics.sh --bootstrap-server localhost:9092 --list &>/dev/null; then
        echo -e "${GREEN}✓ Running${NC}"
    else
        echo -e "${RED}✗ Down${NC}"
    fi
    
    # Elasticsearch
    echo -n "Elasticsearch: "
    if curl -s http://localhost:9200/_cluster/health &>/dev/null; then
        echo -e "${GREEN}✓ Running${NC}"
    else
        echo -e "${RED}✗ Down${NC}"
    fi
}

# Show help
help() {
    echo "Usage: ./dev-infra.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start       - Start all infrastructure services"
    echo "  stop        - Stop all infrastructure services"
    echo "  restart     - Restart all infrastructure services"
    echo "  status      - Show status of all services"
    echo "  logs [svc]  - Show logs (optionally for specific service)"
    echo "  clean       - Stop and remove all data (WARNING: destructive)"
    echo "  health      - Check health of all services"
    echo "  help        - Show this help message"
}

# Main
check_docker_compose

case "${1:-}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs "${2:-}"
        ;;
    clean)
        clean
        ;;
    health)
        health
        ;;
    help|--help|-h)
        help
        ;;
    *)
        echo -e "${RED}Unknown command: ${1:-}${NC}\n"
        help
        exit 1
        ;;
esac
