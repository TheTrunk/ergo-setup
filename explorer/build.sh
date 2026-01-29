#!/bin/sh
set -e

EXPLORER_VERSION=10.0.0

echo "Fetching explorer-backend ${EXPLORER_VERSION}"
curl -L https://github.com/ergoplatform/explorer-backend/archive/refs/tags/${EXPLORER_VERSION}.tar.gz > explorer-backend.tar.gz

echo "Extracting explorer source"
rm -rf explorer-backend-${EXPLORER_VERSION}
tar -xf explorer-backend.tar.gz
rm explorer-backend.tar.gz

echo "Preparing Dockerfiles"
cp explorer-backend-${EXPLORER_VERSION}/modules/chain-grabber/Dockerfile explorer-backend-${EXPLORER_VERSION}/chain-grabber.Dockerfile
cp explorer-backend-${EXPLORER_VERSION}/modules/explorer-api/Dockerfile explorer-backend-${EXPLORER_VERSION}/explorer-api.Dockerfile
cp explorer-backend-${EXPLORER_VERSION}/modules/utx-broadcaster/Dockerfile explorer-backend-${EXPLORER_VERSION}/utx-broadcaster.Dockerfile
cp explorer-backend-${EXPLORER_VERSION}/modules/utx-tracker/Dockerfile explorer-backend-${EXPLORER_VERSION}/utx-tracker.Dockerfile

echo "Fixing Docker base images (if needed)"
sed -i.bak 's|FROM openjdk:8-jre-slim as builder|FROM eclipse-temurin:8-jdk as builder|g' explorer-backend-${EXPLORER_VERSION}/*.Dockerfile 2>/dev/null || true
sed -i.bak 's|FROM openjdk:8-jre-slim As builder|FROM eclipse-temurin:8-jdk as builder|g' explorer-backend-${EXPLORER_VERSION}/*.Dockerfile 2>/dev/null || true
sed -i.bak 's|FROM openjdk:8-jre-slim|FROM eclipse-temurin:8-jre|g' explorer-backend-${EXPLORER_VERSION}/*.Dockerfile 2>/dev/null || true
rm -f explorer-backend-${EXPLORER_VERSION}/*.Dockerfile.bak 2>/dev/null || true

echo "Done."
echo "Now update docker-compose.yml to use explorer-backend-${EXPLORER_VERSION}"
echo "Then run: docker compose build --no-cache && docker compose up -d"
