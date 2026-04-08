import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyBCy2uyooJJDvobBYSIDvrjTAwOigW8CRk",
  authDomain: "pyaroute.firebaseapp.com",
  projectId: "pyaroute",
  storageBucket: "pyaroute.firebasestorage.app",
  messagingSenderId: "356398123137",
  appId: "1:356398123137:web:c85f4e09f5e07d9a580" // Derived from project defaults
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
