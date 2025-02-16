FROM quay.io/centos/centos:stream9

ARG REPO_URL=https://github.com/defrostediceman/ephemeral-hosted-actions-runner
ARG TOKEN=YOU_SHOULD_USE_A_SECRET_HERE
ARG RUNNER_VERSION=2.314.1
ARG RUNNER_ARCH="x64"

ENV REPO_URL=${REPO_URL}
ENV TOKEN=${TOKEN}
ENV RUNNER_VERSION=${RUNNER_VERSION}
ENV RUNNER_ARCH=${RUNNER_ARCH}

COPY etc /etc

# Install required packages
RUN dnf update --assumeyes --allowerasing && \
    dnf install --assumeyes --allowerasing \
        curl \
        sudo \
        git \
        jq \
        podman \
        buildah \
        cronie \
        systemd \
        systemd-libs && \
    dnf autoremove --assumeyes && \
    dnf clean all && \
    rm -rf /var/lib/apt/lists/*

# Create runner user and setup permissions
RUN useradd -m runner && \
    usermod -aG wheel runner

WORKDIR /home/runner

# Download and install GitHub Actions runner
RUN curl -o actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz

# Setup cron job for cleanup
COPY cleanup.sh /usr/local/bin/cleanup

RUN chmod +x /usr/local/bin/cleanup && \
echo "0 0 * * * /cleanup.sh > /var/log/cleanup.log 2>&1" > /etc/cron.d/cleanup-cron && \
    chmod 0644 /etc/cron.d/cleanup-cron

# inject the repo url and token into the github-runner.service file
RUN sed -i \
    '/Environment="REPO_URL/s|\${REPO_URL}|'"${REPO_URL}"'|g; \
     /Environment="TOKEN/s|\${TOKEN}|'"${TOKEN}"'|g' \
    /etc/systemd/system/github-runner.service

# Set ownership
RUN chown -R runner:runner /home/runner

USER runner

RUN sudo systemctl enable \
        cleanup.service \
        cleanup.timer \
        github-runner.service

# Use systemd as entrypoint
ENTRYPOINT ["/sbin/init"]