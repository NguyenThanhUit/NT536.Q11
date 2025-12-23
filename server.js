const express = require("express");
const { spawn } = require("child_process");
const multer = require("multer");
const fs = require("fs");
const path = require("path");

const app = express();
app.use(express.json());

/* ===== CORS ===== */
app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.header("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") return res.sendStatus(204);
    next();
});


let ffmpegYT = null;
let ffmpegFB = null;

app.post("/restream/start", (req, res) => {
    const { youtubeKey, facebookKey } = req.body;

    if (!youtubeKey && !facebookKey) {
        return res.status(400).json({ error: "No stream key provided" });
    }

    // ===== YouTube =====
    if (youtubeKey && !ffmpegYT) {
        ffmpegYT = spawn("ffmpeg", [
            "-re",
            "-i", "rtmp://127.0.0.1:1935/live/live",
            "-c", "copy",
            "-f", "flv",
            `rtmp://a.rtmp.youtube.com/live2/${youtubeKey}`
        ]);

        ffmpegYT.stderr.on("data", d =>
            console.log("[YT]", d.toString())
        );

        ffmpegYT.on("close", () => {
            ffmpegYT = null;
            console.log("YouTube restream stopped");
        });
    }

    // ===== Facebook =====
    if (facebookKey && !ffmpegFB) {
        ffmpegFB = spawn("ffmpeg", [
            "-re",
            "-i", "rtmp://127.0.0.1:1935/live/live",
            "-c", "copy",
            "-f", "flv",
            `rtmps://live-api-s.facebook.com:443/rtmp/${facebookKey}`
        ]);

        ffmpegFB.stderr.on("data", d =>
            console.log("[FB]", d.toString())
        );

        ffmpegFB.on("close", () => {
            ffmpegFB = null;
            console.log("Facebook restream stopped");
        });
    }

    res.json({ ok: true });
});

app.post("/restream/stop", (req, res) => {
    if (ffmpegYT) {
        ffmpegYT.kill("SIGKILL");
        ffmpegYT = null;
    }
    if (ffmpegFB) {
        ffmpegFB.kill("SIGKILL");
        ffmpegFB = null;
    }
    res.json({ ok: true });
});


const VOD_DIR = "/var/vds";
fs.mkdirSync(VOD_DIR, { recursive: true });

const storage = multer.diskStorage({
    destination: VOD_DIR,
    filename: (req, file, cb) => {
        cb(null, file.originalname);
    }
});

const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 * 1024 } // 5GB
});

app.post("/vods/upload", upload.single("video"), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: "No file uploaded" });
    }

    console.log("Uploaded:", req.file.filename);

    res.json({
        ok: true,
        filename: req.file.filename,
        saved_to: `${VOD_DIR}/${req.file.filename}`
    });
});


const PORT = 3000;
app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on ${PORT}`);
});
