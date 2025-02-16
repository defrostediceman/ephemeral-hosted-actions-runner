# Ephemeral GitHub Actions Runner Container

A self-hosted GitHub Actions runner using rootful podman with systemd integration and automatic cleanup capabilities.

## Features

- Runs as a privileged container with systemd
- Automatic daily cleanup of container resources
- Ephemeral runner configuration
- Uses CentOS Stream 9 base image
- Integrated system logging
- Systemd service management
- Cron-based cleanup scheduling

## Prerequisites

- Podman installed on the host machine
- GitHub repository with admin access
- Runner token from GitHub

## Configuration Files

The container expects the following files in the `/etc/systemd/system` directory. These files are included in the container image on build.

- /etc/systemd/system/github-runner.service
- /etc/systemd/system/cleanup.service
- /etc/systemd/system/cleanup.timer

Additionally, a cleanup script should be provided at cleanup.sh in the `/usr/local/bin` directory. This script will be used to clean up the container resources.

## Building the Container

Build the image with your GitHub repository URL and token:

```bash
podman build \
    --build-arg REPO_URL="your-repo-url" \ # mandatory
    --build-arg TOKEN="your-token" \ # mandatory
    --build-arg RUNNER_VERSION="your-runner-version" \ # optional, default is 2.314.1
    --build-arg RUNNER_ARCH="your-runner-arch" \ # optional, default is x64
    -t defrostediceman/ephemeral-hosted-actions-runner
```

## Pulling the container

Or you can pull the image from the GitHub Container Registry and insert those variables at runtime.

```bash
podman pull ghcr.io/defrostediceman/ephemeral-hosted-actions-runner:latest
```

## Running the container

```bash
podman run -d \
    --privileged \
    --name github-runner \
    --tmpfs /tmp \
    --tmpfs /run \
    --tmpfs /var/tmp \
    --tmpfs /home/runner/_work \
    --systemd=always \
    --user=runner \
    ghcr.io/defrostediceman/ephemeral-hosted-actions-runner:latest
```

## System Services

The container runs two main services:
1. github-runner.service: Manages the GitHub Actions runner
2. cleanup.service: Handles periodic system cleanup
3. cleanup.timer: Triggers the cleanup service daily

## Logging

System logs can be accessed using:

```bash
podman logs github-runner
```

For cleanup-specific logs:

```bash
podman exec github-runner journalctl -u cleanup.service
```

## Security Considerations

- Container runs with privileged access
- Uses root-level podman
- Runner has sudo privileges
- Contains sensitive GitHub tokens

## Maintenance

Stop the container:

```bash
podman stop github-runner
```

View service status:

```bash
podman exec github-runner systemctl status github-runner
```

Check cleanup timer:

```bash
podman exec github-runner systemctl status cleanup.timer
```

## Troubleshooting

Common issues and solutions:

1. Container fails to start:
  - Check systemd services status
  - Verify GitHub token validity
  - Ensure all required files are present

2. Cleanup not running:
  - Check timer status
  - Verify service permissions
  - Review systemd logs

3. Runner registration fails:
  - Confirm repository URL
  - Validate runner token
  - Check network connectivity

## License

Apache 2.0.

## Contributing

Contributions are welcome. Please open an issue or submit a pull request.

## Support

For issues and feature requests, please use the GitHub issue tracker.