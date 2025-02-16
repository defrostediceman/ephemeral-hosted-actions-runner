#!/bin/bash
logger -t "github-runner-cleanup" "Starting cleanup process"
podman system prune -af | logger -t "github-runner-cleanup"
rm -rf /tmp/* | logger -t "github-runner-cleanup"
rm -rf /var/tmp/* | logger -t "github-runner-cleanup"
logger -t "github-runner-cleanup" "Cleanup process completed"