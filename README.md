### Note
I found this solution on ackblk https://gist.github.com/jackblk/fdac4c744ddf2a0533278a38888f3caf source and modified it a bit. 

This is tutorial how to create your onw proxie on linux\ubuntu servers with login and password and use it with python. 

AUTOMATIC installer at the end of article. Read it first.

This tutorial is for Ubuntu & Squid3. Use AWS, Google cloud, Digital Ocean or any services with Ubuntu to follow this tutorial.

### Install squid & update
```
sudo apt-get update
sudo apt-get install squid // it was squid3 in original article, but it doesn't work at recent ubuntu serverc
sudo apt-get install apache2-utils
```

### Setup the password store
Choose a username/password. Example:
```
username: abc
password: 123
```
Type in console:
```
sudo touch /etc/squid/passwords
sudo chmod 777 /etc/squid/passwords
sudo htpasswd -c /etc/squid/passwords [USERNAME]
```

Replace [USERNAME] with your username, in this example: ```abc```.

You will be prompted for entering the password. Enter and confirm it. This example password: ```123```.


#### [Optional] Test the password store

```
/usr/lib/squid3/basic_ncsa_auth /etc/squid/passwords
```

After executing this line the console will look like its hung, there is a prompt without any text in it. Enter ```USERNAME PASSWORD``` (replacing these with your specific username and password) and hit return. You should receive the response "OK".

If not, review the error message, your username/password might be incorrect. Its also possible basic_ncsa_auth is located on a different path (e.g. lib64).

### Config squid proxy

Backup default config file:
```
sudo mv /etc/squid/squid.conf /etc/squid/squid.conf.original
```

Make a new configuration files
```
sudo vi /etc/squid/squid.conf
```

Enter this in the config file
```
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 24 hours
auth_param basic casesensitive off
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
dns_v4_first on
forwarded_for delete
via off
http_port 8888
```

* ```auth_param basic credentialsttl 24 hours```: after 24 hours, user/pass will be asked again.
* ```auth_param basic casesensitive off```: case sensitive for user is off.
* ```dns_v4_first on```: use only IPv4 to speed up the proxy.
* ```forwarded_for delete```: remove the forwarded_for http header which would expose your source to the destination
* ```via off```: remove more headers to avoid exposing the source.
* ```http_port 8888```: port 8888 is used for proxy. You can choose any port.

Save the file in vi with [esc]:wq

### Start the squid service
Start squid: ```sudo service squid start```

To check service status: ```service squid status```

### Restart the squid service and try proxy
Restart squid service
```sudo service squid restart``` or ```sudo systemctl restart squid.service```.

Use your proxy with your ```ip:port```. Example: ```111.111.222.333:8888``` and login with your user/pass.

### Caution
You might need to create inbound firewall rule first before using the proxy.

For Google cloud: [Firewall](https://console.cloud.google.com/networking/firewalls/). Create an Ingress rule, Target Apply to all, IP range of ```0.0.0.0/0```, allow ```TCP:8888, UDP:8888``` for all traffic.


Using this proxy by python should be like 

```
import requests
from urllib3.util import parse_url, Url
from urllib.parse import quote

def add_creds_to_proxy_url(url, username, password):
    url_dict = parse_url(url)._asdict()
    url_dict['auth'] = username + ':' + quote(password, '')
    return Url(**url_dict).url

proxy_url_credentials = add_creds_to_proxy_url('http://proxyip:proxyport/', 'yourlogin', 'yourpassword')

proxies = {'http': proxy_url_credentials, 'https': proxy_url_credentials}
session = requests.session()
session.proxies.update(proxies)

url = 'https://httpbin.org/ip'

response = session.get(url, verify=False)

print(response.text)
```

Then I wanted make creating server automatically. For this purpouse you should crate your install.sh file using via ssh console in the server like
Create install.sh file: ```sudo nano install.sh```

Then paste this code and replace userlogin and userpassword for your own login and pass. You can change the port using the proxy, my one is 3201. 
```
#!/bin/sh

sudo apt-get update -y

sudo apt-get install squid -y

sudo apt-get install apache2-utils -y

sudo touch /etc/squid/passwords

sudo chmod 777 /etc/squid/passwords

sudo htpasswd -c -b /etc/squid/passwords userlogin userpassword

sudo mv /etc/squid/squid.conf /etc/squid/squid.conf.original

echo "auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 24 hours
auth_param basic casesensitive off
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
dns_v4_first on
forwarded_for delete
via off
http_port 3201" >> /etc/squid/squid.conf

sudo service squid start

sudo systemctl restart squid.service
```
Then it had to be installed. 
```
sh install.sh
```

Thats all. If you did some changes in squid.conf file don't forget to make restart of the service. 
```
sudo systemctl restart squid.service
```
