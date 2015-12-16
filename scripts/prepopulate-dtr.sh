#!/bin/bash

DTR_IP=$1

curl -Livk \
     -X PUT https://$DTR_IP/api/v0/admin/settings/auth \
     -H 'Content-Type: application/json; charset=UTF-8' \
     -H 'Accept: */*' \
     -H 'X-Requested-With: XMLHttpRequest' \
     --data-binary '{"method":"managed","managed":{"users":[{"username":"admin","password":"dockerdtr","isNew":true,"isAdmin":true,"isReadWrite":false,"isReadOnly":false,"teamsChanged":true}]}}'

# Let dtr restart after locking it down
sleep 20

create-user() {

  USER_NAME=$1

  # create user and set their password
  curl -Livk -X POST --header "Content-Type: application/json" --header "Accept: application/json" \
    --user admin:dockerdtr -d "{
      \"type\": \"user\",
      \"name\": \"${USER_NAME}\",
      \"password\": \"dockerdtr\" }" \
    "https://dtr.docker.vm/api/v0/accounts"

  curl -Livk -X PUT --header "Content-Type: application/json" --header "Accept: application/json" \
    --user admin:dockerdtr "https://dtr.docker.vm/api/v0/accounts/${USER_NAME}/activate"
}

create-user chad
create-user bob
create-user alice
create-user jack
create-user jill

curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" \
    --user admin:dockerdtr -d "{
      \"type\": \"organization\",
      \"name\": \"eng\"}" \
    "https://dtr.docker.vm/api/v0/accounts"

curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" \
    --user admin:dockerdtr -d "{
      \"type\": \"organization\",
      \"name\": \"infra\"}" \
    "https://dtr.docker.vm/api/v0/accounts"


curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" \
    --user admin:dockerdtr -d "{
      \"type\": \"organization\",
      \"name\": \"qa\"}" \
    "https://dtr.docker.vm/api/v0/accounts"


curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" \
    --user admin:dockerdtr  -d "{
      \"name\": \"ducp\",
      \"description\": \"The DUCP team\",
      \"type\": \"managed\"}" \
    "https://dtr.docker.vm/api/v0/accounts/eng/teams"

curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" \
    --user admin:dockerdtr  -d "{
      \"name\": \"dtr\",
      \"description\": \"The DTR team\",
      \"type\": \"managed\"}" \
    "https://dtr.docker.vm/api/v0/accounts/eng/teams"

curl -X PUT --header "Content-Type: application/json" --header "Accept: application/json" \
  --user admin:dockerdtr  "https://dtr.docker.vm/api/v0/accounts/eng/teams/dtr/members/chad"

curl -X PUT --header "Content-Type: application/json" --header "Accept: application/json" \
  --user admin:dockerdtr  "https://dtr.docker.vm/api/v0/accounts/eng/teams/dtr/members/alice"

curl -X PUT --header "Content-Type: application/json" --header "Accept: application/json" \
  --user admin:dockerdtr  "https://dtr.docker.vm/api/v0/accounts/eng/teams/dtr/members/bob"

curl -X PUT --header "Content-Type: application/json" --header "Accept: application/json" \
  --user admin:dockerdtr  "https://dtr.docker.vm/api/v0/accounts/eng/teams/ducp/members/chad"

curl -X PUT --header "Content-Type: application/json" --header "Accept: application/json" \
  --user admin:dockerdtr  "https://dtr.docker.vm/api/v0/accounts/eng/teams/ducp/members/jill"

curl -X PUT --header "Content-Type: application/json" --header "Accept: application/json" \
  --user admin:dockerdtr  "https://dtr.docker.vm/api/v0/accounts/eng/teams/ducp/members/jack"

curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" \
  --user admin:dockerdtr -d "{
    \"name\": \"alpine\",
    \"shortDescription\": \"\",
    \"longDescription\": \"\",
    \"visibility\": \"public\"}" \
  "https://dtr.docker.vm/api/v0/repositories/eng"

curl -X PUT --header "Content-Type: application/json" --header "Accept: application/json" \
  --user admin:dockerdtr -d "{
    \"accessLevel\": \"read-write\"}" \
  "https://dtr.docker.vm/api/v0/repositories/eng/alpine/teamAccess/dtr"


  curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" \
    --user admin:dockerdtr -d "{
      \"name\": \"ubuntu\",
      \"shortDescription\": \"\",
      \"longDescription\": \"\",
      \"visibility\": \"public\"}" \
    "https://dtr.docker.vm/api/v0/repositories/eng"

  curl -X PUT --header "Content-Type: application/json" --header "Accept: application/json" \
    --user admin:dockerdtr -d "{
      \"accessLevel\": \"read-write\"}" \
    "https://dtr.docker.vm/api/v0/repositories/eng/ubuntu/teamAccess/dtr"

    curl -X PUT --header "Content-Type: application/json" --header "Accept: application/json" \
      --user admin:dockerdtr -d "{
        \"accessLevel\": \"read-write\"}" \
      "https://dtr.docker.vm/api/v0/repositories/eng/ubuntu/teamAccess/ducp"
