# k8s-gateway-demo

Demo code to show how the persona based Kubernetes Gateway API can be used with Multi repo Config Sync with GKE. This repo is be used for the SpringOne talk https://springone.io/2021/sessions/introducing-kubernetes-gateway-api

![](images/mutli-repo-k8-gateway.png)
# Kubernetes Gateway API Demo using GitOps

Demo code to show how the persona based Kubernetes Gateway API can be used with Multi repo Config Sync with GKE. This repo is be used for the SpringOne talk https://springone.io/2021/sessions/introducing-kubernetes-gateway-api

![](images/mutli-repo-k8-gateway.png)
## Prerequisites
- CloudBuild
- A GKE Cluster
- Ability to create repos on Github 

## Create Config Sync GitHub repos
- Cluster Admin repo (a.k.a Root repo) - Fork the repo https://github.com/abhinavrau/sp1-config-sync-root
- App Owner repo used by Developers - For the repo https://github.com/abhinavrau/sp1-config-sync-app-owner
  
## Create DockerHub and GitHub secrets
- Create secrets called `docker-username` and `docker-password` in Secret Manager
- From GitHub developer setting create a [GitHub personal access token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token). Then create secrets called `github-username`, `github-token`  and `github-email` in Secret Manager. 

## Build the apps and push to DockerHub

- Use CloudBuild to build the 2 apps called `foo-blue`and `foo-green` and save the image to DockerHub
```
gcloud builds submit . --config=cloudbuild.yaml
```

## Get GKE credentails for your cluster
```
gcloud container clusters get-credentials [your-gke-cluster-name] --zone=[your-gke-zone]
```

## Install the Istio implementation of Gateway API

Install the Istio Kubernetes Gateway API CRDs and Istio by following the directions here: https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/

## Install ConfigSync operator on the Cluster

```
gsutil cp gs://config-management-release/released/latest/config-management-operator.yaml config-management-operator.yaml

kubectl apply -f config-management-operator.yaml

```
## Create SSH keys so Configs Sync can access the GitHUb repos

Run the below twice. One of the Cluster Admin repo and the other for App owner repo

```
ssh-keygen -t rsa -b 4096 \
-C "GIT_REPOSITORY_USERNAME" \
-N '' \
-f /path/to/KEYPAIR_FILENAME
```
Add the private keys to a new Secret in the cluster:
```
kubectl create ns config-management-system && \
kubectl create secret generic git-creds \
 --namespace=config-management-system \
 --from-file=ssh=/path/to/KEYPAIR_PRIVATE_KEY_FILENAME
 ```

 Register the Public keys with GitHub. You can also GitHub Personal Access Tokens or Deploy Tokens.

 ## 
## Deploy the app 
This will deploy the app, service and HTTPRoute
```
kubectl apply -f k8s/app-owner/
```

### Steps to perfom on a new Cluster
- Install istio gateway CRD 
- Install istio 
- Setup ACM operator 
- kubectl apply -f config-sync/config-management.yaml -f root-sync.yaml
- Create secret for SSH private key of the GIT repos in cluster

  