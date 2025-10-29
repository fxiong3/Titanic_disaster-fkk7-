suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fastDummies)
})

DATA_DIR <- "/data"

# ---------- helpers ----------
print_missing <- function(df, title) {
  cat(paste0("\nMissing values per column (", title, "):\n"))
  print(sapply(df, function(x) sum(is.na(x) | (is.character(x) & x == ""))))
}

scale_fit <- function(df_num) {
  mu  <- sapply(df_num, mean, na.rm = TRUE)
  sdv <- sapply(df_num, sd,   na.rm = TRUE)
  sdv[sdv == 0] <- 1
  list(mu = mu, sd = sdv)
}
scale_apply <- function(df, stats) {
  out <- df
  for (nm in names(stats$mu)) {
    out[[nm]] <- (out[[nm]] - stats$mu[[nm]]) / stats$sd[[nm]]
  }
  out
}

# 清洗函数（train / test 共用）
clean_titanic <- function(df, is_train = TRUE) {
  # 1) 丢弃 Cabin（若存在）
  if ("Cabin" %in% names(df)) {
    df <- df %>% select(-Cabin)
    cat("Dropped column: Cabin\n")
  }

  # 2) 填充 Age / Fare / Embarked
  if ("Age" %in% names(df)) {
    before <- sum(is.na(df$Age))
    med    <- median(df$Age, na.rm = TRUE)
    df     <- df %>% mutate(Age = ifelse(is.na(Age), med, Age))
    cat("Filled Age median. Before:", before, " After:", sum(is.na(df$Age)), "\n")
  }
  if ("Fare" %in% names(df)) {
    before <- sum(is.na(df$Fare))
    med    <- median(df$Fare, na.rm = TRUE)
    df     <- df %>% mutate(Fare = ifelse(is.na(Fare), med, Fare))
    cat("Filled Fare median. Before:", before, " After:", sum(is.na(df$Fare)), "\n")
  }
  if ("Embarked" %in% names(df)) {
    before <- sum(is.na(df$Embarked) | df$Embarked == "")
    df     <- df %>%
      mutate(Embarked = ifelse(is.na(Embarked) | Embarked == "", "S", Embarked))
    cat("Filled Embarked='S'. Before:", before,
        " After:", sum(is.na(df$Embarked) | df$Embarked == ""), "\n")
  }

  # 3) Sex 数值化
  if ("Sex" %in% names(df)) {
    df <- df %>% mutate(Sex = ifelse(Sex == "male", 0L, 1L))
  }

  # 4) One-hot for Embarked（以 S 为基准）
  if ("Embarked" %in% names(df)) {
    df <- df %>%
      mutate(Embarked = factor(Embarked, levels = c("S", "C", "Q"))) %>%
      fastDummies::dummy_cols(
        select_columns = "Embarked",
        remove_selected_columns = TRUE,
        remove_first_dummy = TRUE # 删除 S，保留 Embarked_C / Embarked_Q
      )
  }

  df
}

# ========== 13. Load train.csv ==========
cat("\nLoading train.csv ...\n")
train <- readr::read_csv(file.path(DATA_DIR, "train.csv"), show_col_types = FALSE)
cat("Train shape:", paste(dim(train), collapse = " x"), "\n")
cat("Train columns:", paste(names(train), collapse = ", "), "\n")
print_missing(train, "train")

# ========== 14. Explore / clean ==========
cat("\nExploring / cleaning train ...\n")
train <- clean_titanic(train, is_train = TRUE)
cat("\nData cleaned! New shape:", paste(dim(train), collapse = " x"), "\n")
cat("Columns:", paste(names(train), collapse = ", "), "\n")

# ========== 15. Logistic regression on training set ==========
features <- c("Pclass","Sex","Age","SibSp","Parch","Fare","Embarked_C","Embarked_Q")
cat("\nUsing features:", paste(features, collapse = ", "), "\n")

# 保证 dummy 列存在
for (nm in c("Embarked_C","Embarked_Q")) {
  if (!nm %in% names(train)) train[[nm]] <- 0L
}

X <- train[, features, drop = FALSE]
y <- train$Survived


num_cols <- names(X)[sapply(X, is.numeric)]
stats    <- scale_fit(X[, num_cols, drop = FALSE])
X_scaled <- X
X_scaled[, num_cols] <- scale_apply(X[, num_cols, drop = FALSE], stats)

fit <- glm(y ~ ., data = cbind(y = y, X_scaled), family = binomial())
cat("Model training complete.\n")

# ========== 16. Training accuracy ==========
p_train <- ifelse(predict(fit, type = "response") > 0.5, 1L, 0L)
train_acc <- mean(p_train == y)
cat("Training accuracy:", sprintf("%.4f", train_acc), "\n")

# ========== 17–18. Test: load / predict / agreement ==========
cat("\nLoading test.csv ...\n")
test <- readr::read_csv(file.path(DATA_DIR, "test.csv"), show_col_types = FALSE)
cat("Test shape:", paste(dim(test), collapse = " x"), "\n")
print_missing(test, "test")

cat("\nCleaning test ...\n")
test <- clean_titanic(test, is_train = FALSE)

# 对齐列（确保 Embarked_C / Embarked_Q 存在）
for (nm in c("Embarked_C","Embarked_Q")) {
  if (!nm %in% names(test)) test[[nm]] <- 0L
}

X_test <- test[, features, drop = FALSE]
X_test_scaled <- X_test
X_test_scaled[, num_cols] <- scale_apply(X_test[, num_cols, drop = FALSE], stats)

p_test <- ifelse(predict(fit, newdata = X_test_scaled, type = "response") > 0.5, 1L, 0L)
cat("First 10 test predictions:", paste(p_test[1:min(10, length(p_test))], collapse = " "), "\n")

# Agreement vs gender_submission.csv
gender_path <- file.path(DATA_DIR, "gender_submission.csv")
if (file.exists(gender_path)) {
  gender <- readr::read_csv(gender_path, show_col_types = FALSE)
  merged <- merge(
    data.frame(PassengerId = test$PassengerId, Predicted = p_test),
    gender, by = "PassengerId", all = FALSE
  )
  cat("Merged rows:", nrow(merged), "\n")
  agreement <- mean(merged$Predicted == merged$Survived)
  cat("Agreement with gender_submission.csv:", sprintf("%.4f", agreement), "\n")
} else {
  cat("gender_submission.csv not found; skipping agreement metric.\n")
}
