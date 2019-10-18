#!/usr/bin/env bash

PROJECT=$(gcloud config get-value core/project)
ZONE=$(gcloud config get-value compute/zone)

gcloud container clusters get-credentials spinnaker-prometheus-operator \
  --zone $ZONE --project $PROJECT

kubectl create serviceaccount --namespace kube-system tiller
sleep 10

kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
sleep 60

kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
sleep 10

helm init
echo "waiting a minute for tiller to become available on the pods..."
sleep 60


echo "Installing Spinnaker with helm..."

helm install stable/spinnaker --name spinnaker \
  --values spinnaker-values.yaml


echo "Installing Prometheus Operator with helm..."

helm install stable/prometheus-operator --name prometheus-operator \
  --values prometheus-operator-values.yaml


echo "sleeping for 120 to wait for spinnaker & prometheus operator to come up... (todo to use wait for service status ready)"
sleep 180

echo "Installing latest Spinnaker dashboards to Grafana..."
source generate-grafana-yaml-dashboards.sh

echo "applying dashboards as configmaps to cluster..."
kubectl apply -f generated
