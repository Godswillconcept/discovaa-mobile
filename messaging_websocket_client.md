# WebSocket Chat Client Guide

This document describes how a client should integrate with the real-time chat WebSocket API.

## Overview

The WebSocket API provides real-time messaging for:

- Pre-booking provider inquiries
- Booking-linked conversations

It is designed to work alongside the REST API for:

- Thread discovery/listing
- Message history retrieval
- Thread creation
- Read-state updates

## WebSocket endpoints

- Primary (recommended): `GET /ws/chat/`
  - One connection per authenticated user.
  - On connect, the server subscribes the connection to:
    - The per-user inbox group (`user_<user_id>`)
    - All eligible thread rooms the user belongs to
    - Then pushes missed incoming messages for threads where your last_read_at is behind

- Legacy (single-thread): `GET /ws/chat/<room_id>/`
  - Joins a single thread room (`chat_<room_id>`) after authorization.
  - Still also subscribes the per-user inbox group (`user_<user_id>`).

## Authentication

WebSocket connections authenticate using the **headless JWT access token**.

If the token is missing or invalid, the server closes the connection.

### Recommended (works in browsers): query parameter

Connect with:

`wss://<host>/ws/chat/?access_token=<access_token>`

### Alternative (non-browser clients): `Sec-WebSocket-Protocol`

Some clients can’t or shouldn’t put tokens in URLs. The server also supports passing the token via
the `Sec-WebSocket-Protocol` header as:

- `access_token, <access_token>`

Notes:

- Standard browser `WebSocket` APIs do not allow setting arbitrary headers.
- Putting tokens in URLs may leak into logs/analytics; prefer the subprotocol approach where possible.

## Recommended client flow (primary endpoint)

1. Authenticate via headless REST (obtain `access_token`).
2. Fetch threads via REST:
   - `GET /api/message-threads/`
3. Connect WebSocket:
   - `wss://<host>/ws/chat/?access_token=<access_token>`
4. Start receiving events:
   - New messages (from any subscribed thread)
   - `thread_created` events (when a new thread is created, your connection auto-subscribes)
5. Send messages over WebSocket (preferred) or via REST fallback.
6. Update read state via REST when appropriate:
   - `POST /api/message-threads/{id}/mark_read/`

## Sending a message

Send a JSON object.

### Required fields

- Either:
  - `thread` (or `thread_id`): the message thread id
  - OR `provider`: provider id (inquiry send; server will resolve/create the inquiry thread)
- `text` (or `message`): message body

### Example

```json
{ "thread": "<thread_id>", "text": "hello" }
```

Inquiry message example (no thread id required):

```json
{ "provider": "<provider_id>", "text": "hello" }
```

### Server behavior

- The server validates that:
  - You are a participant of the thread
  - Provider messaging restrictions allow sending (if applicable)
  - You are not rate-limited
  - The message content is not empty

If valid, the server persists the message and broadcasts a message event to all connections subscribed to `chat_<thread_id>`.

## Receiving events

The server sends JSON payloads.

### Message event (broadcast)

When a message is successfully persisted, the server broadcasts the saved message object:

```json
{
  "id": "<message_id>",
  "thread": "<thread_id>",
  "sender": 123,
  "kind": "TEXT",
  "content": "hello",
  "metadata": { "thread": "<thread_id>", "text": "hello" },
  "created_at": "2026-01-09T07:00:00.000000Z",
  "status": "sent"
}
```

Notes:

- `metadata` echoes the original client payload for traceability.
- `kind` is currently persisted as `TEXT` for WebSocket sends.
- `status` is a convenience field for UI. For incoming messages it is typically `received` (or `read` if already read). For outgoing messages it starts as `sent`.

### Message status update (client -> server)

Clients should acknowledge delivery or read state after rendering messages. This enables server-side tracking for sender UI.

Send:

```json
{ "type": "update_message_status", "thread": "<thread_id>", "status": "delivered", "message_ids": ["<message_id>"] }
```

Read example:

```json
{ "type": "update_message_status", "thread": "<thread_id>", "status": "read", "message_ids": ["<message_id>"] }
```

### Status update events (server -> client)

When delivery/read state changes, the server broadcasts status events to the thread group:

Message status updated:

```json
{
  "type": "message_status_updated",
  "thread": "<thread_id>",
  "user": "<user_id>",
  "status": "read",
  "status_at": "2026-01-11T08:00:00.000000Z",
  "message_ids": ["<message_id>"]
}
```

### Thread created event (push)

When a new thread is created (booking thread or inquiry thread), the server notifies connected participants via their per-user inbox group (`user_<user_id>`).

Payload:

```json
{
  "type": "thread_created",
  "thread": "<thread_id>",
  "booking": "<booking_id>",
  "provider": "<provider_id>"
}
```

Client handling:

- Treat this as a hint to refresh the thread list UI.
- You do **not** need to reconnect.
- The server auto-subscribes your connection to `chat_<thread_id>` when it emits this event.

## Error payloads

When a send fails, the server responds only to the sender with an error payload:

```json
{ "error": true, "detail": "..." }
```

Common causes:

- `thread is required.`
- `Message content cannot be empty.`
- `Not allowed to post messages in this thread.`
- `This provider is not accepting messages.`
- `You cannot message this provider.`
- `You are sending messages too quickly. Please slow down.`

## Permissions and eligibility

### Thread membership

For non-admin users:

- You can only send messages to threads where you are a participant.
- Connecting to `/ws/chat/<room_id>/` is rejected if you are not a participant.

### Eligible threads auto-subscribed on connect (`/ws/chat/`)

The server auto-subscribes the connection to thread groups for threads where:

- You are a participant
- The thread is either:
  - An inquiry thread (no booking)
  - A booking thread where booking status is in `REQUESTED` or `CONFIRMED`

Admins are subscribed to all eligible threads.

## Reconnection strategy

Recommended approach:

- Reconnect with exponential backoff.
- After reconnecting:
  - Refresh threads via REST (`GET /api/message-threads/`)
  - Optionally refresh message history for the active thread (`GET /api/messages/?thread=<thread_id>`)

## Minimal examples

### Browser

```js
const ws = new WebSocket("wss://example.com/ws/chat/");

ws.onopen = () => {
  ws.send(JSON.stringify({ thread: "<thread_id>", text: "hello" }));
};

ws.onmessage = (evt) => {
  const data = JSON.parse(evt.data);
  // handle either message payload or {type:"thread_created",...} or {error:true,...}
};

ws.onclose = () => {
  // reconnect with backoff
};
```

### React Native (conceptual)

Use a WS client that supports cookie-based auth or ensure the HTTP session is shared with the WebSocket handshake.

## REST endpoints used with chat

- `GET /api/message-threads/`
- `POST /api/message-threads/` (create thread)
- `POST /api/message-threads/{id}/mark_read/`
- `GET /api/messages/?thread=<thread_id>`
- `POST /api/messages/` (fallback send)
