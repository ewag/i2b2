ARG WEB_TAG
FROM i2b2/i2b2-web:${WEB_TAG}

WORKDIR /docker-entrypoint
## Run some generic fixes
RUN cd /var/www/html/ && \
    grep -rl "if (response.transport.statusText==\"OK\") {" * | xargs sed -i 's/if (response.transport.statusText=="OK") {/if (response.transport.status == 200) {/g' && \
    ls -1 {admin,webclient}/index.php | xargs sed -i 's*$pmURL = "http://127.0.0.1:8080/i2b2/rest/PMService/getServices";*$pmURL = "http://i2b2-wildfly:8080/i2b2/rest/PMService/getServices";*g' && \
    find  . -maxdepth 2 -type f -name i2b2_config_data.js -exec sed -i 's*urlCellPM: "http://services.i2b2.org/i2b2/services/PMService/",*urlCellPM: "http://i2b2-wildfly:8080/i2b2/services/PMService/",*g' {} \; && \
    sed -i -e 's*{ code: "ONT"   },*//{ code: "ONT"   },*g' -e 's*{ code: "CRC"   },*//{ code: "CRC"   },*g' -e 's*{ code: "WORK"   },*//{ code: "WORK"   },*g' admin/js-i2b2/i2b2_loader.js

COPY ./bootstrap-web.sh ./bootstrap.sh
COPY ./conf ./conf

## Override entrypoint for custom initialisation...
ENTRYPOINT ["/docker-entrypoint/bootstrap.sh"]
