# k8s-gateway-demo
We are using GKE for this demo. 

## Build the app and save the image to DockerHub
Please note first create Secret Manager secrets with ```docker-username``` and ```docker-passpword```.
```
gcloud builds submit ./ --config cloud-build-steps.yaml
```

If you want to use the GCR then. 
```
PROJECT_ID=[your project id]
gcloud builds submit ./  --tag=gcr.io/$PROJECT_ID/k8s-gateway-demo

```

## Get GKE credentails
```
gcloud container clusters get-credentials [your-gke-cluster-name] --zone=[your-gke-zone]
```


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
