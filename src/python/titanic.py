import sys
import pandas as pd
import os
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report


# === 13. Load train.csv ===
print("\nLoading train.csv ...")
train = pd.read_csv("/data/train.csv")
print("Train loaded. Shape:", train.shape)
print("Train columns:", list(train.columns))

# === 14. Explore / clean the data ===
print("\nExploring and cleaning train data ...")
print("Missing values per column (train):\n", train.isnull().sum())

# Drop irrelevant Cabin column
print("Dropping column: Cabin (if exists)")
train = train.drop(["Cabin"], axis=1)
print("Columns after dropping Cabin:", list(train.columns))

# Fill missing values
age_na_before = train["Age"].isna().sum()
train["Age"].fillna(train["Age"].median(), inplace=True)
print("Filled Age missing with median. Before:", age_na_before, "After:", train["Age"].isna().sum())

emb_na_before = train["Embarked"].isna().sum()
train["Embarked"].fillna(train["Embarked"].mode()[0], inplace=True)
print("Filled Embarked missing with mode. Before:", emb_na_before, "After:", train["Embarked"].isna().sum())

# Encode categorical data
print("Encoding Sex as {male:0, female:1}")
train["Sex"] = train["Sex"].map({"male": 0, "female": 1})
print("One-hot on Embarked with drop_first=True")
train = pd.get_dummies(train, columns=["Embarked"], drop_first=True)
print("Columns after get_dummies (train):", list(train.columns))

print("Train cleaned. New shape:", train.shape)

# === 15. logistic regression model to predict survivability ===
features = ["Pclass", "Sex", "Age", "SibSp", "Parch", "Fare",
            'Embarked_Q', 'Embarked_S']
print("\nUsing features:", features)
X = train[features]
y = train["Survived"]
print("X shape (train):", X.shape, " y shape:", y.shape)

scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)
print("Scaled X (train) shape:", X_scaled.shape)

model = LogisticRegression(max_iter=1000, random_state=42)
model.fit(X_scaled, y)
print("Model training complete.")

# === 16. Measure the accuracy ===
y_pred = model.predict(X_scaled)
acc = accuracy_score(y, y_pred)
print("Training accuracy:", f"{acc:.4f}")
print("Confusion matrix (train):\n", confusion_matrix(y, y_pred))

# === 17–18. Load test.csv, predict, and measure accuracy ===
print("\nLoading test.csv ...")
test = pd.read_csv("/data/test.csv")
print("Test loaded. Shape:", test.shape)
print("Missing values per column (test):\n", test.isnull().sum())

print("Filling test Age and Fare missing with medians")
test["Age"].fillna(test["Age"].median(), inplace=True)
test["Fare"].fillna(test["Fare"].median(), inplace=True)

print("Encoding train Sex/Embarked (as written above in your script)")
test["Sex"] = test["Sex"].map({"male": 0, "female": 1})
test = pd.get_dummies(test, columns=["Embarked"], drop_first=True)
print("Columns after get_dummies (test):", list(test.columns))

print("Selecting test features with same columns/order as train")
X_test = test[features]
print("X_test shape:", X_test.shape)

print("Scaling test with train scaler and predicting")
X_test_scaled = scaler.transform(X_test)
y_test_pred = model.predict(X_test_scaled)
print("First 10 test predictions:", y_test_pred[:10])

print("Loading gender_submission.csv to compute test accuracy ...")
gender = pd.read_csv("/data/gender_submission.csv")
print("gender_submission shape:", gender.shape)

pred = pd.DataFrame({
    "PassengerId": test["PassengerId"],
    "Predicted": y_test_pred
})

merged = pred.merge(gender, on="PassengerId", how="inner")
print("Merged data shape:", merged.shape)

agreement = (merged["Predicted"] == merged["Survived"]).mean()
print(f"Agreement with gender_submission.csv(testing accuracy): {agreement:.4f}")