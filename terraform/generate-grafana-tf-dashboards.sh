#!/usr/bin/env bash

echo "Getting the latest Spinnaker Grafana dashboards and adding to Terraform..."

VERSION=0.13.0

curl -sL0 -o spinnaker-monitoring.zip https://github.com/spinnaker/spinnaker-monitoring/archive/version-$VERSION.zip

unzip -qo spinnaker-monitoring.zip

# apply our dashboard configmap with label 'grafana_dashboard'
#   so the dashboard sidecar will pick it up and add the dashboard

DASH_DIR=spinnaker-monitoring-version-$VERSION/spinnaker-monitoring-third-party/third_party/prometheus
for filename in $DASH_DIR/*-dashboard.json; do
  fn_only=$(basename $filename)
  fn_root="${fn_only%.*}"
  dest_file="generated/${fn_root}.tf"

  cat grafana-dashboard.tf.template | sed -e "s/%DASHBOARD%/${fn_root}/" > $dest_file
  printf "    ${fn_only} = \"" >> $dest_file

  cat $filename | sed -e "/\"__inputs\"/,/],/d" \
      -e "/\"__requires\"/,/],/d" \
      -e "s/\${DS_SPINNAKER}/Prometheus/g" \
      -e "s/\"/\\\\\"/g" \
    | sed -e ":a" -e "N" -e '$!ba' -e "s/\n/ /g" \
    | sed -e "s/$/\"/" \
    | sed -e "s/\\\\\\\\\"/\\\\\\\\\\\\\"/g" \
    | sed -e "s/ //g" \
  >> $dest_file

  echo -en "  }\n}" >> $dest_file
done

