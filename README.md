# EmailServer

The goal of this server is to manage SMTP and in the future IMAP connections through Websocket sessions. Connect on a socket to an SMTP server, login with credentials, send emails over the socket instance and disconnect from the socket. This server manages the SMTP server connection state: connects and disconnects as gracefully as it can.  
