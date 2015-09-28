---
title: "Practical Machine Learning"
output:
  html_document:
    toc: false
    theme: united
---

Practical Machine Learning
==========================
Biometric data from wearable activity trackers are commonly used to measure the quanitity of physical activity performed over a period of time. The ability of these trackers to measure the quality of physical activity is less understood. Using wearable activity trackers, XX and colleagues collected biometric data from volunteer subjects performing weight lifting activities. The subjects form during these activities was classified as X, Y, and Z. In this assignment, we use these data to determine a biometric model for predicting quality of physical activity.


Loading and cleaning the data
-----------------------------
The caret and randomForest packages are used for predictive modelling. The doMC package is used to employ multiple CPU cores during computation in order to decrease computation time.
```{r}
require("caret")
require("randomForest")
require("doMC")
```

The data are publically downloadable from the internet. Included in the data are variables containing mostly missing data and variables including only metadata (e.g. subject identification, timestamps). These variables are not relevant to prediction modelling and are discarded.
```{r}
## Download training and testing data
training_url <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv"
validate_url <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv"
training_raw <- read.csv(training_url)
validate_raw <- read.csv(validate_url)


## Drop variables with >30% missing values
missing <- function(df, threshold=0.3) {
    columns_missing <- sapply(df, function(x) {
        sum(is.na(x) | x == "" | x == "NA" | x == "#DIV/0!")/length(x)
    })
    columns_missing <- names(columns_missing[columns_missing >= threshold])
    return(columns_missing)
}

training_missing <- missing(training_raw)
validate_missing <- missing(validate_raw)
training <- training_raw[!(names(training_raw) %in% training_missing)]
validate <- validate_raw[!(names(validate_raw) %in% validate_missing)]


## Remove metadata columns
columns_metadata <- c("X", "user_name", "raw_timestamp_part_1", "raw_timestamp_part_2",
                      "cvtd_timestamp", "new_window", "num_window")
training <- training[!(names(training) %in% columns_metadata)]
validate <- validate[!(names(validate) %in% columns_metadata)]


## Set outcome variable as factor
training$classe <- as.factor(training$classe)
```


Data partitioning
-----------------
The training data are partitioned to a training and testing dataset. The training partition will be used to train the model. The testing parition will be used to determine the accuracy of the model.
```{r}
## Create training and testing paritions
in_train <- createDataPartition(training$classe, p=0.2, list=F)
training_partition <- training[in_train, ]
testing_partition <- training[-in_train, ]
```


Model creation
--------------
A random forest method is used to train the model to the training partition. The bootstrap 632 algorithm is used for cross-validation to estimate model accuracy. 
```{r}
## Train model with training partition
registerDoMC(cores=4)
set.seed(1234)
model_rf <- train(classe ~ ., method="rf", trControl=trainControl(method="boot632", number=5),
                  data=training_partition, prox=T)
```

Model testing
-----------------
The model predictions are tested with data from the testing partition. Accuracy is 97.2% (95% confidence interval: 96.9% to 97.4%). 
```{r}
## Test model with testing partition
prediction_testing <- predict(model_rf, newdata=testing_partition)
confusionMatrix(prediction_testing, testing_partition$classe)
```
