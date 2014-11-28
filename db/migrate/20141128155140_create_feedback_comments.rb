class CreateFeedbackComments < ActiveRecord::Migration
  def up
    create_table :feedback_comments do |t|
      t.integer :project_id, null: false
      t.integer :user_id
      
      t.text :text, null: false
      t.text :plain_text, null: false
      t.string :customer, null: false, default: ""
      t.text :tags, null: false, default: ""
      
      t.tsvector :search_vector
      
      t.integer :ticket_id, null: false
      
      t.timestamps
    end
    
    project_ids = Project.where(slug: %w{ledger members unite confb dr epic-auth houston lsb-editor lsb3 musicmate oic}).pluck(:id)
    tickets = Ticket.open
      .unresolved
      .where(milestone_id: nil)
      .where(project_id: project_ids)
    
    require "progressbar"
    pbar = ProgressBar.new("tickets", tickets.count)
    tickets.find_each do |ticket|
      antecedents = ticket.antecedents.select { |a| a.kind == "Goldmine" }
      goldmine_numbers = antecedents.map(&:id).uniq
      attributes = {
        ticket_id: ticket.id,
        project_id: ticket.project_id,
        user_id: ticket.reporter_id,
        text: ticket_to_feedback_text(ticket),
        tags: %w{converted},
        created_at: ticket.created_at,
        updated_at: Time.now }
      if goldmine_numbers.count == 0
        Houston::Feedback::Comment.create(attributes)
      else
        goldmine_numbers.each do |number|
          unless number =~ /^00\d{6}$/
            if number.length == 6
              number = "00#{number}"
            else
              puts "#{number.length}-digit GM number: #{number}"
            end
          end
          Houston::Feedback::Comment.create(attributes.merge(
            text: ticket_to_feedback_text2(ticket, goldmine_notes(number)),
            customer: "GM #{number}"))
        end
      end
      pbar.inc
    end
    pbar.finish
    
    execute "CREATE INDEX index_feedback_comments_on_tsvector ON feedback_comments USING GIN(search_vector)"
  end
  
  def down
    execute "DROP TRIGGER IF EXISTS index_feedback_comments_on_insert_update_trigger ON feedback_comments"
    execute "DROP FUNCTION IF EXISTS index_feedback_comments_on_insert_update()"
    
    drop_table :feedback_comments
  end
  
private
  
  def goldmine_notes(number)
    # response = Faraday.get "http://goldmineweb/DisplayCase.aspx?CaseNumber=#{number}"
    # page = Nokogiri::HTML(response.body)
    # goldmine_notes = page.css("[name=\"txtDescription\"]").first.text
    @goldmine ||= JSON.load(File.read(File.expand_path("~/Desktop/Tickets->Feedback/goldmine_notes.json")))
    @goldmine[number.to_i.to_s]
  end
  
  def ticket_to_feedback_text2(ticket, goldmine_notes)
    [ "# #{ticket.summary}",
      "### Goldmine Notes",
      indent_all(goldmine_notes),
      clean_up_description(ticket) ].join("\n\n")
  end
  
  def indent_all(text)
    text.to_s.split(/\r?\n/).map { |line| "> " + line }.join("\n")
  end
  
  def ticket_to_feedback_text(ticket)
    [ "# #{ticket.summary}",
      clean_up_description(ticket) ].join("\n\n")
  end
  
  def clean_up_description(ticket)
    description = ticket.description.to_s
      .gsub(/^#+ *Antecedents?:? *\r?\n/, "")
      .gsub(/^ *(\- *)?(Goldmine|Errbit)( number| ticket)?[ \d,#:]*\r?\n?/, "")
      .gsub(/(##+)(?=\w)/, '\1 ') # put spaces after heading sigils
    
    puts [ticket.project.slug, ticket.number, ticket.summary].join(" ") if description =~ /Antecedent/ or description =~ /Goldmine/
    description
  end
  
end
