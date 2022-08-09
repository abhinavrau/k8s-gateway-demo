#!/bin/bash

echo "GitHub Username:${GITHUB_USERNAME}"
echo "CommitSHA:${COMMIT_SHA}"
echo "ClusterName: ${_CLUSTER_NAME}"
echo "ClusterRegion: ${_CLUSTER_REGION}"

rollout_http_route() 
{
    pwd
    cd config-ci-cd || exit

    # Use the SHA of the new service 
    # Since the output is sorted by Oldest to Newest, this command will give us the new service version.
    export _SERVICE_N_PLUS_ONE=$(cat ../services.txt | awk '{print $1}' | tail -n +3 | sed -e "s/^k8s-gateway-api-demo-service-//")
    sed -i 's/__VERSION__/'"${_SERVICE_N_PLUS_ONE}"'/g' overlays/prod-100p/patch.yaml
    kustomize build overlays/prod-100p > ../sp1-config-sync-app-owner/gateway-api-demo-http-route.yaml
    
    # Commit the config for traffic split
    cd ../sp1-config-sync-app-owner || exit

    git add gateway-api-demo-http-route.yaml && \
    git commit -m "Rolling out HTTP-Route! 
        Rendering HTTP-Route for 100% traffic to service version: ${_SERVICE_N_PLUS_ONE}
        Author: $(git log --format='%an <%ae>' -n 1 HEAD)" 
    echo "---Updated HttpRoute to send 100% traffic to version: ${_SERVICE_N_PLUS_ONE}---"
    echo "---Updated gateway-api-demo-http-route.yaml in the Namespace (AppOwner) Config Sync Repo---"
    cd ..
}

git_push() 
{
    pwd
    cd sp1-config-sync-app-owner || exit 
    #git tag "Rollout:${_SERVICE_N_PLUS_ONE}"
    git push origin main #"Rollout:${_SERVICE_N_PLUS_ONE}"
    cd ..
}    

git_clone() 
{
    git clone https://github.com/"${GITHUB_USERNAME}"/sp1-config-sync-app-owner && \
    cd sp1-config-sync-app-owner || exit 
    git config user.email "${GITHUB_EMAIL}"
    git config user.name "${GITHUB_USERNAME}"
    git remote set-url origin https://"${GITHUB_USERNAME}":"${GITHUB_TOKEN}"@github.com/"${GITHUB_USERNAME}"/sp1-config-sync-app-owner.git
    cd ..
}

delete_old_app_and_service() 
{
    pwd
    cd sp1-config-sync-app-owner || exit 
    # Since the output is sorted by Oldest to Newest, this command will give us the old service version.
    cat ../services.txt
    export _SERVICE_N_SHA=$(cat ../services.txt | awk '{print $1}' | tail -n +2 | head -n +1 | sed -e "s/^k8s-gateway-api-demo-service-//")
    echo "$_SERVICE_N_SHA"
    rm gateway-api-demo-app-"$_SERVICE_N_SHA".yaml  

    git add . && \
    git commit -m "Deleting: ${_SERVICE_N_SHA}
    Deleting file: gateway-api-demo-app-${_SERVICE_N_SHA}.yaml
    Author: $(git log --format='%an <%ae>' -n 1 HEAD)" 
    echo "---Deleting app version: ${_SERVICE_N_PLUS_ONE}---"
    echo "---Deleting gateway-api-demo-app-${_SERVICE_N_PLUS_ONE}.yaml from the Namespace (AppOwner) Config Sync Repo---"
    cd ..
}

# We are retrieving the deployed services and the GIT-SHA from the service names to identify the previous deployment which is currently servicing live traffic. 
gcloud container clusters get-credentials  "${_CLUSTER_NAME}" --region="${_CLUSTER_REGION}"
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
    # Day 1 scenario - No service exist
    if [[ "${_NO_OF_SERVICES}" == "2" ]]; 
    then 
        # Code to roll out HTTP Route and serve 100% traffic by new version 
        echo "Rollout to new service and service 100% traffic using new service."
        # Git clone the app owner repo
        git_clone
        # Render http-route for 100% traffic
        rollout_http_route
        # Render app/service yamls
        delete_old_app_and_service
        # git push to app owner repo
        git_push
    elif [[ "${_NO_OF_SERVICES}" == "1" ]]; 
        then 
            echo "There is only one service deployed. Nothing to rollout."
            echo "Aborting rollout!!!"
            exit 1
        else 
            echo "Found ${_NO_OF_SERVICES} services. Can't rollout."
            echo "Aborting rollout!!!"
            exit 1;
    fi 
else 
    echo "Failed to connect to cluster";
    echo "Aborting rollout!!!"
    cat errors.txt;
    exit 1;
fi