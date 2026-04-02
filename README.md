# chatty

A cross-platform, real-time messaging application built with **Flutter** and **Firebase**. Chatty enables users to connect via unique friend codes, manage friend requests through a robust transactional system, and receive real-time updates.

## 🚀 Features

*   **Real-time Messaging:** High-performance chat synchronization using Firestore Streams and RxDart.
*   **Social Graph Management:** A complete friendship system including:
    *   Unique 8-character friend code generation.
    *   Transactional friend requests to prevent race conditions.
    *   Status tracking (Pending, Accepted, Declined).
*   **Serverless Backend:** TypeScript-based Firebase Cloud Functions to handle heavy lifting and notifications.
*   **Cross-Platform:** Architected for iOS, Android, macOS, Windows, and Linux.
*   **Push Notifications:** FCM integration with automated token cleanup logic to ensure delivery reliability.

## 🛠️ Tech Stack

*   **Frontend:** Flutter, Dart, RxDart (Reactive Programming), Provider (State Management).
*   **Backend:** Firebase (Firestore, Authentication, Cloud Messaging).
*   **Cloud Logic:** Node.js, TypeScript (Firebase Cloud Functions).

## 🏗️ Technical Highlights

*   **Data Integrity:** Implemented Firestore Transactions to handle mutual friendship creation, ensuring data consistency across distributed documents.
*   **Reactive Streams:** Utilized `rxdart` to pipe authentication states directly into Firestore listeners, providing a seamless UX for logged-in/logged-out states.
*   **Scalable Notifications:** Developed a multicast notification system in TypeScript that handles batching (500 tokens/batch) and automatically prunes stale device tokens from the database.

## 🔧 Setup

1.  **Prerequisites:** Install Flutter SDK and Firebase CLI.
2.  **Configuration:**
    ```bash
    flutter pub get
    flutterfire configure
    ```
3.  **Functions Deployment:**
    ```bash
    cd functions
    npm install
    firebase deploy --only functions
    ```
