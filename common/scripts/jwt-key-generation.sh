#!/bin/bash -x 
# This script generates JSON Web Keys (JWKS) for Slurm authentication.
# It uses the json-web-key-generator tool to create RSA and Octet keys.

# Copy the key generator source and build it
cp -rvL /json-web-key-generator /build
cd /build
mvn package

# Generate RSA Key Set for public/private key authentication
java -jar /build/target/json-web-key-generator-0.9-SNAPSHOT-jar-with-dependencies.jar \
    --type RSA --size 2048 --algorithm RS256 --idGenerator sha1 --keySet \
    --output /opt/jwks.json --pubKeyOutput /opt/jwks.pub.json

# Generate Octet Key Set for symmetric key authentication (slurm.jwks)
java -jar /build/target/json-web-key-generator-0.9-SNAPSHOT-jar-with-dependencies.jar \
    --type oct --size 2048 --algorithm HS256 --idGenerator sha1 --keySet \
    --output /opt/slurm.jwks
