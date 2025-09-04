// netlify/functions/proxy.js
const fetch = require('cross-fetch'); // ✅ Use cross-fetch

exports.handler = async (event, context) => {
  const url = event.queryStringParameters.url;

  if (!url) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Missing "url" parameter' }),
    };
  }

  try {
    const response = await fetch(url);
    const data = await response.text();

    return {
      statusCode: response.status,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET',
        'Access-Control-Allow-Headers': 'Content-Type',
      },
      body: data,
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Proxy failed', message: error.message }),
    };
  }
};