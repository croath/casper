if @error.count > 0
  json.error @error
else
  json.count @count
end
