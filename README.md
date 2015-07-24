# Getting and Cleaning Data Course Project Repo

## Project Summary
        Coursera Course: Getting and Cleaning Data
        Assignment:      Course Project [1]
        Author:          Santiago Oleas

## Project Purpose
Using data captured during the study Human Activity Recognition Using Smartphones Dataset Version 1.0 [2] gather the data and cleanse it based on the instructions described in the course project.  The project has elements that are to be delivered either through github or through the Coursera web site:
* link to this Github repository that is to be provided at the Coursera Project page
* README.md:       This file, which is in the Github repo.
* CodeBook.md:     A codebook describing the data output and the sources
* run_analysis.R:  An R program that takes the data from the study and transforms it based on instructions provided.
* step5Output.txt  Tidy Data Output from run_analysis.R

## Repo Contents
### README.md
This file, which provides an overview of the repo contents and describes the method that the run_analysis.R program follows

### CodeBook.md
This file contains the following information pertaining to the project and the method for producing the final data output.
* Information about the experimental design study
* Information about the source variables, including the units.
* Information about the transformation of any source variables, including summaries.

### run_analysis.R
This file is the R program that takes the data provided, loads, transforms and extracts in the required format.
####Process
* Acquire Data

        Get zip source data file from provided source [3]
        - Unzip file and observe contents

        Information is structured as follows: 
        - activity_labels.txt This activity list maps to the main observation data sets
        - features_info.txt   Describes data field measurement types. Important for answering 
                              further questions
        - features.txt        These are the "column" names for both sets of X_test.txt and X_train.txt data
        - README.txt          Overview doc
        
        ./UCI HAR Dataset/test/
        contains files
        - subject_test.txt    subject ID for each observation in X_test.txt
        - X_test.txt          detailed observations
        - y_test              activity ID for each observation in X_test.txt
        ./UCI HAR Dataset/test/Inertial Signals ***Can be ignored
        
        ./UCI HAR Dataset/train/
        contains files        
        - subject_train.txt   subject ID for each observation in X_train.txt
        - X_train.txt         detailed observations
        - y_train             activity ID for each observation in X_train.txt
        ./UCI HAR Dataset/train/Inertial Signals ***Can be ignored

        Each of train and test has 3 data files that must be combined.  They appear to be 3 different 
        sets of data sets pertaining to the same observations
        "subject_*.txt" has the ID of the subject while the observation took place
        "X_*.txt"       has the actual observations.  There are no COLUMN names here, these can be 
                        found in the "features.txt"
        "y_*.txt"       has the activiy label IDs.  These can later be joined with activity_labels.txt 
                        to know which activity we are dealing with
        
        So this is how we have to put this together. Picture these like blocks that we either stack 
        on top of or put next to each other. In some cases we force a label eg, "subject_id" or we 
        force a column value ("train" and "test" to differentiate the data source)
        ["group"]["subject_id"     ]["activity_id"][features.txt$description]
        ["train"][subject_test.txt ][y_test.txt   ][X_test.txt  ]
        ["test" ][subject_train.txt][y_train.txt  ][X_train.txt ]
        
        The sample data will look something like this after we are done 
|group  | subject_id | activity_id | tBodyAcc-mean()-X | tBodyAcc-mean()-Y |...| angle(Z,gravityMean) |
|-------|-----------:|-------------|-------------------|-------------------|---|----------------------|
| train | 1          | 5           | 2.8858451e-001    | -2.0294171e-02    |...| -5.8626924E-02       |
| ...   |            |             |                   |                   |   |                      |
| test  | 2          | 5           | 2.5717778e-001    | -2.3285230e-002   |...| -6.7430222e-001      |
        
* Merge the training and the test sets to create one data set.

        Load common data:
                - Load features.txt and place into 'features' data frame with column names 
                  featureID and featureDesc
                - Load activity_levels.txt and place into 'activities' data frame with
                  column names activtyID and activityDesc
                  
        Load test data
                - Load subject_test.txt into testSubject data frame with column name of subjectID
                - Load y_test.txt into testActivity data frame with column name of activityID
                - Load X_test.txt into testReadings data frame and force features$featureDesc as
                  column names

        Load Train data
                - Load subject_tRAIN.txt into tRAINSubject data frame with column name of subjectID
                - Load y_train.txt into trainActivity data frame with column name of activityID
                - Load X_train.txt into trainReadings data frame and force features$featureDesc as
                  column names
                 
        Combine all test data
                - place testSubject, testActivity and testReadings into a single data frame
                  called test by placing the 3 data frames next to each other using cbind()
                - add an additional column called test$group with value of 'test' for every
                  observation so that we can distinguish between test and train data when we
                  combine it all together
                  
        Combine all train data
                - place trainSubject, trainActivity and trainReadings into a single data frame
                  called train by placing the 3 data frames next to each other using cbind()
                - add an additional column called train$group with value of 'train' for every
                  observation so that we can distinguish between test and train data when we
                  combine it all together
                  
        Combine train and test data
                - using rbind combine the test and train data frames into a single new one
                  called motionData
                  
