import { Server } from "socket.io";
import http from "http";
import express from "express";
import { activeConnections, usersOnline } from "./metrics.js";

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: ["http://localhost:5173"],
  },
});

export function getReceiverSocketId(userId) {
  return userSocketMap[userId];
}

// used to store online users
const userSocketMap = {}; // {userId: socketId}

io.on("connection", (socket) => {
  console.log("A user connected", socket.id);

  // Update metrics
  activeConnections.inc();
  usersOnline.set(Object.keys(userSocketMap).length + 1);

  const userId = socket.handshake.query.userId;
  if (userId) userSocketMap[userId] = socket.id;

  // io.emit() is used to send events to all the connected clients
  io.emit("getOnlineUsers", Object.keys(userSocketMap));

  socket.on("disconnect", () => {
    console.log("A user disconnected", socket.id);
    delete userSocketMap[userId];

    // Update metrics
    activeConnections.dec();
    usersOnline.set(Object.keys(userSocketMap).length);

    io.emit("getOnlineUsers", Object.keys(userSocketMap));
  });
});

export { io, app, server };
