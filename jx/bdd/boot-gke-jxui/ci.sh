#!/usr/bin/env bash
set -e
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export GH_USERNAME="cjxd-bot-test"
export GH_OWNER="cb-kubecd"
export GH_EMAIL="jenkins-x@googlegroups.com"

# fix broken `BUILD_NUMBER` env var
export BUILD_NUMBER="$BUILD_ID"

JX_HOME="/tmp/jxhome"
KUBECONFIG="/tmp/jxhome/config"

# lets avoid the git/credentials causing confusion during the test
export XDG_CONFIG_HOME=$JX_HOME

mkdir -p $JX_HOME/git

jx --version
# replace the credentials file with a single user entry
echo "https://$GH_USERNAME:$GH_ACCESS_TOKEN@github.com" > $JX_HOME/git/credentials

gcloud auth activate-service-account --key-file $GKE_SA

# lets setup git 
git config --global --add user.name CJXDBot
git config --global --add user.email $GH_EMAIL

echo "running the BDD tests with JX_HOME = $JX_HOME"

# setup jx boot parameters
export JX_REQUIREMENT_ENV_GIT_PUBLIC=true
export JX_REQUIREMENT_GIT_PUBLIC=true
export JX_REQUIREMENT_ENV_GIT_OWNER="$GH_OWNER"
export JX_REQUIREMENT_PROJECT="jenkins-x-bdd3"
export JX_REQUIREMENT_ZONE="europe-west1-c"
export JX_VALUE_ADMINUSER_PASSWORD="$JENKINS_PASSWORD"
export JX_VALUE_PIPELINEUSER_USERNAME="$GH_USERNAME"
export JX_VALUE_PIPELINEUSER_EMAIL="$GH_EMAIL"
export JX_VALUE_PIPELINEUSER_GITHUB_USERNAME="$GH_USERNAME"
export JX_VALUE_PIPELINEUSER_GITHUB_TOKEN="$GH_ACCESS_TOKEN"
export JX_VALUE_PIPELINEUSER_TOKEN="$GH_ACCESS_TOKEN"
export JX_VALUE_PROW_HMACTOKEN="$GH_ACCESS_TOKEN"


# override checking for diffs in jx-requirements.yaml as we need to change it before booting
export OVERRIDE_DIFF_CHECK="true"

# TODO temporary hack until the batch mode in jx is fixed...
export JX_BATCH_MODE="true"

mkdir boot-source
cd boot-source

JX_DOWNLOAD_LOCATION=$(<../jx/CJXD_LOCATION_LINUX)

wget $JX_DOWNLOAD_LOCATION
tar -zxvf jx-linux-amd64.tar.gz
export PATH=$(pwd):$PATH


# use the current git SHA being built in the version stream
if [[ -n "${PULL_PULL_SHA}" ]]; then
  sed -i "/^ *versionStream:/,/^ *[^:]*:/s/ref: .*/ref: ${PULL_PULL_SHA}/" ../jx/bdd/boot-gke-jxui/jx-requirements.yml
fi

echo "Using ../jx/bdd/boot-gke-jxui/jx-requirements.yml"
cat ../jx/bdd/boot-gke-jxui/jx-requirements.yml
cp ../jx/bdd/boot-gke-jxui/jx-requirements.yml .

helm init --client-only
helm repo add jenkins-x https://storage.googleapis.com/chartmuseum.jenkins-x.io
helm repo add cloudbees  https://charts.cloudbees.com/cjxd/cloudbees

helm repo update
export JX_APP_UI_VERSION=$(helm search -l cloudbees/jx-app-ui | awk 'NR>1 {print $2}' | head -n 1)

mkdir /workspace/source/reports
export REPORTS_DIR=/workspace/source/reports

echo "Running bdd tests with JX_APP_UI_VERSION=${JX_APP_UI_VERSION}"

TEST_EXIT_CODE=0
jx step bdd \
    --use-revision \
    --version-repo-pr \
    --versions-repo https://github.com/cloudbees/cloudbees-jenkins-x-versions.git \
    --gopath /tmp \
    --git-provider=github \
    --config ../jx/bdd/boot-gke-jxui/cluster.yaml \
    --git-username $GH_USERNAME \
    --git-owner $GH_OWNER \
    --git-api-token $GH_ACCESS_TOKEN \
    --default-admin-password $JENKINS_PASSWORD \
    --no-delete-app \
    --no-delete-repo \
    --tests test-jxui \
    || TEST_EXIT_CODE=$?

echo "Generating test report"
${DIR}/report.sh ${REPORT_OUT_DIR} ${REPORT_OUTPUT_NAME}

exit ${TEST_EXIT_CODE}
