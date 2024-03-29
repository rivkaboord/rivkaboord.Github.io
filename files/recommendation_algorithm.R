# RECOMMENDATION ALGORITHM ----

# 1.0 Setup ----

# Libraries
library(readxl)
library(tidyverse)
library(tidyquant)
library(recipes)    # Make sure v0.1.3 or laters is installed. If not restart & install.packages("recipes") to update.

# Data
path_train            <- "https://github.com/rivkaboord/rivkaboord.Github.io/blob/master/files/telco_train.xlsx"
path_test             <- "https://github.com/rivkaboord/rivkaboord.Github.io/blob/master/files/telco_test.xlsx"
path_data_definitions <- "https://github.com/rivkaboord/rivkaboord.Github.io/blob/master/files/telco_data_definitions.xlsx"

train_raw_tbl       <- read_excel(path_train, sheet = 1)
test_raw_tbl        <- read_excel(path_test, sheet = 1)
definitions_raw_tbl <- read_excel(path_data_definitions, sheet = 1, col_names = FALSE)

# Processing Pipeline
source("https://github.com/rivkaboord/rivkaboord.Github.io/blob/master/files/data_processing_pipeline.R")
train_readable_tbl <- process_hr_data_readable(train_raw_tbl, definitions_raw_tbl)
test_readable_tbl  <- process_hr_data_readable(test_raw_tbl, definitions_raw_tbl)



# 2.0 Correlation Analysis - Machine Readable ----
source("https://github.com/rivkaboord/rivkaboord.Github.io/blob/master/files/plot_cor.R")

# 2.1 Recipes ----

train_readable_tbl %>% glimpse()

# Factor Names
factor_names <- c("JobLevel", "StockOptionLevel")

# Recipe

recipe_obj <- recipe(Attrition ~ ., data = train_readable_tbl) %>%
    step_zv(all_predictors()) %>%
    step_mutate_at(all_of(factor_names), fn = as.factor) %>%
    step_discretize(all_numeric(), options = list(min_unique = 1)) %>%
    step_dummy(all_nominal(), one_hot = TRUE) %>%
    prep()

recipe_obj

train_corr_tbl <- bake(recipe_obj, new_data = train_readable_tbl)

train_corr_tbl %>% glimpse()

tidy(recipe_obj)

tidy(recipe_obj, number = 4)

# 2.2 Correlation Visualization ----

# Manipulate Data

corr_level <- 0.06

correlation_results_tbl <- train_corr_tbl %>%
    select(-Attrition_No) %>%
    get_cor(Attrition_Yes, fct_reorder = TRUE, fct_rev = TRUE) %>%
    filter(abs(Attrition_Yes) >= corr_level) %>%
    mutate(
        relationship = case_when(
            Attrition_Yes > 0 ~ "Supports",
            TRUE ~ "Contradicts"
        )
    ) %>%
    mutate(feature_text = as.character(feature)) %>%
    separate(feature_text, into = "feature_base", sep = "_", extra = "drop") %>%
    mutate(feature_base = as_factor(feature_base) %>% fct_rev())

length_unique_groups <- correlation_results_tbl %>%
    pull(feature_base) %>%
    unique() %>%
    length()

# Create Visualization

correlation_results_tbl %>%
    ggplot(aes(Attrition_Yes, feature_base, color = relationship)) +
    geom_point() +
    geom_label(aes(label = feature), vjust = -0.5) +
    expand_limits(x = c(-0.3, 0.3), y = c(1, length_unique_groups + 1.5)) +
    theme_tq() +
    scale_color_tq() +
    labs(
        title = "Correlation Analysis: Recommendation Strategy Development",
        subtitle = "Discretizing features to help identify a strategy"
    )

# 3.0 Recommendation Strategy Development Worksheet ----




# 4.0 Recommendation Algorithm Development ----

# 4.1 Personal Development (Mentorship, Education) ----

# Years at Company
# YAC - High - Likely to stay / YAC - LOW - Likely to leave
# Tie promotion if low to advance faster / Mentor if YAC low

# TotalWorkingYears
# TWY - High - More likely to stay / TWY - LOW - More likely to leave
# Tie Low TWY to training & formation/mentorship

# YearsInCurrentRole
# More time in current role related to lower attrition
# Incentivize specialize or promote / Mentorship Role

# JobInvolvement
# High JI - Likely to stay / Low JI - Likely to leave
# Create personal development plan / high: seek leadership role

