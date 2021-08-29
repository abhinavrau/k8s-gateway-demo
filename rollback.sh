#!/bin/bash

echo "${GITHUB_USERNAME}"
echo "$COMMIT_SHA"

rollback_http_route() 
{
    pwd
    cd config-ci-cd

    # Use the SHA of the current service 
    export _SERVICE_N_SHA=$(cat ../services.txt | awk '{print $1}' | tail -n +2 | head -n +1 | sed -e "s/^k8s-gateway-api-demo-service-//")
    sed -i 's/__VERSION__/'"${_SERVICE_N_SHA}"'/g' overlays/prod-100p/kustomization.yaml
    kubectl kustomize overlays/prod-100p > ../sp1-config-sync-app-owner/gateway-api-demo-http-route.yaml
    
    # Commit the config for traffic split
    cd ../sp1-config-sync-app-owner

    git add gateway-api-demo-http-route.yaml && \
    git commit -m "Rolling back HTTP-Route! 
        Rendering HTTP-Route for 100% traffic to service version: ${_SERVICE_N_SHA}
        Author: $(git log --format='%an <%ae>' -n 1 HEAD)" 

    cd ..
}

git_push() 
{
    pwd
    cd sp1-config-sync-app-owner 
    git push origin main
    cd ..
}    

git_clone() 
{
    git clone https://github.com/${GITHUB_USERNAME}/sp1-config-sync-app-owner && \
    cd sp1-config-sync-app-owner 
    git config user.email ${GITHUB_EMAIL}
    git config user.name ${GITHUB_USERNAME}
    git remote set-url origin https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/sp1-config-sync-app-owner.git
    cd ..
}

delete_new_app_and_service() 
{
    pwd
    cd sp1-config-sync-app-owner 
    # Since the output is sorted by Oldest to Newest, this command will give us the New service version.
    export _SERVICE_N_PLUS_ONE=$(cat ../services.txt | awk '{print $1}' | tail -n +3 | sed -e "s/^k8s-gateway-api-demo-service-//")
    rm gateway-api-demo-app-"$_SERVICE_N_PLUS_ONE".yaml

    git add gateway-api-demo-app-"$_SERVICE_N_PLUS_ONE".yaml && \
    git commit -m "Rolling back: ${_SERVICE_N_PLUS_ONE}
    Deleting file: gateway-api-demo-app-${_SERVICE_N_PLUS_ONE}.yaml
    Author: $(git log --format='%an <%ae>' -n 1 HEAD)" 
    cd ..
}

# We are retrieving the deployed services and the GIT-SHA from the service names to identify the previous deployment which is currently servicing live traffic. 
gcloud container clusters get-credentials sp1-cluster --region=us-east1
# If your namespace has more than one app/service then please remember to add more filters
kubectl get service -n foo --sort-by=.metadata.creationTimestamp > services.txt 2> errors.txt
if [[ "$(echo $?)" == "0" ]];
then 
    echo "Got the services"
    cat services.txt
    cat services.txt | awk '{print $1}' | tail -n +2 > svc-names.txt
    cat svc-names.txt
    _NO_OF_SERVICES=$(cat svc-names.txt | wc -l)
    echo "${_NO_OF_SERVICES}"
    if [[ "${_NO_OF_SERVICES}" == "2" ]]; 
    then 
        # Code to roll back HTTP Route and serve 100% traffic by previous version 
        echo "Rollback to older service and service 100% traffic using older service."
        # Git clone the app owner repo
        git_clone
        # Render http-route for 100% traffic
        rollback_http_route
        # Render app/service yamls
        delete_new_app_and_service
        # git push to app owner repo
        git_push
    elif [[ "${_NO_OF_SERVICES}" == "1" ]]; 
        then 
            echo "There is only one service deployed. Nothing to rollback."
            echo "Aborting rollback!!!"
            exit 1
        else 
            echo "Found ${_NO_OF_SERVICES} services. Can't rollback."
            echo "Aborting rollback!!!"
            exit 1;
    fi 
else 
    echo "Failed to connect to cluster";
    echo "Aborting rollback!!!"
    cat errors.txt;
    exit 1;
fi