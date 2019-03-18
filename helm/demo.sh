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

curl -sL0 -o spinnaker-monitoring.zip https://github.com/spinnaker/spinnaker-monitoring/archive/version-0.11.2.zip

unzip -o spinnaker-monitoring.zip


# apply our dashboard configmap with label 'grafana_dashboard'
#   so the dashboard sidecar will pick it up and add the dashboard

DASH_DIR=spinnaker-monitoring-version-0.11.2/spinnaker-monitoring-third-party/third_party/prometheus
for filename in $DASH_DIR/*-dashboard.json; do
  fn_only=$(basename $filename)
  fn_root="${fn_only%.*}"
  dest_file="generated/${fn_root}.yaml"

  cat grafana-dashboard.yaml.template | sed -e "s/%DASHBOARD%/${fn_root}/" > $dest_file
  printf "  ${fn_only}: |-\n" >> $dest_file

  cat $filename | sed -e "/\"__inputs\"/,/],/d" \
      -e "/\"__requires\"/,/],/d" \
      -e "s/\${DS_SPINNAKER\}/Prometheus/g" \
      -e "s/^/    /" \
  >> $dest_file
done

echo "applying dashboards as configmaps to cluster..."
kubectl apply -f generated
