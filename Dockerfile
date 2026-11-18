# ci-java: CI image for the "bacherik-java" Forgejo runner label.
# node:22-bookworm (act/Forgejo needs Node for JS actions) + the official
# Temurin JDKs copied out of the eclipse-temurin images.
# Renovate bumps all three FROM tags; no JDK download at job runtime.

FROM eclipse-temurin:21.0.13_9-jdk AS jdk21
FROM eclipse-temurin:25.0.5_8-jdk AS jdk25

FROM node:22-bookworm

# /usr/lib/jvm is where Gradle auto-detects toolchains on Linux, so the
# daemon JVM criteria (21) are met without foojay downloads.
COPY --from=jdk21 /opt/java/openjdk /usr/lib/jvm/temurin-21
COPY --from=jdk25 /opt/java/openjdk /usr/lib/jvm/temurin-25

ENV JAVA_HOME=/usr/lib/jvm/temurin-21 \
    JAVA_HOME_21_X64=/usr/lib/jvm/temurin-21 \
    JAVA_HOME_25_X64=/usr/lib/jvm/temurin-25 \
    PATH=/usr/lib/jvm/temurin-21/bin:$PATH

RUN java -version && /usr/lib/jvm/temurin-25/bin/java -version
