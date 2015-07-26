## Getting and Cleaning Data 
## Course Project
## Santiago Oleas

## Version summary while coding
## v0 - Initial Version submitted to github
## v1 - Added concluding statement to Requirement 5 in comments
## v2 - Wrapped file download and unzip in Boolean test to see if zip file
##      exists to avoid unnecessary downloading
##    - adjust features.txt descriptions to have a more meaningful
##      name to fulfill Tidy Data requirements
##    - exclude all 'angle' readings from final output of measurements 
##      because some of these have the term 'Mean' but not as a function
##      'mean()' as we are expected to keep
## v3 - added comments to clarify that no duplicate column names occurred 
##      even though data for features.txt has duplicates

## INSTRUCTIONS
## You will be required to submit: 
##     (1) a tidy data set as described below
##     (2) a link to a Github repository with your script for performing 
##         the analysis
##     (3) a code book that describes the variables, the data, and any 
##         transformations or work that you performed to clean up the data 
##         called CodeBook.md. 
##     (4) You should also include a README.md in the repo with your scripts.
##         This repo explains how all of the scripts work and how they are 
##         connected.  

## This file addresses what was requested in (1) above
## You should create one R script called run_analysis.R that does the 
## following. 
## Req 1 - Merges the training and the test sets to create one data set.
## Req 2 - Extracts only the measurements on the mean and standxard deviation 
##         for each measurement. 
## Req 3 - Uses descriptive activity names to name the activities in the data set
## Req 4 - Appropriately labels the data set with descriptive variable names. 
## Req 5 - From the data set in Step 4, creates a second, independent tidy 
##         data set with the average of each variable for each activity and each
##         subject.

## Set working directory
        setwd('/Users/santiago/git/coursera/Getting and Cleaning Data/Assignment')

## Load important libraries
        library(dplyr)

## Get data from Internet
        #Check if we already have file.  If we do not then
        #proceed with downloading and unzipping
        if(!file.exists("./motionData.zip")) {
                #Get file
                fileURL <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip" 
                download.file(fileURL, destfile = "motionData.zip", method = "curl")

                ##Unzip file
                unzip("motionData.zip",overwrite=TRUE)
        }
        
