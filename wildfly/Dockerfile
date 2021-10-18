ARG WILDFLY_TAG
FROM i2b2/i2b2-wildfly:${WILDFLY_TAG}

## Override entrypoint for custom initialisation...
COPY ./bootstrap-wildfly.sh /root/bin/bootstrap.sh
ENTRYPOINT ["/root/bin/bootstrap.sh"]
