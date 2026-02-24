json.array! @registries do |registry|
  json.extract! registry, :name, :url, :ecosystem, :packages_count
end
