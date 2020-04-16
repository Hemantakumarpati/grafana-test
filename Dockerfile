FROM ubuntu:19.10
 
 EXPOSE 3000
  
  ARG GF_UID="472"
  ARG GF_GID="472"
  
  ENV PATH="/usr/share/grafana/bin:$PATH" \
      GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
      GF_PATHS_DATA="/var/lib/grafana" \
      GF_PATHS_HOME="/usr/share/grafana" \
      GF_PATHS_LOGS="/var/log/grafana" \
      GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
      GF_PATHS_PROVISIONING="/etc/grafana/provisioning"
  
  WORKDIR $GF_PATHS_HOME
  
  COPY conf conf
  
  # We need font libs for phantomjs, and curl should be part of the image
  RUN apt-get update && apt-get upgrade -y && apt-get install -y ca-certificates libfontconfig1 curl
  
  RUN mkdir -p "$GF_PATHS_HOME/.aws" && \
    addgroup --system --gid $GF_GID grafana && \
    adduser --uid $GF_UID --system --ingroup grafana grafana && \
    mkdir -p "$GF_PATHS_PROVISIONING/datasources" \
               "$GF_PATHS_PROVISIONING/dashboards" \
               "$GF_PATHS_PROVISIONING/notifiers" \
               "$GF_PATHS_LOGS" \
               "$GF_PATHS_PLUGINS" \
               "$GF_PATHS_DATA" && \
      cp conf/sample.ini "$GF_PATHS_CONFIG" && \
      cp conf/ldap.toml /etc/grafana/ldap.toml && \
      chown -R grafana:grafana "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" "$GF_PATHS_PROVISIONING" && \
      chmod -R 777 "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" "$GF_PATHS_PROVISIONING"
  
  # PhantomJS
  COPY --from=js-builder /usr/local/bin/phantomjs /usr/local/bin/
  
  COPY --from=go-builder /src/grafana/bin/linux-amd64/grafana-server /src/grafana/bin/linux-amd64/grafana-cli bin/
  COPY --from=js-builder /usr/src/app/public public
  COPY --from=js-builder /usr/src/app/tools tools
  
  COPY tools/phantomjs/render.js tools/phantomjs/
  COPY packaging/docker/run.sh /
  
  USER grafana
  ENTRYPOINT [ "/run.sh" ]
