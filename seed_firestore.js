// seed_firestore.js
// Run this to auto-upload all 5 sample events to Firestore
// Usage:
//   npm install firebase-admin
//   node seed_firestore.js

const admin = require("firebase-admin");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

// -------------------------------------------------------
// 🔧 CHANGE THIS: path to your service account key JSON
// Download it from:
// Firebase Console → Project Settings → Service accounts → Generate new private key
// -------------------------------------------------------
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = getFirestore();

// -------------------------------------------------------
// Helper: build a Firestore Timestamp from date + time
// -------------------------------------------------------
function ts(year, month, day, hour = 0, minute = 0) {
    return Timestamp.fromDate(new Date(year, month - 1, day, hour, minute, 0));
}

// -------------------------------------------------------
// Today = April 12 2026, Weekend = April 18-19 2026
// -------------------------------------------------------
const TODAY = { y: 2026, m: 4, d: 12 };
const SAT = { y: 2026, m: 4, d: 18 };
const SUN = { y: 2026, m: 4, d: 19 };

const events = [
    {
        title: "Kochi Open Mic Night",
        category: "comedy",
        description:
            "Kochi's biggest open mic night returns! Join us for an evening of stand-up comedy, spoken word, and raw talent from local comedians. Whether you're a first-timer or a seasoned performer, this is your stage. Free entry, first come first served.",
        date: ts(TODAY.y, TODAY.m, TODAY.d, 19, 0),
        location: "Kashi Art Café, Fort Kochi",
        mapLink: "https://maps.google.com/?q=Kashi+Art+Cafe+Fort+Kochi",
        imageUrl:
            "https://images.unsplash.com/photo-1527224857830-43a7acc85260?w=800",
        organizer: "Kochi Comedy Collective",
        contactPhone: "+919876543210",
        contactInstagram: "@kochicomedy",
        isFeatured: true,
        isActive: true,
        status: "active",
        userId: "system_seed",
        createdAt: ts(TODAY.y, TODAY.m, TODAY.d, 10, 0),
    },
    {
        title: "Flutter & Firebase Workshop",
        category: "tech",
        description:
            "Hands-on workshop for developers who want to build production apps with Flutter and Firebase. We'll cover Firestore integration, authentication patterns, and deployment. Bring your laptop. Limited seats.",
        date: ts(SAT.y, SAT.m, SAT.d, 10, 0),
        location: "Startup Village, Kalamassery",
        mapLink: "https://maps.google.com/?q=Startup+Village+Kalamassery",
        imageUrl:
            "https://images.unsplash.com/photo-1591115765373-5207764f72e7?w=800",
        organizer: "GDG Kochi",
        contactPhone: null,
        contactInstagram: "@gdgkochi",
        isFeatured: false,
        isActive: true,
        status: "active",
        userId: "system_seed",
        createdAt: ts(TODAY.y, TODAY.m, TODAY.d, 11, 0),
    },
    {
        title: "Yoga at the Beach",
        category: "fitness",
        description:
            "Start your Saturday right with a sunrise yoga session at Cherai Beach. Suitable for all levels — beginners welcome. Bring your own mat. Session runs for 1 hour followed by fresh coconut water. Pure Kerala vibes.",
        date: ts(SAT.y, SAT.m, SAT.d, 6, 30),
        location: "Cherai Beach, North Paravur",
        mapLink: "https://maps.google.com/?q=Cherai+Beach+Kerala",
        imageUrl:
            "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800",
        organizer: "Kerala Wellness Co.",
        contactPhone: "+919765432100",
        contactInstagram: "@keralawellness",
        isFeatured: false,
        isActive: true,
        status: "active",
        userId: "system_seed",
        createdAt: ts(TODAY.y, TODAY.m, TODAY.d, 12, 0),
    },
    {
        title: "Indie Music Night: Local Bands",
        category: "music",
        description:
            "Four of Kochi's best indie bands perform live in an intimate venue setting. Featuring experimental rock, folk fusion, and jazz. Doors open at 6 PM. Tickets at the door. Food and drinks available.",
        date: ts(SUN.y, SUN.m, SUN.d, 18, 0),
        location: "The Barge, Marine Drive",
        mapLink: "https://maps.google.com/?q=The+Barge+Marine+Drive+Kochi",
        imageUrl:
            "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800",
        organizer: "Kochi Live Music",
        contactPhone: null,
        contactInstagram: "@kochilivemusic",
        isFeatured: true,
        isActive: true,
        status: "active",
        userId: "system_seed",
        createdAt: ts(TODAY.y, TODAY.m, TODAY.d, 13, 0),
    },
    {
        title: "Mural Art Walk — Fort Kochi",
        category: "art",
        description:
            "Join our guided walk through Fort Kochi's iconic street murals. A local artist will explain the stories behind the works and the Kochi-Muziris Biennale legacy. 2 hours. Meeting point at David Hall.",
        date: ts(SAT.y, SAT.m, SAT.d, 9, 0),
        location: "David Hall, Fort Kochi",
        mapLink: "https://maps.google.com/?q=David+Hall+Fort+Kochi",
        imageUrl:
            "https://images.unsplash.com/photo-1561839561-b13bcfe4b50a?w=800",
        organizer: "Kochi Arts Foundation",
        contactPhone: "+918888877777",
        contactInstagram: "@kochiartswalk",
        isFeatured: false,
        isActive: true,
        status: "active",
        userId: "system_seed",
        createdAt: ts(TODAY.y, TODAY.m, TODAY.d, 14, 0),
    },
];

// -------------------------------------------------------
// Upload all events
// -------------------------------------------------------
async function seed() {
    console.log("🌱 Seeding Firestore with sample events...\n");
    const collection = db.collection("events");

    for (const event of events) {
        const ref = await collection.add(event);
        console.log(`✅ Added: "${event.title}" → ID: ${ref.id}`);
    }

    console.log("\n🎉 Done! All 5 events uploaded to Firestore.");
    console.log("Open your app and set date filter to Today or This Weekend.\n");
    process.exit(0);
}

seed().catch((err) => {
    console.error("❌ Error seeding Firestore:", err);
    process.exit(1);
});
