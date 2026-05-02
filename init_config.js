// init_config.js
// Initialize the app_config/pricing document
const admin = require("firebase-admin");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = getFirestore();

async function initConfig() {
    console.log("🛠️ Initializing app_config/pricing...\n");
    const docRef = db.collection("app_config").doc("pricing");

    const initialConfig = {
        postingFee: 9900,
        postingFeeLabel: "₹99",
        eventDurationDays: 30,
        isFreePeriod: true,
        freePeriodReason: "Free for launch phase",
        paymentEnabled: true,
        razorpayMode: "test",
        showPromoBanner: true,
        promoBannerText: "🎉 KochiGo v3.0 is LIVE! Enjoy a FREE posting period for a limited time.",
        promoBannerLink: "https://kochigo.com/updates",
        promoBannerColor: "#FF5247",
        promoBannerCta: "Learn More",
        maintenanceMode: false,
        maintenanceMessage: "KochiGo is upgrading to version 3.0! We'll be back in a few minutes.",
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: "system_init",
        changeLog: "Initial v3.0 dynamic config setup"
    };

    await docRef.set(initialConfig);
    console.log("✅ app_config/pricing initialized successfully.");
    process.exit(0);
}

initConfig().catch((err) => {
    console.error("❌ Error initializing config:", err);
    process.exit(1);
});
