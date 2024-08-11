
# How to upload code to server

- Run luacheck on new code
	- $ luacheck ./nakama/data/modules/*
- Confirm that you can SSH into the server from current server
- SSH into server
- Shut down nakama server
	- $ docker compose down
- On local machine, navigate to repo with server code
- Add new server code to server
	- $ scp -r ./nakama/data/modules/. username@server_ip_address:~/nakama/data/modules
- Start nakama server
	- $ docker compose up
- Confirm in logs that new modules were loaded
