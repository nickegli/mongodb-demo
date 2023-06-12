FROM mongo:latest

WORKDIR /usr/bin

COPY ./build/DemoApp/bin/probe.sh ./

RUN chmod +x probe.sh

# Run the shell script
CMD ["/usr/bin/probe.sh"]
