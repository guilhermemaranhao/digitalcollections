if (@msg.present?)
  json.erro @msg
else
  json.array! @resultado_enxuto, :id, :text
end
