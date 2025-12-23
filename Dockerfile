# Multi-stage Dockerfile for Open SWE monorepo
# This builds both the agent and web applications

# Build stage
FROM node:20-alpine AS builder

# Install dependencies needed for native modules
RUN apk add --no-cache python3 make g++ git

WORKDIR /app

# Copy workspace configuration
COPY package.json yarn.lock .yarnrc.yml turbo.json tsconfig.json ./

# Copy all packages and apps
COPY packages ./packages
COPY apps ./apps
COPY langgraph.json ./

# Install dependencies
RUN corepack enable && corepack prepare yarn@3.5.1 --activate
RUN yarn install --immutable

# Build all packages
RUN yarn build

# Agent production stage
FROM node:20-alpine AS agent

# Install runtime dependencies
RUN apk add --no-cache git openssh-client

WORKDIR /app

# Copy workspace configuration
COPY package.json yarn.lock .yarnrc.yml ./
COPY langgraph.json ./

# Copy built artifacts
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/apps/open-swe ./apps/open-swe
COPY --from=builder /app/apps/open-swe-v2 ./apps/open-swe-v2
COPY --from=builder /app/node_modules ./node_modules

# Enable corepack
RUN corepack enable && corepack prepare yarn@3.5.1 --activate

WORKDIR /app

# Set environment variables
ENV NODE_ENV=production
ENV PORT=2024

EXPOSE 2024

# Start the agent
CMD ["yarn", "workspace", "@openswe/agent", "dev"]

# Web production stage
FROM node:20-alpine AS web

WORKDIR /app

# Copy workspace configuration
COPY package.json yarn.lock .yarnrc.yml ./

# Copy built artifacts
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/apps/web ./apps/web
COPY --from=builder /app/node_modules ./node_modules

# Enable corepack
RUN corepack enable && corepack prepare yarn@3.5.1 --activate

WORKDIR /app

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

# Start the web app
CMD ["yarn", "workspace", "@openswe/web", "start"]
