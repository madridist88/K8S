#!/usr/bin/env bash

START_TIME=$(date +%s)

KUBE_CONFIG=./kube-config/kube.config
KUBE_NAMESPACE=default

#--kubeconfig ./config/config

echo "Deploy DEV cluster started:"

export KUBECONFIG=${PWD}/dev/kube-config/config

echo "# K8S config:"
kubectl config view

echo "# Cluster info:"
kubectl cluster-info

echo "# Undeploy all of resources:"
./undeploy.sh

echo "# Wait for 50s..."
sleep 50

kubectl create secret \
  docker-registry registry-cred \
  --docker-server=hub.ru:4567\
  --docker-username= \
  --docker-password=DoTheGreatest! \
  --docker-email=

kubectl  apply -n $KUBE_NAMESPACE --force -f dev/volume.yaml
kubectl  apply -n $KUBE_NAMESPACE --force -f dev/tools.yaml
sleep 20
echo "# Cloning ci-tools repository"
kubectl  exec tools ./bin/clone-repo.sh
echo "# Prepare initial data for cluster (NFS)"
kubectl  exec tools ./bin/init-data-dev.sh

kubectl  apply -n $KUBE_NAMESPACE --force -f dev/zookeeper.yaml
kubectl  apply -n $KUBE_NAMESPACE --force -f dev/redis.yaml
kubectl  apply -n $KUBE_NAMESPACE --force -f dev/elk.yaml

echo "# Deploy Databases:"
echo "# Deploy CMS DB:"
kubectl  apply -n $KUBE_NAMESPACE --force -f dev/cms-db.yaml
echo "# Deploy Gateway DB:"
kubectl  apply -n $KUBE_NAMESPACE --force -f dev/gateway-db.yaml
echo "# Deploy Auth DB:"
kubectl  apply -n $KUBE_NAMESPACE --force -f dev/auth-db.yaml

echo "# Deploy CMS:"
kubectl  apply -n $KUBE_NAMESPACE --force -f dev/cms-php.yaml
kubectl  apply -n $KUBE_NAMESPACE --force -f dev/cms.yaml

echo "# Wait for 30s..."
sleep 30

CMS_PHP_POD=`kubectl get pods | grep cms-php- | awk '{print $1}' | tail -n 1`
echo "# cms-php-pod: $CMS_PHP_POD"

echo "# Run CMS DB migration:"
kubectl exec $CMS_PHP_POD -- bash -c "yes | php console/yii migrate"
echo "# Run CMS cache generation:"
kubectl exec $CMS_PHP_POD -- php console/yii static/cache-generation

echo "# Deploy dashboard-service:"
kubectl  apply -n $KUBE_NAMESPACE --force -f dev/dashboard.yaml
echo "# Wait for 30s..."
sleep 30
echo "# Populate zookeeper settings:"
kubectl  exec tools -- bash -c "cd /tools/gateway-service/dashboard && \
 ./dashboard.sh"

echo "# Deploy gateway-service:"
kubectl  apply -n $KUBE_NAMESPACE --force -f dev/gateway.yaml

sleep 10
echo "# Pod list:"
kubectl get pods

END_TIME=$(date +%s)
EXECUTION_TIME=$(( $END_TIME - $START_TIME ))

echo "It took $SECONDS seconds"

echo "# Execution time = $EXECUTION_TIME seconds"