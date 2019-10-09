ENV['RAILS_ENV'] ||= 'development'
require_relative '../config/environment'
require 'csv'

filename = '../data.csv'
CSV.foreach(filename) do |row|
  # p row[0]
  Employee.create!(empname: row[0], address: row[1], lat: row[2], lon: row[3])
end
