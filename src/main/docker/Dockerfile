FROM openjdk:8-jdk-alpine
VOLUME /tmp
RUN wget https://busybox.net/downloads/binaries/1.28.1-defconfig-multiarch/busybox-x86_64 -O /bin/busybox; \
    chmod +x /bin/busybox; 

# The application's jar file
ARG JAR_FILE=target/ranjeeta_spring-0.0.1-SNAPSHOT.jar

ADD ${JAR_FILE} app.jar

ENV SPRING_PROFILES_ACTIVE=local-docker-compose
ENV SERVER_PORT=80
EXPOSE 80

RUN chmod +x start.sh
ENTRYPOINT [ "sh", "-c" ]
CMD ["/start.sh"]

