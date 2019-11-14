## commands

## environment variables
HACK_RG="teamResources"
HACK_LOC="westus2"
HACK_AKS_NAME="team10-aks"
HACK_ACR="registryine4658"
HACK_AKS_VERSION=$(az aks get-versions -l $HACK_LOC --query 'orchestrators[-1].orchestratorVersion' -o tsv)

## create a resource group
az group create --name $HACK_RG --location $HACK_LOC

## create an aks resource
az aks create --resource-group $HACK_RG \
    --name $HACK_AKS_NAME \
    --location $HACK_LOC \
    --kubernetes-version $HACK_AKS_VERSION \
    --generate-ssh-keys

## get aks credentials
az aks get-credentials --resource-group $HACK_RG --name $HACK_AKS_NAME

## attach to ACR
az aks update -n $HACK_AKS_NAME -g $HACK_RG --attach-acr $HACK_ACR

## kubectl
kubectl cluster-info
kubectl get pods

## create a service
kubectl apply -f deployment.yaml

## add rbac to support the dashboard
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard

## browse the cluster?
az aks browse --resource-group $HACK_RG --name $HACK_AKS_NAME