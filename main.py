import requests
from urllib3.util import parse_url, Url
from urllib.parse import quote

def add_creds_to_proxy_url(url, username, password):
    url_dict = parse_url(url)._asdict()
    url_dict['auth'] = username + ':' + quote(password, '')
    return Url(**url_dict).url

proxy_url_credentials = add_creds_to_proxy_url('http://ip:port/', 'login', 'password')

proxies = {'http': proxy_url_credentials, 'https': proxy_url_credentials}
session = requests.session()
session.proxies.update(proxies)

url = 'https://httpbin.org/ip'

response = session.get(url, verify=False)

print(response.text)
