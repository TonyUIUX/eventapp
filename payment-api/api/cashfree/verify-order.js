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

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { orderId } = req.query;
    
    if (!orderId) {
        return res.status(400).json({ error: 'Missing orderId parameter' });
    }

    const isSandbox = process.env.CASHFREE_SANDBOX !== 'false';
    const baseUrl = isSandbox ? 'https://sandbox.cashfree.com/pg' : 'https://api.cashfree.com/pg';

    const response = await fetch(`${baseUrl}/orders/${orderId}`, {
      method: 'GET',
      headers: {
        'x-api-version': '2023-08-01',
        'x-client-id': process.env.CASHFREE_APP_ID,
        'x-client-secret': process.env.CASHFREE_SECRET_KEY,
      }
    });
    
    if (!response.ok) {
        const errText = await response.text();
        console.error('Cashfree Verify Order Error:', response.status, errText);
        return res.status(response.status).json({ error: errText });
    }

    const data = await response.json();
    return res.status(200).json({
      orderId: data.order_id,
      orderStatus: data.order_status,
      isPaid: data.order_status === 'PAID',
    });
  } catch (error) {
    console.error('Verify Order Exception:', error);
    return res.status(500).json({ error: error.message });
  }
}
