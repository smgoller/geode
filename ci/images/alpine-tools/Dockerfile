FROM alpine:3.7

COPY --from=google/cloud-sdk:alpine /google-cloud-sdk /google-cloud-sdk
COPY --from=hashicorp/packer:latest /bin/packer /usr/local/bin/packer
ENV PATH /google-cloud-sdk/bin:$PATH
RUN apk --no-cache add \
      bash \
      curl \
      git \
      openssh-client \
      python \
      py2-pip \
      rsync \
  && gcloud config set core/disable_usage_reporting true \
  && gcloud config set component_manager/disable_update_check true \
  && gcloud config set metrics/environment github_docker_image