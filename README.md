Debian Stretch agent with jdk8

# Build and push

docker build -t registry.example.com:5000/jenkins-slave:latest .
docker push registry.example.com:5000/jenkins-slave:latest

# SSH credentials for jenkins
Create ssh credentials https://jenkins.io/doc/book/using/using-credentials/ or use existing

# Run
docker run registry.example.com:5000/jenkins-slave:latest \
    -e JENKINS_SLAVE_SSH_PUBKEY='{jenkins ssh public key}' \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -p 50022:22

# Configure jenkins slave
https://plugins.jenkins.io/ssh-agent/
