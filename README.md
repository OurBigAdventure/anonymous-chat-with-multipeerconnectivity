#Playing with Multi-Peer Connectivity and UIAnimations

# anonymous-chat-with-multipeerconnectivity
This is a simple anonymous chat application in Swift that uses multipeerconnectivity to send messages
between devices.

Devices are never required to connect, the user's message is sent as the name of their channel.

Users can block other users by tapping on a message and marking it with a thumbs down.  This is handled by
sending a connection request to the other device which triggers the block count to increment by one before
the connection is automatically refused.

Receiving 25 blocks will prevent a user from sending messages again.

Because this is an anonymous chat with no intended conversation format, messages are displayed in random
sizes and fonts that scroll across the user's screen thus creating a 'cloud conversation' effect.

All app text is displayed as emoji to avoid the need for localization.

Use of the app is simple:

Swipe right to access the background color switcher
Tap the thought bubble to create a message
Swipe up on your message to send it
Tap outside of your message to cancel sending it
Tap a message on the screen to block that sender
  - blocking a sender is permenant until the sender reinstalls the app

Messages are only shown while the sending device has the app open.  Messages expire after 2 minutes to avoid
message clutter.
