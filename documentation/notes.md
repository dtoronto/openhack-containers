# Openhack Containers

## Info

### Team 10

- Team Email: 84376-2f9e8-10@skillmeup.com
- Team Password: Password123
- OpenhackPortal: <https://openhack.skillmeup.com>
- azure login/teams login:
  - user: hacker4o50@OTAPRD1574ops.onmicrosoft.com
  - new stuff

Hackers

- Hacker One: ryan
- Hacker Two: subhransu
- Hacker three: dave
- Hacker Four: tiffany
- Hacker Five: huseyin
- Hacker Six: alex

## Challenges

```txt
Information you'll need for challenges. You can find these later in the 'Messages' tab.

Web-dev User: webdev@OTAPRD1574ops.onmicrosoft.com
Web-dev PW: pZ0ow5Gd4
Api-dev User: apidev@OTAPRD1574ops.onmicrosoft.com
Api-dev PW: rZ7cx4S00

Azure SQL FDQN: sqlserverine4658.database.windows.net
Azure SQL Server User: sqladminiNe4658
Azure SQL Server Pass: qA0w25Fw9
Azure SQL Server Database: mydrivingDB

Simulator url:simulatorregistryiNe4658.westus2.azurecontainer.io
```

- Source Code: <https://github.com/Azure-Samples/openhack-containers>

### first challenge

- get the POI app running in a docker container along with the database

run the database locally via docker:

```powershell
## run SQL Server Locally
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=qA0w25Fw9" `
   -p 1433:1433 --name sql1 `
   -d mcr.microsoft.com/mssql/server:2017-latest

## figure out the IP address of the server
docker network inspect bridge

## run the data-load script on the database
docker run -e SQLFQDN=172.17.0.2 -e SQLUSER=sa -e SQLPASS=qA0w25Fw9 -e SQLDB=mydrivingDB openhack/data-load:v1

## build the POI image from dockerfile (from the openhack-containers\src\poi folder)
docker build -f ..\..\dockerfiles\Dockerfile_3 -t "tripinsights/poi:1.0" .

docker build --no-cache --build-arg IMAGE_VERSION="1.0" --build-arg IMAGE_CREATE_DATE="$(Get-Date((Get-Date).ToUniversalTime()) -UFormat '%Y-%m-%dT%H:%M:%SZ')" --build-arg IMAGE_SOURCE_REVISION="$(git rev-parse HEAD)" -f ..\..\dockerfiles\Dockerfile_3 -t "tripinsights/poi:1.0" .

## run the POI docker image
docker run -d -p 8080:80 --name poi -e "SQL_PASSWORD=qA0w25Fw9" -e "SQL_SERVER=172.17.0.2" -e "ASPNETCORE_ENVIRONMENT=Local" -e "SQL_USER=sa" tripinsights/poi:1.0
```

Logging in to ACR

```powershell
## make sure we're using the hackerXXX subscription
az login

## setup docker with the ACR credentials
az acr login --name registryine4658
```

other services:

```powershell
## poi
docker build --no-cache --build-arg IMAGE_VERSION="1.0" --build-arg IMAGE_CREATE_DATE="$(Get-Date((Get-Date).ToUniversalTime()) -UFormat '%Y-%m-%dT%H:%M:%SZ')" --build-arg IMAGE_SOURCE_REVISION="$(git rev-parse HEAD)" -f ..\..\dockerfiles\Dockerfile_3 -t "tripinsights/poi:1.0" .
docker tag tripinsights/poi:1.0 registryine4658.azurecr.io/tripinsights/poi:1.0
docker push registryine4658.azurecr.io/tripinsights/poi:1.0

## trips
docker build --no-cache --build-arg IMAGE_VERSION="1.0" --build-arg IMAGE_CREATE_DATE="$(Get-Date((Get-Date).ToUniversalTime()) -UFormat '%Y-%m-%dT%H:%M:%SZ')" --build-arg IMAGE_SOURCE_REVISION="$(git rev-parse HEAD)" -f ..\..\dockerfiles\Dockerfile_4 -t "tripinsights/trips:1.0" .
docker tag tripinsights/trips:1.0 registryine4658.azurecr.io/tripinsights/trips:1.0
docker push registryine4658.azurecr.io/tripinsights/trips:1.0

## tripviewer
docker build --no-cache --build-arg IMAGE_VERSION="1.0" --build-arg IMAGE_CREATE_DATE="$(Get-Date((Get-Date).ToUniversalTime()) -UFormat '%Y-%m-%dT%H:%M:%SZ')" --build-arg IMAGE_SOURCE_REVISION="$(git rev-parse HEAD)" -f ..\..\dockerfiles\Dockerfile_1 -t "tripinsights/tripviewer:1.0" .
docker tag tripinsights/tripviewer:1.0 registryine4658.azurecr.io/tripinsights/tripviewer:1.0
docker push registryine4658.azurecr.io/tripinsights/tripviewer:1.0

## user-java
docker build --no-cache --build-arg IMAGE_VERSION="1.0" --build-arg IMAGE_CREATE_DATE="$(Get-Date((Get-Date).ToUniversalTime()) -UFormat '%Y-%m-%dT%H:%M:%SZ')" --build-arg IMAGE_SOURCE_REVISION="$(git rev-parse HEAD)" -f ..\..\dockerfiles\Dockerfile_0 -t "tripinsights/user-java:1.0" .
docker tag tripinsights/user-java:1.0 registryine4658.azurecr.io/tripinsights/user-java:1.0
docker push registryine4658.azurecr.io/tripinsights/user-java:1.0

## userprofile
docker build --no-cache --build-arg IMAGE_VERSION="1.0" --build-arg IMAGE_CREATE_DATE="$(Get-Date((Get-Date).ToUniversalTime()) -UFormat '%Y-%m-%dT%H:%M:%SZ')" --build-arg IMAGE_SOURCE_REVISION="$(git rev-parse HEAD)" -f ..\..\dockerfiles\Dockerfile_2 -t
"tripinsights/userprofile:1.0" .
docker tag tripinsights/userprofile:1.0 registryine4658.azurecr.io/tripinsights/userprofile:1.0
docker push registryine4658.azurecr.io/tripinsights/userprofile:1.0
```

### Second Challenge

AKS!!!

### Fourth Challenge

1. create key, add secrets to the key vault
2. hook up k8s to key vault
3. update yaml to use key vault secrets
