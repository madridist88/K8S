#!/usr/bin/env bash

KUBE_NAMESPACE=default

#kubectl delete -n $KUBE_NAMESPACE --force -f tools.yaml


#kubectl delete services,deployment,statefulsets,pods -n $KUBE_NAMESPACE --all --force


kubectl delete all --all
kubectl delete pv,pvc -n $KUBE_NAMESPACE --all --force