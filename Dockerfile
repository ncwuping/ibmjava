FROM centos:7

RUN yum clean all -y && yum makecache fast && yum update -y \
 && yum install -y epel-release \
 && yum clean all -y \
 && rm -rf /var/cache/yum

ENV JAVA_VERSION 1.8.0_sr6fp20

RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "${ARCH}" in \
      amd64|x86_64) \
        ESUM='367a777afa71945eeaf623ff4f04d5dcd930eac2c1a234adbba4afe2d88926c1'; \
        YML_FILE='sdk/linux/x86_64/index.yml'; \
        ;; \
      i386) \
        ESUM='a0e7eb3a68c2883e62b4a34e45c59c3f2880cfe57dbff09484c6b18fc2925e68'; \
        YML_FILE='sdk/linux/i386/index.yml'; \
        ;; \
      ppc64el|ppc64le) \
        ESUM='4a7ac4712548d7630f2471a067406c94c3846fff75a0afc660682129dcf80e5b'; \
        YML_FILE='sdk/linux/ppc64le/index.yml'; \
        ;; \
      s390) \
        ESUM='e6b476694cef95a2653a823dc5ed8e662ea08c975fe8564672385b5346ba29fe'; \
        YML_FILE='sdk/linux/s390/index.yml'; \
        ;; \
      s390x) \
        ESUM='17fad00b25231a85d15d681db2329f54d95cab48c1bab6bcd23b6306ad60d785'; \
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
