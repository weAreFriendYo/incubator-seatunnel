#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -eu
# resolve links - $0 may be a softlink
PRG="$0"

while [ -h "$PRG" ] ; do
  # shellcheck disable=SC2006
  ls=`ls -ld "$PRG"`
  # shellcheck disable=SC2006
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    # shellcheck disable=SC2006
    PRG=`dirname "$PRG"`/"$link"
  fi
done

PRG_DIR=`dirname "$PRG"`
APP_DIR=`cd "$PRG_DIR/.." >/dev/null; pwd`
CONF_DIR=${APP_DIR}/config
APP_JAR=${APP_DIR}/starter/seatunnel-starter.jar
APP_MAIN="org.apache.seatunnel.core.starter.seatunnel.SeaTunnelServer"
OUT="${APP_DIR}/logs/seatunnel-server.out"

if [ -f "${CONF_DIR}/seatunnel-env.sh" ]; then
    . "${CONF_DIR}/seatunnel-env.sh"
fi

if [ $# == 0 ]
then
    args=""
else
    args=$@
fi

set +u
# SeaTunnel Engine Config
if [ -z $HAZELCAST_CONFIG ]; then
  HAZELCAST_CONFIG=${CONF_DIR}/hazelcast.yaml
fi

if [ -z $SEATUNNEL_CONFIG ]; then
    SEATUNNEL_CONFIG=${CONF_DIR}/seatunnel.yaml
fi

if test ${JvmOption} ;then
    JAVA_OPTS="${JAVA_OPTS} ${JvmOption}"
fi

for i in "$@"
do
  if [[ "${i}" == *"JvmOption"* ]]; then
    JVM_OPTION="${i}"
    JAVA_OPTS="${JAVA_OPTS} ${JVM_OPTION#*=}"
  elif [[ "${i}" == "-d" || "${i}" == "--daemon" ]]; then
    DAEMON=true
  elif [[ "${i}" == "-h" || "${i}" == "--help" ]]; then
    HELP=true
  fi
done

JAVA_OPTS="${JAVA_OPTS} -Dseatunnel.config=${SEATUNNEL_CONFIG}"
JAVA_OPTS="${JAVA_OPTS} -Dhazelcast.config=${HAZELCAST_CONFIG}"

# Log4j2 Config
JAVA_OPTS="${JAVA_OPTS} -Dlog4j2.contextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector"
if [ -e "${CONF_DIR}/log4j2.properties" ]; then
  JAVA_OPTS="${JAVA_OPTS} -Dlog4j2.configurationFile=${CONF_DIR}/log4j2.properties"
  JAVA_OPTS="${JAVA_OPTS} -Dseatunnel.logs.path=${APP_DIR}/logs"
  JAVA_OPTS="${JAVA_OPTS} -Dseatunnel.logs.file_name=seatunnel-engine-server"
fi

CLASS_PATH=${APP_DIR}/lib/*:${APP_JAR}

ST_TMPDIR=`java -cp ${CLASS_PATH} org.apache.seatunnel.core.starter.seatunnel.jvm.TempDirectory`
# The JVM options parser produces the final JVM options to start seatunnel-engine.
JVM_OPTIONS=`java -cp ${CLASS_PATH} org.apache.seatunnel.core.starter.seatunnel.jvm.JvmOptionsParser ${CONF_DIR}/jvm_options`
JAVA_OPTS="${JAVA_OPTS} ${JVM_OPTIONS//\$\{loggc\}/${ST_TMPDIR}}"
echo "JAVA_OPTS:" ${JAVA_OPTS}

if [[ $DAEMON == true && $HELP == false ]]; then
 touch $SEATUNNEL_HOME/logs/seatunnel-server.out
 java ${JAVA_OPTS} -cp ${CLASS_PATH} ${APP_MAIN} ${args} > "$OUT" 200<&- 2>&1 < /dev/null &
 else
 java ${JAVA_OPTS} -cp ${CLASS_PATH} ${APP_MAIN} ${args}
fi

