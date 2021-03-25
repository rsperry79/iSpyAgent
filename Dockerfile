ARG REPO=mcr.microsoft.com/dotnet/runtime-deps
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-bionic-arm64v8
ENV DEFAULT_FILE_LOCATION="https://www.ispyconnect.com/api/Agent/DownloadLocation2?productID=24&is64=true&platform=ARM"
ARG DEBIAN_FRONTEND=noninteractive 
ARG TZ=America/Los_Angeles

RUN apt update \
    && apt install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Download and install dependencies
RUN apt update && \ 
    apt install -y \
        wget libtbb-dev libc6-dev unzip multiarch-support gss-ntlmssp software-properties-common \
        libtbb-dev libc6-dev gss-ntlmssp libgdiplus tzdata

# Install jonathon's ffmpeg
RUN add-apt-repository ppa:jonathonf/ffmpeg-4 -y && \
    apt update && \ 
    apt install -y ffmpeg

# Run upgrade
RUN apt update && apt upgrade -y 

# Download/Install iSpy Agent DVR
RUN curl -l  $(curl  ${DEFAULT_FILE_LOCATION} |  grep https| tr -d '"') -o agent.zip && unzip agent.zip -d /agent && rm agent.zip;

# Cleanup
RUN apt -y --purge remove unzip wget \ 
    && apt autoremove -y \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Docker needs to run a TURN server to get webrtc traffic to and from it over forwarded ports from the host
# These are the default ports. If the ports below are modified here you'll also need to set the ports in XML/Config.xml
# for example <TurnServerPort>3478</TurnServerPort><TurnServerMinPort>50000</TurnServerMinPort><TurnServerMaxPort>50010</TurnServerMaxPort>
# The main server port is overridden by creating a text file called port.txt in the root directory containing the port number, eg: 8090
# To access the UI you must use the local IP address of the host, NOT localhost - for example http://192.168.1.12:8090/

# Define default environment variables
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Main UI port
EXPOSE 8090

# TURN server port
EXPOSE 3478/udp

# TURN server UDP port range
EXPOSE 50000-50010/udp

# Data volumes
VOLUME ["/agent/Media/XML", "/agent/Media/WebServerRoot/Media", "/agent/Commands"]

# Define service entrypoint
CMD ["dotnet", "/agent/Agent.dll"]