# JobSatisfaction
# Low JS - More likely to leave / High JS - More likely to stay
# Low: Create personal development plan / High: Mentorship roles

# PerformanceRating
# Low: Create personal development plan / High: seek leadership or mentorship role

# Good, Better, Best Approach

# (Worst Case) Create Personal Development Plan: JobInvolvement, JobSatisfaction, PerformanceRating

# (Better Case) Promote Training & Formation: YearsAtCompany, TotalWorkingYears

# (Best Case 1) Seek Mentorship Role: YearsInCurrentRole, YearsAtCompany, PerformanceRating, JobSatisfaction

# (Best Case 2) Seek Leadership Role: JobInvolvement, JobSatisfaction, PerformanceRating

train_readable_tbl %>%
    select(YearsAtCompany, TotalWorkingYears, YearsInCurrentRole,
           JobInvolvement, JobSatisfaction, PerformanceRating) %>%
    mutate_if(is.factor, as.numeric) %>%
    mutate(
        personal_development_strategy = case_when(

            # (Worst Case) Create Personal Development Plan: JobInvolvement, JobSatisfaction, PerformanceRating
            PerformanceRating == 1 |
                JobSatisfaction == 1 |
                JobInvolvement <= 2          ~ "Create Personal Development Plan",

            # (Better Case) Promote Training & Formation: YearsAtCompany, TotalWorkingYears
            YearsAtCompany < 3 |
                TotalWorkingYears < 6        ~ "Promote Training and Formation",

            # (Best Case 1) Seek Mentorship Role: YearsInCurrentRole, YearsAtCompany, PerformanceRating, JobSatisfaction
            (YearsInCurrentRole > 3 | YearsAtCompany >= 5) &
                PerformanceRating >= 3 &
                JobSatisfaction == 4         ~ "Seek Mentorship Role",

            # (Best Case 2) Seek Leadership Role: JobInvolvement, JobSatisfaction, PerformanceRating
            JobInvolvement >= 3 &
                JobSatisfaction >= 3 &
                PerformanceRating >= 3       ~ "Seek Leadership Role",

            # Catch All
            TRUE                             ~ "Retain and Maintain"
        )
    )

tidy(recipe_obj, number = 3) %>%
    filter(str_detect(terms, "TotalWorking"))

# 4.2 Professional Development (Promotion Readiness) ----

# 4.2 Professional Development (Promotion Readiness) ----

# JobLevel
#   Employees with Job Level 1 are leaving / Job Level 2 staying
#   Promote faster for high performers

# YearsAtCompany
#   YAC - High - Likely to stay / YAC - LOW - Likely to leave
#   Tie promotion if low to advance faster / Mentor if YAC low

# YearsInCurrentRole
#   More time in current role related to lower attrition
#   Incentivize specialize or promote

# Additional Features
#   JobInvolvement - Important for promotion readiness, incentivizes involvment for leaders and early promotion
#   JobSatisfaction - Important for specialization, incentivizes satisfaction for mentors
#   PerformanceRating - Important for any promotion


# Good Better Best Approach

# Ready For Rotation: YearsInCurrentRole, JobSatisfaction (LOW)

# Ready For Promotion Level 2: JobLevel, YearsInCurrentRole, JobInvolvement, PerformanceRating

# Ready For Promotion Level 3: JobLevel, YearsInCurrentRole, JobInvolvement, PerformanceRating

# Ready For Promotion Level 4: JobLevel, YearsInCurrentRole, JobInvolvement, PerformanceRating

# Ready For Promotion Level 5: JobLevel, YearsInCurrentRole, JobInvolvement, PerformanceRating

# Incentivize Specialization: YearsInCurrentRole, JobSatisfaction, PerformanceRating


