#!/bin/bash

echo "GitHub Username:${GITHUB_USERNAME}"
echo "CommitSHA:${COMMIT_SHA}"
echo "ClusterName: ${_CLUSTER_NAME}"
echo "ClusterRegion: ${_CLUSTER_REGION}"
render_app_and_service() 
{
    pwd
    cd config-ci-cd || exit

    sed -i 's/__VERSION__/'"$SHORT_SHA"'/g' overlays/deployment/kustomization.yaml
    kustomize build overlays/deployment > ../sp1-config-sync-app-owner/gateway-api-demo-app-"$SHORT_SHA".yaml

    cd ../sp1-config-sync-app-owner || exit 

    echo "Update foo-app to version: ${SHORT_SHA}" > README.md
    

    git add gateway-api-demo-app-"$SHORT_SHA".yaml && \
    git commit -m "Rendered: ${SHORT_SHA}
    Built from commit ${COMMIT_SHA} of repository foo-config-source - main branch 
    Author: $(git log --format='%an <%ae>' -n 1 HEAD)" && \

    echo "---Updated foo-app to version: ${SHORT_SHA}---"
    echo "---Added gateway-api-demo-app-${SHORT_SHA}.yaml in Namespace (AppOwner) Config Sync Repo.---"
    cd ..
}

render_http_route_50_50()
{
    pwd
    cd config-ci-cd || exit
    # Use the SHA of the current service 
    export _SERVICE_N_SHA=$(cat ../svc-names.txt | sed -e "s/^k8s-gateway-api-demo-service-//")
    sed -i 's/__PREVIOUS_VERSION__/'"${_SERVICE_N_SHA}"'/g' overlays/prod-50-50/patch.yaml
    
    # Use ${SHORT_SHA} for new service 
    sed -i 's/__VERSION__/'"${SHORT_SHA}"'/g' overlays/prod-50-50/patch.yaml
    kustomize build  overlays/prod-50-50 > ../sp1-config-sync-app-owner/gateway-api-demo-http-route.yaml

    # Commit the config for traffic split
    cd ../sp1-config-sync-app-owner || exit

    git add gateway-api-demo-http-route.yaml && \
    git commit -m "Built from commit ${COMMIT_SHA} 
        Rendered HTTP-Route for 50-50 traffic split between service versions: ${_SERVICE_N_SHA} and ${SHORT_SHA}
        Author: $(git log --format='%an <%ae>' -n 1 HEAD)" 
    echo "---Updated HttpRoute to split traffic 50-50 between older (${_SERVICE_N_SHA}) and newer (${SHORT_SHA})  versions.---"
    echo "---Updated gateway-api-demo-http-route.yaml in the Namespace (AppOwner) Config Sync Repo---"
    cd ..
}

render_http_route_100p() 
{
    pwd
    cd config-ci-cd || exit
    # Use ${SHORT_SHA} for new service 
    sed -i 's/__VERSION__/'"${SHORT_SHA}"'/g' overlays/prod-100p/patch.yaml
    kustomize build overlays/prod-100p > ../sp1-config-sync-app-owner/gateway-api-demo-http-route.yaml
    
    # Commit the config for traffic split
    cd ../sp1-config-sync-app-owner || exit

    git add gateway-api-demo-http-route.yaml && \
    git commit -m "Built from commit ${COMMIT_SHA} 
        Rendered HTTP-Route for 100% traffic to service version: ${SHORT_SHA}
        Author: $(git log --format='%an <%ae>' -n 1 HEAD)" 

    cd ..
}

git_push() 
{
    pwd
    cd sp1-config-sync-app-owner || exit 
    #git tag ${SHORT_SHA}
    git push origin main #${SHORT_SHA}
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
    if [[ "${_NO_OF_SERVICES}" == "0" ]]; 
    then 
        # Code to deploy 100% traffic to one service 
        echo "No running service found"; 
        echo "Deploying service to receive 100% traffic"
        # Git clone the app owner repo
        git_clone
        # Render app/service yamls
        render_app_and_service
        # Render http-route for 100% traffic
        render_http_route_100p
        # git push to app owner repo
        git_push
    # Day 2+ scenario - a service with live traffic exists
    elif [[ "${_NO_OF_SERVICES}" == "1" ]]; 
        then 
            # Code to deploy 50-50 traffic split 
            echo "Got 1 service running."   
            echo "Deploying new service and splitting traffic 50-50 between current and new service."
            # Git clone the app owner repo
            git_clone
            # Render app/service yamls
            render_app_and_service
            # Render http-route for 50-50 traffic split
            render_http_route_50_50
            # git push to app owner repo 
            git_push
        else 
            echo "Found ${_NO_OF_SERVICES} services."
            echo "Can't traffic split for more than 2 services."
            echo "Aborting deploy!!!"
            echo "Check cluster and app config repo why there are more than 1 version of services running.";
            exit 1;
    fi 
else 
    echo "Failed to connect to cluster";
    cat errors.txt;
    exit 1;
fi
