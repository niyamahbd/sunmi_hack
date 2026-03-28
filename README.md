# Sunmi V2 Pro Print App

Flutter app — website থেকে text ও QR code print করার জন্য।

---

## ✅ ব্যবহারের আগে একটাই কাজ করুন

`lib/main.dart` ফাইলে এই লাইনটা খুঁজুন:

```dart
final String _websiteUrl = 'https://yourwebsite.com';
```

এখানে আপনার নিজের website URL বসান।

---

## 🚀 GitHub Actions দিয়ে APK বানানো (PC ছাড়া)

### Step 1 — GitHub-এ repo বানান
1. [github.com](https://github.com) → Login করুন
2. **New repository** → নাম দিন: `sunmi-print-app`
3. **Public** রাখুন → **Create repository**

### Step 2 — ফাইলগুলো upload করুন
1. Repo-তে গিয়ে **"uploading an existing file"** ক্লিক করুন
2. এই project-এর সব ফাইল ও ফোল্ডার drag করুন
3. **Commit changes** চাপুন

### Step 3 — APK build হওয়া দেখুন
1. Repo-তে **Actions** tab-এ যান
2. **"Build Sunmi APK"** workflow দেখবেন — চলছে (🟡)
3. ৫-৭ মিনিট অপেক্ষা করুন
4. সবুজ ✅ হলে ক্লিক করুন → **Artifacts** → **sunmi-print-release** download করুন

### Step 4 — Sunmi-তে install করুন
1. ZIP extract করুন → `app-release.apk` পাবেন
2. APK ফাইলটা Sunmi V2 Pro-তে copy করুন (USB বা Google Drive)
3. Sunmi-তে install করুন (Unknown sources allow করতে হবে)

---

## 📱 App ব্যবহার

App-এ দুটো Tab আছে:

**Website Tab** → আপনার website WebView-এ খুলবে

**Manual Print Tab** → সরাসরি text ও QR দিয়ে print করুন

---

## 🌐 Website থেকে Print trigger করতে

আপনার website-এর কোনো button-এ এই JS যোগ করুন:

```javascript
function printReceipt(shopName, text, qrUrl) {
  // Sunmi app-এ থাকলে print হবে, নইলে কিছু হবে না
  if (window.SunmiPrint) {
    SunmiPrint.postMessage(JSON.stringify({
      shop: shopName,
      text: text,
      qr: qrUrl
    }));
  }
}

// উদাহরণ:
printReceipt(
  "আমার দোকান",
  "Item: পণ্যের নাম\nমূল্য: ৳ ৫০০\nতারিখ: " + new Date().toLocaleDateString('bn-BD'),
  "https://yourwebsite.com/order/123"
);
```

---

## ❓ সমস্যা হলে

- **APK install হচ্ছে না** → Settings → Security → Unknown sources → ON করুন
- **Print হচ্ছে না** → Sunmi-র built-in printer service চালু আছে কিনা দেখুন
- **Website লোড হচ্ছে না** → URL ঠিক আছে কিনা `main.dart`-এ চেক করুন
