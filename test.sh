#!/bin/bash

export _SERVICES=$(kubectl get service -n foo --sort-by=.metadata.creationTimestamp | awk '{print $1}' | tail -n +2)
export _NO_OF_SERVICES=$(echo ${_SERVICES} | wc -l)
if [[ "${_NO_OF_SERVICES}" == "2" ]]; 
then echo "got 2"; 
else echo "Check your services"
fi 