# OpenSSL command line Root and Intermediate CA

## Creating root, intermediate and end-user certs
### Prepare
Create a directory to contain everything

#### Create index files
```
touch certindex
echo 1000 > certserial
echo 1000 > crlnumber
```

#### Create configuration file
`vi ca.conf`
```
[ ca ]
default_ca = myca

[ crl_ext ]
issuerAltName=issuer:copy 
authorityKeyIdentifier=keyid:always

[ myca ]
dir = ./
new_certs_dir = $dir
unique_subject = no
certificate = $dir/rootca.crt
database = $dir/certindex
private_key = $dir/rootca.key
serial = $dir/certserial
default_days = 730
default_md = sha256
policy = myca_policy
x509_extensions = myca_extensions
crlnumber = $dir/crlnumber
default_crl_days = 730

[ myca_policy ]
commonName = supplied
stateOrProvinceName = supplied
countryName = optional
emailAddress = optional
organizationName = supplied
organizationalUnitName = optional

[ myca_extensions ]
basicConstraints = critical,CA:TRUE
keyUsage = critical,any
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
keyUsage = digitalSignature,keyEncipherment,cRLSign,keyCertSign
extendedKeyUsage = serverAuth
crlDistributionPoints = @crl_section
subjectAltName  = @alt_names
authorityInfoAccess = @ocsp_section

[ v3_ca ]
basicConstraints = critical,CA:TRUE,pathlen:0
keyUsage = critical,any
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
keyUsage = digitalSignature,keyEncipherment,cRLSign,keyCertSign
extendedKeyUsage = serverAuth
crlDistributionPoints = @crl_section
subjectAltName  = @alt_names
authorityInfoAccess = @ocsp_section

[alt_names]
DNS.0 = Sparkling Intermidiate CA 1
DNS.1 = Sparkling CA Intermidiate 1

[crl_section]
URI.0 = http://pki.sparklingca.com/SparklingRoot.crl
URI.1 = http://pki.backup.com/SparklingRoot.crl

[ocsp_section]
caIssuers;URI.0 = http://pki.sparklingca.com/SparklingRoot.crt
caIssuers;URI.1 = http://pki.backup.com/SparklingRoot.crt
OCSP;URI.0 = http://pki.sparklingca.com/ocsp/
OCSP;URI.1 = http://pki.backup.com/ocsp
```

### Root
#### Generate root CA key (no passphrase)
`openssl genrsa -out rootca.key 8192`

#### Create self-signed root CA certificate
`openssl req -sha256 -new -x509 -days 3650 -key rootca.key -out rootca.crt`

Then fill in required info

### Intermediate CA
#### Generate intermediate CA key (no passphrase)
`openssl genrsa -out interca1.key 8192`

#### Create intermediate CA CSR (Certificate Signing Request)
`openssl req -sha256 -new -key interca1.key -out interca1.csr`
Then fill in required info. Skip challenge password and optional company name

#### Sign the intermediate CSR using the root
`openssl ca -batch -config ca.conf -notext -in interca1.csr -out interca1.crt`

### Creating certificates
#### Make a directory for user certificates
`mkdir certs`

#### Generate private key
`openssl genrsa -out certs/example.com.key 4096`

#### Create CSR
`openssl req -new -sha256 -key certs/example.com.key -out certs/example.com.csr`

Fill in required info. Skip challenge password and optional company name

#### Sign CSR with intermediate CA
`openssl ca -batch -config ca.conf -notext -in certs/example.com.csr -out certs/example.com.crt`

#### Make certificate chain
`cat rootca.crt interca1.crt > certs/example.com.chain`

#### Collect files
Send the following files to whoever requested the certificate
- certs/example.com.crt
- certs/example.com.key
- certs/example.com.chain

## Notes
### Inspect a certificate's content
`openssl x509 -in example.com.crt -text -noout | less`

## Reference
- [Raymii.org - OpenSSL command line Root and Intermediate CA including OCSP, CRL and revocation](https://raymii.org/s/tutorials/OpenSSL_command_line_Root_and_Intermediate_CA_including_OCSP_CRL%20and_revocation.html)
