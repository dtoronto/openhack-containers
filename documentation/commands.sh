## commands

## environment variables
HACK_SUB=$(az account show --query id -o tsv)
HACK_TENANT_ID=$(az account show --query tenantId -o tsv)
HACK_RG="teamResources"
HACK_LOC="westus2"
HACK_AKS_NAME="team10-secure2-aks"
HACK_KV="team10-kv"
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

## create a key vault
az keyvault create --location $HACK_LOC --name $HACK_KV --resource-group $HACK_RG

## add secrets
az keyvault secret set --vault-name $HACK_KV --name sqluser --value sqladminiNe4658
az keyvault secret set --vault-name $HACK_KV --name sqlpassword --value qA0w25Fw9
az keyvault secret set --vault-name $HACK_KV --name sqlserver --value sqlserverine4658.database.windows.net

## install FlexVolume
kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-keyvault-flexvol/master/deployment/kv-flexvol-installer.yaml

### validate flexvolume is running
kubectl get pods -n kv

### create the aad-pod-identity deployment on an RBAC-enabled cluster
kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml





### create azure identity 
az identity create -g $HACK_RG -n keyvaultUser -o json

HACK_KVClientId="99304fc8-7d49-4a51-b9dd-1dfd9f4de17b"
HACK_KVId="/subscriptions/f6892e2c-404f-44a4-8889-b4efa546cdff/resourcegroups/teamResources/providers/Microsoft.ManagedIdentity/userAssignedIdentities/keyvaultUser"
HACK_SVR_APP_ID="109832d2-b6f3-492d-a543-811420381dc3"
SPN="b3628465-617e-4c85-86ea-a5e5b2da77b9"

### managed operator role to our Server SPN -- sp = aks server app id??
az role assignment create --role "Managed Identity Operator" --assignee 581b2e04-c0cc-49f0-84c3-b6cf35b2ef71 --scope $HACK_KVId

# Assign Reader Role to new Identity for your Key Vault -- kvClientId??
az role assignment create --role Reader --assignee $HACK_KVClientId --scope "/subscriptions/f6892e2c-404f-44a4-8889-b4efa546cdff/resourcegroups/teamResources/providers/Microsoft.KeyVault/vaults/team10-kv"

# set policy to access keys in your Key Vault
az keyvault set-policy -n $HACK_KV --key-permissions get --spn $HACK_KVClientId
# set policy to access secrets in your Key Vault
az keyvault set-policy -n $HACK_KV --secret-permissions get --spn $HACK_KVClientId
# set policy to access certs in your Key Vault
az keyvault set-policy -n $HACK_KV --certificate-permissions get --spn $HACK_KVClientId


## troubleshooting

kubectl describe pods poi --namespace api
kubectl get all --namespace api
kubectl get po poi --show-labels
kubectl logs poi-754cc9759d-rxzjk --namespace api

kubectl exec -it poi-754cc9759d-rxzjk --namespace api -- /bin/sh

## kill the deployment
kubectl delete deployment.apps/poi --namespace api