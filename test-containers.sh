#!/bin/bash

echo "Testing Open WebUI containers..."
echo "================================="

# Check if containers are running
echo "Checking if containers are running..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "Checking if Open WebUI is accessible..."
sleep 5  # Wait a bit for containers to fully start

# Test if Open WebUI is accessible
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Open WebUI is accessible at http://localhost:3000"
else
    echo "❌ Open WebUI is not accessible at http://localhost:3000"
    echo "Container logs:"
    docker logs open-webui --tail 20
fi

echo ""
echo "Checking if Ollama is accessible..."
# Test if Ollama is accessible
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✅ Ollama is accessible at http://localhost:11434"
else
    echo "❌ Ollama is not accessible at http://localhost:11434"
    echo "Container logs:"
    docker logs projekt-openwebui-merge-with-main-backend-ollama-1 --tail 20
fi

echo ""
echo "Test completed!"
