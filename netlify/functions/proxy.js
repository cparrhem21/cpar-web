// netlify/functions/proxy.js

exports.handler = async (event, context) => {
  const url = event.queryStringParameters?.url;

  if (!url) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Missing "url" parameter' }),
    };
  }

  try {
    const method = event.httpMethod;
    const headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    const body = method === 'POST' ? event.body : undefined;

    const response = await fetch(url, {
      method: method,
      headers: headers,
      body: body,
    });

    const data = await response.text();

    return {
      statusCode: response.status,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST',
        'Access-Control-Allow-Headers': 'Content-Type',
      },
      body: data,
    };
  } catch (error) {
    console.error('Proxy failed:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ 
        error: 'Proxy failed', 
        message: error.message 
      }),
    };
  }
};
