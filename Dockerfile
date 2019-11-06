FROM centos:7

RUN yum clean all -y && yum makecache fast && yum update -y \
 && yum install -y epel-release \
 && yum clean all -y \
 && rm -rf /var/cache/yum

ENV JAVA_VERSION 1.8.0_sr5fp41

RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "${ARCH}" in \
      amd64|x86_64) \
        ESUM='6545147d99ed83124eb6f0091b262d97089ba41b2c8c7d8adc7836836af29658'; \
        YML_FILE='sdk/linux/x86_64/index.yml'; \
        ;; \
      i386) \
        ESUM='1aaf206c6eeb9d6501b4006c081fb2cf30f6d2ef2ce5568ba04e2ac42e897f77'; \
        YML_FILE='sdk/linux/i386/index.yml'; \
        ;; \
      ppc64el|ppc64le) \
        ESUM='c625e54e80dd3e743dca0507708bcaee3435cfb7d1efc5960299449a4693a60b'; \
        YML_FILE='sdk/linux/ppc64le/index.yml'; \
        ;; \
      s390) \
        ESUM='38e07d464b89ae594dd049e89bc04fe0c6adce0e65dba926fc26f27c0cb93b94'; \
        YML_FILE='sdk/linux/s390/index.yml'; \
        ;; \
      s390x) \
        ESUM='cd99fbfc86e3236d0de885890652ce0f5b7e4194a157aff6c8619b600fe0a934'; \
        YML_FILE='sdk/linux/s390x/index.yml'; \
        ;; \
      *) \
        echo "Unsupported arch: ${ARCH}"; \
        exit 1; \
        ;; \
    esac; \
    BASE_URL="https://public.dhe.ibm.com/ibmdl/export/pub/systems/cloud/runtimes/java/meta/"; \
    curl -s -A UA_IBM_JAVA_Docker -o /tmp/index.yml ${BASE_URL}/${YML_FILE}; \
    JAVA_URL=$(sed -n '/^'${JAVA_VERSION}:'/{n;s/\s*uri:\s//p}'< /tmp/index.yml); \
    curl -s -A UA_IBM_JAVA_Docker -o /tmp/ibm-java.bin ${JAVA_URL}; \
    echo "${ESUM}  /tmp/ibm-java.bin" | sha256sum -c -; \
    echo "INSTALLER_UI=silent" > /tmp/response.properties; \
    echo "USER_INSTALL_DIR=/opt/ibm/java" >> /tmp/response.properties; \
    echo "LICENSE_ACCEPTED=TRUE" >> /tmp/response.properties; \
    mkdir -p /opt/ibm; \
    chmod +x /tmp/ibm-java.bin; \
    /tmp/ibm-java.bin -i silent -f /tmp/response.properties; \
    rm -f /tmp/response.properties; \
    rm -f /tmp/index.yml; \
    rm -f /tmp/ibm-java.bin; \
    chown -R root.root /opt/ibm/java/jre; \
    rm -rf /opt/ibm/java/{demo,sample}; \
    chmod -x /opt/ibm/java/{copyright,*.txt,release,src.zip}; \
    chmod -x /opt/ibm/java/Logs/*; \
    find /opt/ibm/java/docs -type f -perm 0775 -print0 | xargs -0 chmod -x; \
    find /opt/ibm/java/include -type f -perm 0775 -print0 | xargs -0 chmod -x; \
    chmod -x /opt/ibm/java/jre/.systemPrefs/{.system.lock,.systemRootModFile}; \
    find /opt/ibm/java/jre/lib -type f -perm 0755 -print0 | xargs -0 chmod -x; \
    find /opt/ibm/java/jre/lib -name '*.so' -type f -perm 0644 -print0 | xargs -0 chmod +x; \
    chmod -x /opt/ibm/java/jre/plugin/desktop/*; \
    chmod -x /opt/ibm/java/lib/{*.jar,*.idl};

ENV JAVA_HOME=/opt/ibm/java/jre \
    PATH=/opt/ibm/java/jre/bin:$PATH \
    IBM_JAVA_OPTIONS="-XX:+UseContainerSupport"
