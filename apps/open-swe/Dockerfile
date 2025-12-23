# Build stage
FROM node:20-alpine AS builder

# Install dependencies needed for native modules
RUN apk add --no-cache python3 make g++ git

WORKDIR /app

# Copy workspace files
COPY package.json yarn.lock .yarnrc.yml ./

# Copy all workspace packages
COPY packages ./packages
COPY apps/open-swe ./apps/open-swe

# Install dependencies
RUN corepack enable && corepack prepare yarn@3.5.1 --activate
RUN yarn install --immutable

# Build the project
WORKDIR /app/apps/open-swe
RUN yarn build

# Production stage
FROM node:20-alpine

# Install dependencies needed for runtime
RUN apk add --no-cache git openssh-client

WORKDIR /app

# Copy workspace files
COPY package.json yarn.lock .yarnrc.yml ./

# Copy built artifacts and necessary files
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/apps/open-swe ./apps/open-swe
COPY --from=builder /app/node_modules ./node_modules
COPY langgraph.json ./

# Install production dependencies
RUN corepack enable && corepack prepare yarn@3.5.1 --activate

WORKDIR /app/apps/open-swe

# Set environment variables
ENV NODE_ENV=production
ENV PORT=2024

EXPOSE 2024

# Start the agent
CMD ["yarn", "dev"]
