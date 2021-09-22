FROM debian:latest

# Install required packages
RUN apt-get update \
    && apt-get install -y \
        curl \
        sudo \
        git \
        jq \
        tar \
        gnupg2 \
        apt-transport-https \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create rootless user
RUN useradd -m github && \
    usermod -aG sudo github && \
    echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install docker in docker
RUN curl -sSL https://get.docker.com/ | bash && \
    usermod -aG docker github

# Use rootless user
USER github
WORKDIR /home/github

# Download & install latest version of runner
RUN RUNNER_VERSION=$(curl https://api.github.com/repos/actions/runner/releases | jq '.[0].name') && \
    RUNNER_VERSION=$(echo $RUNNER_VERSION | sed 's/"//g') && \
    RUNNER_VERSION=$(echo $RUNNER_VERSION | sed 's/v//g') && \
    KERNEL_VERSION=$(uname -m) && \
    KERNEL_VERSION=$(echo $KERNEL_VERSION | sed 's/86_//g') && \
    KERNEL_VERSION=$(echo $KERNEL_VERSION | sed 's/v6l//g') && \
    KERNEL_VERSION=$(echo $KERNEL_VERSION | sed 's/v7l//g') && \
    KERNEL_VERSION=$(echo $KERNEL_VERSION | sed 's/v8l//g') && \
    curl -O -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-$KERNEL_VERSION-$RUNNER_VERSION.tar.gz \
    && tar xzf ./actions-runner-linux-$KERNEL_VERSION-$RUNNER_VERSION.tar.gz \
    && rm -f ./actions-runner-linux-$KERNEL_VERSION-$RUNNER_VERSION.tar.gz
RUN sudo ./bin/installdependencies.sh

# Prepare entrypoint 
COPY --chown=github:github entrypoint.sh ./entrypoint.sh
RUN sudo chmod u+x ./entrypoint.sh

# Run the container from entrypoint
ENTRYPOINT ["/home/github/entrypoint.sh"]