* Extract only the Mean and Standard Deviation for each measurement.
        
        We need to keep the key varibles and the Mean and Standard Deviation. The 
        SELECT function from the dplyr function is used here. A new transformed data frame
        called motionDataMeanSTD is created here.  The required elements:
        - group
        - subjectID
        - activityID
        - all mean measurements:  contains("mean")
        - all standard deviation measurements:  contains('std')
        - exclude 'meanFreq' since that is not the same as mean: -contains('meanFreq')
        - exclude all of the 'angle' measurements. These are measuring an
          angle between gravity and another measurement and sometimes the
          word 'Mean' is in these measurements but they are not an actual
          mean of an observation as requested.
          
* Use descriptive activity names to name the activities in the data set

        We can use the MERGE command to combine the activities and the
        motionDataMeanSTD data frames into a new one called motionDataMeanSTDActivity.
        They both have activityID. We will get activities$activityDesc, which is what
        we need to include to fulfill the requirements for this requirement.
        We can then drop motionDataMeanSTDActivity$activityID

* Appropriately labels the data set with descriptive variable names. 

        We will now create feature descriptions that are meaningful
        This is important to help us with obtaining a Tidy Data Set
        The README.txt file helps us understand the variable names
        here.
        PREFIX
        - if prefixed with 't' (time) we will rename as 'time'
        - if prefixed with 'f' (frequency) we will rename 'freq'
        MEASUREMENT
        - the measurements do have some meaningful names
          and these do not need to be simplified. Examples 
          are BodyAcc, GravityAcc, BodyAccJerk, BodyGyro
          BodyGyroJerk, BodyAccMag, GravityAccMag, 
          BodyAccJerkMag, BodyGyroMag, BodyGyroJerkMag
        FUNCTION ON MEASUREMENT
        - the measurements have functions applied to them
          which we can identify with '-fn()', where 'fn' is 
          the function name that is prefixed with '-'.  These 
          mean(), std(), mad(), max(), min(), sma(), energy()
          igr(), entropy(), arCoeff(), correlation(), etc.
          However the only two we care about are the 
          mean stated as  '-mean()' and standard deviation 
          stated as '-std()' we will rename 'Mean' and 'Std' 
          respectively.
        AXIS
        - some measurements have an axis direction denoted with 
          '-X', '-Y', '-Z' and other variations.  However the
          mean() and std() measurements make use of the simple
          variation '-X', '-Y', '-Z' so it is only these three
          we will rename 
        MISC
        - there are other observation variations (see all 'angle'
          prefixed measurements) that are not covered by the above
          however since we will not need these in the final Tidy Data
          output we will not rename these and simply keep them as is.
        EXAMPLES
        - tBodyGyroJerk-mean()-X ==> timeBodyGyroJerkMeanX
        - fBodyAccJerk-std()-Z   ==> freqBodyAccJerkStdZ


* Creates a second, independent tidy data set with the average of each variable for each activity and each subject.

        Since we need an average of each variable for each activity and subject
        this means we can safely exclude 'group', the variable used to distinguish
        between 'test' and 'train' data observations.
        Using the dplyr chaining commands (%>%) we will do this
        one step at a time
        - get all columns except group because we want to be left with
          activity, subject and all measurements but not group
        - group by activity and subject since we need to summarize on this
        - find the mean of each measurement against our group using the
          summarise_all() function call with an argument of funs(mean)
          meaning that we want the mean of each measurement
        As a final step, we use write.table to produce the text file based on the
        tidy data source we produced to be submitted with the project.

### step5Output.txt
A copy of the tidy data set extracted from the run_analysis.R program following the instructions required for the project.

## References
[1] Course Project Information: <https://class.coursera.org/getdata-030/human_grading>
[2] Study information: <http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones#>
[3] Data Source: <https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip>