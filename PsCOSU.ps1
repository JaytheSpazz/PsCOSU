# Passwords
$root_password = ""
$signer_password = ""
$device_password = ""

Expand-Archive -Path "./openssl.zip" -DestinationPath $PSScriptRoot -Force

# Days
$sslrootdays="7300"
$sslintdays="3650"
$sslsrvdays="800"

# Config
$ssldef_country="US"
$ssldef_state="NJ"
$ssldef_locality="Rockleigh"
$ssldef_org="COSU Default Org"
$ssldef_org_unit="COSU Default Org Unit"
$ssldef_email="test@example.com"
$ssldef_signer_cn="COSU Signing Cert"
$ssldef_root_cn="COSU Root Cert"
$ssldef_device_hostname="COSU-DEMO-DEVICE"
$ssldef_device_ip="<invalid>"

# File structure
$home_dir = (Join-Path $PSScriptRoot "COSU")
$output_folder = (Join-Path $home_dir "Output")
$root_dir = (Join-Path $output_folder "Root")
$signer_dir = (Join-Path $output_folder "Intermediate")
$device_dir = (Join-Path $output_folder "Device")
$deploy_folder = (Join-Path $output_folder "Deploy")
$deploy_dir=(Join-Path $deploy_folder "Device")

new-item -Path "$home_dir" -itemtype directory -Force
new-item -Path "$root_dir" -itemtype directory -Force
new-item -Path "$signer_dir" -itemtype directory -Force
new-item -Path "$device_dir" -itemtype directory -Force
new-item -Path "$deploy_folder" -itemtype directory -Force
new-item -Path "$deploy_dir" -itemtype directory -Force

################README####################
$ReadMeTxt = "rootCA_cert.cer may be added to your local certificate store as a trusted certificate

**********************************************
***** 3 Series Instructions
***** Firmware 1.601 or higher!!
**********************************************
Please place rootCA_cert.cer, intermediate_cert.cer, 
srv_cert.cer and srv_key.pem
into the control system \User folder using SFTP

Execute the following commands

>del \sys\rootCA_cert.cer
>del \sys\srv_cert.cer
>del \sys\srv_key.pem

>del \ROMDISK\User\Cert\intermediate_cert.cer
>move \User\intermediate_cert.cer \ROMDISK\User\Cert\intermediate_cert.cer
>certificate add intermediate

>move User\rootCA_cert.cer \sys\rootCA_cert.cer
>move User\srv_cert.cer \sys
>move User\srv_key.pem \sys

>ssl ca 

**********************************************
***** 4 Series Instructions
**********************************************
Please place rootCA_cert.cer, intermediate_cert.cer, srv_cert.cer and srv_key.pem
into the control system \Sys folder using SFTP

Execute the following commands

>del \romdisk\user\cert\intermediate.cer
>move sys\intermediate_cert.cer \romdisk\user\cert

>certificate add intermediate
>ssl ca 


**********************************************
***** Other Devices (NVX, TSW, etc)
**********************************************
Please place rootCA_cert.cer, intermediate_cert.cer, webserver_cert.pfx
into the /User/Cert folder using SFTP (first remove any root_cert.cer that might be present)

>move /User/Cert/rootCA_cert.cer /User/Cert/root_cert.cer
>certificate add root
>certificate add intermediate
>certificate add webserver <password>
>ssl ca"

################Root CA####################
 $rootconfig = "[ ca ]
 default_ca = CA_default 
 [CA_default] 
 default_md = sha256 
 policy            = policy_strict
 [ policy_strict ] 
 # The root CA should only sign intermediate certificates that match. 
 # See the POLICY FORMAT section of man ca. 
 countryName             = match 
 stateOrProvinceName     = match 
 organizationName        = match 
 organizationalUnitName  = optional 
 commonName              = supplied 
 emailAddress            = optional 
 [ req ] 
 # Options for the req tool (man req). 
 prompt              = no
 default_bits        = 2048 
 distinguished_name  = req_distinguished_name 
 string_mask         = utf8only 
 [ req_distinguished_name ] 
 C = $ssldef_country 
 ST = $ssldef_state
 L = $ssldef_locality 
 O = $ssldef_org
 #OU = $ssldef_org_unit 
 CN = $ssldef_root_cn
 #emailAddress = $ssldef_email
 [ v3_ca ] 
 # Extensions for a typical CA (man x509v3_config). 
 subjectKeyIdentifier = hash 
 authorityKeyIdentifier = keyid:always,issuer 
 basicConstraints = critical, CA:true 
 keyUsage = critical, digitalSignature, cRLSign, keyCertSign"
