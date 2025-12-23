# Build stage
FROM node:20-alpine AS builder

# Install dependencies needed for native modules
RUN apk add --no-cache python3 make g++ git

WORKDIR /app

# Copy workspace files
COPY package.json yarn.lock .yarnrc.yml ./

# Copy all workspace packages
COPY packages ./packages
COPY apps/web ./apps/web

# Install dependencies
RUN corepack enable && corepack prepare yarn@3.5.1 --activate
RUN yarn install --immutable

# Build the web app
WORKDIR /app/apps/web
RUN yarn build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copy workspace files
COPY package.json yarn.lock .yarnrc.yml ./

# Copy built artifacts and necessary files
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/apps/web ./apps/web
COPY --from=builder /app/node_modules ./node_modules

# Install production dependencies
RUN corepack enable && corepack prepare yarn@3.5.1 --activate

WORKDIR /app/apps/web

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

# Start the web app
CMD ["yarn", "start"]
