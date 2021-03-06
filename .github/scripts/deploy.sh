#!/bin/bash

helm repo add stable https://charts.helm.sh/stable
helm plugin install https://github.com/chartmuseum/helm-push
helm repo add --username=${HARBOR_USER} --password=${HARBOR_TOKEN} myrepo  https://registry.cern.ch/chartrepo/cmsweb
helm repo update
helm repo list
cd helm
for chart in $(ls -d */Chart.yaml | xargs dirname); do
echo $chart
          LOCAL_VERSION=$(grep -R "version:" ${chart}/Chart.yaml | awk '{print $2}')
          if ! REMOTE_LATEST_VERSION="$(helm search repo myrepo/"${chart}" | grep myrepo/"${chart}" | awk '{print $2}')" ; then
              echo "INFO There are no remote versions."
              REMOTE_LATEST_VERSION=""
          fi
          if [ "${REMOTE_LATEST_VERSION}" = "" ] || \
              [ "$(expr "${REMOTE_LATEST_VERSION}" \< "${LOCAL_VERSION}")" -eq 1 ]; then
              helm dep update ${chart}
              helm package ${chart}
              helm push --username=${HARBOR_USER} --password=${HARBOR_TOKEN} "${chart}-${LOCAL_VERSION}.tgz"  myrepo
              #set +x
              #curl --fail -F "chart=@${chart}-${LOCAL_VERSION}.tgz" -H "authorization: Basic $(echo -n ${HARBOR_USER}:${HARBOR_TOKEN} | base64)" https://registry.cern.ch/api/chartrepo/cmsweb/charts
              #set -x
          fi
done

