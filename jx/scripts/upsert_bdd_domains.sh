#!/usr/bin/env bash

BDD_PROJECT="jenkins-x-bdd3"
PARENT_PROJECT="jenkins-x-rocks"
PREFIXES=("cjxd1" "cjxd2" "cjxd3" "cjxd4" "cjxd5" "cjxd6" "cjxd7" "cjxd8" "cjxd9" "cjxd10" "cjxd11" "cjxd12")
SUBDOMAIN="bdd.jenkins-x.rocks"

function does_subdomain_exist()
{
  local domain=$1
  gcloud dns managed-zones --project=$BDD_PROJECT list --filter=$domain --format=json | jq length
}

function get_domain_nameservers()
{
  local domain=$1
  local project=$2
  gcloud dns managed-zones --project=$project list --filter=$domain --format=json | jq .[].nameServers
}

function get_recordset_nameservers()
{
  #TODO
  echo "TODO"
}

function create_subdomain()
{
  local domain=$1
  gcloud dns managed-zones --project=$BDD_PROJECT create "${domain//\./-}" --dns-name "${domain}." --description="managed-zone for bdd tests"
}

function create_recordset_ns_entry()
{
  #TODO
  echo "TODO"
}

function create_managed_zone()
{
  #TODO
  echo "TODO"
}

for prefix in "${PREFIXES[@]}"
do
  domain="${prefix}.${SUBDOMAIN}"
  exists=$(does_subdomain_exist "${domain}")

  if [[ $exists -eq 0 ]]
  then
    create_subdomain "${domain}"
    echo "$domain created"
  else
    echo "$domain exists"
    child_nameservers="$(get_domain_nameservers "${domain}" "${BDD_PROJECT}")"
    parent_nameservers="$(get_recordset_nameservers "${domain}" "${PARENT_PROJECT}")"
    echo "${child_nameservers}"
  fi
done

