// seed_users.js
// Run this to auto-create test users in Firebase Auth and Firestore
// Usage:
//   npm install firebase-admin
//   node seed_users.js

const admin = require("firebase-admin");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = getFirestore();
const auth = admin.auth();

const users = [
    {
        email: "admin@kochigo.com",
        password: "Test@1234",
        displayName: "KochiGo Admin",
        isVerifiedOrg: true,
        role: "admin"
    },
    {
        email: "user_a@test.com",
        password: "Test@1234",
        displayName: "Regular User A",
        isVerifiedOrg: false,
        role: "user"
    },
    {
        email: "org_b@test.com",
        password: "Test@1234",
        displayName: "Verified Org B",
        isVerifiedOrg: true,
        role: "organizer"
    },
    {
        email: "testuser.kochigo@gmail.com",
        password: "Test@1234",
        displayName: "QA Test User",
        isVerifiedOrg: false,
        role: "user"
    },
    {
        email: "organiser.kochigo@gmail.com",
        password: "Test@1234",
        displayName: "QA Organiser",
        isVerifiedOrg: true,
        role: "organizer"
    }
];

async function seedUsers() {
    console.log("👥 Seeding Firebase Auth and Firestore with test users...\n");

    for (const userData of users) {
        try {
            // 1. Create/Update Auth User
            let userRecord;
            try {
                userRecord = await auth.getUserByEmail(userData.email);
                console.log(`ℹ️ User already exists: ${userData.email}. Updating password...`);
                await auth.updateUser(userRecord.uid, {
                    password: userData.password,
                    displayName: userData.displayName
                });
            } catch (error) {
                if (error.code === 'auth/user-not-found') {
                    userRecord = await auth.createUser({
                        email: userData.email,
                        password: userData.password,
                        displayName: userData.displayName,
                    });
                    console.log(`✅ Created Auth User: ${userData.email}`);
                } else {
                    throw error;
                }
            }

            // 2. Create/Update Firestore Profile
            await db.collection("users").doc(userRecord.uid).set({
                uid: userRecord.uid,
                email: userData.email,
                displayName: userData.displayName,
                isVerifiedOrg: userData.isVerifiedOrg,
                role: userData.role,
                createdAt: FieldValue.serverTimestamp(),
                lastActiveAt: FieldValue.serverTimestamp(),
                totalEventsPosted: 0,
                totalViews: 0,
                photoUrl: `https://ui-avatars.com/api/?name=${encodeURIComponent(userData.displayName)}&background=random`,
                bio: userData.role === 'admin' ? "System Administrator" : `Test ${userData.role} account`,
            }, { merge: true });

            console.log(`✅ Synced Firestore profile for: ${userData.displayName} (${userRecord.uid})\n`);

        } catch (err) {
            console.error(`❌ Error seeding user ${userData.email}:`, err.message);
        }
    }

    console.log("🎉 User seeding complete!");
    process.exit(0);
}

seedUsers().catch((err) => {
    console.error("❌ Fatal Error:", err);
    process.exit(1);
});
