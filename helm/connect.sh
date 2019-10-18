#!/usr/bin/env bash

DECK_POD=$(kubectl get pods --namespace default -l "cluster=spin-deck" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace default $DECK_POD 9000 &

GATE_POD=$(kubectl get pods --namespace default -l "cluster=spin-gate" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace default $GATE_POD 8084 &

PROM_POD=$(kubectl get pods --namespace default -l "app=prometheus-operator-prometheus" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace default $PROM_POD 9090 &
