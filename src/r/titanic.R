suppressPackageStartupMessages({
  library(readr)        # small & fast CSV reader
  library(fastDummies)  # light-weight one-hot encoder
})

# ====== Load train.csv ======
cat("\nLoading train.csv ...\n")
train <- readr::read_csv("/data/train.csv", show_col_types = FALSE)
cat("Train shape:", paste(dim(train), collapse = " x"), "\n")
cat("Train columns:", paste(names(train), collapse = ", "), "\n")

# ====== Q14. Explore / clean ======
cat("\nExploring / cleaning train ...\n")
miss_count <- sapply(train, function(x) sum(is.na(x) | (is.character(x) & x == "")))
cat("Missing values per column (train):\n"); print(miss_count)

# Drop Cabin (if present)
if ("Cabin" %in% names(train)) {
  train <- train[, setdiff(names(train), "Cabin")]
  cat("Dropped column: Cabin\n")
}

# Fill Age median; Embarked blanks -> 'S'
age_na_before <- sum(is.na(train$Age))
train$Age[is.na(train$Age)] <- median(train$Age, na.rm = TRUE)
cat("Filled Age (median). Before:", age_na_before,
    " After:", sum(is.na(train$Age)), "\n")

emb_na_before <- sum(is.na(train$Embarked) | train$Embarked == "")
train$Embarked[is.na(train$Embarked) | train$Embarked == ""] <- "S"
cat("Filled Embarked='S'. Before:", emb_na_before,
    " After:", sum(is.na(train$Embarked) | train$Embarked == ""), "\n")

# Encode Sex
train$Sex <- ifelse(train$Sex == "male", 0L, 1L)

# One-hot for Embarked with S as reference
train$Embarked <- factor(train$Embarked, levels = c("S","C","Q"))
train <- fastDummies::dummy_cols(
  train,
  select_columns = "Embarked",
  remove_selected_columns = TRUE,
  remove_first_dummy = TRUE  # drops 'S' because it's the first level
)
# Columns now include Embarked_C and Embarked_Q

cat("Columns after encoding (train):\n"); print(names(train))

# ====== Q15. Logistic regression on train ======
features <- c("Pclass","Sex","Age","SibSp","Parch","Fare","Embarked_C","Embarked_Q")
cat("\nUsing features:", paste(features, collapse = ", "), "\n")

X <- train[, features]
y <- train$Survived

# Scale numerics (mirror your Python flow)
num_cols <- sapply(X, is.numeric)
mu  <- sapply(X[, num_cols, drop = FALSE], mean)
sdv <- sapply(X[, num_cols, drop = FALSE], sd); sdv[sdv == 0] <- 1

scale_df <- function(df, mu, sdv) {
  out <- df
  for (nm in names(mu)) out[[nm]] <- (out[[nm]] - mu[[nm]]) / sdv[[nm]]
  out
}
X_scaled <- X
X_scaled[, names(mu)] <- scale_df(X[, names(mu), drop = FALSE], mu, sdv)[, names(mu)]

fit <- glm(y ~ ., data = data.frame(y = y, X_scaled), family = binomial())

# ====== Q16. Training accuracy ======
p_train <- ifelse(predict(fit, type = "response") > 0.5, 1L, 0L)
train_acc <- mean(p_train == y)
cat("Training accuracy:", sprintf("%.4f", train_acc), "\n")

# ====== Q17–18. Test set ======
cat("\nLoading test.csv ...\n")
test <- readr::read_csv("/data/test.csv", show_col_types = FALSE)
cat("Test shape:", paste(dim(test), collapse = " x"), "\n")
cat("Missing values per column (test):\n")
print(sapply(test, function(x) sum(is.na(x) | (is.character(x) & x == ""))))

# Same cleaning
if ("Cabin" %in% names(test)) test <- test[, setdiff(names(test), "Cabin")]
test$Age[is.na(test$Age)]   <- median(test$Age, na.rm = TRUE)
test$Fare[is.na(test$Fare)] <- median(test$Fare, na.rm = TRUE)
test$Embarked[is.na(test$Embarked) | test$Embarked == ""] <- "S"
test$Sex <- ifelse(test$Sex == "male", 0L, 1L)

test$Embarked <- factor(test$Embarked, levels = c("S","C","Q"))
test <- fastDummies::dummy_cols(
  test,
  select_columns = "Embarked",
  remove_selected_columns = TRUE,
  remove_first_dummy = TRUE   # drop 'S'
)

# Ensure missing dummy columns exist (safety)
for (nm in c("Embarked_C","Embarked_Q")) {
  if (!nm %in% names(test)) test[[nm]] <- 0L
}

X_test <- test[, features]
X_test_scaled <- X_test
for (nm in names(mu)) X_test_scaled[[nm]] <- (X_test[[nm]] - mu[[nm]]) / sdv[[nm]]

p_test <- ifelse(predict(fit, newdata = X_test_scaled, type = "response") > 0.5, 1L, 0L)
cat("First 10 test predictions:", paste(p_test[1:min(10, length(p_test))], collapse = " "), "\n")

# Agreement with gender_submission
cat("\nComparing with gender_submission.csv ...\n")
gender <- readr::read_csv("/data/gender_submission.csv", show_col_types = FALSE)
merged <- merge(
  data.frame(PassengerId = test$PassengerId, Predicted = p_test),
  as.data.frame(gender), by = "PassengerId", all = FALSE
)
cat("Merged rows:", nrow(merged), "\n")
agreement <- mean(merged$Predicted == merged$Survived)
cat("Agreement with gender_submission.csv:", sprintf("%.4f", agreement), "\n")
