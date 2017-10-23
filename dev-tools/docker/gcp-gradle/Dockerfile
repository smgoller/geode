FROM ubuntu:16.04

# Java license acceptance script
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections

# Install and update the kitchen sink
RUN apt-get update && \
    apt-get install -y software-properties-common  && \
    add-apt-repository ppa:webupd8team/java && \
    apt-get update && \
    apt-get install -y --allow-unauthenticated \
      build-essential cmake \
      man unzip vim \
      lsb-release curl git \
      htop wget libssl-dev \
      oracle-java8-installer && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/oracle-jdk8-installer

# Vars
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
# Using 'xenial' since we know this is ubuntu:16.04
ENV CLOUD_SDK_REPO "cloud-sdk-xenial"

# Setup Google APT repository
RUN echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

#Get the Google needs for cloud file storage
RUN apt-get update && apt-get install -y google-cloud-sdk


ENV GRADLE_USER_HOME /usr/local/maven_files
WORKDIR /tmp/work
ADD cache_dependencies.sh cache_dependencies.sh
#RUN mkdir -p /root/.ssh
#RUN chmod 700 /root/.ssh
#ADD ssh_config /root/.ssh/config
#ADD id_gemfire /root/.ssh/id_rsa
#RUN chmod 600 /root/.ssh/id_rsa
RUN chmod +x cache_dependencies.sh
RUN ./cache_dependencies.sh
RUN rm -rf /tmp/work
