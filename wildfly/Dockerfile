ARG WILDFLY_TAG=${WILDFLY_TAG:-'release-v1.7.12a.0002'}
FROM i2b2/i2b2-wildfly:${WILDFLY_TAG}

ENV TZ=America/New_York
USER jboss
RUN sed -i 's/-Xms64m -Xmx512m/-Xms256m -Xmx1g/' /opt/jboss/wildfly/bin/appclient.conf
RUN sed -i 's/-Xms64m -Xmx512m/-Xms256m -Xmx1g/' /opt/jboss/wildfly/bin/standalone.conf

USER root
## Override entrypoint for custom initialisation...
COPY ./bootstrap-wildfly.sh /root/bin/bootstrap.sh
ENTRYPOINT ["/root/bin/bootstrap.sh"]
