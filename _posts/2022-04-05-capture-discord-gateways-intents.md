---
title: Create a Discord Selfbot
date: 2022-04-07
tags:
    - discord
    - selfbot
    - nodejs
    - typescript
toc: true
---

# Introduction
In this tutorial I will show you how to create a Discord selfbot in NodeJS. In order for us to create our selfbot we need to understand how Discord Gateway works. For the purpose of this tutorial I will focus on `MESSAGE_CREATE` intent so we capture new messages over Websockets. I assume that you are already familiar with NodeJS and TypeScript programming language, so I will focus on how Discord Gateways works.
<br>
If you don't really care about Discord Gateways internals, you can skip the rest of the article and use my [discord-gateways module](#using-discord-gateways).

# How to get your Discord authentication token
In order to authenticate our client on Discord Gateway, we will need to find the authentication token for our personal Discord account. Unfortunately there is no a straight-forward way to do this, so I will try to explain the process as simple as I can.

## Steps
1. [Login](https://discord.com/) to your Discord account from your browser.
2. Enable `Developer Tools` using [Ctrl]+[Shift]+[I] key combination on Google Chrome.
3. Go to `Network` tab.
4. Send a message to anyone.
5. Select the `messages` packet, make sure that `Headers` tab is selected, and scroll down to find and copy the `authorization` header under the `Request Headers`.
![Authorization token](/assets/images/capture-discord-gateways-intents/token-instructions.png)

That's it! Now that we have our authentication token, we can proceed to the code.

# Implementation
Fire-up your favorite text-editor or IDE and create a new NodeJS project with TypeScript installed & configured.
<br>
Next, we will have to install a couple of dependencies:
1. ws
2. @types/ws

After that, we create a new file called `DiscordClient`:

```
import { WebSocket } from 'ws';
import { EventEmitter } from 'events';

export declare interface DiscordClient {
    on(event: 'messageCreate', listener: (message: any) => void): this;
}

export class DiscordClient extends EventEmitter {
    private discordToken: string;
    private seq: number | null;
    private session_id: string | null;
    private ack: boolean;
    private heartbeatTimer: NodeJS.Timer | undefined;
    private ws: WebSocket;

    constructor(discordToken: string) {
        super();
        this.discordToken = discordToken;
        this.seq = null;
        this.session_id = null;
        this.ack = false;
        this.ws = new WebSocket('wss://gateway.discord.gg/?v=6&encoding=json');
    }

    public connect() {
        this.ws = new WebSocket('wss://gateway.discord.gg/?v=6&encoding=json');

        this.ws.on('message', (data: string) => {
            const payload = JSON.parse(data);
            const { op, d, s, t } = payload;

            this.seq = s ? s : this.seq;

            if (op == 1) {
                this.heartbeat();
            } else if (op == 9) {
                setTimeout(() => {
                    this.identify();
                }, 3000);
            } else if (op == 10) {
                this.heartbeatTimer = setInterval(() => {
                    this.heartbeat();
                }, d.heartbeat_interval);

                if (this.session_id && this.seq) {
                    this.ws.send(JSON.stringify({
                        'op': 6,
                        'd': {
                            'token': this.discordToken,
                            'session_id': this.session_id,
                            'seq': this.seq
                        }
                    }));
                } else {
                    this.identify();
                }
            } else if (op == 11) {
                this.ack = true;
            }

            switch (t) {
                case 'READY':
                    this.session_id = d.session_id;
                    break;
                case 'MESSAGE_CREATE':
                    this.emit('messageCreate', d);
                    break;
            }
        })
    }

    private heartbeat() {
        this.ws.send(JSON.stringify({
            'op': 1,
            'd': this.seq
        }));
        this.ack = false;

        setTimeout(() => {
            if (!this.ack) {
                this.ws.close();
                this.ack = false;
                if (this.heartbeatTimer) {
                    clearInterval(this.heartbeatTimer);
                }
                this.connect();
            }
        }, 5000);
    }

    private identify() {
        this.ws.send(JSON.stringify({
            'op': 2,
            'd': {
                'token': this.discordToken,
                'properties': {
                    '$os': 'linux',
                    '$browser': 'chrome',
                    '$device': 'chrome'
                }
            }
        }));
    }
}
```

OK, now let's get through the code.

## Class
Notice that this DiscordClient class extends the EventEmitter class. That's because we want to emit a NodeJS event every time that we receive a new message, so we can easily subscribe and process every new message.

## Constructor
A very simple constructor that gets the user's Discord token as parameter and store it to a variable, so we can use it during our class lifecycle.

## Function: connect
This function is responsible for the connection and reconnection process to Discord Gateway.
<br>
First of all we have to connect on the Discord Gateway over websocket by creating a new instance of the WebSocket object:

`this.ws = new WebSocket('wss://gateway.discord.gg/?v=6&encoding=json');` 

The `encoding=json` part, tells Discord that we want to receive messages in JSON format.
<br>
Next we subscribe to listen for new events from the Discord Gateway.

`this.ws.on('message', (data: string)`

Each event that we receive contains the following fields:

| Field | Description |
| ----- | ----------- |
| op | optcode for the payload |
| d | event data |
| s | sequence number, used for resuming sessions and heartbeats |
| t | the event name for this payload |

> More about event payload [here](https://discord.com/developers/docs/topics/gateway#payloads)

Let's deserialize the JSON message to a variable called `payload`:

`const { op, d, s, t } = payload;`

For each event that we receive, we have to store the sequence number to a variable. This is very important because this sequence number will be used for reconnection, in case that we disconnect from the websocket (for any reason). So by sending the sequence number during the reconnection process, Discord Gateway will replay all missed events, ensuring that we will not lose any message.

`this.seq = s ? s : this.seq;`

> More about the reconnection process [here](https://discord.com/developers/docs/topics/gateway#resuming)

Now that we have the sequence number stored in our `seq` variable, we can examine the opcode field (`op` variable) in order to determine the type of the event.

### Optcode 10
This is the first optcode that we will receive once we connect to the websocket. It defines the heartbeat interval that our client should send heartbeats.
<br>
Here is the structure of Optcode 10 Hello:

```
{
  "op": 10,
  "d": {
    "heartbeat_interval": 45000
  }
}
```

So, according to Discord Gateway documentation, after we receive Optcode 10 Hello, we should <i>begin sending Optcode 1 Heartbeat payloads after every `heartbeat_interval * jitter` (where jitter is a random value between 0 and 1), and every `heartbeat_interval` milliseconds thereafter.</i>

```
this.heartbeatTimer = setInterval(() => {
    this.heartbeat();
}, d.heartbeat_interval);
```

We will get through the `heartbeat()` function later. For now notice that we send a heartbeat every `heartbeat_interval` milliseconds in order to retain our websocket connection.
<br>
Once we start sending heartbeats, we will have to identify our client to Discord Gateway. This is implemented in `identify()` function, which is called in the `else` part of the following `if` statement. (Since this is the first time that we call the `connect()` function in our application's lifecycle, the `this.session_id && this.seq` condition will be `false` because of the `session_id` variable, so the `else` part gets executed and the `identify()` function is called this time)
<br>
For now just ignore the code after the `this.session_id && this.seq` condition. We will get through this later, once we discuss about the [heartbeat() function](#function-heartbeat).
<br>
To summarize, so far the steps are:
1. Connect to websocket
2. Once we receive Optcode 10 Hello, we start sending heartbeats every `heartbeat_interval` milliseconds. (Note that `heartbeat_interval` is defined in Optcode 10 Hello event).
3. Identify our client to Discord Gateway by calling `identify()` function.
<br>
Once we identify our client the Discord Gateway will respond with a `Ready` event which is means that our client is connected! We will talk about the `Ready` event [later](#ready-event).

> More about Optcode 10 Hello [here](https://discord.com/developers/docs/topics/gateway#hello)

### Optcode 1
Sometimes the Discord Gateway may request a heartbeat from our client by sending an Optcode 1 Heartbeat. In this case we just call the `heartbeat()` function, which is responsible for sending the heartbeats.

> More about Optcode 1 Heartbeat [here](https://discord.com/developers/docs/topics/gateway#heartbeat)

### Optcode 9
The Optcode 9 Invalid Session actually means that we are disconnected from the gateway. In this case according to the documentation we have to wait between 1-5 seconds and then send a fresh Optcode 2 Identify. So we can just call the `identify()` function after 3 seconds.

```
setTimeout(() => {
    this.identify();
}, 3000);
```

> More about Optcode 9 Invalid Session [here](https://discord.com/developers/docs/topics/gateway#invalid-session)

### Optcode 11
Any time that our client sends a an Optcode 1 Heartbeat, the Gateway will respond with Optcode 11 Heartbeat ACK for a successful acknowledgement. So we are going to use a variable called `ack` as a flag to determine if the Gateway respond successfully to our last Heartbeat. We actually set the `ack` flag to `false` every time that we call the `heartbeat` function and if we receive the an Optcode 11 Heartbeat ACK response we set this to `true`. I will explain how the `ack` variable works and why it's useful in order to detairmine the state of our connection, once we discuss about the [heartbeat function](#function-heartbeat)

> More about Optcode 11 Heartbeat ACK [here](https://discord.com/developers/docs/topics/gateway#heartbeating-example-gateway-heartbeat-ack)

## READY event
Once we send a valid identify payload the Gateway will respond with a Ready event. Which actually means that our client is consider connected. So we just store the `session_id` to our `session_id` variable. We will need this variable in the reconnection process in case that our client gets disconnected.

```
this.session_id = d.session_id;
```

> More about READY event [here](https://discord.com/developers/docs/topics/gateway#ready)

## MESSAGE_CREATE event
The `MESSAGE_CREATE` event, is send once we receive a new message on Discord. In this case we just emit a NodeJS event which contains the message. 

```
this.emit('messageCreate', d);
```

Notice that we have already declare a `DiscordClient` interace for this NodeJS event.

```
export declare interface DiscordClient {
    on(event: 'messageCreate', listener: (message: any) => void): this;
}
```

> More about MESSAGE_CREATE event [here](https://discord.com/developers/docs/topics/gateway#message-create)

## Function: heartbeat
This function is responsible for sending a heartbeat and checking if our client has received and acknowledgement respond. Also it will call the `connect()` function in case that our client gets disconnected in order to reconnect.
<br>
So first of all we send the Optcode 1 Heartbeat payload to Discord Gateway, and set our `ack` variable to `false`.

```
this.ws.send(JSON.stringify({
    'op': 1,
    'd': this.seq
}));
this.ack = false;
```

Now we have to make sure that we receive an acknowledgement respond for our last heartbeat, otherwise it means that our client has been disconnected. In order to implement this, we wait for 5 seconds. If our `ack` variable is `true`, it means that we received an ACK event. Remember that once we receive Optcode 11 Heartbeat ACK we set the `ack` variable to true (This is actually implemented in our `connect()` function). Otherwise, if our `ack` variable is set to `false`, it means that we haven't received an Optcode 11 Heartbeat ACK, so our client has been disconnected from websocket. In this case we have to close our websocket connection and reconnect. That's what we are doing if the following `if` condition gets executed.

```
setTimeout(() => {
    if (!this.ack) {
        this.ws.close();
        this.ack = false;
        if (this.heartbeatTimer) {
            clearInterval(this.heartbeatTimer);
        }
        this.connect();
    }
}, 5000);
```

Notice that this time the `session_id` and `seq` variables has been set. So once we call the `connect()` function and we receive Optcode 10 Hello during the connection process, the `this.session_id && this.seq` condition will be true and the following code gets executed:

```
this.ws.send(JSON.stringify({
    'op': 6,
    'd': {
        'token': this.discordToken,
        'session_id': this.session_id,
        'seq': this.seq
    }
}));
```

This code will send an Optcode 6 Resume payload to Discord Gateway in order to reconnect to websocket. Notice that we pass the `discordToken` (in order to get authenticated), the `session_id` (for our websocket connection) and the `seq` (in order to make sure that Discord Gateway will replay any lost messages, during our disconnection period).

> More about heartbeat payload [here](https://discord.com/developers/docs/topics/gateway#heartbeat)

## Function: identify
This function is responsible for sending an identify payload. Notice that we are passing the `discordToken` here. This is very important, otherwise we will not be able to authenticated on Discord Gateway.

```
this.ws.send(JSON.stringify({
    'op': 2,
    'd': {
        'token': this.discordToken,
        'properties': {
            '$os': 'linux',
            '$browser': 'chrome',
            '$device': 'chrome'
        }
    }
}));
```

> More about identify payload [here](https://discord.com/developers/docs/topics/gateway#identifying)

# Using discord-gateways
If you just want to capture your Discord messages easily, you can use my NodeJS module.

## Installation
`npm install discord-gateways`

## Usage

```
import { DiscordClient, MessageDto } from 'discord-gateways';

const client = new DiscordClient("DISCORD_TOKEN");

client.on("messageCreate", (message: MessageDto) => {
    console.log(message);
});

client.connect();
```

# Capture more intents
You can easily capture more intents using the same approach. You can find a list of available Discord Gateways intents [here](https://discord.com/developers/docs/topics/gateway#list-of-intents)

# References
[Discord Gateways](https://discord.com/developers/docs/topics/gateway)