## Req 1 - Merges the training and the test sets to create one data set.

        
        ##Observing the unzipped file I see that we now have a nest of folders that looks like:
        ## ./UCI HAR Dataset/
        ##      contains files 
        ##      - activity_labels.txt ***IMPORTANT*** This maps to other data sets
        ##      - features_info.txt   ***Describes data field types. Important for answering 
        ##                               further questions
        ##      - features.txt        ***IMPORTANT*** These are the "column" names for both sets
        ##                               of X_test.txt and X_train.txt data
        ##      - README.txt          ***Overview doc
        
        ## ./UCI HAR Dataset/test/
        ##      contains files
        ##      - subject_test.txt    ***subject ID for each observation in X_test.txt
        ##      - X_test.txt          ***detailed observations
        ##      - y_test              ***activity ID for each observation in X_test.txt
        ## ./UCI HAR Dataset/test/Inertial Signals ***Can be ignored
        
        ## ./UCI HAR Dataset/train/
        ##      contains files        
        ##      - subject_train.txt   ***subject ID for each observation in X_train.txt
        ##      - X_train.txt         ***detailed observations
        ##      - y_train             ***activity ID for each observation in X_train.txt
        ## ./UCI HAR Dataset/train/Inertial Signals ***Can be ignored

        ## Each of train and test has 3 data files that must be combined.  They
        ## appear to be 3 different sets of data sets pertaining to the same 
        ## observations
        ## "subject_*.txt" has the ID of the subject while the observation took
        ##                 place
        ## "X_*.txt"       has the actual observations.  There are no COLUMN  
        ##                 names here, these can be found in the "features.txt"
        ## "y_*.txt"       has the activiy label IDs.  These can later be 
        ##                 joined with activity_labels.txt to know which 
        ##                 activity we are dealing with
        
        ## So this is how we have to put this together. Picture these like blocks 
        ## that we either stack on top of or put next to each other. In some cases
        ## we force a label eg, "subject_id" or we force a column value ("train"
        ## and "test" to differentiate the data source)
        ## ["group"]["subject_id"     ]["activity_id"][features.txt$description]
        ## ["train"][subject_test.txt ][y_test.txt   ][X_test.txt  ]
        ## ["test" ][subject_train.txt][y_train.txt  ][X_train.txt ]
        
        ## The sample data will look something like this after we are done 
        ## (assume comma separated)
        ## group, subject_id, activity_id, tBodyAcc-mean()-X, tBodyAcc-mean()-Y, ..., angle(Z,gravityMean)
        ## train, 1,          5,           2.8858451e-001,    -2.0294171e-02, ...,    -5.8626924E-02
        ## ...
        ## test,  2,          5,           2.5717778e-001,    -2.3285230e-002, ...,   -6.7430222e-001
        
        ## gather general data
        ## NB - when provided with more than one column the separator is
        ##      the empty string "" and not a space " ".  When the " "
        ##      space was used, it produced errors but "" worked fine
                
                ##features
                ##Give column names of featureID and featureDesc
                features <- read.table("./UCI HAR Dataset/features.txt",sep="",col.names=c("featureID","featureDesc"))
                ##NB##
                # There is an issue here we will take care of later.  There are
                # DUPLICATE column names in the data source for the "features" list
                # This can be proven here where we get TRUE to test for duplicated
                # values.  This will be addressed below.
                any(duplicated(features$featureDesc))
        
        
                ##activities
                ##Give column names of activityID and activityDesc
                activities <- read.table("./UCI HAR Dataset/activity_labels.txt",sep="",col.names=c("activityID","activityDesc"))
        
        ## gather test data
                ## get subject ID and give it a column name of subject_id
                testSubject <- read.table("./UCI HAR Dataset/test/subject_test.txt",col.names=c("subjectID"))
        
                ## get activity ID and give it a column name of 
                testActivity <- read.table("./UCI HAR Dataset/test/y_test.txt",col.names=c("activityID"))
        
                ## get reading data
                ## the column names come from features$featureDesc so we assign
                ## to col.names
                ## NB ## 
                ## We have addressed the duplicate features$featuresDesc we previously 
                ## identified. By forcing this into the column names it appears to have
                ## automatically placed suffixes to differentiate between the duplicated
                ## names.  In any case, the duplicated names are NOT any that we will need
                ## later.
                testReadings <- read.table("./UCI HAR Dataset/test/X_test.txt", sep = "",col.names=features$featureDesc)
                
                ## Run this to confirm we no longer have duplicated column names/featureDesc
                any(duplicated(colnames(testReadings)))
        
        
                ##Check that all three have the same row count.  IF they don't 
                ##then something went wrong.
                dim(testSubject)
                dim(testActivity)
                dim(testReadings)
                ## 2947 for all three.  GOOD.  Proceed.
        

                ##COMBINE test data into a single data frame
                test <- cbind(testSubject,testActivity,testReadings)
                
                #Finally we will append a single column called group
                #that will have the value 'test' for all rows.
                #This will be necessary later when we combine 'test'
                #and 'train' so we can distinguish the rows
                test <- mutate(test, group="test")
                
        
        ## gather train data
                ## get subject ID and give it a column name of subject_id
                trainSubject <- read.table("./UCI HAR Dataset/train/subject_train.txt",col.names=c("subjectID"))
        
                ## get activity ID and give it a column name of 
                trainActivity <- read.table("./UCI HAR Dataset/train/y_train.txt",col.names=c("activityID"))
        
                ## get reading data
                ## the column names come from features$featureDesc so we assign
                ## to col.names
                ## NB ## 
                ## We have addressed the duplicate features$featuresDesc we previously 
                ## identified. By forcing this into the column names it appears to have
                ## automatically placed suffixes to differentiate between the duplicated
                ## names.  In any case, the duplicated names are NOT any that we will need
                ## later.
                trainReadings <- read.table("./UCI HAR Dataset/train/X_train.txt", sep = "",col.names=features$featureDesc)
        
                ## Run this to confirm we no longer have duplicated column names/featureDesc
                any(duplicated(colnames(testReadings)))
                
                ##Check that all three have the same row count.  If they don't
                ##then something went wrong.
                dim(trainSubject)
                dim(trainActivity)
                dim(trainReadings)
                ## 7352 for all three.  GOOD.  Proceed.
        
                ##COMBINE train data into a single data frame
                train <- cbind(trainSubject,trainActivity,trainReadings)
        
                #Finally we will append a single column called group
                #that will have the value 'test' for all rows.
                #This will be necessary later when we combine 'test'
                #and 'train' so we can distinguish the rows
                train <- mutate(train, group="train")
        
        ## combine train and test data
                motionData <- rbind(test,train)
        
                #double check that rows from test and train.
                #recall that train had 7352 and test had 2947 
                #so we expect 10299 rows
                dim(motionData)
                #confirmed 10299.Good
        ###
        ### This concludes Requirement 1.
        ### motionData successfully has a combination of test and train data
        ###

