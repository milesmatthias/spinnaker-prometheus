#!/usr/bin/env bash

PROM_POD=$(kubectl get pods --namespace default -l "app=prometheus" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace default $PROM_POD 9090 > /dev/null 2>&1 & echo $! > prom.pid

DECK_POD=$(kubectl get pods --namespace default -l "cluster=spin-deck" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace default $DECK_POD 9000 > /dev/null 2>&1 & echo $! > deck.pid

GATE_POD=$(kubectl get pods --namespace default -l "cluster=spin-gate" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace default $GATE_POD 8084 > /dev/null 2>&1 & echo $! > gate.pid

GRAFANA_POD=$(kubectl get pods --namespace default -l "app=grafana" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace default $GRAFANA_POD 3000 > /dev/null 2>&1 & echo $! > grafana.pid 

echo "Grafana default creds are admin / prom-operator"
