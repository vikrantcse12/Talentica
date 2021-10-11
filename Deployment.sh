#bin/bash

# Deployment of docker image
docker build -t python-img .
sleep 100
docker container run -it python-img:latest
echo "Deployment completed! Please check the page on the Browser by hitting<IP>:5000"
