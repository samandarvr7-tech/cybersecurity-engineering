# Detection of SQLi
* Before writing signatures and preventing the attacks, we should know what we are defending against. For this purpose we performed SQLi, so we can see it in the logs, analyse the patterns of SQLi, and then write signatures against these exact patterns
# Resources&Tools
* Suricata
## Analysing patterns
* Note if you didnt turn on live monitoring before exploiting SQLi, turn it on and perform your SQLi again, to generate necessary logs.
* Or look at the [logs](./02_logs.json) I collected
* From logs we can analyse that SQLi are in URI part of the packets, so we should focus on this part of packets.
* To exploit SQLi, attackers should first of all find number of columns, by using `ORDER BY` or `UNION SELECT`, so we can prevent/predict SQLi in this phase before giving up users credentials
* So the patterns are `ORDER BY` or `UNION SELECT`
## Signature writing
* If you are not familiar with signature syntaxes, look for [Suricata Rules section](https://docs.suricata.io/en/suricata-8.0.2/index.html), and learn `Rule formats`, `Meta keywords`, and `HTTP keywords`
* We should write our rules /var/lib/suricata/rules/ in this derectory, create the exact file which you meantioned in Suricata configuration file, in my example its /var/lib/suricata/rules/user.rules. Start editing the file with vim
```
alert http any any -> 165.232.172.9 4280 (msg: "Potential sql injection attempt"; http.method; content: "GET"; http.uri; content: "order"; nocase; content: "by"; nocase; classtype: T1190; sid: 8365772; rev: 1;)
```
* This rule, focuses on packets targeting only our server IP address on port 4280, where DVWA exactly is, and produces alert if he sees `order by` in URI part of the packets, which is exactly how attackers starts his exploitation
* However attacker may also use `UNION` based attack to identify the number of columns, and exploit the same `UNION` based attack for DataBase dump, so lets write a signature for this pattern too
```
alert http any any -> 165.232.172.9 4280 (msg: "UNION based sql injection"; http.method; content: "GET"; http.uri; content: "union"; nocase; content: "select"; nocase; classtype: T1190; sid: 8365771; rev: 1;)
```
* Restart Suricata and check if everything is okay, status should show if error occurs
```
systemctl restart suricata
systemctl status suricata
```
* If everything is ok lets again monitor the logs by filtering for alerts and simulate SQLi
```
tail -f /var/log/suricata/eve.json | jq 'select(.event_type == "alert")'
```
* As we can see, our SQLi exploitations are producing alerts
```
{
  "timestamp": "2026-01-24T17:32:44.511153+0000",
  "flow_id": 1395574454298038,
  "in_iface": "eth0",
  "event_type": "alert",
  "src_ip": "95.214.210.64",
  "src_port": 25921,
  "dest_ip": "165.232.172.9",
  "dest_port": 4280,
  "proto": "TCP",
  "ip_v": 4,
  "pkt_src": "wire/pcap",
  "tx_id": 0,
  "alert": {
    "action": "allowed",
    "gid": 1,
    "signature_id": 8365771,
    "rev": 1,
    "signature": "UNION based sql injection",
    "category": "",
    "severity": 3
  },
  "ts_progress": "request_complete",
  "tc_progress": "response_complete",
  "http": {
    "hostname": "165.232.172.9",
    "http_port": 4280,
    "url": "/vulnerabilities/sqli/?id=1%27+union+select+user,password+from+users--+&Submit=Submit",
    "http_user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15",
    "http_content_type": "text/html",
    "http_method": "GET",
    "protocol": "HTTP/1.1",
    "status": 200,
    "length": 1648
  },
  "app_proto": "http",
  "direction": "to_server",
  "flow": {
    "pkts_toserver": 4,
    "pkts_toclient": 4,
    "bytes_toserver": 823,
    "bytes_toclient": 2297,
    "start": "2026-01-24T17:32:44.193860+0000",
    "src_ip": "95.214.210.64",
    "dest_ip": "165.232.172.9",
    "src_port": 25921,
    "dest_port": 4280
  }
}
{
  "timestamp": "2026-01-24T17:33:08.222170+0000",
  "flow_id": 1187813071434891,
  "in_iface": "eth0",
  "event_type": "alert",
  "src_ip": "95.214.210.64",
  "src_port": 26047,
  "dest_ip": "165.232.172.9",
  "dest_port": 4280,
  "proto": "TCP",
  "ip_v": 4,
  "pkt_src": "wire/pcap",
  "tx_id": 0,
  "alert": {
    "action": "allowed",
    "gid": 1,
    "signature_id": 8365772,
    "rev": 1,
    "signature": "Potential sql injection attempt",
    "category": "Unknown Classtype",
    "severity": 3
  },
  "ts_progress": "request_complete",
  "tc_progress": "response_body",
  "http": {
    "hostname": "165.232.172.9",
    "http_port": 4280,
    "url": "/vulnerabilities/sqli/?id=2%27+order+by+2--+&Submit=Submit",
    "http_user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15",
    "http_content_type": "text/html",
    "http_method": "GET",
    "protocol": "HTTP/1.1",
    "status": 200,
    "length": 971
  },
  "app_proto": "http",
  "direction": "to_server",
  "flow": {
    "pkts_toserver": 5,
    "pkts_toclient": 5,
    "bytes_toserver": 874,
    "bytes_toclient": 2202,
    "start": "2026-01-24T17:32:44.342095+0000",
    "src_ip": "95.214.210.64",
    "dest_ip": "165.232.172.9",
    "src_port": 26047,
    "dest_port": 4280
  }
}
```