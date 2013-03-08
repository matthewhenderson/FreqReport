
The purpose of this script is to get all the fields in a database, 
then, look at the distinct values appearing in that field.
Once that is done, the frequency each value occurs is calculated. 
A bar graph is produced in R, and a table is generated in an HTML
file, showing the data for each field in the database.

May need to change setting of ENV['R_HOME'].
REQUIRES SQLITE3 (sudo gem install sqlite3-ruby)
REQUIRES R (http://www.r-project.org/)
REQUIRES RSRUBY (https://github.com/alexgutteridge/rsruby)
