// server.js
const express = require("express");
const path = require("path");
const cors = require("cors");
const multer = require("multer");
const fetch = require("node-fetch");
const FormData = require("form-data");

const app = express();
app.use(cors());

const upload = multer({ storage: multer.memoryStorage() });

const UPLOAD_FUNCTION_URL = "https://us-central1-gcloud-prj-2-487221.cloudfunctions.net/image-uploader";
const LIST_FUNCTION_URL   = "https://us-central1-gcloud-prj-2-487221.cloudfunctions.net/image-lister";

app.post("/api/upload", upload.single("image"), async (req, res) => {
  try {
    if (!req.file) return res.status(400).send("No file uploaded");

    const formData = new FormData();
    formData.append("image", req.file.buffer, req.file.originalname);

    const response = await fetch(UPLOAD_FUNCTION_URL, {
      method: "POST",
      body: formData,
      headers: formData.getHeaders(),
    });

    const data = await response.json();
    res.json(data);
  } catch (err) {
    console.error("UPLOAD ERROR:", err);
    res.status(500).send("Upload failed");
  }
});

app.get("/api/list-processed", async (req, res) => {
  try {
    const response = await fetch(LIST_FUNCTION_URL);
    const data = await response.json();
    // ensure frontend gets { images: [...] }
    res.json({ images: data.images || data });
  } catch (err) {
    console.error("LIST ERROR:", err);
    res.status(500).send("Failed to list images");
  }
});

app.use(express.static(path.join(__dirname, "build")));
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "build", "index.html"));
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

