
# 🛳 Titanic Disaster Survival Prediction

A dual-language machine learning pipeline using both **R** and **Python** to predict Titanic passenger survival. This project is built for containerized execution using Docker, ensuring consistent environments and reproducibility.

---

## 📁 Project Structure

```
Titanic_disaster-fkk7/
├── data/
├── src/
│   ├── r/
│   │   ├── install_packages.R
│   │   ├── titanic.R
│   │   └── Dockerfile
│   └── python/
│       ├── requirements.txt
│       ├── titanic.py
│       └── Dockerfile
├── .gitignore
└── README.md
```

---

## 📥 Data Download

This project uses the Titanic dataset from Kaggle:  
🔗 https://www.kaggle.com/c/titanic/data

Please download the following files and place them in the `data/` directory:
```
data/
├── train.csv
├── test.csv
└── gender_submission.csv
```

---

## ⚙️ Environment Setup

This project runs entirely within **Docker containers**.

### 1️⃣ Build the R container

```bash
cd src/r
docker build -t titanic-r .
```

### 2️⃣ Run the R model

```bash
docker run --rm -v "$(pwd)/../../data":/data titanic-r
```

### 3️⃣ Build the Python container

```bash
cd ../python
docker build -t titanic-py .
```

### 4️⃣ Run the Python model

```bash
docker run --rm -v "$(pwd)/../../data":/data titanic-py
```

---

## 📦 R Environment Details

**install_packages.R**
```r
pkgs <- c("readr", "fastDummies", "dplyr")
...
```

**titanic.R** does the following:
- Loads `train.csv` and `test.csv`
- Cleans missing values
- Encodes categorical variables
- Trains a logistic regression model
- Prints training accuracy and agreement with `gender_submission.csv`

✅ Output:
```yaml
Training accuracy: 0.7980
Agreement with gender_submission.csv: 0.9354
```

---

## 🧠 Python Environment Details

**requirements.txt**
```txt
pandas
numpy
scikit-learn
```

**titanic.py** does the following:
- Loads data
- Fills missing values
- One-hot encodes categorical variables
- Scales features
- Trains logistic regression or random forest model
- Outputs accuracy and CSV predictions

---

## 📊 Model Summary

| Feature             | R Model                         | Python Model                       |
|---------------------|----------------------------------|------------------------------------|
| Algorithm           | Logistic Regression             | Logistic Regression / Random Forest |
| Preprocessing       | dplyr + fastDummies             | pandas + scikit-learn              |
| Feature Engineering | Dummy Encoding                  | One-Hot Encoding                   |
| Evaluation          | Training Accuracy               | Accuracy & Submission Agreement    |
| Output              | Console Summary                 | Console + CSV Predictions          |

---

## 🧪 Branching Strategy

```text
main     – Stable, production-ready code  
develop  – Integration and validation branch  
fx-dev   – Experimental development
```

### Version Control Workflow

1. Create features under `fx-dev` or a feature branch  
2. Submit pull request into `develop`  
3. Test, then merge `develop` into `main`  
4. Each merge updates Docker and results

---

## 👤 Author

**Xiong Feng**  
Machine Learning Developer  
_MLDS400 — Advanced Data Science Workflow (Fall 2025)_

---

## 🪪 License

This project is licensed under the **MIT License** for educational purposes.

---

⭐ If you found this project useful, please give it a star!
