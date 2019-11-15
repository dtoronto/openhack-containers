## commands

## environment variables
HACK_SUB=$(az account show --query id -o tsv)
HACK_TENANT_ID=$(az account show --query tenantId -o tsv)
HACK_RG="teamResources"
HACK_LOC="westus2"
HACK_AKS_NAME="team10-secure2-aks"
HACK_ACR="registryine4658"
HACK_AKS_VERSION=$(az aks get-versions -l $HACK_LOC --query 'orchestrators[-1].orchestratorVersion' -o tsv)
HACK_VNET="vnet"
HACK_SUBNET="team10-aks-secure2-subnet"

## helm rbac
kubectl apply -f helm-rbac.yaml

## Create a namespace for your ingress resources
#kubectl create namespace ingress-basic

## Use Helm to deploy an NGINX ingress controller
helm install stable/nginx-ingress \
    --namespace ingress-basic \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux
