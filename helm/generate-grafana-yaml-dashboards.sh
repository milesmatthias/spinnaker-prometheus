#!/bin/bash

echo -n "Getting the latest Spinnaker Grafana dashboards and adding to Terraform..."

curl -sL0 -o spinnaker-monitoring.zip https://github.com/spinnaker/spinnaker-monitoring/archive/master.zip

unzip -qo spinnaker-monitoring.zip

echo "done."


# apply our dashboard configmap with label 'grafana_dashboard'
#   so the dashboard sidecar will pick it up and add the dashboard

echo -n "Generating dashboards in YAML format in 'generated' directory..."

DASH_DIR=spinnaker-monitoring-master/spinnaker-monitoring-third-party/third_party/prometheus
for filename in $DASH_DIR/*-dashboard.json; do
  fn_only=$(basename $filename)
  fn_root="${fn_only%.*}"
  dest_file="generated/${fn_root}.yaml"
  uid=$(uuidgen)

  cat grafana-dashboard.yaml.template | sed -e "s/%DASHBOARD%/${fn_root}/" > $dest_file
  printf "  ${fn_only}: |-\n" >> $dest_file

  cat $filename | sed -e "s/\"uid\": null/\"uid\": \"${uid}\"/" \
    | sed -e "/\"__inputs\"/,/],/d" \
      -e "/\"__requires\"/,/],/d" \
      -e "s/\${DS_SPINNAKER\}/Prometheus/g" \
      -e "s/^/    /" \
  >> $dest_file
done

echo "done."
