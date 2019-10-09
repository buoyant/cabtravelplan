json.extract! employee, :id, :empid, :empname, :address, :lat, :lon, :distance, :created_at, :updated_at
json.url employee_url(employee, format: :json)
