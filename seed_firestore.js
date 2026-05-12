// seed_firestore.js
// Run this to auto-upload all 5 sample events to Firestore
// Events are dated starting from TODAY so they always appear in app
// Usage:
//   npm install firebase-admin
//   node seed_firestore.js

const admin = require("firebase-admin");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = getFirestore();

// -------------------------------------------------------
// Helper: build a Timestamp N days from now at a given hour
// -------------------------------------------------------
function daysFromNow(days, hour = 18, minute = 0) {
    const d = new Date();
    d.setDate(d.getDate() + days);
    d.setHours(hour, minute, 0, 0);
    return Timestamp.fromDate(d);
}

const now = new Date();

const events = [
    {
        title: "Kochi Open Mic Night",
        category: "comedy",
        description:
            "Kochi's biggest open mic night returns! Join us for an evening of stand-up comedy, spoken word, and raw talent from local comedians. Whether you're a first-timer or a seasoned performer, this is your stage. Free entry, first come first served.",
        date: daysFromNow(0, 19, 0), // tonight
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
        postedBy: "system_seed",
        postedByName: "KochiGo Team",
        price: "Free",
        tags: ["free", "popular"],
        totalViews: 0,
        totalShares: 0,
        isVerifiedOrg: true,
        tier: "standard",
        paymentStatus: "free_period",
        createdAt: Timestamp.fromDate(now),
    },
    {
        title: "Flutter & Firebase Workshop",
        category: "tech",
        description:
            "Hands-on workshop for developers who want to build production apps with Flutter and Firebase. We'll cover Firestore integration, authentication patterns, and deployment. Bring your laptop. Limited seats.",
        date: daysFromNow(1, 10, 0), // tomorrow
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
        postedBy: "system_seed",
        postedByName: "GDG Kochi",
        price: "Free",
        tags: ["tech", "workshop"],
        totalViews: 0,
        totalShares: 0,
        isVerifiedOrg: true,
        tier: "standard",
        paymentStatus: "free_period",
        createdAt: Timestamp.fromDate(now),
    },
    {
        title: "Yoga at the Beach",
        category: "fitness",
        description:
            "Start your Saturday right with a sunrise yoga session at Cherai Beach. Suitable for all levels — beginners welcome. Bring your own mat. Session runs for 1 hour followed by fresh coconut water. Pure Kerala vibes.",
        date: daysFromNow(2, 6, 30), // 2 days from now
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
        postedBy: "system_seed",
        postedByName: "Kerala Wellness Co.",
        price: "Free",
        tags: ["fitness", "outdoor"],
        totalViews: 0,
        totalShares: 0,
        isVerifiedOrg: false,
        tier: "standard",
        paymentStatus: "free_period",
        createdAt: Timestamp.fromDate(now),
    },
    {
        title: "Indie Music Night: Local Bands",
        category: "music",
        description:
            "Four of Kochi's best indie bands perform live in an intimate venue setting. Featuring experimental rock, folk fusion, and jazz. Doors open at 6 PM. Tickets at the door. Food and drinks available.",
        date: daysFromNow(3, 18, 0), // 3 days from now
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
        postedBy: "system_seed",
        postedByName: "Kochi Live Music",
        price: "₹200",
        tags: ["music", "popular", "limited"],
        totalViews: 0,
        totalShares: 0,
        isVerifiedOrg: true,
        tier: "standard",
        paymentStatus: "free_period",
        createdAt: Timestamp.fromDate(now),
    },
    {
        title: "Mural Art Walk — Fort Kochi",
        category: "art",
        description:
            "Join our guided walk through Fort Kochi's iconic street murals. A local artist will explain the stories behind the works and the Kochi-Muziris Biennale legacy. 2 hours. Meeting point at David Hall.",
        date: daysFromNow(4, 9, 0), // 4 days from now
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
        postedBy: "system_seed",
        postedByName: "Kochi Arts Foundation",
        price: "Free",
        tags: ["art", "outdoor", "family"],
        totalViews: 0,
        totalShares: 0,
        isVerifiedOrg: false,
        tier: "standard",
        paymentStatus: "free_period",
        createdAt: Timestamp.fromDate(now),
    },
];

// -------------------------------------------------------
// Upload all events — delete existing system_seed events first
// -------------------------------------------------------
async function seed() {
    console.log("🌱 Seeding Firestore with sample events...\n");
    const collection = db.collection("events");

    // Remove old seed data to avoid duplicates
    console.log("🧹 Cleaning up old seeded events...");
    const existing = await collection
        .where("userId", "==", "system_seed")
        .get();
    const deletePromises = existing.docs.map((doc) => doc.ref.delete());
    await Promise.all(deletePromises);
    console.log(`   Deleted ${existing.docs.length} old events.\n`);

    for (const event of events) {
        const ref = await collection.add(event);
        const eventDate = event.date.toDate();
        console.log(
            `✅ Added: "${event.title}" → ID: ${ref.id} | Date: ${eventDate.toLocaleDateString("en-IN")}`
        );
    }

    console.log("\n🎉 Done! All 5 events uploaded to Firestore.");
    console.log(
        "Events span today → next 4 days. Open app with 'This Week' filter.\n"
    );
    process.exit(0);
}

seed().catch((err) => {
    console.error("❌ Error seeding Firestore:", err);
    process.exit(1);
});
