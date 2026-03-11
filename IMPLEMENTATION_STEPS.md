# Ayeyo Firebase Implementation Steps

## 1. Install backend dependencies

From the project root:

```bash
cd functions
npm install
```

## 2. Deploy Firestore rules and indexes

From the project root:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

This enforces:
- customers cannot create orders directly from the client
- only admins can edit `meal_sessions`, `menu_items`, and `settings/*`
- customers can only read their own orders and user profile

## 3. Deploy Cloud Functions

From the project root:

```bash
firebase deploy --only functions
```

This deploys:
- `placeOrder`: validates session window, stock, totals, and writes orders
- `setUserRole`: lets an existing admin assign roles and custom claims

## 4. Seed admin-managed business data

Before checkout can succeed, create:
- `settings/business`
- at least one `meal_sessions/{sessionId}`
- at least one `menu_items/{itemId}`

Recommended first records:

`settings/business`

```json
{
  "businessName": "Ayeyo Delivery",
  "phone": "+254700111222",
  "deliveryFee": 180,
  "currency": "KSh"
}
```

`meal_sessions/breakfast`

```json
{
  "name": "Breakfast",
  "startHour": 9,
  "startMinute": 0,
  "endHour": 11,
  "endMinute": 0,
  "isActive": true
}
```

`menu_items/chicken-biryani`

```json
{
  "name": "Chicken Biryani",
  "description": "Fragrant rice with tender chicken and house spices.",
  "price": 650,
  "imageUrl": "",
  "mealSessionId": "breakfast",
  "isAvailable": true,
  "stock": 20,
  "prepTimeMinutes": 25
}
```

## 5. Bootstrap the first admin

The `setUserRole` function requires an existing admin, so the first admin must be created manually with the Firebase Admin SDK, Firebase Console, or a local one-off script.

After that, admins can assign roles through the callable function.

## 6. Verify the customer flow

The Flutter app now:
- signs in anonymously during bootstrap
- reads menu and orders from Firestore
- sends checkout through the callable `placeOrder` function

Expected checkout result:
- inside the allowed meal window: order is created
- outside the allowed meal window: function rejects the order
- if stock is too low: function rejects the order

## 7. Build next

Recommended next implementation tasks:
- replace anonymous auth with phone/email sign-in
- create admin CRUD pages for sessions, menu items, and business settings
- add order status updates from admin panel
- add FCM notifications for order progress