# Implement Strategy Into Code
train_readable_tbl %>%
    select(JobLevel, YearsInCurrentRole,
           JobInvolvement, JobSatisfaction, PerformanceRating) %>%
    mutate_if(is.factor, as.numeric) %>%
    mutate(
        professional_development_strategy = case_when(

            # Ready For Rotation: YearsInCurrentRole, JobSatisfaction (LOW)
            YearsInCurrentRole >= 2 &
                JobSatisfaction <= 2              ~ "Ready for Rotation",

            # Ready For Promotion Level 2: JobLevel, YearsInCurrentRole, JobInvolvement, PerformanceRating
            JobLevel == 1 &
                YearsInCurrentRole >= 2 &
                JobInvolvement >= 3 &
                PerformanceRating >= 3            ~ "Ready for Promotion",

            # Ready For Promotion Level 3: JobLevel, YearsInCurrentRole, JobInvolvement, PerformanceRating
            JobLevel == 2 &
                YearsInCurrentRole >= 2 &
                JobInvolvement >= 4 &
                PerformanceRating >= 3            ~ "Ready for Promotion",

            # Ready For Promotion Level 4: JobLevel, YearsInCurrentRole, JobInvolvement, PerformanceRating
            JobLevel == 3 &
                YearsInCurrentRole >= 3 &
                JobInvolvement >= 4 &
                PerformanceRating >= 3            ~ "Ready for Promotion",

            # Ready For Promotion Level 5: JobLevel, YearsInCurrentRole, JobInvolvement, PerformanceRating
            JobLevel == 4 &
                YearsInCurrentRole >= 4 &
                JobInvolvement >= 4 &
                PerformanceRating >= 3            ~ "Ready for Promotion",

            # Incentivize Specialization: YearsInCurrentRole, JobSatisfaction, PerformanceRating
            YearsInCurrentRole >= 4 &
                JobSatisfaction >= 4 &
                PerformanceRating >= 3            ~ "Incentivize Specialization",


            # Catch All
            TRUE ~ "Retain and Maintain"
        )
    )

tidy(recipe_obj, number = 3) %>%
    filter(str_detect(terms, "YearsInCurrentRole"))

# 4.3 Work Environment Strategy ----

# OverTime
#  Employees with high OT are leaving
#  Reduce Overtime - work life balance

# EnvironmentSatisfaction
#  Employees with low environment satisfaction are more likely to leave
#  Improve the workplace environment - review job assignment after period of time in current role

# WorkLifeBalance
#  Bad worklife balance - more likely to leave
#  Improve the worklife balance

# BusinessTravel
#  More business travel - more likely to leave / Less BT - more likely to stay
#  Reduce Business Travel where possible

# DistanceFromHome
#  High distance from Home - more likely to leave
#  Monitor worklife balance - Monitor Business Travel

# Additional Features
#  YearsInCurrentRole - Important for reviewing a job assignment is to give sufficient time in a role (min 2 years)
#  JobInvolvement - Not included, but important in keeping work environment satisfaction (Target Medium & Low)


# Good Better Best Approach
# Improve Work-Life Balance: OverTime, WorkLifeBalance
# Monitor Business Travel: BusinessTravel, DistanceFromHome, WorkLifeBalance
# Review Job Assignment: EnvironmentSatisfaction, YearsInCurrentRole
# Promote Job Engagement: JobInvolvement


# Implement Strategy Into Code
train_readable_tbl %>%
    select(OverTime, EnvironmentSatisfaction, WorkLifeBalance, BusinessTravel,
           DistanceFromHome, YearsInCurrentRole, JobInvolvement) %>%
    mutate_if(is.factor, as.numeric) %>%
    mutate(
        work_environment_strategy = case_when(

            # Improve Work-Life Balance: OverTime, WorkLifeBalance
            OverTime == 2 |
                WorkLifeBalance == 1     ~ "Improve Work-Life Balance",

            # Monitor Business Travel: BusinessTravel, DistanceFromHome, WorkLifeBalance
            (BusinessTravel == 3 |
                 DistanceFromHome >= 10) &
                WorkLifeBalance == 2     ~  "Monitor Business Travel",

            # Review Job Assignment: EnvironmentSatisfaction, YearsInCurrentRole
            EnvironmentSatisfaction == 1 &
                YearsInCurrentRole >= 2  ~ "Review Job Assignment",

            # Promote Job Engagement: JobInvolvement
            JobInvolvement <= 2  ~ "Promote Job Engagement",

            # Catch All
            TRUE ~ "Retain and Maintain"
        )
    )

train_readable_tbl %>%
    pull(JobInvolvement) %>%
    levels()

tidy(recipe_obj, 3) %>%
    filter(str_detect(terms, "Distance"))

data <- train_readable_tbl
employee_number = 19

