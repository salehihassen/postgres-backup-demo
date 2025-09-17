FROM alpine:latest

RUN apk add --no-cache postgresql-client bash

COPY pgdump-cron.sh /usr/local/bin/pgdump-cron.sh
RUN chmod +x /usr/local/bin/pgdump-cron.sh

COPY cronjob /etc/crontabs/root

CMD ["crond", "-f", "-L", "/dev/stdout"]
