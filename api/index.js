const serverless = require("serverless-http");
const express = require("express");
const resourceRoutes = require("./src/routes/resource");

const app = express();
app.use(express.json());
app.use("/", resourceRoutes);

exports.handler = serverless(app);
