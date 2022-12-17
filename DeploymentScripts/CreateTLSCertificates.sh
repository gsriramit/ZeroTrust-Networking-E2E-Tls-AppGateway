export DOMAIN_NAME="contoso.com"
# Create the server certificate that the appgw should use to establish connection with the client & also perform the TLS termination
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -out appgw.crt -keyout appgw.key -subj "/CN=${DOMAIN_NAME}/O=Contoso Org" -addext "subjectAltName = DNS:${DOMAIN_NAME}" -addext "keyUsage = digitalSignature" -addext "extendedKeyUsage = serverAuth"
openssl pkcs12 -export -out appgw.pfx -in appgw.crt -inkey appgw.key -passout pass:appgwtlssecret#12

#Create the root key
openssl ecparam -out customrootCA.key -name prime256v1 -genkey
#Create a Root Certificate and self-sign it
openssl req -new -sha256 -key customrootCA.key -out customrootCA.csr
#generate the Root Certificate
openssl x509 -req -sha256 -days 365 -in customrootCA.csr -signkey customrootCA.key -out customrootCA.crt

#Create a server certificate
#Create the certificate's key
openssl ecparam -out contoso.key -name prime256v1 -genkey
#Create the CSR (Certificate Signing Request)
#The CSR is a public key that is given to a CA when requesting a certificate. The CA issues the certificate for this specific request.
openssl req -new -sha256 -key contoso.key -out contoso.csr

#Generate the certificate with the CSR and the key and sign it with the CA's root key
openssl x509 -req -in contoso.csr -CA  customrootCA.crt -CAkey customrootCA.key -CAcreateserial -out contoso.crt -days 365 -sha256

#Verify the newly created certificate
# Use the following command to print the output of the CRT file and verify its content:
openssl x509 -in contoso.crt -text -noout

#export the server certs to pfx format (if the server does not support the import of crt and key files separately)
openssl pkcs12 -export -out contoso.pfx -in contoso.crt -inkey contoso.key -passout pass:contosotlssecret#12