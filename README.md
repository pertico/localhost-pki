# localhost PKI

## Directory structure
``` 
/opt/pki/
├── root-ca/                      # 🛑 ROOT CA TIER (Keep Offline)
│   ├── certs/                    # Root CA public certificate
│   ├── crl/                      # Root Certificate Revocation Lists
│   ├── csr/                      # Requests signed by Root (e.g., Intermediate CSR)
│   ├── newcerts/                 # OpenSSL certificate archive
│   ├── private/                  # Root CA private key (Strict permissions: 700/600)
│   ├── index.txt                 # Root CA database text file
│   └── serial                    # Root CA serial number counter
│
└── intermediate-ca/              # 🌐 INTERMEDIATE CA TIER (Online)
    ├── certs/                    # Intermediate CA cert & issued end-entity certs
    ├── crl/                      # End-entity Certificate Revocation Lists
    ├── csr/                      # Incoming requests from servers/users
    ├── newcerts/                 # OpenSSL certificate archive
    ├── private/                  # Intermediate CA private key (Permissions: 700/600)
    ├── index.txt                 # Intermediate CA database text file
    └── serial                    # Intermediate CA serial number counter
```
