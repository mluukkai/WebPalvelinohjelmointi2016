json.array!(@styles) do |style|
  json.extract! style, :id, :name, :description
  json.url style_url(style, format: :json)
end
