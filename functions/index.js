const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnNewMessage = functions.firestore
  .document("chatRooms/{chatRoomId}/chats/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();
    const chatRoomId = context.params.chatRoomId;

    // Ambil token untuk mengirim notifikasi
    const tokensSnapshot = await admin
      .firestore()
      .collection("chatRooms")
      .doc(chatRoomId)
      .collection("users")
      .get();

    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);

    const payload = {
      notification: {
        title: "New Message",
        body: messageData.message,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    // Kirim notifikasi
    await admin.messaging().sendToDevice(tokens, payload);
  });
