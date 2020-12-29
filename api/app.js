const express = require("express");
const cors = require('cors')
const app = express();
const apiRoutes = require("./routes/api-routes");

app.use(cors());
app.use(express.json());
app.use("/api", apiRoutes);

module.exports = app;