const plist = require('plist');

export default async function handler(req, res) {
  // Asegurarnos de que sea una petición POST enviada por el sistema iOS
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).end('Method Not Allowed');
  }

  try {
    // Capturar los datos binarios enviados en crudo (Buffer)
    const chunks = [];
    for await (const chunk of req) {
      chunks.push(chunk);
    }
    const rawBuffer = Buffer.concat(chunks);
    const rawString = rawBuffer.toString('utf8');

    // Apple envía un contenedor S/MIME; localizamos el bloque XML interior (plist)
    const plistStart = rawString.indexOf('<?xml');
    const plistEnd = rawString.indexOf('</plist>') + '</plist>'.length;

    if (plistStart === -1 || plistEnd === -1) {
      throw new Error('No se pudo localizar la estructura plist en el paquete recibido.');
    }

    const plistXml = rawString.substring(plistStart, plistEnd);
    
    // Parsear el texto XML usando la librería plist
    const parsedData = plist.parse(plistXml);
    const udid = parsedData.UDID;

    if (!udid) {
      throw new Error('El UDID no está presente en los datos del dispositivo.');
    }

    // Obtener la URL base dinámicamente de la cabecera de la petición o usar una fija
    const host = req.headers['x-forwarded-host'] || req.headers.host;
    const protocol = req.headers['x-forwarded-proto'] || 'https';
    
    // Redirigir al usuario de regreso a la interfaz web enviando el UDID como parámetro GET
    const redirectUrl = `${protocol}://${host}/?udid=${encodeURIComponent(udid)}`;
    
    res.writeHead(302, { Location: redirectUrl });
    res.end();

  } catch (error) {
    console.error('Error al procesar el UDID:', error);
    res.status(500).send(`Error procesando el perfil: ${error.message}`);
  }
}