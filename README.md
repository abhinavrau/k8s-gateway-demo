# k8s-gateway-demo

Demo code to show how the persona based Kubernetes Gateway API can be used with Multi repo Config Sync with GKE. This repo is be used for the SpringOne talk https://springone.io/2021/sessions/introducing-kubernetes-gateway-api

![](images/mutli-repo-k8-gateway.png)
## Prerequisites
- gcloud configured for you GCP project
- A GKE Cluster
- Ability to create repos on Github 
## Build the apps and push to DockerHub

- Create Secret Manager secrets with `docker-username` and `docker-passpword`.
- Use CloudBuild to build the 2 apps called `foo-blue`and `foo-green` and save the image to DockerHub
```
gcloud builds submit . --config=cloudbuild-apps.yaml
```

## Get GKE credentails for your cluster
```
gcloud container clusters get-credentials [your-gke-cluster-name] --zone=[your-gke-zone]
```

## Install the Istio implementation of Gateway API

Install the Istio Kubernetes Gateway API CRDs and Istio by following the directions here: https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/

## Create ConfigSync repos


## Setup Config sync on Cluster


## Setup GKE cluster with Istio Gateway class

Follow the [docs](https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-gateways)
```
kubectl apply -f k8s/infra-owner
```

## Install the Istio Gateway 
```
kubectl apply -f k8s/cluster-operator/
```

## Deploy the app 
This will deploy the app, service and HTTPRoute
```
kubectl apply -f k8s/app-owner/
```
