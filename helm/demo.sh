#!/usr/bin/env bash

#####################
# SETUP
#####################

PROJECT=$(gcloud config get-value core/project)
ZONE=$(gcloud config get-value compute/zone)
CLUSTER_NAME=spinnaker-prometheus-operator

echo "Creating a cluster called ${CLUSTER_NAME}..."
gcloud container clusters create $CLUSTER_NAME \
  --enable-ip-alias --zone $ZONE --project $PROJECT \
  --machine-type=n1-standard-4

echo "Getting kubectl creds for your cluster..."
gcloud container clusters get-credentials $CLUSTER_NAME \
  --zone $ZONE --project $PROJECT

echo "Creating necessary k8s SAs for Helm..."

kubectl create serviceaccount --namespace kube-system tiller
sleep 10 # wait for the SA to propagate in the master

kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
sleep 60 # wait for the cluster role binding to propagate in the master

helm init --service-account tiller
echo "waiting a minute for tiller to become available on the pods..."
sleep 60

kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
sleep 10 # wait for tiller-deploy to get setup

#####################
# INSTALL APPS
#####################

echo "Installing Spinnaker with helm..."
helm install stable/spinnaker --name spinnaker \
  --values spinnaker-values.yaml


echo "Installing Prometheus Operator with helm..."
helm install stable/prometheus-operator --name prometheus-operator \
  --values prometheus-operator-values.yaml


echo "sleeping for 120 to wait for spinnaker & prometheus operator to come up... (todo to use wait for service status ready)"
sleep 180

##############################
# INSTALL SERVICE MONITOR
##############################
echo "Installing Prometheus Operator service monitor..."
kubectl apply -f ../spinnaker-service-monitor.yaml

##############################
# INSTALL GRAFANA DASHBOARDS
##############################

echo "Installing latest Spinnaker dashboards to Grafana..."
source generate-grafana-yaml-dashboards.sh

echo "applying dashboards as configmaps to cluster..."
kubectl apply -f generated
kubectl apply -f rz-spinnaker-dashboard.yaml
