export default async function handler(req, res) {
  // CORS setup
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { amountRupees, customerId, customerEmail, customerPhone, customerName, eventId } = req.body;
    
    if (!amountRupees || !customerId || !customerPhone || !eventId) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    const isSandbox = process.env.CASHFREE_SANDBOX !== 'false';
    const baseUrl = isSandbox ? 'https://sandbox.cashfree.com/pg' : 'https://api.cashfree.com/pg';
    
    // Max length 50 chars for order ID
    const rawId = `ev_${eventId}_${Date.now()}`;
    const orderId = rawId.length > 50 ? rawId.substring(rawId.length - 50) : rawId;

    // Optional webhook url
    const notifyUrl = `https://${req.headers.host}/api/cashfree/webhook`;

    // Format phone
    let phone = customerPhone.replace(/\D/g, '');
    if (phone.length > 10) phone = phone.slice(-10);
    phone = phone.padStart(10, '0');

    const response = await fetch(`${baseUrl}/orders`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-version': '2023-08-01',
        'x-client-id': process.env.CASHFREE_APP_ID,
        'x-client-secret': process.env.CASHFREE_SECRET_KEY,
      },
      body: JSON.stringify({
        order_id: orderId,
        order_amount: Number(amountRupees).toFixed(2),
        order_currency: 'INR',
        customer_details: {
          customer_id: customerId,
          customer_name: customerName || 'Evorra User',
          customer_email: customerEmail || 'no-email@evorra.app',
          customer_phone: phone,
        },
        order_meta: {
          notify_url: notifyUrl,
        },
        order_note: `Evorra event posting fee — eventId: ${eventId}`,
      })
    });
    
    if (!response.ok) {
        const errText = await response.text();
        console.error('Cashfree Create Order Error:', response.status, errText);
        return res.status(response.status).json({ error: errText });
    }

    const data = await response.json();
    return res.status(200).json({
      orderId: data.order_id,
      paymentSessionId: data.payment_session_id,
      amount: amountRupees,
      eventId: eventId
    });
  } catch (error) {
    console.error('Create Order Exception:', error);
    return res.status(500).json({ error: error.message });
  }
}
