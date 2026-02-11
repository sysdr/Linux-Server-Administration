#!/bin/bash
# Day5: Stop and remove Alpine Lighttpd container.
CONTAINER_NAME="alpine-lighttpd-web"
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true
echo "Stopped and removed container $CONTAINER_NAME"
