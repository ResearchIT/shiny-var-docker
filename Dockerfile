FROM researchit/shiny-server:openshift
LABEL maintainer="Levi Baber <baber@iastate.edu>"


ENV \
    # DEPRECATED: Use above LABEL instead, because this will be removed in future versions.
    STI_SCRIPTS_URL=image:///usr/libexec/s2i \
    # Path to be used in other layers to place s2i scripts into
    STI_SCRIPTS_PATH=/usr/libexec/s2i \
    APP_ROOT=/opt/app-root \
    # The $HOME is not set by default, but some applications needs this variable
    HOME=/opt/app-root/ \
    PATH=/opt/app-root/:$PATH

USER 0
#system dependencies for R packages
RUN yum -y install libxml2-devel libcurl-devel openssl-devel v8-devel
RUN yum -y install nss_wrapper
RUN yum -y install nfs-utils

#R dependencies
RUN Rscript -e "install.packages(c('data.table','ontologyIndex','jsonlite','DT','shiny','WhopGenome'), repos='https://cran.rstudio.com/')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R')" -e "biocLite(c('GenomicFeatures'))"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R')" -e "biocLite(c('Rsamtools'))"

#shiny-server config file changes
RUN sed -i -e 's/run_as 1001;/run_as openshift;/g' /etc/shiny-server/shiny-server.conf;
RUN sed -i -e 's|/opt/app-root|/opt/app-root/src/app|g' /etc/shiny-server/shiny-server.conf

#perms
RUN chmod -R o+w /var/log/shiny-server
RUN chmod g+w /var/lib/shiny-server

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy the passwd template for nss_wrapper
COPY passwd.template /tmp/passwd.template

USER 1001
CMD ["/usr/libexec/s2i/run"]
