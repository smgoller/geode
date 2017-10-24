#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

git clone -b develop --depth 1 https://github.com/apache/geode.git geode


# Seeing downloaded still...
#:rat
#Download https://repo1.maven.org/maven2/commons-cli/commons-cli/1.2/commons-cli-1.2.jar
#Download https://repo1.maven.org/maven2/commons-cli/commons-cli/1.2/commons-cli-1.2.pom
#Download https://repo1.maven.org/maven2/commons-collections/commons-collections/3.2.1/commons-collections-3.2.1.jar
#Download https://repo1.maven.org/maven2/commons-collections/commons-collections/3.2.1/commons-collections-3.2.1.pom
#Download https://repo1.maven.org/maven2/commons-io/commons-io/2.2/commons-io-2.2.jar
#Download https://repo1.maven.org/maven2/commons-io/commons-io/2.2/commons-io-2.2.pom
#Download https://repo1.maven.org/maven2/org/apache/commons/commons-compress/1.5/commons-compress-1.5.jar
#Download https://repo1.maven.org/maven2/org/apache/commons/commons-compress/1.5/commons-compress-1.5.pom
#Download https://repo1.maven.org/maven2/org/apache/commons/commons-parent/28/commons-parent-28.pom
#Download https://repo1.maven.org/maven2/org/apache/commons/commons-parent/9/commons-parent-9.pom
#Download https://repo1.maven.org/maven2/org/apache/rat/apache-rat-core/0.11/apache-rat-core-0.11.jar
#Download https://repo1.maven.org/maven2/org/apache/rat/apache-rat-core/0.11/apache-rat-core-0.11.pom
#Download https://repo1.maven.org/maven2/org/apache/rat/apache-rat-project/0.11/apache-rat-project-0.11.pom
#Download https://repo1.maven.org/maven2/org/apache/rat/apache-rat-tasks/0.11/apache-rat-tasks-0.11.jar
#Download https://repo1.maven.org/maven2/org/apache/rat/apache-rat-tasks/0.11/apache-rat-tasks-0.11.pom
#Download https://repo1.maven.org/maven2/org/slf4j/slf4j-jdk14/1.7.24/slf4j-jdk14-1.7.24.jar
#Download https://repo1.maven.org/maven2/org/slf4j/slf4j-jdk14/1.7.24/slf4j-jdk14-1.7.24.pom
pushd geode
  cat << EOF >> build.gradle
  subprojects {
    task getDeps(type: Copy) {
      from project.sourceSets.main.runtimeClasspath
      from project.sourceSets.test.runtimeClasspath
      from configurations.testRuntime
      into 'runtime/'
    }
  }
EOF
./gradlew --parallel --no-daemon getDeps

popd

rm -rf geode
