FROM openjdk:8-jdk-stretch

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG JENKINS_AGENT_HOME=/home/${user}

ENV JENKINS_AGENT_HOME ${JENKINS_AGENT_HOME}

RUN groupadd -g ${gid} ${group} \
    && useradd -d "${JENKINS_AGENT_HOME}" -u "${uid}" -g "${gid}" -m -s /bin/bash "${user}"

RUN ln -s /usr/local/openjdk-8/bin/java /usr/local/bin/java

# setup SSH server
RUN apt-get update \
    && apt-get install --no-install-recommends -y openssh-server \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i /etc/ssh/sshd_config \
        -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
        -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
        -e 's/#LogLevel.*/LogLevel INFO/' && \
    mkdir /var/run/sshd

VOLUME "${JENKINS_AGENT_HOME}" "/tmp" "/run" "/var/run"
WORKDIR "${JENKINS_AGENT_HOME}"

COPY setup-sshd /usr/local/bin/setup-sshd
COPY run.sh /usr/local/bin/run.sh

RUN printf 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";\n' > /etc/apt/apt.conf.d/no-recommands

# install python
RUN apt-get -qqy update && apt-get -y install \
    apt-transport-https ca-certificates curl lxc iptables \
    build-essential git wget \
    python3 python-pip python3-pip && \
    pip3 install setuptools && \
    pip3 install fire pyyaml

# install docker
RUN apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common

RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/debian \
        $(lsb_release -cs) \
        stable" && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io && \
    usermod -a -G docker jenkins

# consul
RUN mkdir -p /etc/consul.d/ && \
    echo 'datacenter = "int"' > /etc/consul.d/consul.hcl && \
    echo 'retry_join = ["swarm1-int", "swarm2-int", "swarm3-int"]' >> /etc/consul.d/consul.hcl && \
    echo 'data_dir = "/opt/consul"' >> /etc/consul.d/consul.hcl && \
    echo 'encrypt = "IgDyT6MRF1R582HpUTL1cuY9ndHHxLWs86ApHSCoJ5k="' >> /etc/consul.d/consul.hcl

RUN wget -q https://releases.hashicorp.com/consul/1.7.0/consul_1.7.0_linux_amd64.zip && \
    unzip consul* && \
    mkdir /opt/consul && \
    mv ./consul /opt/consul/ && \
    rm consul*

# misc
RUN apt-get install -y jq

EXPOSE 22

ENTRYPOINT ["run.sh"]

VOLUME /var/lib/docker
