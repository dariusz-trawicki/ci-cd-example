FROM public.ecr.aws/docker/library/node:20-alpine
WORKDIR /app

# simple HTTP server on port 8080
COPY <<'EOT' server.js
const http = require('http');
const port = 8080;
const msg = process.env.MESSAGE || 'Hello from STAGING!';
http.createServer((req, res) => { res.end(msg + "\\n"); }).listen(port);
console.log('Server on ' + port);
EOT

EXPOSE 8080
CMD ["node", "server.js"]
