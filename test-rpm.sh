#!/bin/bash

# This script is used to test the spire-agent and spire-server RPMs in a Docker container.
# This makes it easy to check that the RPM really works on several major RPM-based distributions.
# The script takes three arguments:
# 1. Docker image name
# 2. Path to spire-agent RPM
# 3. Path to spire-server RPM

# Function to install RPM
install_rpm() {
    docker exec $container_id /bin/bash -c "rpm -vv -i /tmp/$1"
    if [ $? -ne 0 ]; then
        echo "Failed to install $1"
        exit 1
    else
        echo "$1 installed successfully."
    fi
}

# Function to test RPM
test_rpm() {
    # Assuming a simple test that just checks rpm is installed
    docker exec $container_id rpm -q $1
    if [ $? -ne 0 ]; then
        echo "Testing $1 failed."
        exit 1
    else
        echo "$1 installed successfully."
    fi
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

# Check if all arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <container_image> <agent_rpm> <server_rpm>"
    exit 1
fi

# TODO add more files here
declare -a agent_files=("/usr/bin/spire-agent")
declare -a server_files=("/usr/bin/spire-server")

container_image=$1
agent_rpm=$2
server_rpm=$3

find . 
find /tmp

# Check if RPM files exist
if [ ! -f "$agent_rpm" ] || [ ! -f "$server_rpm" ]; then
    echo "Specified RPM files do not exist."
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
container_id=$(docker run -d -v $(pwd):/tmp --rm $container_image /bin/bash -c "while true; do sleep 1; done")
echo "Container started with ID: $container_id"

# Install systemd (required for RPM installation)
echo "Installing systemd..."
#docker exec $container_id dnf install -y systemd
docker exec $container_id /bin/bash -c "dnf install -y systemd || zypper install -y systemd || yum install -y systemd"


# Install and test agent RPM
echo "Installing and testing agent RPM..."
install_rpm $agent_rpm
test_rpm spire-agent
test_spire_agent

# Uninstall agent RPM
echo "Uninstalling agent RPM..."
uninstall_rpm spire-agent

# Install and test server RPM
echo "Installing and testing server RPM..."
install_rpm $server_rpm
test_rpm spire-server
test_spire_server

# Stop and remove container
echo "Stopping and removing container..."
docker stop $container_id

echo "Test completed successfully."
