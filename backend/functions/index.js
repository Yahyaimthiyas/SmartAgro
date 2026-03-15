const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// 1. Notify Owner when a new order is placed
exports.onOrderPlaced = functions.firestore
    .document("orders/{orderId}")
    .onSelectionModeChanged(async (snapshot, context) => {
        const orderData = snapshot.data();
        const orderId = context.params.orderId;

        // Find Owner tokens
        const owners = await admin.firestore().collection("users").where("role", "==", "owner").get();
        
        let tokens = [];
        owners.forEach(owner => {
            if (owner.data().fcmTokens) {
                tokens = tokens.concat(owner.data().fcmTokens);
            }
        });

        if (tokens.length === 0) return null;

        const payload = {
            notification: {
                title: "New Order Received!",
                body: `Order #${orderId} has been placed. Check the dashboard.`,
                sound: "default",
            },
            data: {
                orderId: orderId,
                click_action: "FLUTTER_NOTIFICATION_CLICK"
            }
        };

        return admin.messaging().sendToDevice(tokens, payload);
    });

// 2. Notify Farmer when order status changes (Ready/Picked)
exports.onOrderStatusUpdate = functions.firestore
    .document("orders/{orderId}")
    .onUpdate(async (change, context) => {
        const after = change.after.data();
        const before = change.before.data();
        const orderId = context.params.orderId;

        if (after.status === before.status) return null;

        const farmerId = after.userId;
        const farmerDoc = await admin.firestore().collection("users").doc(farmerId).get();
        
        const tokens = farmerDoc.data()?.fcmTokens || [];
        if (tokens.length === 0) return null;

        let title = "Order Update";
        let body = `Your order #${orderId} is now ${after.status}.`;

        if (after.status === 'ready') {
            title = "Order Ready!";
            body = "Your order is ready at the shop. Please pick it up.";
        } else if (after.status === 'picked') {
            title = "Order Delivered";
            body = "Thank you for shopping with Smart Agro!";
        }

        const payload = {
            notification: {
                title: title,
                body: body,
                sound: "default",
            },
            data: {
                orderId: orderId,
                status: after.status,
                click_action: "FLUTTER_NOTIFICATION_CLICK"
            }
        };

        return admin.messaging().sendToDevice(tokens, payload);
    });
