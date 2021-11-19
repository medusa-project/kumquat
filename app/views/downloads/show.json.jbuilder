json.id @download.id
json.key @download.key
json.filename @download.filename
json.url @download.url
json.expired @download.expired

if @download.task # the task will be nil until the download job starts running
  json.task do
    json.id @download.task.id
    json.status @download.task.status
    json.status_text @download.task.status_text
    json.percent_complete @download.task.percent_complete
    json.indeterminate @download.task.indeterminate
  end
end