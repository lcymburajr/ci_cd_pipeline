#!/bin/sh

sed -i "s/VERSION/${TRAVIS_BUILD_NUMBER}/g" ./k8s/api-deployment.yml
sed -i "s/VERSION/${TRAVIS_BUILD_NUMBER}/g" ./k8s/client-deployment.yml

cat ./k8s/api-deployment.yml
cat ./k8s/client-deployment.yml