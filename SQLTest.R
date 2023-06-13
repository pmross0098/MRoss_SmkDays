# This is similar to the work I did to generate smoke day estimates at various
# Air Quality monitors in BC and the NW US. Here I use the sqldf package, which
# manipulates dataframes like a SQL table using SQL commands

# This is analogous to work done in code blocks "AQmungeCan" and "AQmungeUS" in
# my capstone found here:
# https://github.com/pmross0098/MRoss_SmkDays
# To browse end result in a Shiny App:
# https://pmross0098.shinyapps.io/MRoss_SmkDaysWA/

## Canadian data, calculating smoke days in a given year
library(sqldf)
fl <- "ftp://ftp.env.gov.bc.ca/pub/outgoing/AIR/AnnualSummary/2020/PM25.csv"

temp <- tempfile()
download.file(fl, temp, quiet = TRUE)
AQ_raw <- read.csv(temp)
#Coerce to string to allow function to work properly
AQ_raw$DATE <- as.character(AQ_raw$DATE)
# Convert from hourly data to daily
AQsql_bc <- sqldf(paste('SELECT "STATION_NAME", "EMS_ID", "DATE",',
                        'COUNT("Observation.Count") AS Hrs, ',
                        'AVG("RAW_VALUE") AS DailyAvg',
                        'FROM AQ_raw WHERE',
                        '("DATE" BETWEEN "2020-04-01" AND "2020-10-31")',
                        'GROUP BY "EMS_ID", "DATE"'))

# Convert From daily to entire wildfire season (~153days: 4/1-10/31)
AQsql_bc <- sqldf(paste('SELECT *,',
                        '2020 AS Year,',
                        '"BC" AS Province,',
                        'COUNT("DailyAvg") AS TotalDays, ',
                        'SUM(IIF("DailyAvg" >= 35, 1, 0)) AS SmokeDays ',
                        'FROM AQsql_bc',
                        'GROUP BY "EMS_ID"'))
# Drop columns, add Per153
AQsql_bc <- sqldf(c('ALTER TABLE AQsql_bc DROP COLUMN "DATE"',
                    'ALTER TABLE AQsql_bc DROP COLUMN "Hrs"',
                    'ALTER TABLE AQsql_bc DROP COLUMN "DailyAvg"',
                    paste('SELECT *, ((SmokeDays*1.0)/TotalDays*153) AS Per153',
                    'FROM AQsql_bc')))
unlink(temp)
## Need to Join to 'bc_air_monitoring_stations.csv' which has Lat,Long data

## US EPA Data, a rough first pass
fl <- "https://aqs.epa.gov/aqsweb/airdata/daily_88101_2020.zip"
temp <- tempfile()
download.file(fl, temp, quiet = TRUE)
AQ_raw <- read.csv(unzip(temp))

#Coerce to string to allow function to work properly
AQ_raw$Date.Local <- as.character(AQ_raw$Date.Local)
# Group by site, filter to 24-hr avg
AQsql_us <- sqldf(paste('SELECT "Local.Site.Name", "Site.Num", "State.Name", ',
                        '2020 AS Year,',
                        '"Latitude", "Longitude",',
                        'COUNT("Observation.Count") AS TotalDays, ',
                        'SUM(IIF("Arithmetic.Mean" >= 35, 1, 0)) AS SmokeDays ',
                        'FROM AQ_raw WHERE',
                        '("Date.Local" BETWEEN "2020-04-01" AND "2020-10-31") AND',
                        '("State.Name" IN ("Washington","Oregon","Idaho","Montana"))',
                        'GROUP BY "Site.Num"'))

AQsql_us <- sqldf(paste('SELECT *,',
                        '((SmokeDays*1.0)/TotalDays*153) AS Per153',
                        'FROM AQsql_us'))
unlink(temp)


