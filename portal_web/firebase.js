// =========================================================================
// PCM WAYANAD - OFFICIAL FIREBASE CONFIGURATION & INITIALIZATION
// =========================================================================

window.firebaseConfig = {
  apiKey: "AIzaSyCBAxjvRnOSA6r4UPs2VK7P3lWd5beK1nQ",
  authDomain: "premier-ceiling-master-381b0.firebaseapp.com",
  projectId: "premier-ceiling-master-381b0",
  storageBucket: "premier-ceiling-master-381b0.firebasestorage.app",
  messagingSenderId: "949356430964",
  appId: "1:949356430964:web:2da1263f2f419f77763321"
};

if (typeof firebase !== 'undefined' && !firebase.apps.length) {
  try {
    firebase.initializeApp(window.firebaseConfig);
  } catch (e) {
    console.warn('[Firebase Init Notice]', e);
  }
}
