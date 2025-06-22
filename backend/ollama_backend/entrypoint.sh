#!/bin/bash
set -e
/bin/ollama serve &
pid=$!
sleep 5
MODELS_TO_PULL=$(echo $OLLAMA_MODELS | sed 's/,/ /g')
echo ">>> Rozpoczynam pobieranie modeli: $OLLAMA_MODELS"

for model in $MODELS_TO_PULL
do
	echo "--- Pobieranie modelu: $model ---"
	ollama pull $model
	echo "--- Pobieranie modelu $model zakończone ---"
done

echo ">>> Zakończono pobieranie zdefiniowanych modeli!"

wait $pid
