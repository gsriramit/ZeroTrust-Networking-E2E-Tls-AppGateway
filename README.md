## Reference HLA Diagram
The following diagram has been prepared after modifying the base diagram available at the following docs page
[How an Application Gateway Works](https://learn.microsoft.com/en-us/azure/application-gateway/how-application-gateway-works)
![NetworkSecurityNinja - Appgw-e2e-tls](https://user-images.githubusercontent.com/13979783/209676455-c92468b8-e518-4470-a499-16aec5173ea1.png)


## Implementation References
End-to-End TLS Encryption in the app gateway setup
https://learn.microsoft.com/en-us/azure/application-gateway/ssl-overview#end-to-end-tls-encryption

Configuring E2E TLS in an app gateway setup using powershell
https://learn.microsoft.com/en-us/azure/application-gateway/application-gateway-end-to-end-ssl-powershell

Generating self-signed certificates for the backend workload
https://learn.microsoft.com/en-us/azure/application-gateway/self-signed-certificates

IIS
For instructions on how to import certificate and upload them as server certificate on IIS, see HOW TO: Install Imported Certificates on a Web Server in Windows Server 2003(https://support.microsoft.com/help/816794/how-to-install-imported-certificates-on-a-web-server-in-windows-server)

For TLS binding instructions, see How to Set Up SSL on IIS 7(https://learn.microsoft.com/en-us/iis/manage/configuring-security/how-to-set-up-ssl-on-iis#create-an-ssl-binding-1)

Converting a cert file into a cer file
https://support.comodo.com/index.php?/Knowledgebase/Article/View/361/17/how-do-i-convert-crt-file-into-the-microsoft-cer-format

## Note:
Since contoso.com is not a publicly available domain, the DNS resolution of the same cannot happen at the public authoritative DNS servers or the Azure public DNS zone (if the management of the DNS has been delegated to the Azure public DNS zones). So, the mapping of the application gateway's public IP address to the domain name, i.e. contoso.com has to be done in the client's hosts file (<sysdrive>:\Windows\System32\drivers\etc\hosts in windows). This way, the client would still be able to send the requests to the application gateway even when the requests are sent to https://contoso.com
example:  
**20.237.194.223 contoso.com**

