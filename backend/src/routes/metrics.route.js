import express from "express";
import { register } from "../lib/metrics.js";

const router = express.Router();

// Metrics endpoint for Prometheus
router.get("/", async (req, res) => {
  try {
    res.set("Content-Type", register.contentType);
    res.end(await register.metrics());
  } catch (error) {
    res.status(500).end(error);
  }
});

export default router;
