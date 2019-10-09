class Employee < ApplicationRecord

  acts_as_mappable :default_units => :kms,
                :default_formula => :sphere,
                :distance_field_name => :distance,
                :lat_column_name => :lat,
                :lng_column_name => :lon

  default_scope { where.not(empname: 'origin') }


  def self.origin
    unscoped.where(empname: 'origin').first
  end

  def self.distance_of_each_employee_from_others(range=3)
    result = {}
    all.each do |employee|
      result[employee.empname] = within(range, origin: employee)
    end
    result
  end


  def self.sort_group_by_distance(group, not_group_ids=[])
    where(id: group.collect(&:id)).where.not(id: not_group_ids).by_distance(origin: origin)
  end

  def self.grouping_nearest_employees
    result = {}
    count = 0
    distance_of_each_employee_from_others.sort_by {|k,v| v.size}.reverse.each do |group|
      result[count] = sort_group_by_distance(group[1], result.values.flatten.map(&:id)).reverse
      # result[count] = sort_group_by_distance(group[1], []).reverse
      count += 1
    end
    result
  end



  # values are employee ids, distance traveled 
  @@vehicle_trips = {car: [], mpv: [], traveller: [], bus: []}

  def self.split_by_40(batch_value)
    if batch_value.size > 40
       batch_value.each_slice(40).to_a
    else
      [batch_value]
    end
  end

  def self.get_no_of_vehicle_trips batch_value
    split_by_40(batch_value).each do |batch|
      get_vehicle_trips(batch)
    end
    @@vehicle_trips
  end


  def self.get_vehicle_trips(batch_value)
    case batch_value.size
    when (2..3)
      dist_traveled = calculate_distance_in_kms(batch_value)
      @@vehicle_trips[:car] << [batch_value.collect(&:id), dist_traveled]
    when (4..5)
      dist_traveled = calculate_distance_in_kms(batch_value)
      @@vehicle_trips[:mpv] << [batch_value.collect(&:id), dist_traveled]
    when (6..15)
      dist_traveled = calculate_distance_in_kms(batch_value)
      @@vehicle_trips[:traveller] << [batch_value.collect(&:id), dist_traveled]
    when (19..40)
      dist_traveled = calculate_distance_in_kms(batch_value)
      @@vehicle_trips[:bus] << [batch_value.collect(&:id), dist_traveled]
    end
  end

  def self.calculate_distance_in_kms(batch_value)
    distance_traveled = 0
    batch_value.each_with_index do |bv, index|
      if index == 0
        origin = Geokit::LatLng.new(Employee.origin.lat, Employee.origin.lon)
        employee_location = Geokit::LatLng.new(bv.lat, bv.lon)
        distance_traveled += Geokit::LatLng.distance_between(origin, employee_location, units: :kms, formula: :sphere).round(2)
      else
        last_employee = batch_value[index-1]
        le = Geokit::LatLng.new(last_employee.lat, last_employee.lon)
        employee_location = Geokit::LatLng.new(bv.lat, bv.lon)
        distance_traveled += Geokit::LatLng.distance_between(le, employee_location, units: :kms, formula: :sphere).round(2)
      end
    end
    distance_traveled
  end

  def self.travel_plan
    final_outcome = []
    grouping_nearest_employees.each do |k, v|
      next if (v.size == 0)
      final_outcome << get_no_of_vehicle_trips(v)
    end
    final_outcome.last
  end

end