## Req 2 - Extracts only the measurements on the mean and standard deviation
##         for each measurement.
        ## We need to keep the key varibles as well.  That includes:
        ## - group
        ## - subjectID
        ## - activityID
        ## - all mean measurements:  contains("mean")
        ## - all standard deviation measurements:  contains('std')
        ## - exclude 'meanFreq' since that is not the same as mean: -contains('meanFreq')
        ## - exclude all of the 'angle' measurements. These are measuring an
        ##   angle between gravity and another measurement and sometimes the
        ##   word 'Mean' is in these measurements but they are not an actual
        ##   mean of an observation as requested.
        
        ## We will use dplyr's SELECT function using the above list
        motionDataMeanSTD <- select(motionData,group,subjectID,activityID,contains('mean'),contains('std'),-contains('meanFreq'),-contains('angle'))
        
        ###
        ### This concludes Requirement 2.
        ### motionDataMeanSTD successfully has the key variables and all 
        ### mean() and std() columns
        ###
        
        

## Req 3 - Uses descriptive activity names to name the activities in the
##         data set
        ## We can use the merge command to combine the activities and the
        ## motionDataMeanSTD data frames.  They both have activityID.
        ## We will get activities$activityDesc, which is what we need to 
        ## include to fulfill the requirements for this requirement
        motionDataMeanSTDActivity <- merge(activities, motionDataMeanSTD, by.x = "activityID", by.y = "activityID", all=TRUE)
        
        ## We can now drop the original activityID since we are using
        ## activityDesc
        ## We will use -activityID meaning everything except activityID
        motionDataMeanSTDActivity <- select(motionDataMeanSTDActivity,-activityID)
        
        ## Let us check that we have the activityDesc
        head(select(motionDataMeanSTDActivity,activityDesc,group, subjectID),5)
        
        #   activityDesc group subjectID
        # 1      WALKING train        26
        # 2      WALKING train        29
        # 3      WALKING train        29
        # 4      WALKING train        29
        # 5      WALKING train        29
        
        # looks good
        
        ###
        ### This concludes Requirement 3.
        ### motionDataMeanSTDActivity successfully has activity names
        ###
        
