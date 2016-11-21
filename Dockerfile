### docker build --pull -t acme/starter-systemd -t acme/starter-systemd:v3.2 .
FROM registry.access.redhat.com/rhel7
MAINTAINER Red Hat Systems Engineering <refarch-feedback@redhat.com>

### Default to UTF-8 file.encoding
ENV LANG en_US.utf8
### Set the JAVA_HOME variable to make it clear where Java is located
ENV JAVA_HOME /usr/lib/jvm/jre

### Atomic/OpenShift Labels
### https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL Name="acme/starter-systemd" \
      Vendor="Acme Corp" \
      Version="3.2" \
      Release="7" \
      build-date="2016-10-12T14:12:54.553894Z" \
      url="https://www.acme.io" \
      summary="Acme Corp's Starter App" \
      description="Starter App will do ....." \
      RUN='docker run -tdi --name ${NAME} \
      -p 8080:80 \
      -p 8443:443 \
      ${IMAGE}' \
      STOP='docker stop ${NAME}' \
      io.k8s.description="Starter App will do ....." \
      io.k8s.display-name="Starter App" \
      io.openshift.expose-services="8080:http,8443:https" \
      io.openshift.tags="Acme,starter,starterapp"

### Atomic Help File - Write in Markdown, it will be converted to man format at build time.
### https://github.com/projectatomic/container-best-practices/blob/master/creating/help.adoc
COPY help.md user_setup systemd_setup /tmp/

RUN yum clean all && \
    yum -y update-minimal --security \
                          --sec-severity=Important \
                          --sec-severity=Critical \
                          --setopt=tsflags=nodocs \
                          --disablerepo "*" \
                          --enablerepo rhel-7-server-rpms,rhel-7-server-optional-rpms,rhel-7-server-thirdparty-oracle-java-rpms && \
    yum -y install --disablerepo "*" \
                   --enablerepo rhel-7-server-rpms,rhel-7-server-optional-rpms,rhel-7-server-thirdparty-oracle-java-rpms \
                   --setopt=tsflags=nodocs java-1.8.0-oracle hostname strace redhat-lsb-core && \
    yum clean all
    
 

#RUN yum clean all && \
#    yum-config-manager --disable \* && \
### Add necessary Red Hat repos here
#    yum-config-manager --enable rhel-7-server-rpms,rhel-7-server-optional-rpms && \
#    yum-config-manager --enable rhel-7-server-thirdparty-oracle-java-rpms && \    
#    yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical --setopt=tsflags=nodocs && \
### help markdown to man conversion
### Add your package needs to this installation line
#    yum -y install --setopt=tsflags=nodocs golang-github-cpuguy83-go-md2man cronie java-1.8.0-oracle && \
#    go-md2man -in /tmp/help.md -out /help.1 && yum -y remove golang-github-cpuguy83-go-md2man && \
#    yum clean all

### Setup user for build execution and application runtime
#ENV APP_ROOT=/opt/app-root \
#    USER_NAME=default \
#    USER_UID=10001
#ENV APP_HOME=${APP_ROOT}/src  PATH=$PATH:${APP_ROOT}/bin
#RUN mkdir -p ${APP_HOME} ${APP_ROOT}/etc
#COPY bin/ ${APP_ROOT}/bin/
#RUN chmod -R ug+x ${APP_ROOT}/bin ${APP_ROOT}/etc /tmp/user_setup /tmp/systemd_setup && \
#    /tmp/user_setup

####### Add app-specific needs below. #######
### these are systemd requirements
### To cleanly shutdown systemd, use SIGRTMIN+3
STOPSIGNAL SIGRTMIN+3
ENV container=docker
RUN systemctl set-default multi-user.target
#    systemctl enable crond
#    /tmp/systemd_setup

COPY ./rpm/CARKaim-9.70.0.3.x86_64.rpm /tmp/
COPY credfile Vault.ini /  
COPY aimparms /var/tmp/

RUN yum -y localinstall /tmp/CARKaim-9.70.0.3.x86_64.rpm && \
    cat /var/tmp/opm-install-logs/CreateEnv.log

### Containers should NOT run as root as a best practice
#USER ${USER_UID}
#WORKDIR ${APP_ROOT}
EXPOSE 18923 18924
### arbitrary uid recognition at runtime
#RUN sed "s@${USER_NAME}:x:${USER_UID}:0@${USER_NAME}:x:\${USER_ID}:\${GROUP_ID}@g" \
#        /etc/passwd > ${APP_ROOT}/etc/passwd.template

CMD ["/opt/CARKaim/bin/opmd","-mode","SERVICE"]