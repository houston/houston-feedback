class Houston::Feedback::ConversationExcelPresenter
  include OpenXml::Xlsx::Elements

  attr_reader :project, :query, :conversations

  def initialize(project, query, conversations)
    @project = project
    @query = query
    @conversations = conversations || []
  end

  def to_s
    package = OpenXml::Xlsx::Package.new
    worksheet = package.workbook.worksheets[0]

    conversations = Houston.benchmark "[#{self.class.name.underscore}] Load objects" do
      self.conversations.load
    end if self.conversations.is_a?(ActiveRecord::Relation)

    title = { font: Font.new("Calibri", 16) }
    heading = { alignment: Alignment.new("left", "center") }
    general = { alignment: Alignment.new("left", "center") }
    timestamp = {
      format: NumberFormat::DATETIME,
      alignment: Alignment.new("right", "center") }

    title_value = "Feedback for #{project.name}"
    title_value << " that contains \"#{query}\"" unless query.blank?
    worksheet.add_row(
      number: 2,
      cells: [{ column: 2, value: title_value, style: title, height: 24 }])

    worksheet.add_row(
      number: 3,
      cells: [
        { column: 2, value: "Reporter", style: heading },
        { column: 3, value: "Customer", style: heading },
        { column: 4, value: "Created", style: heading },
        { column: 5, value: "Text", style: heading }
      ])

    conversations.each_with_index do |conversation, i|
      worksheet.add_row(
        number: i + 4,
        cells: [
          { column: 2, value: conversation.user.try(:name), style: general },
          { column: 3, value: conversation.attributed_to, style: general },
          { column: 4, value: conversation.created_at, style: timestamp },
          { column: 5, value: conversation.text, style: general }
        ])
    end

    worksheet.column_widths({
      1 => 3.83203125,
      2 => 18,
      3 => 18,
      4 => 14,
      5 => 132})

    worksheet.add_table 1, "Conversations", "B3:E#{conversations.length + 3}", [
      TableColumn.new("Reporter"),
      TableColumn.new("Customer"),
      TableColumn.new("Created"),
      TableColumn.new("Text")
    ]

    Houston.benchmark "[#{self.class.name.underscore}] Prepare file" do
      package.to_stream.string
    end
  end

end
