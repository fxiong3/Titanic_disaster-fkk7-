# 🛳 Titanic Disaster Project  
**Machine Learning Workflow in R & Python with Docker**

---

## 📘 Overview  
This project builds and evaluates machine learning models predicting passenger survival on the Titanic using both **R** and **Python**.  
It demonstrates a reproducible, containerized data science workflow managed with **Docker**.

---

## 🧱 Project Structure  

Titanic_disaster-fkk7/
├── data/ # Raw and processed datasets
├── src/
│ ├── r/
│ │ ├── install_packages.R # Installs required R packages
│ │ ├── titanic.R # Main R model and data processing script
│ │ └── Dockerfile # Docker setup for R environment
│ └── python/
│ ├── requirements.txt # Python dependencies
│ ├── titanic.py # Main Python ML script
│ └── Dockerfile # Docker setup for Python environment
├── .gitignore
└── README.md


---

## ⚙️ Environment Setup  

### 1️⃣ Build the R container  
```bash
cd src/r
docker build -t titanic-r .
