FROM openjdk:17-jdk-bullseye

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libfreetype6 \
    fontconfig \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

COPY WatermarkAdder.java /app/WatermarkAdder.java

RUN javac WatermarkAdder.java && \
    jar cfe WatermarkAdder.jar WatermarkAdder WatermarkAdder.class

RUN mkdir -p /app/Ex5_3_pictures

RUN fc-cache -f -v

ENTRYPOINT ["java", "-jar", "/app/WatermarkAdder.jar"]
