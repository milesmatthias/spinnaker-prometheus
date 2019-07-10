# Spinnaker + Prometheus Operator on K8s

When using Prometheus Operator + Spinnaker on K8s, this repo shows you how to configure Prometheus to monitor Spinnaker and add Spinnaker's default dashboards to Grafana.

There are 2 steps to enabling Spinnaker monitoring with Prometheus operator:

1. Enable Prometheus as the metric store with halyard: `hal config metric-stores prometheus enable`
  * You'll need to re-apply your halyard deployment as well: `hal deploy apply`
  * This will add the spinnaker-monitoring daemon sidecar to all of your Spinnaker service deployments
2. Apply a Service Monitor (Prometheus Operator CRD) to add Spinnaker to Prometheus
  * This tells all Prometheus instances configured by Prometheus Operator to poll the Spinnaker monitoring daemon periodically to collect metrics
  * See `spinnaker-service-monitor.yaml` for this ServiceMonitor

## Grafana dashboards

To add a dashboard to your Grafana instance (managed by Prometheus Operator), you simply apply a ConfigMap to your cluster with the dashboard data. The Prometheus Operator listens for new ConfigMaps added to your cluster with a certain label, extracts the JSON from the ConfigMap, and adds it to Grafana.

The Spinnaker Monitoring repository has several default Grafana dashboards in their JSON format, but no installation script for adding these dashboards to a Grafana instance managed by Prometheus Opeator. The Spinnaker Monitoring project assumes you're running on VMs and has a setup script for that scenario.

Scripts in this repo can download those dashboards and convert them to K8s/Prometheus Operator compliant formats for adding to Grafana.

1. Plain ConfigMaps (YAML): see the `helm` directory.
2. Terraform ConfigMaps: see the `terraform` directory.

## Helm setup

If you use helm to install Spinnaker + Prometheus Operator, read and run `demo.sh` in the `helm` directory, which does the following:

1. Creates a GKE cluster
2. Installs Spinnaker with Helm with Prometheus enabled
3. Installs Prometheus Operator with the Spinnaker ServiceMonitor enabled
4. Downloads the default Grafana dashboards from the Spinnaker Monitoring container and adds them to Grafana

## Terraform setup

If you use Terraform to make changes to your cluster, you can use the `generate-grafana-tf-dashboards.sh` script in the `terraform` directory to download the Grafana Spinnaker dashboards and add them to Grafana.

This will generate TF files for each dashboard. Apply the generated Terraform files and Grafana will have new dashboards for Spinnaker, automatically reading from your Prometheus Operator.

The Terraform demo does not setup a cluster or install Spinnaker or Prometheus Operator, as that is straightforward on your own with the Helm provider.