recommendation_strategies <- function(data, employee_number) {

    data %>%
        filter(EmployeeNumber == employee_number) %>%
        mutate_if(is.factor, as.numeric) %>%

        # Personal Development Strategy
        mutate(
            personal_development_strategy = case_when(

                # (Worst Case) Create Personal Development Plan: JobInvolvement, JobSatisfaction, PerformanceRating
                PerformanceRating == 1 |
                    JobSatisfaction == 1 |
                    JobInvolvement <= 2          ~ "Create Personal Development Plan",

                # (Better Case) Promote Training & Formation: YearsAtCompany, TotalWorkingYears
                YearsAtCompany < 3 |
                    TotalWorkingYears < 6        ~ "Promote Training and Formation",

                # (Best Case 1) Seek Mentorship Role: YearsInCurrentRole, YearsAtCompany, PerformanceRating, JobSatisfaction
                (YearsInCurrentRole > 3 | YearsAtCompany >= 5) &
                    PerformanceRating >= 3 &
                    JobSatisfaction == 4         ~ "Seek Mentorship Role",

                # (Best Case 2) Seek Leadership Role: JobInvolvement, JobSatisfaction, PerformanceRating
                JobInvolvement >= 3 &
                    JobSatisfaction >= 3 &
                    PerformanceRating >= 3       ~ "Seek Leadership Role",

                # Catch All
                TRUE                             ~ "Retain and Maintain"
            )
        ) %>%
        # select(EmployeeNumber, personal_development_strategy)

        # Professional Development Strategy
        mutate(
            professional_development_strategy = case_when(

                # Ready For Rotation: YearsInCurrentRole, JobSatisfaction (LOW)
                YearsInCurrentRole >= 2 &
                    JobSatisfaction <= 2              ~ "Ready for Rotation",

                # Ready For Promotion Level 2: JobLevel, YearsInCurrentRole, JobInvolvement, PerformanceRating
                JobLevel == 1 &
                    YearsInCurrentRole >= 2 &
                    JobInvolvement >= 3 &
                    PerformanceRating >= 3            ~ "Ready for Promotion",

                # Ready For Promotion Level 3: JobLevel, YearsInCurrentRole, JobInvolvement, PerformanceRating
                JobLevel == 2 &
                    YearsInCurrentRole >= 2 &
                    JobInvolvement >= 4 &
                    PerformanceRating >= 3            ~ "Ready for Promotion",

                # Ready For Promotion Level 4: JobLevel, YearsInCurrentRole, JobInvolvement, PerformanceRating
                JobLevel == 3 &
                    YearsInCurrentRole >= 3 &
                    JobInvolvement >= 4 &
                    PerformanceRating >= 3            ~ "Ready for Promotion",

                # Ready For Promotion Level 5: JobLevel, YearsInCurrentRole, JobInvolvement, PerformanceRating
                JobLevel == 4 &
                    YearsInCurrentRole >= 4 &
                    JobInvolvement >= 4 &
                    PerformanceRating >= 3            ~ "Ready for Promotion",

                # Incentivize Specialization: YearsInCurrentRole, JobSatisfaction, PerformanceRating
                YearsInCurrentRole >= 4 &
                    JobSatisfaction >= 4 &
                    PerformanceRating >= 3            ~ "Incentivize Specialization",


                # Catch All
                TRUE ~ "Retain and Maintain"
            )
        ) %>%
        # select(EmployeeNumber, professional_development_strategy)

        # Work Environment Strategy
        mutate(
            work_environment_strategy = case_when(

                # Improve Work-Life Balance: OverTime, WorkLifeBalance
                OverTime == 2 |
                    WorkLifeBalance == 1     ~ "Improve Work-Life Balance",

                # Monitor Business Travel: BusinessTravel, DistanceFromHome, WorkLifeBalance
                (BusinessTravel == 3 |
                     DistanceFromHome >= 10) &
                    WorkLifeBalance == 2     ~  "Monitor Business Travel",

                # Review Job Assignment: EnvironmentSatisfaction, YearsInCurrentRole
                EnvironmentSatisfaction == 1 &
                    YearsInCurrentRole >= 2  ~ "Review Job Assignment",

                # Promote Job Engagement: JobInvolvement
                JobInvolvement <= 2  ~ "Promote Job Engagement",

                # Catch All
                TRUE ~ "Retain and Maintain"
            )
        ) %>%
        select(EmployeeNumber, personal_development_strategy, professional_development_strategy, work_environment_strategy)
}

train_readable_tbl %>%
    recommendation_strategies(14)
