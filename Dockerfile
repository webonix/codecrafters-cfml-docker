FROM eclipse-temurin:21-jre-alpine

RUN apk add --no-cache curl

# LuCLI latest JAR
ENV LUCLI_JAR=/opt/lucli.jar
RUN curl -sL -o "$LUCLI_JAR" "https://github.com/cybersonic/LuCLI/releases/latest/download/lucli.jar"

WORKDIR /app
COPY . /app
RUN chmod +x .codecrafters/run.sh .codecrafters/compile.sh
