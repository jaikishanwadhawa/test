FROM ubuntu:18.04
LABEL description="Image used for building Projected Modes pulsar packages for RAPIDE platform."

# Add gpg keys for parrot tools
RUN apt-get update && apt-get install -y gnupg dirmngr
RUN gpg --keyserver keys.gnupg.net --recv-keys 0x95A03282 || gpg --keyserver subkeys.pgp.net --recv-keys 95A03282 && \
    gpg -a --export 95A03282 | apt-key add - && \
    echo deb http://canari.pfa.tds/debian/ binary-amd64/ > /etc/apt/sources.list.d/canari.list

# Needed packages for building pulsar environment on RAPIDE platform
RUN apt-get update && apt-get install -y \
        autoconf \
        automake \
        bison \
        bsdtar \
        build-essential \
        cmake \
        curl \
        flex \
        gettext \
        git \
        golang \
        makeself \
        openjdk-8-jdk-headless \
        openssh-server \
        parrot-tools-linuxgnutools-2016.02-aarch64-linaro \
        pkg-config \
        python \
        python3 \
        python3-lxml \
        python3-jinja2 \
        unzip \
        wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add Android repo tools to get source code
RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/bin/repo && chmod 0777 /usr/bin/repo

# Add user jenkins to the image and set password
RUN mkdir -p /var/run/sshd && \
    adduser --quiet jenkins && \
    mkdir -p /home/jenkins/.ssh && \
    chown -R jenkins /home/jenkins/.ssh
RUN echo jenkins:jenkins | chpasswd

# Install Coverity
ENV COVERITY_PATH=/opt/cov-analysis-linux64-2018.09
# /!\ The --insecure option is added in January 2020 as a quick fix for a certificate error which should be fixed properly asap.
RUN curl --insecure https://coverity.pfa.tds/downloads/${COVERITY_PATH#/opt/}.tar.gz | bsdtar -xzf - -C /opt/ && \
    curl http://canari.pfa.tds/resources/coverity/licenses/licence-auto-20200127.dat -o ${COVERITY_PATH}/bin/license.dat
RUN ${COVERITY_PATH}/bin/cov-configure --gcc && \
    ${COVERITY_PATH}/bin/cov-configure --template --comptype gcc --compiler aarch64-linux-gnu-gcc && \
    ${COVERITY_PATH}/bin/cov-configure --template --comptype g++ --compiler aarch64-linux-gnu-g++

# Expose standard SSH port for Jenkins SSH Slave
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
