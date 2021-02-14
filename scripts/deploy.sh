#!/bin/bash

echo "$KUBERNETES_CLUSTER_CERTIFICATE" | base64 --decode > cert.crt

/usr/local/bin/kubectl \
  --kubeconfig=/dev/null \
  --server=$KUBERNETES_SERVER \
  --certificate-authority=cert.crt \
  --token=$KUBERNETES_TOKEN \
  apply -f ./k8s

echo "The build number is ${TRAVIS_BUILD_NUMBER}"

/usr/local/bin/kubectl \
  --kubeconfig=/dev/null \
  --server=$KUBERNETES_SERVER \
  --certificate-authority=cert.crt \
  --token=$KUBERNETES_TOKEN \
  kubectl set image deployment/client-deployment client=$DOCKER_ID/client:${TRAVIS_BUILD_NUMBER} --record
  kubectl set image deployment/api-deployment api=$DOCKER_ID/api:${TRAVIS_BUILD_NUMBER} --record