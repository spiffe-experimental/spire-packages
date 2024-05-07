#!/bin/bash

# This script is used to test the spire-agent and spire-server RPMs in a Docker container.
# This makes it easy to check that the RPM really works on several major RPM-based distributions.
# The script takes three arguments:
# 1. Docker image name
# 2. Path to spire-agent RPM
# 3. Path to spire-server RPM

# Function to install RPM
install_deb() {
    docker exec $container_id /bin/bash -c "dpkg -i /pkg/$1"
    if [ $? -ne 0 ]; then
        echo "Failed to install $1"
        exit 1
    else
        echo "$1 installed successfully."
    fi
}

install_rpm() {
    # RPM had an issue running systemd commands from RPM scripts without having a full
    # interactive shell. Hence running this inside bash -c. 
    docker exec $container_id /bin/bash -c "rpm -vv -i /pkg/$1"
    if [ $? -ne 0 ]; then
        echo "Failed to install $1"
        exit 1
    else
        echo "$1 installed successfully."
    fi
    # Assuming a simple test that just checks rpm is installed
    docker exec $container_id rpm -q /pkg/$1
    if [ $? -ne 0 ]; then
        echo "Testing $1 failed."
        exit 1
    else
        echo "$1 installed successfully."
    fi
}

# Function to test RPM
test_package() {
    # Verify that expected files are present
    for file in "${expected_files[@]}"; do 
        docker exec $container_id test -f $file
        if [ $? -ne 0 ]; then
            echo "Expected file $file is missing after installing $1."
            exit 1
        fi
    done
    echo "All expected files for $1 are present."
}

# test binaries
test_spire_agent() {
    # Run the binary and capture the output
    OUTPUT=$(docker exec $container_id /usr/bin/spire-agent 2>&1)
    EXIT_CODE=$?

    # Check the exit code and specific words in the output
    if [[ $EXIT_CODE -eq 127 ]] && [[ $OUTPUT == *"Usage: spire-agent"* ]]; then
        echo "spire-agent ran with expected output and exit code."
    else
        echo "spire-agent did not run as expected."
        echo "Output: $OUTPUT"
        echo "Exit Code: $EXIT_CODE"
        exit 1 
    fi
}

test_spire_server() {
    # Run the binary and capture the output
    OUTPUT=$(docker exec $container_id /usr/bin/spire-server 2>&1)
    EXIT_CODE=$?

    # Check the exit code and specific words in the output
    if [[ $EXIT_CODE -eq 127 ]] && [[ $OUTPUT == *"Usage: spire-server"* ]]; then
        echo "spire-server ran with expected output and exit code."
    else
        echo "spire-server did not run as expected."
        echo "Output: $OUTPUT"
        echo "Exit Code: $EXIT_CODE"
        exit 1 
    fi
}

# Function to uninstall RPM
uninstall_rpm() {
    docker exec $container_id rpm -e $1
    if [ $? -ne 0 ]; then
        echo "Failed to uninstall $1"
        exit 1
    else
        echo "$1 uninstalled successfully."
    fi
}

uninstall_deb() {
    docker exec $container_id apt-get remove -y $1
    if [ $? -ne 0 ]; then
        echo "Failed to uninstall $1"
        exit 1
    else
        echo "$1 uninstalled successfully."
    fi
}

# Check if all arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <container_image> <agent_rpm> <server_rpm>"
    exit 1
fi

# TODO add more files here
declare -a agent_files=("/usr/bin/spire-agent")
declare -a server_files=("/usr/bin/spire-server")

container_image=$1
agent_pkg=$2
server_pkg=$3

find . 
find /pkg

# Check if RPM files exist
if [ ! -f "$agent_pkg" ] || [ ! -f "$server_pkg" ]; then
    echo "Specified files do not exist."
    exit 1
fi

# Pull Docker image
echo "Pulling Docker image: $container_image"
docker pull $container_image
if [ $? -ne 0 ]; then
    echo "Failed to pull Docker image: $container_image"
    exit 1
fi

# Start container
echo "Starting container..."
find . 
container_id=$(docker run -d -v $(pwd):/pkg --rm $container_image /bin/bash -c "while true; do sleep 1; done")
echo "Container started with ID: $container_id"

# Install systemd 
echo "Installing systemd..."
docker exec $container_id /bin/bash -c "dnf install -y systemd || zypper install -y systemd || yum install -y systemd || (apt-get update && apt-get install -y systemd)"

if [[ "$agent_pkg" == *.rpm && "$server_pkg" == *.rpm ]]; then
    echo "Detected RPM packages"
    # Install, test, and uninstall agent
    install_rpm $agent_pkg
    test_rpm spire-agent
    uninstall_rpm spire-agent

    # Install, test, and uninstall server
    install_rpm $server_pkg
    test_rpm spire-server
    uninstall_rpm spire-server
elif [[ "$agent_pkg" == *.deb && "$server_pkg" == *.deb ]]; then
    echo "Detected DEB packages"
    # Install, test, and uninstall agent
    install_deb $agent_pkg
    test_deb spire-agent
    uninstall_deb spire-agent

    # Install, test, and uninstall server
    install_deb $server_pkg
    test_deb spire-server
    uninstall_deb spire-server
else
    echo "Error: Inconsistent or unrecognized package types."
    exit 1
fi

# Stop and remove container
echo "Stopping and removing container..."
docker stop $container_id

echo "Test completed successfully."
