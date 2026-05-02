importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBvFwuF3ywsM_7CUeCP6NPi1THhiNS3cKo",
  appId: "1:179045522471:web:5975dbc706f54e95470202",
  messagingSenderId: "179045522471",
  projectId: "kochigo-app",
  authDomain: "kochigo-app.firebaseapp.com",
  storageBucket: "kochigo-app.firebasestorage.app"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here if needed
});