new-item -Path "$root_dir\openssl.cnf" -itemtype file -Force | Add-Content -Value $rootconfig
new-item -Path "$root_dir\index.txt" -ItemType file -Force
new-item -Path "$root_dir\index.txt.attr" -ItemType file -Force
new-item -Path "$root_dir\serial" -ItemType file -Force | Add-Content -Value "1000"
Write-Host "Generating Root CA Key..."
.\openssl.exe genpkey -algorithm RSA -pass pass:$root_password -aes-256-cbc -pkeyopt rsa_keygen_bits:2048 -out $root_dir\key.pem
Write-Host "Creating Root CA Certificate..."
.\openssl.exe req -passin pass:$root_password -config $root_dir\openssl.cnf -key $root_dir\key.pem -new -x509 -days $sslrootdays -sha256 -extensions v3_ca -out $root_dir\cert.pem
Write-Host "Done"

################Intermediate####################
$signerconfig = "[ ca ]
default_ca = CA_default 
[CA_default] 
default_md = sha256 
database          = .\\COSU\\Output\\Intermediate\\index.txt
serial            = .\\COSU\\Output\\Intermediate\\serial
policy            = policy_loose 
[ policy_loose ] 
# The signer CA should only sign intermediate certificates that match. 
# See the POLICY FORMAT section of man ca. 
countryName             = optional 
stateOrProvinceName     = optional 
organizationName        = optional 
organizationalUnitName  = optional 
commonName              = supplied 
emailAddress            = optional 
[ req ] 
# Options for the req tool (man req). 
prompt              = no
default_bits        = 2048 
distinguished_name  = req_distinguished_name 
string_mask         = utf8only 
[ req_distinguished_name ] 
C = $ssldef_country 
ST = $ssldef_state
L = $ssldef_locality 
O = $ssldef_org
#OU = $ssldef_org_unit 
CN = $ssldef_signer_cn
#emailAddress = $ssldef_email  
[ v3_intermediate_ca ] 
# Extensions for a typical CA (man x509v3_config). 
subjectKeyIdentifier = hash 
authorityKeyIdentifier = keyid:always,issuer 
basicConstraints = critical, CA:true, pathlen:0 
keyUsage = critical, digitalSignature, cRLSign, keyCertSign"
new-item -Path "$signer_dir\openssl.cnf" -itemtype file -Force | Add-Content -Value $signerconfig
new-item -Path "$signer_dir\index.txt" -ItemType file -Force
new-item -Path "$signer_dir\index.txt.attr" -ItemType file -Force
new-item -Path "$signer_dir\serial" -ItemType file -Force | Add-Content -Value "1000"
Write-Host "Generating Signer Key.."
.\openssl.exe genpkey -algorithm RSA -pass pass:$signer_password -aes-256-cbc -pkeyopt rsa_keygen_bits:2048 -out $signer_dir\key.pem
Write-Host "Done"
Write-Host "Creating the signer CSR..."
.\openssl.exe req -passin pass:$signer_password -config $signer_dir\openssl.cnf -new -sha256 -key $signer_dir\key.pem -out $signer_dir\csr.pem
Write-Host "Ready to sign the intermediate certificate"
Write-Host "Creating Signer Certificate..."
.\openssl.exe ca -batch -passin pass:$root_password -config $signer_dir\openssl.cnf -cert $root_dir\cert.pem -keyfile $root_dir\key.pem -outdir $signer_dir -extensions v3_intermediate_ca -days $sslintdays -notext -md sha256 -in $signer_dir\csr.pem -out $signer_dir\cert.pem
Write-Host "Done"
new-item -Path "$signer_dir\chain.pem" -ItemType file -Force | Add-Content -Value "$signer_dir\cert.pem `n $root_dir\cert.pem"
.\openssl.exe verify -CAfile $root_dir\cert.pem $signer_dir\cert.pem

