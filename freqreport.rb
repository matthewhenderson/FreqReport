#*************************************
#  Author: Matthew Henderson
#  Created: 2012-04-05
#
#  The purpose of this script is to get all the fields in a database, 
#  then, look at the distinct values appearing in that field.
#  Once that is done, the frequency each value occurs is calculated. 
#  A bar graph is produced in R, and a table is generated in an HTML
#  file, showing the data for each field in the database.
#
#  May need to change setting of ENV['R_HOME'] below.
#
#  REQUIRES SQLITE3 (sudo gem install sqlite3-ruby)
#  REQUIRES R (http://www.r-project.org/)
#  REQUIRES RSRUBY (https://github.com/alexgutteridge/rsruby)
#
#*************************************
require 'rubygems'
require 'sqlite3'
require 'rsruby'
require 'tempfile'

#*************************************
#  REQUEST INFORMATION     
#*************************************
puts "\n\nPLEASE NOTE:"
puts "Run from location of Sqlite3 database."
puts "Expects the folder named 'graphs' to be in this location."

#request databasename and table from user
puts "\nWhat is the database filename?"
@thedatabase = gets.chomp #get user input
puts "What is the table name?"
@tablename = gets.chomp #get user input


#*************************************
#  DATABASE ACCESS              
#*************************************

def openthedatabase
  @db = SQLite3::Database.new(@thedatabase)
end

def closethedatabase
  @db.close
end


#*************************************
#  FREQUENCY REPORT  WORK
#*************************************

#this will be used in later reports for mean values
def getrowcount
  @rowcount = @db.execute("select count(*) from #{@tablename}").to_s
end

def getthefieldnames
  @fields = Array.new
  @db.execute("PRAGMA table_info([#{@tablename}])") do |row|
    @fields << row[1]
  end
end

def setcurrentfield(fieldname)
  @fieldname = fieldname
end

#get distinct values for the specified field
def getfieldvalues
  #instantiate the Array here to be sure it is clear of values before populating
  @fieldvalues = Array.new
  @db.execute("select distinct(#{@fieldname}) from data") do |value|
    v=value[0].to_s
    @fieldvalues << value[0].to_s
  end
end

#for the specified field get frequency of each distinct value
def getfreqs
  @freqs = Hash.new
  @fieldvalues.each do |v|
    @freqs[v] = @db.execute("select count(*) from #{@tablename} where #{@fieldname} = '#{v}'").to_s    
  end
end


#*************************************
#  DEFINE GRAPH DATA
#*************************************

def getxyaxisvalues
  @x = Array.new #holds x-axis data
  @y = Array.new #holds y-axis data
    
  #first, determine if there is a null value
  #then, set it if so
  if @freqs[""]
    nullfreq = @freqs[""].to_i
  end

  thevalueoptions = Array.new
  @freqs.each do|valueoption,frequency|
    #set the values, skipping if null (set above)
    if not valueoption == ""
      thevalueoptions << valueoption.to_i
    end
  end

  $stdout.sync = true #allows the print output to not be buffered

  if nullfreq 
    @x << "SKIP"
    @y << nullfreq
  end
  
  thevalueoptions.sort!
  thevalueoptions.each do |v|
    @x << v.to_s
    @y << @freqs[v.to_s].to_i
  end

  print "." #update 'progress' bar
end


#*************************************
#  CREATE THE R GRAPH      
#*************************************

def prepgraph(width)
  #configure R location
  if ENV['R_HOME'].nil?
    ENV['R_HOME'] = "/Library/Frameworks/R.framework/Resources/"
  end
  
  @r = RSRuby.instance    
  @writefile = "graphs/" + @fieldname.to_s + ".png"
  File.new(@writefile, 'a')
  @r.png @writefile, :width => width
end

def createbargraph(x,y)
  #build the graph
  @r.barplot(
      @y, 
      :names => @x, 
      :main => "Value Frequency for #{@fieldname}",
      #:type => "b",      
      #:xlab => "x label", 
      :ylab => "Frequency", 
      :col => "blue", 
      :las => 2
      )    
  @r.eval_R("dev.off()")
end  


#*************************************
#  CREATE THE HTML FILE    
#*************************************

def openhtmlfile
  html = "<!DOCTYPE html><head><meta charset='utf-8'><style>
      table{width:1000px;border-collapse:collapse;padding:0;border:3px solid #000;}
      th{background:#999;text-align:left;border:2px solid #000;margin:0;padding:5px 8px;}
      td{border:2px solid #000;margin:0;padding:5px 8px;}
      hr{margin:20px 0 20px 0;padding:3px;border:0;background:#660000;}
      </style></head><body>"
        
  @htmlfilename =  "frequencyreport.html"  
  #use the 'w' switch to overwrite the html file if it already exists
  File.open(@htmlfilename, 'w') {|file| file.write(html) }    
end

def generatehtml(x,y)
    tdwidthpercentage = 950 / (x.length.to_i)
    
    html = "<div style='width:1000px;margin:0 auto;'>"    
    html = html + "<style>th{width:#{tdwidthpercentage}px;td{width:#{tdwidthpercentage}px;</style>"
    html = html + "<img src='graphs/" + @fieldname + ".png' alt='Frequency graph for " + @fieldname  + "' />"
    html = html + "<br /><br /><table><tr><th style='width:50px;background:#222;color:#FFF;'>Answer</th>"
    #create the header
    x.each do |field|
      html = html + "<th>" + field.to_s + "</th>"
    end
    html = html + "</tr><tr><td style='width:50px;background:#222;color:#FFF;'>Frequency</td>"
    #create the row
    y.each do |value|
      html = html + "<td>" + value.to_s + "</td>"
    end
    
    html = html + "</tr></table></div><hr />"
    
    #use the 'w' switch to overwrite the html file if it already exists
    File.open(@htmlfilename, 'a') {|file| file.write(html) }    
end

def closehtmlfile
    html = "</body></html>"
    File.open(@htmlfilename, 'a') {|file| file.write(html) }        
end


#*************************************
#  EXECUTE         
#*************************************

openthedatabase
getrowcount

if @rowcount
  getthefieldnames
  print "Generating report for " + @fields.length.to_s + " fields."
  openhtmlfile
  
  @fields.each do |fieldname|
    setcurrentfield(fieldname)
    getfieldvalues
    getfreqs
    prepgraph(1000)
    getxyaxisvalues 
    createbargraph(@x,@y)    
    generatehtml(@x,@y)
  end
  
  closehtmlfile
end

closethedatabase
puts "\nDone!\n\n"

