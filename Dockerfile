FROM centos:7

RUN yum clean all -y && yum makecache fast && yum update -y \
 && yum install -y epel-release \
 && yum clean all -y \
 && rm -rf /var/cache/yum

ENV JAVA_VERSION 1.8.0_sr6fp26

RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "${ARCH}" in \
      amd64|x86_64) \
        ESUM='c51b7afed4911a4eefdf02c44ee440de726a5a605c5507cc50d4795394b418c2'; \
        YML_FILE='sdk/linux/x86_64/index.yml'; \
        ;; \
      i386) \
        ESUM='dfe87d34c40cd0c23dc4b7ee47c85f84e26d21ff75476b234998bb9132379659'; \
        YML_FILE='sdk/linux/i386/index.yml'; \
        ;; \
      ppc64el|ppc64le) \
        ESUM='bbc55934ec867290cd9307422beae48e5032dfabb7cb496bed6e47b7ab3f90be'; \
        YML_FILE='sdk/linux/ppc64le/index.yml'; \
        ;; \
      s390) \
        ESUM='a1ed2722f283a3f3eb0a71f23354b0b4d2761865e759a3bf7f89297e17c20e6f'; \
        YML_FILE='sdk/linux/s390/index.yml'; \
        ;; \
      s390x) \
        ESUM='c2ddf185daafacd0b50f3e4e593d613b2e9b70d66b88a8da6ee313181376aef6'; \
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
