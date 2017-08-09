library(dplyr)
library(data.table)
library(tidyr)
library(plyr)

################# 1.Merges the training and the test sets to create one data set. ####################

#download the zip file and load to temp , then extract to data
downloadURL <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
temp <- tempfile()
download.file(downloadURL, temp)
data <- read.csv(unzip(temp),header = TRUE, stringsAsFactors = FALSE) 

# Read both train and test subject files and merge to allSubject
trainSubject <- read.table("../UCI HAR Dataset/train/subject_train.txt")
testSubject  <- read.table("../UCI HAR Dataset/test/subject_test.txt")
allSubject <- rbind(trainSubject,testSubject)
setnames(allSubject, "V1", "subject")

# Read both train and test Y files and merge to allY
trainY <- read.table("../UCI HAR Dataset/train/Y_train.txt")
testY  <- read.table("../UCI HAR Dataset/test/Y_test.txt")
allY <- rbind(trainY,testY)
setnames(allY, "V1", "activity")

#merge allSubject +  allY  to allSubjectY
allSubjectY<- cbind(allSubject, allY) 

# Read both train and test X files and merge to allX
trainX <- read.table("../UCI HAR Dataset/train/X_train.txt")
testX  <- read.table("../UCI HAR Dataset/test/X_test.txt")
allX <- rbind(trainX,testX)

##### 2. Extracts only the measurements on the mean and standard deviation for each measurement. ######

# set V1 of allX to featurename of dataFeatures
dataFeatures <- read.table("../UCI HAR Dataset/features.txt")
colnames(allX) <- dataFeatures[,2]

#merge allX and allSubjectY to allData
allData <- cbind(allSubjectY, allX)

#filter only mean/sd of measurements
filteredData <- allData[,grepl("subject|activity|mean\\(\\)|std\\(\\)",colnames(allData))]

############## 3. Uses descriptive activity names to name the activities in the data set ##############

#read and set column names for activity labels
activityLabels<- read.table("./UCI HAR Dataset/activity_labels.txt")

meanStdData <- activityLabels %>% 
               setnames( names(activityLabels), c("activity","activityName")) %>%
               merge(filteredData , by="activity", all.x = TRUE) %>%
               select( subject,activityName, everything()) %>%
               select( -activity)

###### 4. Appropriately labels the data set with descriptive variable names. ######
## Label according to the names listed below
## Acc = Accelerometer
## Gyro = Gryoscope
## BodyBody = Body
## Mag = Magnitude
## f = Frequency
## t = Time
## -std() = Std
## -mean() = Mean

colnames(meanStdData) <- colnames(meanStdData) %>%
                         gsub(pattern="Acc",replacement="Accelerometer") %>%
                         gsub(pattern="Gyro",replacement="Gryoscope") %>%
                         gsub(pattern="BodyBody",replacement="Body") %>%
                         gsub(pattern="^t",replacement="Time") %>%
                         gsub(pattern="^f",replacement="Frequency") %>%
                         gsub(pattern="-std\\(\\)",replacement="Std") %>%
                         gsub(pattern="-mean\\(\\)",replacement="Mean") %>%
                         gsub(pattern="Mag",replacement="Magnitude") 
                  

# 5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject. #

tidymean <-  meanStdData %>% group_by(subject, activityName) %>%
             summarise_each(funs(mean)) 

write.table(tidymean, file = "TidyDataset.txt", row.names = FALSE)
