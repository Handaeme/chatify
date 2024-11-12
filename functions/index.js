const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotification = functions.https.onRequest((req, res) => {
  const { to, notification } = req.body;

  const message = {
    notification: {
      title: notification.title,
      body: notification.body,
    },
    token: to,
  };

  admin
    .messaging()
    .send(message)
    .then((response) => {
      console.log("Notification sent successfully:", response);
      res.status(200).send("Notification sent successfully");
    })
    .catch((error) => {
      console.error("Error sending notification:", error);
      res.status(500).send("Error sending notification");
    });
});
