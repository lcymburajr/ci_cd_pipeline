# eksctl

### Automaticlly create a VPC and puts the cluster into 2 subnets if not specified:  
`eksctl create cluster -f <yaml file> --profile=<profile name>`  

### Delete Cluster:  
`eksctl delete cluster --name=<name> [--region=<region>] --profile=<profile name>`  

### Use existing VPC:
```
vpc:
  id: "vpc-id"
  cidr: "10.0.0.0/16"
  subnets:
    private:
      us-east-1a:
          id: "subnet-id"
          cidr: "10.0.1.0/24"
      us-east-1b:
          id: "subnet-id"
          cidr: "10.0.2.0/24"
      us-east-1c:
          id: "subnet-id"
          cidr: "10.0.3.0/24"
```
`eksctl create cluster -f cluster.yaml --profile=<profile name>`

### Add another nodeGroup:  
`eksctl create nodegroup --config-file=cluster.yaml --include='ng-mixed' --profile=<profile name>`

```
  - name: ng-mixed
    minSize: 3
    maxSize: 5
    instancesDistribution:
      maxPrice: 0.2
      instanceTypes: ["t2.small", "t3.small"]
      onDemandBaseCapacity: 0
      onDemandPercentageAboveBaseCapacity: 50
    ssh: 
      publicKeyName: eks
```
Set `onDemandPercentageAboveBaseCapacity` to `0` if you only want spot instances.

### Delete nodeGroup:  
`eksctl delete nodegroup --cluster=my-cluster --name=ng-mixed --approve`

## Autoscaler
The cluster autoscaler automatically launches additional worker nodes if more resources are needed, and shutdown worker nodes if they are underutilized. The autoscaling works within a nodegroup, hence create a nodegroup first which has this feature enabled.

`kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml`

### put required annotation to the deployment:  
`kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"`

### edit deployment and set your EKS cluster name:
    • Add name
    • Add versions number
`kubectl -n kube-system edit deployment.apps/cluster-autoscaler`

### check updated deployment:  
`kubectl -n kube-system describe deployment cluster-autoscaler`

## test the autoscaler

### create a deployment of nginx  
`kubectl apply -f nginx-deployment.yaml`

### scale the deployment  
`kubectl scale --replicas=3 deployment/test-autoscaler`

### view cluster autoscaler logs  
`kubectl -n kube-system logs deployment.apps/cluster-autoscaler | grep -A5 "Expanding Node Group"`

`kubectl -n kube-system logs deployment.apps/cluster-autoscaler | grep -A5 "removing node"`

# Cloudwatch logging of an EKS cluster

## enable e.g. via yaml config file
`eksctl utils update-cluster-logging --config-file eks-course.yaml --approve`

## disable via plain commandline call
`eksctl utils update-cluster-logging --name=EKS-course-cluster --disable-types all`

# Container insights with Cloudwatch Metrics

## add policy to your nodegroup(s)
add policy *CloudWatchAgentServerPolicy* to nodegroup(s) role

## deploy the cloudwatch agent
runs as daemonset, means one per node

```bash
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/EKS-course-cluster/;s/{{region_name}}/us-east-1/" | kubectl apply -f -

```

## load generation

```bash
kubectl run php-apache --image=k8s.gcr.io/hpa-example --requests=cpu=200m --limits=cpu=500m --expose --port=80
```

```bash
kubectl run --generator=run-pod/v1 -it --rm load-generator --image=busybox /bin/sh

Hit enter for command prompt

while true; do wget -q -O- http://php-apache.default.svc.cluster.local; done
```

# Helm 

### auto-scaler
`helm repo add autoscaler https://kubernetes.github.io/autoscaler`
`helm install autoscaler autoscaler/cluster-autoscaler --set autoDiscovery.clusterName=<CLUSTER NAME>`


# Providing RBAC to IAM users

## add a cluster admin

Steps:

1. create IAM user in AWS console (_k8s-cluster-admin_)
2. create access key for this user and store it locally
3. add user to configmap aws-auth
4. add user+accesskey to aws credentials file in dedicated section (profile)

Config Map  
`kubectl -n kube-system get cm`

fetch current configmap before adding our user mapping - prints everything on to a yaml file

`kubectl -n kube-system get configmap aws-auth -o yaml > aws-auth-configmap.yaml`

edit the yaml file and add a "mapUsers" section
```bash
  mapUsers: |
    - userarn: arn:aws:iam::xxxxxxxxx:user/k8-cluster-admin
      username: k8-cluster-admin
      groups:
        - system:masters
```

list of K8's default role  
https://kubernetes.io/docs/reference/access-authn-authz/rbac/#default-roles-and-role-bindings

Apply changes
`kubectl apply -f aws-auth-configmap.yaml`

add user to ~/.aws/credentials by creating a new section

```bash
[clusteradmin]
aws_access_key_id=.....
aws_secret_access_key=.....
region=us-east-1
output=json
```

get current aws user
`aws sts get-caller-identity`

to change aws profile
`export AWS_PROFILE="k8-cluster-admin"`

Check it works
`kubectl get nodes`
## add read-only user for particular namespace

```bash
kubectl create namespace production
```

create IAM user and grab access-key

create role

```bash
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  namespace: production
  name: prod-viewer-role
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["*"]  # can be further limited, e.g. ["deployments", "replicasets", "pods"]
  verbs: ["get", "list", "watch"] 
```

create rolebinding

```bash
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: prod-viewer-binding
  namespace: production
subjects:
- kind: User
  name: prod-viewer
  apiGroup: ""
roleRef:
  kind: Role
  name: prod-viewer-role
  apiGroup: ""
```

create role and binding

```bash
kubectl apply -f role.yaml rolebinding.yaml
```

add user to aws-auth configmap

add user to ~/.aws/credentials file

```bash
[clusteradmin]
aws_access_key_id=
aws_secret_access_key=
region=us-east-1
output=json
[productionviewer]
aws_access_key_id=
aws_secret_access_key=
region=us-east-1
output=json
```

set this user as the active one

```bash
aws sts get-caller-identity
export AWS_PROFILE="productionviewer"
aws sts get-caller-identity
```

test
`kubectl -n production get pods`

# Dashboard
### Deploy the K8s Metrics Server
`kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`

test its installed 
`get deployment metrics-server -n kube-system`

Download Dashboard with same version on K8s you are using
`kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.3/aio/deploy/recommended.yaml`

next make a services accout  
```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: eks-course-admin
  namespace: kube-system

---
  
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: eks-course-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: eks-course-admin
  namespace: kube-system
  ```

### create an admin user account
```
kubectl apply -f admin-service-account.yml
```
### access the dashboard
* get a security token
```kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-course-admin | awk '{print $1}')
```
record the output of ```token:```

* start kube proxy via ```kubectl proxy```

* open browser at `http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login`

and choose _token_ as login method, where you have to provide the token you recorded two steps before

Get cluster IPs
`kubectl get pods -o wide`

get info

`kubectl describe service frontend`