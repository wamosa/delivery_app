const admin = require("firebase-admin");
const { onCall, HttpsError } = require("firebase-functions/v2/https");

admin.initializeApp();

const db = admin.firestore();
const businessTimeZone = "Africa/Nairobi";

function validateItemsPayload(items) {
  if (!Array.isArray(items) || items.length === 0) {
    throw new HttpsError("invalid-argument", "At least one order item is required.");
  }

  return items.map((item, index) => {
    if (!item || typeof item.itemId !== "string" || item.itemId.trim().length === 0) {
      throw new HttpsError("invalid-argument", `Order item ${index + 1} is missing itemId.`);
    }

    const quantity = Number(item.quantity);
    if (!Number.isInteger(quantity) || quantity <= 0) {
      throw new HttpsError("invalid-argument", `Order item ${index + 1} has an invalid quantity.`);
    }

    return {
      itemId: item.itemId.trim(),
      quantity,
    };
  });
}

function minutesOfDayFromSession(session) {
  return {
    start: (session.startHour * 60) + session.startMinute,
    end: (session.endHour * 60) + session.endMinute,
  };
}

function minutesOfDayFromDate(date) {
  const formatter = new Intl.DateTimeFormat("en-GB", {
    timeZone: businessTimeZone,
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
  const parts = formatter.formatToParts(date);
  const hour = Number(parts.find((part) => part.type === "hour")?.value || "0");
  const minute = Number(parts.find((part) => part.type === "minute")?.value || "0");
  return (hour * 60) + minute;
}

function ensureSessionOpen(session) {
  if (!session.isActive) {
    throw new HttpsError("failed-precondition", "This meal session is currently closed.");
  }

  const now = new Date();
  const currentMinutes = minutesOfDayFromDate(now);
  const { start, end } = minutesOfDayFromSession(session);

  if (currentMinutes < start || currentMinutes > end) {
    throw new HttpsError("failed-precondition", "Ordering is not allowed for this meal session right now.");
  }
}

exports.placeOrder = onCall({ enforceAppCheck: true }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in to place an order.");
  }

  const itemsInput = validateItemsPayload(request.data.items);
  const deliveryType = typeof request.data.deliveryType === "string"
    ? request.data.deliveryType.trim()
    : "";
  const address = typeof request.data.address === "string"
    ? request.data.address.trim()
    : "";

  if (!deliveryType) {
    throw new HttpsError("invalid-argument", "deliveryType is required.");
  }

  if (!address) {
    throw new HttpsError("invalid-argument", "address is required.");
  }

  const result = await db.runTransaction(async (transaction) => {
    const settingsRef = db.doc("settings/business");
    const settingsSnap = await transaction.get(settingsRef);
    if (!settingsSnap.exists) {
      throw new HttpsError("failed-precondition", "Business settings have not been configured.");
    }

    const settings = settingsSnap.data();
    const deliveryFee = Number(settings.deliveryFee || 0);
    const orderingOpen = settings.orderingOpen !== false;
    const pickupEnabled = settings.pickupEnabled !== false;

    if (!orderingOpen) {
      throw new HttpsError("failed-precondition", "Ordering is currently closed.");
    }

    if (deliveryType === "pickup" && !pickupEnabled) {
      throw new HttpsError("failed-precondition", "Pickup orders are currently disabled.");
    }

    const menuRefs = itemsInput.map((item) => db.collection("menu_items").doc(item.itemId));
    const menuSnaps = await Promise.all(menuRefs.map((ref) => transaction.get(ref)));

    const menuItems = menuSnaps.map((snap, index) => {
      if (!snap.exists) {
        throw new HttpsError("not-found", `Menu item ${itemsInput[index].itemId} was not found.`);
      }
      return {
        id: snap.id,
        ...snap.data(),
      };
    });

    const sessionIds = [...new Set(menuItems.map((item) => item.mealSessionId))];
    if (sessionIds.length !== 1) {
      throw new HttpsError("failed-precondition", "All items in an order must belong to the same meal session.");
    }

    const sessionRef = db.collection("meal_sessions").doc(sessionIds[0]);
    const sessionSnap = await transaction.get(sessionRef);
    if (!sessionSnap.exists) {
      throw new HttpsError("failed-precondition", "The meal session for this order does not exist.");
    }

    const session = sessionSnap.data();
    ensureSessionOpen(session);

    let subtotal = 0;
    const orderItems = itemsInput.map((itemRequest, index) => {
      const menuItem = menuItems[index];
      if (!menuItem.isAvailable) {
        throw new HttpsError("failed-precondition", `${menuItem.name} is not available right now.`);
      }
      if (Number(menuItem.stock || 0) < itemRequest.quantity) {
        throw new HttpsError("failed-precondition", `${menuItem.name} does not have enough stock.`);
      }

      const unitPrice = Number(menuItem.price || 0);
      subtotal += unitPrice * itemRequest.quantity;

      transaction.update(menuRefs[index], {
        stock: Number(menuItem.stock || 0) - itemRequest.quantity,
      });

      return {
        itemId: menuItem.id,
        name: menuItem.name,
        quantity: itemRequest.quantity,
        unitPrice,
      };
    });

    const total = subtotal + deliveryFee;
    const orderRef = db.collection("orders").doc();
    transaction.set(orderRef, {
      userId: request.auth.uid,
      items: orderItems,
      subtotal,
      deliveryFee,
      total,
      status: "pending",
      mealSessionId: sessionRef.id,
      deliveryType,
      address,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      orderId: orderRef.id,
      subtotal,
      deliveryFee,
      total,
      status: "pending",
    };
  });

  return result;
});

exports.setUserRole = onCall({ enforceAppCheck: true }, async (request) => {
  if (!request.auth?.token?.admin) {
    throw new HttpsError("permission-denied", "Only admins can assign roles.");
  }

  const userId = typeof request.data.userId === "string" ? request.data.userId.trim() : "";
  const role = typeof request.data.role === "string" ? request.data.role.trim() : "";
  const adminRole = role === "admin";

  if (!userId || !role) {
    throw new HttpsError("invalid-argument", "userId and role are required.");
  }

  await admin.auth().setCustomUserClaims(userId, {
    admin: adminRole,
    role,
  });

  await db.collection("users").doc(userId).set(
    {
      role,
    },
    { merge: true },
  );

  return { userId, role };
});
