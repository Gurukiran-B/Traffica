// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { getStorage } from "firebase/storage";

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyDAbiDXwTLT9Wl1mkFhMKqfLlEEHJBjMwI",
  authDomain: "traffica-mini.firebaseapp.com",
  projectId: "traffica-mini",
  storageBucket: "traffica-mini.firebasestorage.app",
  messagingSenderId: "245902879974",
  appId: "1:245902879974:web:5924a2bf096f2decd61f27",
  measurementId: "G-C882L35MMV"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
const analytics = getAnalytics(app);
const db = getFirestore(app);
const auth = getAuth(app);
const storage = getStorage(app);

// Export services for use in other files
export { db, auth, storage, analytics };
