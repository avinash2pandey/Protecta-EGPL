# 📱 Protecta iOS App

A production-ready iOS application built using **Swift + WKWebView**, designed to replicate and enhance an WebView-based CRM app.

This app supports advanced features such as:

* 🔥 WebView-based CRM loading
* 📸 File upload (Camera + PDF + Multi-select)
* 🔔 Firebase Push Notifications (FCM)
* 🔗 Deep linking from notifications
* 🌐 JavaScript ↔ Native bridge
* 📦 Offline caching support

---

## 🚀 Features

### ✅ WebView (Core)

* Loads CRM: `https://crm.espareware.com/`
* JavaScript enabled
* Cookie support
* Navigation handling
* Back navigation support

---

### 📸 Advanced File Upload

* Camera capture
* File picker (Images + PDF)
* Multi-file selection
* Temporary file storage

---

### 🔔 Push Notifications (Firebase)

* FCM token generation
* Token sync with backend
* Notification handling (foreground + background)
* Deep linking support

---

### 🔗 Deep Linking

* Open specific URLs inside WebView
* Triggered from push notifications

Example payload:

```json
{
  "url": "https://crm.espareware.com/leads"
}
```

---

### 🌐 JavaScript Bridge (Important for CRM)

Communication between WebView and iOS app

#### JS → iOS

```javascript
window.webkit.messageHandlers.iosBridge.postMessage({
  action: "getToken"
});
```

#### iOS → JS

```javascript
window.onReceiveToken = function(token) {
  console.log("Received token:", token);
};
```

---

### 📦 Offline Caching

* URLCache enabled
* Fallback offline page (`offline.html`)
* Cache-first loading strategy

---
## 🔐 Permissions Used

| Permission    | Purpose             |
| ------------- | ------------------- |
| Camera        | Upload images       |
| Photo Library | File selection      |
| Location      | WebView geolocation |
| Notifications | Push alerts         |


## 👨‍💻 Author

**Avinash Pandey**

* Senior Mobile Developer (15+ yrs)
* React Native | Flutter | iOS | Android
* AI + LLM + Generative AI integrations

---

## 📄 License

This project is for internal use purposes.
