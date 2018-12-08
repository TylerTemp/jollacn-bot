#!/usr/bin/env bash
IP="$1"
USER="root"

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
PROJECTPATH="$(dirname ${SCRIPTPATH})"
PROJECTDIR="$(basename ${PROJECTPATH})"

cd PROJECTPATH;

export version="$(cat mix.exs | grep version | awk '{print substr($2, 2, length($2)-3)}')"
echo "version=${version}"

echo "upgrade"
MIX_ENV=prod mix release --upgrade --env=prod
mkdir -p ${HOME}/release/${PROJECTDIR}/releases/${version} && cp _build/prod/rel/jollacn_bot/releases/${version}/jollacn_bot.tar.gz ~/release/${PROJECTDIR}/releases/${version}/jollacn_bot.tar.gz

echo "do upgrade"
cd ${HOME}/release/${PROJECTDIR}
bin/jollacn_bot upgrade "${version}"
