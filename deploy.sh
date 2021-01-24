docker build -t $DOCKER_ID/client:latest -t $DOCKER_ID/client:$SHA ./client
docker build -t $DOCKER_ID/api:latest -t $DOCKER_ID/api:$SHA ./api

docker push $DOCKER_ID/client:latest
docker push $DOCKER_ID/api:latest

docker push $DOCKER_ID/client:$SHA
docker push $DOCKER_ID/api:$SHA

kubectl apply -f k8s
kubectl set image deployment/client-deployment client=$DOCKER_ID/client:$SHA
kubectl set image deployment/api-deployment api=$DOCKER_ID/api:$SHA