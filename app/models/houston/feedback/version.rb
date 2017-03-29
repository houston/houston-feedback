module Houston
  module Feedback
    class Version < VestalVersions::Version
      self.table_name = "feedback_versions"
    end
  end
end
