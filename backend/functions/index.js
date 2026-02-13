const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// 1. Order Creation Trigger
// Updates stock and notifies owner
exports.onOrderCreated = functions.firestore
    .document('shops/{shopId}/orders/{orderId}')
    .onCreate(async (snap, context) => {
        const order = snap.data();
        const shopId = context.params.shopId;

        // 1. Update Stock (Atomically)
        const batch = admin.firestore().batch();
        for (const item of order.items) {
            const productRef = admin.firestore().doc(`shops/${shopId}/products/${item.productId}`);
            batch.update(productRef, {
                stock: admin.firestore.FieldValue.increment(-item.quantity)
            });
        }
        await batch.commit();

        // 2. Notify Owner (Critical)
        // Note: In real app, we should look up Owner ID via Shop ID.
        // For this hackathon/MVP, we assume we can broadcast to 'owners' topic or find the owner.
        // Let's write to a known owner ID or dynamic query.

        // Strategy: Get the shop document to find 'ownerId'
        const shopDoc = await admin.firestore().doc(`shops/${shopId}`).get();
        const ownerId = shopDoc.data().ownerId;

        if (ownerId) {
            await admin.firestore().collection('users').doc(ownerId).collection('notifications').add({
                title_en: 'New Order Received! 🛍️',
                body_en: `Order #${context.params.orderId.slice(0, 5)}... for ₹${order.totalAmount}`,
                title_ta: 'புதிய ஆர்டர் வந்துள்ளது! 🛍️',
                body_ta: `ஆர்டர் #${context.params.orderId.slice(0, 5)}... மதிப்பு ₹${order.totalAmount}`,
                type: 'NEW_ORDER',
                priority: 'high',
                isRead: false,
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                data: { orderId: context.params.orderId }
            });

            // Send Push
            const ownerUser = await admin.firestore().collection('users').doc(ownerId).get();
            const tokens = ownerUser.data().fcmTokens || [];
            if (tokens.length > 0) {
                await admin.messaging().sendToDevice(tokens, {
                    notification: {
                        title: 'New Order Received! 🛍️',
                        body: `₹${order.totalAmount} - Open App to Accept`,
                    }
                });
            }
        }
    });

// 2. Order Status Update Trigger (Notifies Farmer)
exports.onOrderStatusUpdate = functions.firestore
    .document('orders/{orderId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();

        // Only trigger if status changed
        if (newData.status === oldData.status) return;

        const userId = newData.userId;
        const status = newData.status; // 'ready', 'picked', 'cancelled'

        // Prepare Notification Data
        let titleEn = 'Order Update';
        let bodyEn = `Your order is now ${status}`;
        let titleTa = 'ஆர்டர் நிலை';
        let bodyTa = `உங்கள் ஆர்டர் இப்போது ${status}`;
        let type = 'ORDER_UPDATE';
        let priority = 'normal';

        if (status === 'ready') {
            titleEn = 'Order Ready for Pickup!';
            bodyEn = 'Your items are packed and ready at the shop.';
            titleTa = 'ஆர்டர் தயார்!';
            bodyTa = 'உங்கள் பொருட்கள் கடையில் தயாராக உள்ளன.';
            priority = 'important';
        } else if (status === 'picked') {
            titleEn = 'Order Completed';
            bodyEn = 'Thank you for shopping with us!';
            titleTa = 'ஆர்டர் முடிந்தது';
            bodyTa = 'எங்களுடன் ஷாப்பிங் செய்ததற்கு நன்றி!';
            type = 'ORDER_UPDATE';
        } else if (status === 'cancelled') {
            titleEn = 'Order Cancelled';
            bodyEn = 'Your order has been cancelled.';
            titleTa = 'ஆர்டர் ரத்து';
            bodyTa = 'உங்கள் ஆர்டர் ரத்து செய்யப்பட்டது.';
            type = 'critical';
            priority = 'high';
        }

        // 1. Write to Firestore History (So it shows in UI)
        await admin.firestore().collection('users').doc(userId).collection('notifications').add({
            title_en: titleEn,
            body_en: bodyEn,
            title_ta: titleTa,
            body_ta: bodyTa,
            type: type,
            priority: priority,
            isRead: false,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            data: { orderId: context.params.orderId }
        });

        // 2. Send FCM Push Notification
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        const fcmTokens = userDoc.data().fcmTokens || [];

        if (fcmTokens.length > 0) {
            await admin.messaging().sendToDevice(fcmTokens, {
                notification: {
                    title: titleEn,
                    body: bodyEn,
                },
                data: {
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    type: type
                }
            });
        }
    });

// 3. New User Welcome Notification
exports.onUserCreated = functions.firestore
    .document('users/{userId}')
    .onCreate(async (snap, context) => {
        const userId = context.params.userId;

        await admin.firestore().collection('users').doc(userId).collection('notifications').add({
            title_en: 'Welcome to SmartAgro!',
            body_en: 'We are happy to have you here. Start adding your crops.',
            title_ta: 'பெயர் உழவன் சந்தைக்கு வரவேற்கிறோம்!',
            body_ta: 'நீங்கள் இணைந்ததில் மகிழ்ச்சி. உங்கள் பயிர்களைச் சேர்க்கவும்.',
            type: 'system',
            priority: 'normal',
            isRead: false,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            data: {}
        });
    });

// 4. Low Stock Alert Trigger
// Triggers when a product's stock is updated and falls below threshold
exports.onProductUpdate = functions.firestore
    .document('shops/{shopId}/products/{productId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();

        const currentStock = newData.stock || 0;
        const previousStock = oldData.stock || 0;
        const threshold = 10;

        // Only trigger if crossed threshold downwards
        if (currentStock <= threshold && previousStock > threshold) {
            const shopId = context.params.shopId;
            const shopDoc = await admin.firestore().doc(`shops/${shopId}`).get();
            const ownerId = shopDoc.data().ownerId;

            if (ownerId) {
                await admin.firestore().collection('users').doc(ownerId).collection('notifications').add({
                    title_en: 'Low Stock Alert ⚠️',
                    body_en: `Product '${newData.name_en}' is running low (${currentStock} left).`,
                    title_ta: 'குறைந்த இருப்பு எச்சரிக்கை ⚠️',
                    body_ta: `'${newData.name_ta}' தயாரிப்பு குறைவாக உள்ளது (${currentStock} உள்ளது).`,
                    type: 'LOW_STOCK',
                    priority: 'high',
                    isRead: false,
                    sentAt: admin.firestore.FieldValue.serverTimestamp(),
                    data: { productId: context.params.productId }
                });
            }
        }
    });
// 5. Scheduled Backups (Disaster Recovery)
exports.scheduledFirestoreExport = functions.pubsub
    .schedule('every 24 hours')
    .timeZone('Asia/Kolkata')
    .onRun(async (context) => {
        const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
        const databaseName = admin.firestore().databaseName;
        const bucket = `gs://${projectId}-backups`;

        try {
            await admin.firestore.v1.FirestoreClient.exportDocuments({
                name: databaseName,
                outputUriPrefix: bucket,
                // Empty collectionIds exports all collections
                collectionIds: []
            });
            console.log(`Exported database to ${bucket}`);
        } catch (error) {
            console.error('Export failed:', error);
            // In production, send an alert to admin here
        }
    });
