# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
FROM openjdk:8-jdk-alpine
ENTRYPOINT []

ARG CHROME_DRIVER_VERSION=2.35
ENV SPRUCE_VERSION 1.17.0
ENV GRADLE_USER_HOME /usr/local/maven_files
ENV CLOUD_SDK_VERSION 195.0.0

ENV PATH /google-cloud-sdk/bin:$PATH

WORKDIR /geode

ADD https://github.com/geofffranks/spruce/releases/download/v${SPRUCE_VERSION}/spruce-linux-amd64 /usr/local/bin/spruce
ADD https://github.com/krallin/tini/releases/download/v0.14.0/tini-static-amd64 /usr/local/bin/tini
ADD tini-wrapper.go .
ADD ./initdocker /usr/local/bin/initdocker

RUN chmod +x /usr/local/bin/tini \
  && chmod +x /usr/local/bin/spruce \
  && chmod +x /usr/local/bin/initdocker \
  && apk add --no-cache \
    bash \
    chromium \
    curl \
    docker \
    git \
    go \
    htop \
    jq \
    musl-dev \
    openssh-client \
    python \
    python3 \
    py2-pip \
    py3-pip \
    py-crcmod \
    unzip \
    vim \
    zip \
  &&  apk --no-cache add ca-certificates wget \
  &&  wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub \
  &&  wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.27-r0/glibc-2.27-r0.apk \
  &&  apk add glibc-2.27-r0.apk \
  && pip install docker-compose \
  && chmod +x cache_dependencies.sh \
  && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
  && tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz -C / \
  && rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
  && ln -s /lib /lib64 \
  && gcloud config set core/disable_usage_reporting true \
  && gcloud config set component_manager/disable_update_check true \
  && gcloud config set metrics/environment github_docker_image \
  && go build -o /usr/local/bin/tini-wrapper ./tini-wrapper.go \
  && curl -Lo /usr/local/bin/dunit-progress https://github.com/jdeppe-pivotal/progress-util/releases/download/0.2/progress.linux \
  && chmod +x /usr/local/bin/dunit-progress \
  && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip \
  && rm -rf /opt/selenium/chromedriver \
  && mkdir -p /opt/selenium \
  && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
  && rm /tmp/chromedriver_linux64.zip \
  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver \
  && apk del \
    go \
    musl-dev \
  && rm -rf /geode
