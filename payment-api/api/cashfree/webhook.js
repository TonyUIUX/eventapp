export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    // In a production environment, verify the Cashfree signature here using:
    // req.headers['x-webhook-signature']
    // For now, we acknowledge the webhook and return 200.
    
    const body = req.body;
    console.log('Webhook received:', body);

    // If order is paid, you might trigger a Firebase Admin SDK function here to update the DB
    // e.g., if (body.data.payment.payment_status === 'SUCCESS') { ... }

    return res.status(200).json({ status: 'OK' });
  } catch (error) {
    console.error('Webhook Exception:', error);
    return res.status(500).json({ error: error.message });
  }
}
