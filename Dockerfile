# FORGE — container for public hosting (November).
# Build:  docker build -t forge -f ../Dockerfile .
# Run:    docker run -p 3000:3000 -e JWT_SECRET=... -e DATABASE_URL=... forge
FROM node:22-alpine
WORKDIR /srv
COPY backend/package*.json ./backend/
RUN cd backend && npm ci --omit=dev
COPY backend ./backend
COPY docs ./docs
ENV NODE_ENV=production PORT=3000
EXPOSE 3000
CMD ["node", "backend/server.js"]
