### Generate the certificates/keys for server/client with mutual authentication
### documentation https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/mutual.html

{
git clone https://github.com/OpenVPN/easy-rsa.git 
cd easy-rsa/easyrsa3
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa build-server-full server nopass
./easyrsa build-client-full client1.domain.tld nopass
mkdir ~/custom_folder/
# the following "find": look for all files with extension crt or key then copy the to that directory custom_folder
find pki/ \( -name "*.crt" -o -name "*.key" \) -exec cp "{}" /home/devops/custom_folder/. \;
##install aws cli if you don't have it##
{
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
## login to your aws account with your access/secret_acess keys
aws configure
}
##upload the generated certs&keys to the certificate manager at aws
cd ~/custom_folder/
aws acm import-certificate --certificate fileb://server.crt --private-key fileb://server.key --certificate-chain fileb://ca.crt
aws acm import-certificate --certificate fileb://client1.domain.tld.crt --private-key fileb://client1.domain.tld.key --certificate-chain fileb://ca.crt
}
#  check if the certificates are successfully uploaded using aws cli to list all certficates :
aws acm list-certificates