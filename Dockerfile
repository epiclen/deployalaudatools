FROM alpine

RUN mkdir /deploytools

ADD tools /deploytools/tools
ADD install_gitlab.sh /deploytools/install_gitlab.sh
ADD install_harbor.sh /deploytools/install_harbor.sh
ADD install_jenkins.sh /deploytools/install_jenkins.sh
ADD install_nexus.sh /deploytools/install_nexus.sh
ADD install_sonar.sh /deploytools/install_sonar.sh