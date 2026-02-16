import { useState, useEffect } from "react";

function App() {
  const [file, setFile] = useState(null);
  const [images, setImages] = useState([]);
  const BACKEND_URL = "";
  const uploadFile = async () => {
    if (!file) return;

    const formData = new FormData();
    formData.append("image", file);

    try {
      const res = await fetch(`${BACKEND_URL}/api/upload`, {
        method: "POST",
        body: formData,
      });
      const data = await res.json();
      alert(data.message);
      fetchImages(); // refresh list
    } catch (err) {
      console.error(err);
    }
  };

  const fetchImages = async () => {
    try {
      const res = await fetch(`${BACKEND_URL}/api/list-processed`);
      const data = await res.json();
      setImages(data.images);
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchImages();
  }, []);

  return (
    <div style={{ padding: "20px", maxWidth: "600px", margin: "auto" }}>
      <h1>Upload Image</h1>
      <input type="file" onChange={(e) => setFile(e.target.files[0])} />
      <button onClick={uploadFile} style={{ marginLeft: "10px" }}>
        Upload
      </button>

      <h2 style={{ marginTop: "40px" }}>Processed Images</h2>
      <div style={{ display: "flex", flexWrap: "wrap", gap: "10px" }}>
        {images.map((url, idx) => (
          <img key={idx} src={url} alt="processed" width={150} />
        ))}
      </div>
    </div>
  );
}

export default App;


