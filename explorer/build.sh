#!/bin/sh
set -e

EXPLORER_BRANCH=master

echo "Fetching explorer-backend ${EXPLORER_BRANCH} branch"
curl -L https://github.com/ergoplatform/explorer-backend/archive/refs/heads/${EXPLORER_BRANCH}.tar.gz > explorer-backend.tar.gz

echo "Extracting explorer source"
rm -rf explorer-backend-${EXPLORER_BRANCH}
tar -xf explorer-backend.tar.gz
rm explorer-backend.tar.gz

echo "Preparing Dockerfiles"
cp explorer-backend-${EXPLORER_BRANCH}/modules/chain-grabber/Dockerfile explorer-backend-${EXPLORER_BRANCH}/chain-grabber.Dockerfile
cp explorer-backend-${EXPLORER_BRANCH}/modules/explorer-api/Dockerfile explorer-backend-${EXPLORER_BRANCH}/explorer-api.Dockerfile
cp explorer-backend-${EXPLORER_BRANCH}/modules/utx-broadcaster/Dockerfile explorer-backend-${EXPLORER_BRANCH}/utx-broadcaster.Dockerfile
cp explorer-backend-${EXPLORER_BRANCH}/modules/utx-tracker/Dockerfile explorer-backend-${EXPLORER_BRANCH}/utx-tracker.Dockerfile

echo "Fixing deprecated OpenJDK base images"
sed -i.bak 's|FROM openjdk:8-jre-slim|FROM eclipse-temurin:8-jre|g' explorer-backend-${EXPLORER_BRANCH}/*.Dockerfile
rm -f explorer-backend-${EXPLORER_BRANCH}/*.Dockerfile.bak

echo "Fixing broken SNAPSHOT dependencies"
sed -i.bak 's|v3.3.8-aaaab5ef-SNAPSHOT|5.0.27|g' explorer-backend-${EXPLORER_BRANCH}/project/versions.scala
rm -f explorer-backend-${EXPLORER_BRANCH}/project/versions.scala.bak

echo "Done."
