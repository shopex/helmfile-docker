FROM alpine:3.11

ARG KUBECTL_VERSION=1.14.6
ARG HELM_VERSION=2.16.5
ARG HELM_DIFF_VERSION=2.11.0+5
ARG HELM_SECRETS_VERSION=1.3.1
ARG HELMFILE_VERSION=0.98.2

ENV HELM_FILE_NAME helm-v${HELM_VERSION}-linux-amd64.tar.gz

LABEL version="${HELMFILE_VERSION}-${HELM_VERSION}-${KUBECTL_VERSION}"

WORKDIR /

RUN apk --update --no-cache add bash ca-certificates git gnupg curl gettext 
# python3 jq && pip3 install gitpython~=2.1.11 requests~=2.22.0 PyYAML~=5.1.1 awscli

ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

ADD http://storage.googleapis.com/kubernetes-helm/${HELM_FILE_NAME} /tmp
RUN tar -zxvf /tmp/${HELM_FILE_NAME} -C /tmp \
  && mv /tmp/linux-amd64/helm /bin/helm \
  && rm -rf /tmp/* \
  && /bin/helm init --client-only

RUN mkdir -p "$(helm home)/plugins" && \
    helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION} && \
    helm plugin install https://github.com/futuresimple/helm-secrets --version ${HELM_SECRETS_VERSION}

ADD https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64 /bin/helmfile
RUN chmod 0755 /bin/helmfile

# ENTRYPOINT ["/bin/helmfile"]
