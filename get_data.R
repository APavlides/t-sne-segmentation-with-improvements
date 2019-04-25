
devtools::load_all("~/exploration/lib/tggr")
library(dplyr)
library(DBI)
library(fastDummies)

# make a connection to database, here I am using old data, TODO. use current data with  tggr::db_connect()
connection <- DBI::dbConnect(odbc::odbc(),
                            Driver   =  "SQL Server Native Client 11.0",
                            Server   = "10.132.0.2",
                            Database = "GymDW_ML_20190304",
                            UID      = Sys.getenv("uid"),
                            PWD      = Sys.getenv("pwd"))

# get table
SQL <- tggr::utl_read_sql("segmentation/seg_data.sql")
df <- DBI::dbGetQuery(conn = connection, statement = SQL)

# remove NA values
df <- df[complete.cases(df), ]

# make dummy variables and remove categorical columns
data <- fastDummies::dummy_cols(df)
excluded_vars <- c("CategoryCode", "GroupCode", "TypeCode" , "AccountCancellationReason",
                   "Gender", "AccountJoinType", "GymAcquisitionGroup",  "AccountProduct")
data <- data %>% select(-one_of(excluded_vars))

# scale data
normalisation <- function(x){(x - mean(x)) / sd(x)}
data <- apply(data, 2, FUN = normalisation)

#range01 <- function(x){(x-min(x))/(max(x)-min(x))}
#data <- apply(data, 2, FUN = range01)

# 75% sample size
smp_size <- floor(0.75 * nrow(data))
# set the seed to make your partition reproducible
set.seed(123)
train_ind <- sample(seq_len(nrow(data)), size = smp_size)
train <- data[train_ind, ]
test <- data[-train_ind, ]

# y_test provides the colour for the clustures.
# For tsne you should experiement with this to see what features are discriminating
y_test <- as.numeric(as.factor(df$NumberOfDaysAdj))[-train_ind]

# save as csv's and read into python code
write.csv(x = train, file = "~/exploration/segmentation/X_train.csv")
write.csv(x = test, file = "~/exploration/segmentation/X_test.csv")
write.csv(x = y_test, file = "~/exploration/segmentation/y_test.csv")
