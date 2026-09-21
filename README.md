# localhost PKI

## Smallstep

### Generate Root CA Certificate

``` bash
step certificate create "localhost Root CA" ./ca/localhost_Root_CA.crt ./ca/private/localhost_Root_CA.key \
    --template=./config/step/templates/root-ca.tpl \
    --kty=RSA --size=4096 --not-after=8760h \
    --no-password --insecure
```

### Generate Intermediate CA Certificate

``` bash
step certificate create "localhost Intermediate CA" \
    ./intermediate/localhost_Intermediate_CA.crt \
    ./intermediate/private/localhost_Intermediate_CA.key \
    --kty=RSA --size=4096 --not-after=4380h \
    --template ./config/step/templates/intermediate.tpl \
    --ca ./ca/localhost_Root_CA.crt --ca-key ./ca/private/localhost_Root_CA.key \
    --no-password --insecure
``` 

### Initialize Online CA
``` bash
step ca init \
    --context localhost \
    --deployment-type=standalone \
    --name="localhost Smallstep Online CA" \
    --dns="ca.localhost,localhost,127.0.0.1" \
    --address="127.0.0.1:9000" \
    --provisioner="me" \
    --acme \
    --root=./intermediate/localhost_Intermediate_CA.crt \
    --key=./intermediate/private/localhost_Intermediate_CA.key
```
