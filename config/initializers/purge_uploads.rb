Houston.config.at "10:00pm", "purge:uploads" do
  uploads_dir = File.join(Houston::Application.paths["tmp"].first, "uploads")
  earliest_upload_to_keep = "#{uploads_dir}/#{Time.now.beginning_of_day.strftime("%Y%m%d%H%M%S")}.csv"
  Dir.glob("#{uploads_dir}/*.csv").each do |file|
    next unless file < earliest_upload_to_keep
    FileUtils.rm file
  end
end
