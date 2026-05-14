export default async function handler(req, res) {
  const { text } = req.query;

  if (!text || text.trim().length < 2) {
    return res.status(400).json({ error: "Parametro text requerido" });
  }

  const key = process.env.GEOAPIFY_KEY;
  if (!key) {
    return res.status(500).json({ error: "Falta GEOAPIFY_KEY" });
  }

  const query = encodeURIComponent(`${text} Merida, Badajoz, Espana`);
  const url = `https://api.geoapify.com/v1/geocode/autocomplete?text=${query}&apiKey=${key}`;

  try {
    const resp = await fetch(url);
    const data = await resp.json();
    return res.status(resp.status).json(data);
  } catch (err) {
    return res.status(500).json({ error: "Error en Geoapify" });
  }
}