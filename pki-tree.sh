#!/bin/bash

# Define base path
BASE_DIR=$(pwd)

echo "Creating 2-Tier PKI Directory Structure..."

for tier in root-ca intermediate-ca; do
    # Create standard directories
    mkdir -p ${BASE_DIR}/${tier}/{certs,crl,csr,newcerts,private}
    
    # Set strict permissions on the private key directories
    chmod 700 ${BASE_DIR}/${tier}/private
    
    # Initialize the flat-file database
    touch ${BASE_DIR}/${tier}/index.txt
    
    # Initialize the serial number counter with a 4-digit hex number
    echo "1000" > ${BASE_DIR}/${tier}/serial
    
    # Initialize the CRL number counter
    echo "1000" > ${BASE_DIR}/${tier}/crlnumber
done

echo "PKI directories created successfully under ${BASE_DIR}."