## Req 4 - Appropriately labels the data set with descriptive variable names.
        
        ## We will now create feature descriptions that are meaningful
        ##This is important to help us with obtaining a Tidy Data Set
        ##The README.txt file helps us understand the variable names
        ##here.
        ## PREFIX
        ## - if prefixed with 't' (time) we will rename as 'time'
        ## - if prefixed with 'f' (frequency) we will rename 'freq'
        ## MEASUREMENT
        ## - the measurements do have some meaningful names
        ##   and these do not need to be simplified. Examples 
        ##   are BodyAcc, GravityAcc, BodyAccJerk, BodyGyro
        ##   BodyGyroJerk, BodyAccMag, GravityAccMag, 
        ##   BodyAccJerkMag, BodyGyroMag, BodyGyroJerkMag
        ## FUNCTION ON MEASUREMENT
        ## - the measurements have functions applied to them
        ##   which we can identify with '-fn()', where 'fn' is 
        ##   the function name that is prefixed with '-'.  These 
        ##   mean(), std(), mad(), max(), min(), sma(), energy()
        ##   igr(), entropy(), arCoeff(), correlation(), etc.
        ##   However the only two we care about are the 
        ##   mean stated as  '-mean()' and standard deviation 
        ##   stated as '-std()' we will rename 'Mean' and 'Std' 
        ##    respectively.
        ## AXIS
        ## - some measurements have an axis direction denoted with 
        ##   '-X', '-Y', '-Z' and other variations.  However the
        ##   mean() and std() measurements make use of the simple
        ##   variation '-X', '-Y', '-Z' so it is only these three
        ##   we will rename 
        ## MISC
        ## - there are other observation variations (see all 'angle'
        ##   prefixed measurements) that are not covered by the above
        ##   however since we will not need these in the final Tidy Data
        ##   output we will not rename these and simply keep them as is.
        ## EXAMPLES
        ## - tBodyGyroJerk-mean()-X ==> timeBodyGyroJerkMeanX
        ## - fBodyAccJerk-std()-Z   ==> freqBodyAccJerkStdZ
        
        ## taking the vector of names as columns made all special characters
        ## disappear and get replaced with '.' but we don't need those so 
        ## we will clear those.
        names(motionDataMeanSTDActivity) <- gsub("\\.","",names(motionDataMeanSTDActivity))
        
        ## replace all leading 'f' with 'freq'
        names(motionDataMeanSTDActivity) <- gsub("^f","freq",names(motionDataMeanSTDActivity))
        
        ## replace all leading 't' with 'time'
        names(motionDataMeanSTDActivity)<- gsub("^t","time",names(motionDataMeanSTDActivity))
        
        ## replace '-mean()' with 'Mean'
        names(motionDataMeanSTDActivity) <- gsub("mean","Mean",names(motionDataMeanSTDActivity))
        
        ## replace '-std()' with 'Std'
        names(motionDataMeanSTDActivity) <- gsub("std","Std",names(motionDataMeanSTDActivity))
        
        ## We clearly see variables/columns are all labeled
        head(motionDataMeanSTDActivity,1)
        
        ###
        ### This concludes Requirement 4.
        ### tidy column names have been produced.
        ###
        
## Req 5 - From the data set in Step 4, creates a second, independent tidy 
##         data set with the average of each variable for each activity and each
##         subject.
        ## Since we need an average of each variable for each activity and subject
        ## this means we can safely exclude 'group', the variable used to distinguish
        ## between 'test' and 'train' data observations.
        ## Using the dplyr chaining commands (%>%) we will do this
        ## one step at a time
        ##      - get all columns except group because we want to be left with
        ##        activity, subject and all measurements but not group
        ##      - group by activity and subject since we need to summarize on this
        ##      - find the mean of each measurement against our group using the
        ##        summarise_all() function call with an argument of funs(mean)
        ##        meaning that we want the mean of each measurement
        motionDataMeanSummary <- motionDataMeanSTDActivity %>% 
                                   select(-group) %>% 
                                   group_by(activityDesc,subjectID) %>%
                                   summarise_each(funs(mean))
        
        ## We must extract this file
        write.table(motionDataMeanSummary, "step5Output.txt",row.names=FALSE)
        
        ###
        ### This concludes Requirement 5.
        ### tidy data has been produced and placed into a text file that was
        ### also uploaded to the Coursera Course Project site.
        ###
        
