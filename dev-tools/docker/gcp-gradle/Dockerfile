FROM apachegeode/geode-build


# Setup Google APT repository
RUN apt-get update && \
  apt-get install -y lsb-release && \
  echo "deb http://packages.cloud.google.com/apt cloud-sdk-$(lsb_release -c -s) main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
  apt-get update && apt-get install -y google-cloud-sdk && \
  apt-get clean

# RUN chmod +w /usr/local/maven_files/wrapper/dists/gradle-3.5.1-bin/5aglzaqc99i3lll5iwkbm96su/gradle-3.5.1-bin.zip.lck

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
