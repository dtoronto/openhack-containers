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

## create a resource group
##az group create --name $HACK_RG --location $HACK_LOC

## Create the Server Component

### Create the Azure AD application
HACK_SVR_APP_ID=$(az ad app create \
    --display-name "${HACK_AKS_NAME}Server" \
    --identifier-uris "https://${HACK_AKS_NAME}Server" \
    --query appId -o tsv)

### Update the application group memebership claims
az ad app update --id $HACK_SVR_APP_ID --set groupMembershipClaims=All

### Create a service principal for the Azure AD application
az ad sp create --id $HACK_SVR_APP_ID

### Get the service principal secret
HACK_SVR_APP_SECRET=$(az ad sp credential reset \
    --name $HACK_SVR_APP_ID \
    --credential-description "AKSPassword" \
    --query password -o tsv)

### Assign permissions
az ad app permission add \
    --id $HACK_SVR_APP_ID \
    --api 00000003-0000-0000-c000-000000000000 \
    --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role

az ad app permission grant --id $HACK_SVR_APP_ID --api 00000003-0000-0000-c000-000000000000
az ad app permission admin-consent --id $HACK_SVR_APP_ID

## Create the Client Component

HACK_SVR_CLIENT_ID=$(az ad app create \
    --display-name "${HACK_AKS_NAME}Client" \
    --native-app \
    --reply-urls "https://${HACK_AKS_NAME}Client" \
    --query appId -o tsv)

az ad sp create --id $HACK_SVR_CLIENT_ID

HACK_oAuthPermissionId=$(az ad app show --id $HACK_SVR_APP_ID --query "oauth2Permissions[0].id" -o tsv)

az ad app permission add --id $HACK_SVR_CLIENT_ID --api $HACK_SVR_APP_ID --api-permissions $HACK_oAuthPermissionId=Scope
az ad app permission grant --id $HACK_SVR_CLIENT_ID --api $HACK_SVR_APP_ID

## VNET - already created

## subnet
# TODO: create an aks-subnet
az network vnet subnet create -g $HACK_RG --vnet-name $HACK_VNET -n $HACK_SUBNET --address-prefixes 10.2.2.0/24

HACK_SUBNET_ID=$(az network vnet subnet list \
    --resource-group $HACK_RG \
    --vnet-name $HACK_VNET \
    --query "[0].id" --output tsv)

## create an aks resource
az aks create --resource-group $HACK_RG \
    --name $HACK_AKS_NAME \
    --location $HACK_LOC \
    --kubernetes-version $HACK_AKS_VERSION \
    --generate-ssh-keys \
    --aad-server-app-id $HACK_SVR_APP_ID \
    --aad-server-app-secret $HACK_SVR_APP_SECRET \
    --aad-client-app-id $HACK_SVR_CLIENT_ID \
    --aad-tenant-id $HACK_TENANT_ID \
    --network-plugin azure \
    --vnet-subnet-id $HACK_SUBNET_ID \
    --docker-bridge-address 172.17.0.1/16 \
    --dns-service-ip 10.2.3.10 \
    --service-cidr 10.2.3.0/24


az ad signed-in-user show --query userPrincipalName -o tsv

## get aks credentials
az aks get-credentials --resource-group $HACK_RG --name $HACK_AKS_NAME --overwrite-existing
az aks get-credentials --resource-group $HACK_RG --name $HACK_AKS_NAME --admin

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