FROM bitnami/mongodb:5.0.18

USER root

WORKDIR /usr/bin/bash
COPY ./build/BackupJob/bin/backup.sh ./
RUN chmod +x ./backup.sh

USER 1001

ENTRYPOINT [ "/usr/bin/bash/backup.sh" ]