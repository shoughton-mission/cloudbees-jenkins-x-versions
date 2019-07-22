#!/usr/bin/env bash
set -e
set -x

npm i -g xunit-viewer

xunit-viewer --results=reports/junit.xml --output=reports/junit.html --title="BDD Tests"
echo "Generated test report at: reports/junit.html"

ls -larth reports/