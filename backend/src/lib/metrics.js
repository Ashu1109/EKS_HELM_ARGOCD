import {
  register,
  collectDefaultMetrics,
  Counter,
  Histogram,
  Gauge,
} from "prom-client";

// Enable default metrics collection
collectDefaultMetrics();

// Custom metrics for chat application
export const httpRequestDuration = new Histogram({
  name: "http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status_code"],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
});

export const httpRequestTotal = new Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status_code"],
});

export const activeConnections = new Gauge({
  name: "websocket_connections_active",
  help: "Number of active WebSocket connections",
});

export const messagesTotal = new Counter({
  name: "messages_total",
  help: "Total number of messages sent",
  labelNames: ["type"],
});

export const usersOnline = new Gauge({
  name: "users_online",
  help: "Number of users currently online",
});

export const databaseConnections = new Gauge({
  name: "database_connections_active",
  help: "Number of active database connections",
});

// Export the register for the /metrics endpoint
export { register };