################Device CSR####################
$deviceconfig = "[ ca ] 
default_ca = CA_default 
[CA_default] 
default_md = sha256 
[ req ] 
# Options for the req tool (man req). 
default_bits        = 2048 
distinguished_name  = req_distinguished_name 
string_mask         = utf8only 
prompt              = no
[ req_distinguished_name ] 
# See https:\\en.wikipedia.org\wiki\Certificate_signing_request 
C = $ssldef_country 
ST = $ssldef_state
L = $ssldef_locality 
O = $ssldef_org
#OU = $ssldef_org_unit 
CN = $ssldef_device_hostname
#emailAddress = $ssldef_email"
new-item $device_dir\openssl.cnf -itemtype file -Force | Add-Content -Value $deviceconfig
.\openssl.exe genpkey -algorithm RSA -pass pass:$device_password -aes-256-cbc -pkeyopt rsa_keygen_bits:2048 -out $device_dir\key.pem
.\openssl.exe req -passin pass:$device_password -config $device_dir\openssl.cnf -key $device_dir\key.pem -new -sha256 -out $device_dir\csr.pem

################Device Cert####################
$deviceconfig2 = "[ ca ]
default_ca = CA_default 
[CA_default] 
default_md = sha256 
database          = .\\COSU\\Output\\Intermediate\\index.txt
serial            = .\\COSU\\Output\\Intermediate\\serial
policy            = policy_loose 
[ policy_loose ] 
# Allow the intermediate CA to sign a more diverse range of certificates
# See the POLICY FORMAT section of man ca. 
countryName             = optional 
stateOrProvinceName     = optional 
organizationName        = optional 
organizationalUnitName  = optional 
commonName              = supplied 
emailAddress            = optional 
[ req ] 
# Options for the req tool (man req). 
prompt              = no
default_bits        = 2048 
distinguished_name  = req_distinguished_name 
string_mask         = utf8only 
[ req_distinguished_name ] 
C = $ssldef_country 
ST = $ssldef_state
L = $ssldef_locality 
O = $ssldef_org
#OU = $ssldef_org_unit 
CN = $ssldef_device_hostname
#emailAddress = $ssldef_email 
[server_cert] 
# Extensions for server certs(man x509v3_config). 
subjectKeyIdentifier = hash 
authorityKeyIdentifier = keyid:always,issuer 
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
nsCertType = server
nsComment = 'OpenSSL Generated Server Certificate'
extendedKeyUsage = serverAuth"
new-item $device_dir\openssl.cnf -ItemType file -Force | Add-Content -Value $deviceconfig2
if ($ssl_dev_ip -ne "<invalid>")
{
    validate_ip
}
function validate_ip {
    $ip = $ssldef_device_ip

    $ipv4 = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

    if ($ip = "<invalid>") {
        Add-Content -Path $device_dir/openssl.cnf -Value "`n subjectAltName = DNS:$ssldef_device_hostname"
    }
    elseif ($ip -notmatch $ipv4) {
        Write-Host "$ip is invalid."
        break
    }
    else {
        Write-Host "$ip is a valid IPv4 address"
        Add-Content -Path $device_dir/openssl.cnf -Value "`n subjectAltName = DNS:$ssldef_device_hostname, IP:$ssldef_device_ip"
    }
}
Write-Host "Ready to sign the device certificate"
Write-Host "Creating Certificate..."
.\openssl.exe ca -batch -passin pass:$signer_password -config $device_dir\openssl.cnf -cert $signer_dir\cert.pem -keyfile $signer_dir\key.pem -outdir $device_dir -extensions server_cert -days $sslsrvdays -notext -md sha256 -in $device_dir\csr.pem -out $device_dir\cert.pem
Write-Host "Done"
Write-Host "Now copying files for Crestron Device Deployment"
#copy and rename the root certificate
Copy-Item -Path "$root_dir\cert.pem" -Destination "$deploy_dir\rootCA_cert.cer"
#copy and rename the signer certificate
Copy-Item -Path "$signer_dir\cert.pem" -Destination "$deploy_dir\intermediate_cert.cer"
#copy and rename the device certificate
Copy-Item -Path "$device_dir\cert.pem" -Destination "$deploy_dir\srv_cert.cer"
#decrypt and rename the private key
.\openssl.exe rsa -passin pass:$device_password -in $device_dir\key.pem -out $deploy_dir\srv_key.pem
#create PFX File
.\openssl.exe pkcs12 -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -export -passin pass:$device_password -passout pass:$device_password -out $deploy_dir\webserver_cert.pfx -inkey $device_dir\key.pem -in $device_dir\cert.pem
#write out the user instructions
New-Item -Path $deploy_dir\readme.txt -ItemType file -Force | Add-Content -Value $ReadMeTxt
.\openssl.exe verify -CAfile $signer_dir\chain.pem $device_dir\cert.pem