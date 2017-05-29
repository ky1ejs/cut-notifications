#!/bin/bash

set -e

# Update Kubernetes
sudo /opt/google-cloud-sdk/bin/gcloud --quiet components update
sudo /opt/google-cloud-sdk/bin/gcloud --quiet components update kubectl

# Set up gcloud creds
echo $GCLOUD_AUTH | base64 --decode > $GCLOUD_AUTH_JSON
sudo /opt/google-cloud-sdk/bin/gcloud --quiet auth activate-service-account --key-file $GCLOUD_AUTH_JSON

# Get Kuberenetes creds
sudo /opt/google-cloud-sdk/bin/gcloud --quiet config set project $PROJECT_NAME
sudo /opt/google-cloud-sdk/bin/gcloud --quiet config set container/cluster $CLUSTER_NAME
sudo /opt/google-cloud-sdk/bin/gcloud --quiet config set compute/zone ${CLOUDSDK_COMPUTE_ZONE}
sudo /opt/google-cloud-sdk/bin/gcloud --quiet config set container/use_application_default_credentials true
sudo /opt/google-cloud-sdk/bin/gcloud --quiet config set container/use_client_certificate true
sudo /opt/google-cloud-sdk/bin/gcloud --quiet container clusters get-credentials $CLUSTER_NAME

docker build -t kylejm/cut-notifications:$CIRCLE_SHA1 .
docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
docker push kylejm/cut-notifications:$CIRCLE_SHA1

# Fix permissions for .kube so kubectl can access the config
sudo chown -R ubuntu:ubuntu /home/ubuntu/.kube # presumed to be running on circleci

kubectl config view
kubectl config current-context
kubectl get pods
kubectl version
kubectl patch deployment cut-notifications -p '{"spec":{"template":{"spec":{"containers":[{"name":"cut-notifications","image":"kylejm/cut-notifications:'"$CIRCLE_SHA1"'"}]}}}}'
