# 🛳 Titanic Disaster Project  
**Machine Learning Workflow in R & Python with Docker**

---

## 📘 Overview  

This project develops and evaluates machine learning models to predict **passenger survival on the Titanic** using both **R** and **Python**.  
It demonstrates a clean, reproducible workflow powered by **Docker** for environment isolation and consistency across systems.

---

## 🧱 Project Structure  

Titanic_disaster-fkk7/
├── data/ # Raw and processed datasets
├── src/
│ ├── r/
│ │ ├── install_packages.R # Installs required R libraries
│ │ ├── titanic.R # Main R modeling script
│ │ └── Dockerfile # Dockerfile for R environment
│ └── python/
│ ├── requirements.txt # Python dependencies
│ ├── titanic.py # Main Python ML script
│ └── Dockerfile # Dockerfile for Python environment
├── .gitignore
└── README.md



---

## ⚙️ Environment Setup  

This project runs entirely within **Docker containers**, ensuring all dependencies and package versions remain consistent.  

### 1️⃣ Build the R container  
```bash
cd src/r
docker build -t titanic-r .

2️⃣ Run the R model
docker run --rm -v "$(pwd)/../../data":/data titanic-r

3️⃣ Build the Python container
cd ../python
docker build -t titanic-py .

4️⃣ Run the Python model
docker run --rm -v "$(pwd)/../../data":/data titanic-py

