# rmg-netplay-server

## Supported emulators
* [RMG](https://github.com/Rosalie241/RMG)

## Running
```
./rmg-netplay-server --name "Server Name"
```

## Playing locally
The server is discoverable on a LAN. When the server is running, clients on the same LAN should find the server automatically.

## Port/firewall requirements
The server will be listening on ports 45000-45010 by default, using TCP and UDP. Firewalls will need to be configured to allow connections on these ports.
