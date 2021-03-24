ARG arch

ARG REPO=mcr.microsoft.com/dotnet/runtime-deps
FROM $REPO:3.1-buster-slim-${arch}v8

# RUN apt-get update \
#     && apt-get install -y --no-install-recommends 

# Install .NET Core
RUN dotnet_version=3.1.0 \
    && curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Runtime/$dotnet_version/dotnet-runtime-$dotnet_version-linux-arm64.tar.gz \
    && mkdir -p /usr/share/dotnet \
    && tar -ozxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

    #Define download location variables
ARG FILE_LOCATION="https://ispyfiles.azureedge.net/downloads/Agent_ARM64_3_2_4_0.zip"
ENV FILE_LOCATION_SET=${FILE_LOCATION:+true}
ENV DEFAULT_FILE_LOCATION="https://www.ispyconnect.com/api/Agent/DownloadLocation2?productID=24&is64=true&platform=Arm64"
ARG DEBIAN_FRONTEND=noninteractive 
ARG TZ=America/Los_Angeles
    

# Download and install dependencies
RUN apt update \
    # && rm libjpeg8_8c-2ubuntu8_arm64.deb \
    && apt-get install -y wget libtbb-dev libc6-dev unzip multiarch-support gss-ntlmssp software-properties-common libjpeg62-turbo  
    # && wget http://security.ubuntu.com/ubuntu/pool/main/libj/libjpeg-turbo/libjpeg-turbo8_1.5.2-0ubuntu5.18.04.4_arm64.deb \
    # && wget http://fr.archive.ubuntu.com/ubuntu/pool/main/libj/libjpeg8-empty/libjpeg8_8c-2ubuntu8_arm64.deb \
    # && dpkg -i libjpeg-turbo8_1.5.2-0ubuntu5.18.04.4_arm64.deb \
    # && dpkg -i libjpeg8_8c-2ubuntu8_arm64.deb \
    # && rm libjpeg8_8c-2ubuntu8_arm64.deb \
    # && rm libjpeg-turbo8_1.5.2-0ubuntu5.18.04.4_arm64.deb

RUN apt-get install -y libtbb-dev libc6-dev gss-ntlmssp

# # Install ffmpeg
# RUN apt-get install snapd -y


# RUN snap install core \
#     snap install ffmpeg 

# Download/Install iSpy Agent DVR: 
# Check if we were given a specific version

RUN if [ "${FILE_LOCATION_SET}" = "true" ]; then \
    echo "Downloading from specific location: ${FILE_LOCATION}" && \
    wget -c ${FILE_LOCATION} -O agent.zip; \
    else \
    #Get latest instead
    echo "Downloading latest" && \
    wget -c $(wget -qO- "https://www.ispyconnect.com/api/Agent/DownloadLocation2?productID=24&is64=true&platform=${arch}" | tr -d '"') -O agent.zip; \
    fi && \
    unzip agent.zip -d /agent && \
    rm agent.zip
    
# Install libgdiplus, used for smart detection
RUN apt-get install -y libgdiplus
    
# Install Time Zone
RUN apt-get install -y tzdata

# Clean up
RUN apt-get -y --purge remove unzip wget \ 
    && apt autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# RUN apt-get install -y libvlc-dev vlc libx11-dev

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