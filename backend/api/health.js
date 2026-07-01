module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.status(200).json({ status: 'ok', model: process.env.MIMO_MODEL || 'mimo-v2.5' });
};
