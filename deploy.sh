#!/bin/sh

#UUID="42428b37-a05c-4258-bef0-7fafcbc78d05"
#APP_NAME="www"

REGION="hkg"

if ! command -v flyctl >/dev/null 2>&1; then
    printf '\e[33mCould not resolve command - koyebctl. So, install koyeb first.\n\e[0m'
    curl -L https://raw.githubusercontent.com/koyeb/koyeb-cli/master/install.sh | sh | KOYEBCTL_INSTALL=/usr/local sh
fi

if [ -z "${APP_NAME}" ]; then
    printf '\e[31mPlease set APP_NAME first.\n\e[0m' && exit 1
fi

flyctl info --app "${APP_NAME}" >/tmp/${APP_NAME} 2>&1;
if [ "$(cat /tmp/${APP_NAME} | grep -o "Could not resolve App")" = "Could not resolve App" ]; then
    printf '\e[33mCould not resolve app. Next, create the App.\n\e[0m'
    flyctl apps create "${APP_NAME}" >/dev/null 2>&1;

    flyctl info --app "${APP_NAME}" >/tmp/${APP_NAME} 2>&1;
    if [ "$(cat /tmp/${APP_NAME} | grep -o "Could not resolve App")" != "Could not resolve App" ]; then
        printf '\e[32mCreate app success.\n\e[0m'
    else
        printf '\e[31mCreate app failed.\n\e[0m' && exit 1
    fi
else
    printf '\e[33mThe app has been created.\n\e[0m'
fi

printf '\e[33mNext, create app config file - fly.toml.\n\e[0m'
cat <<EOF >./fly.toml
app = "$APP_NAME"

kill_signal = "SIGINT"
kill_timeout = 5
processes = []

[env]

[experimental]
  allowed_public_ports = []
  auto_rollback = true

[[services]]
  http_checks = []
  internal_port = 443
  # processes = ["app"]
  protocol = "tcp"
  script_checks = []

  [services.concurrency]
    hard_limit = 50
    soft_limit = 35
    type = "connections"

  [[services.ports]]
    handlers = ["http"]
    port = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443

  [[services.tcp_checks]]
    grace_period = "120s"
    interval = "15s"
    restart_limit = 0
    timeout = "2s"
EOF
printf '\e[32mCreate app config file success.\n\e[0m'
printf '\e[33mNext, set app secrets and regions.\n\e[0m'

flyctl secrets set UUID="${UUID}"
flyctl regions set ${REGION}
printf '\e[32mApp secrets and regions set success. Next, deploy the app.\n\e[0m'
flyctl deploy --detach
# flyctl status --app ${APP_NAME}
