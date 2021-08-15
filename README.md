# k8s-gateway-demo
We are using GKE for this demo. 

## Build the app and save the image
Please note first create Secret Manager secrets with ```docker-username``` and ```docker-passpword```.
```
gcloud builds submit ./ --config cloud-build-steps.yaml
```

If you want to use the GCR then. 
```
PROJECT_ID=[your project id]
gcloud builds submit ./  --tag=gcr.io/$PROJECT_ID/k8s-gateway-demo

```

Get GKE credentails
```
gcloud container clusters get-credentials [your-gke-cluster-name] --zone=[your-gke-zone]
```


## Setup GKE cluster with Gateway API - Gateway class

Follow the [docs](https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-gateways)
```
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.3.0" \
> | kubectl apply -f -
```

## Setup Gateway 
This will create a LB with external IP because we are using **gxlb** gateway class.
```
kubectl apply -f k8s/cluster-operator/
```

## Deploy the app 
This will deploy the app, service and HTTPRoute
```
kubectl apply -f k8s/app-owner/
```
