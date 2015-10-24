namespace :feedback do
  PROJECTS = %w{ledger members unite bible101 bsb confb discourse dr epic-auth houston lsb-editor lsb3 oic pastoral_care pray_now}.freeze
  
  desc "Erases all feedback"
  task :erase => :environment do
    project_ids = Project.where(slug: PROJECTS).pluck(:id)
    comments = Houston::Feedback::Comment.where(project_id: project_ids)
    
    puts "\e[34mErasing #{comments.count} comments\e[0m"
    comments.delete_all
  end
  
  desc "Converts tickets to feedback"
  task :convert => :environment do
    project_ids = Project.where(slug: PROJECTS).pluck(:id)
    imported_ticket_ids = Houston::Feedback::Comment.where("ticket_id IS NOT NULL").pluck(:ticket_id)
    
    tickets = Ticket.open
      .unresolved
      .where(type: %w{Enhancement Feature}) # not Bugs or Chores
      .where(milestone_id: nil)
      .where(project_id: project_ids)
      .where(Ticket.arel_table[:id].not_in(imported_ticket_ids)) # skip tickets that have already been converted to feedbacks
    
    puts "\e[34mConverting #{tickets.count} tickets into feedback\e[0m"
    
    require "progressbar"
    pbar = ProgressBar.new("tickets", tickets.count)
    tickets.find_each do |ticket|
      antecedents = ticket.antecedents.select { |a| a.kind == "Goldmine" }
      goldmine_numbers = antecedents.map(&:id).uniq
      tags = %w{converted} + TAGS.fetch(ticket.number, [])
      attributes = {
        ticket_id: ticket.id,
        project_id: ticket.project_id,
        user_id: ticket.reporter_id,
        text: ticket_to_feedback_text(ticket),
        tags: tags,
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
            attributed_to: "GM #{number}"))
        end
      end
      pbar.inc
    end
    pbar.finish
  end
  
  desc "Erases all feedback and converts it again from tickets"
  task :reconvert => [:erase, :convert]
  
  
  
  
  def goldmine_notes(number)
    response = Faraday.get "http://goldmineweb/DisplayCase.aspx?CaseNumber=#{number}"
    page = Nokogiri::HTML(response.body)
    page.css("[name=\"txtDescription\"]").first.text
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

  TAGS = {2099=>["cross-linking"], 2336=>["cross-linking"], 2337=>["cross-linking"], 2409=>["cross-linking"], 2779=>["cross-linking"], 2942=>["cross-linking"], 3093=>["cross-linking"], 3152=>["cross-linking"], 3414=>["cross-linking"], 1041=>["reports"], 1190=>["reports"], 1310=>["reports"], 1351=>["reports"], 1435=>["reports"], 1437=>["reports"], 1466=>["reports"], 1467=>["reports"], 1485=>["reports"], 1511=>["reports"], 1704=>["reports"], 1709=>["reports"], 1733=>["reports"], 1857=>["reports"], 2043=>["reports"], 2335=>["reports"], 2382=>["reports"], 2391=>["reports"], 2392=>["reports"], 2396=>["reports"], 2397=>["reports"], 2424=>["reports"], 2440=>["reports"], 2466=>["reports"], 2471=>["reports"], 2472=>["reports"], 2496=>["reports"], 2533=>["reports"], 2560=>["reports"], 2564=>["reports"], 2582=>["reports"], 2584=>["reports"], 2585=>["reports"], 2610=>["reports"], 2615=>["reports"], 2627=>["reports"], 2636=>["reports"], 2647=>["reports"], 2671=>["reports"], 2672=>["reports"], 2703=>["reports"], 2722=>["reports"], 2761=>["reports"], 2799=>["reports"], 2834=>["reports"], 2835=>["reports"], 2839=>["reports"], 2871=>["reports"], 2964=>["reports"], 2993=>["reports"], 3019=>["reports"], 3051=>["reports"], 3068=>["reports"], 3113=>["reports"], 3125=>["reports"], 3128=>["reports"], 3137=>["reports"], 3150=>["reports"], 3160=>["reports"], 3163=>["reports"], 3181=>["reports"], 3199=>["reports"], 3201=>["reports"], 3251=>["reports"], 3285=>["reports"], 3346=>["reports"], 3406=>["reports"], 1508=>["redesign"], 1815=>["redesign"], 2110=>["redesign"], 2441=>["redesign"], 3138=>["redesign"], 3155=>["redesign"], 3156=>["redesign"], 1489=>["add-person"], 3091=>["add-person"], 1550=>["zero-state"], 1576=>["zero-state"], 1635=>["zero-state"], 1816=>["zero-state"], 2105=>["zero-state"], 2147=>["zero-state"], 2171=>["zero-state"], 2185=>["zero-state"], 2283=>["zero-state"], 2551=>["zero-state"], 2767=>["zero-state"], 2786=>["zero-state"], 2860=>["zero-state"], 2903=>["zero-state"], 3202=>["zero-state"], 3210=>["zero-state"], 3231=>["zero-state"], 3267=>["zero-state"], 3290=>["zero-state"], 3297=>["zero-state"], 3344=>["zero-state"], 24=>["mailing-labels"], 627=>["mailing-labels"], 1679=>["mailing-labels"], 1722=>["mailing-labels"], 2230=>["mailing-labels"], 2645=>["mailing-labels"], 2855=>["mailing-labels"], 3236=>["mailing-labels"], 355=>["profile"], 420=>["profile"], 486=>["profile"], 541=>["profile"], 641=>["profile"], 911=>["profile"], 966=>["profile"], 1035=>["profile"], 1046=>["profile"], 1266=>["profile"], 1270=>["profile"], 1271=>["profile"], 1378=>["profile"], 1438=>["profile"], 1445=>["profile"], 1446=>["profile"], 1462=>["profile"], 1586=>["profile"], 1643=>["profile"], 1644=>["profile"], 1715=>["profile"], 1723=>["profile"], 1830=>["profile"], 1889=>["profile"], 1959=>["profile"], 1997=>["profile"], 2027=>["profile"], 2133=>["profile"], 2149=>["profile"], 2158=>["profile"], 2236=>["profile"], 2276=>["profile"], 2459=>["profile"], 2480=>["profile"], 2483=>["profile"], 2542=>["profile"], 2566=>["profile"], 2634=>["profile"], 2754=>["profile"], 2929=>["profile"], 3067=>["profile"], 3076=>["profile"], 3097=>["profile"], 3191=>["profile"], 3213=>["profile"], 3246=>["profile"], 3268=>["profile"], 3274=>["profile"], 3369=>["profile"], 381=>["people"], 1128=>["people"], 1301=>["people"], 1363=>["people"], 1507=>["people"], 1665=>["people"], 1867=>["people"], 1992=>["people"], 2135=>["people"], 2150=>["people"], 2187=>["people"], 2268=>["people"], 2301=>["people"], 2470=>["people"], 2660=>["people"], 2704=>["people"], 2709=>["people"], 2755=>["people"], 2831=>["people"], 3053=>["people"], 3161=>["people"], 3195=>["people"], 3232=>["people"], 650=>["households"], 984=>["households"], 1155=>["households"], 1675=>["households"], 1691=>["households"], 1836=>["households"], 1868=>["households"], 2016=>["households"], 2241=>["households"], 2641=>["households"], 2642=>["households"], 2643=>["households"], 2808=>["households"], 2989=>["households"], 3000=>["households"], 3089=>["households"], 3136=>["households"], 3190=>["households"], 500=>["events"], 817=>["events"], 862=>["events"], 938=>["events"], 1228=>["events"], 1229=>["events"], 1345=>["events"], 1369=>["events"], 1848=>["events"], 1890=>["events"], 1984=>["events"], 2062=>["events"], 2525=>["events"], 2699=>["events"], 2774=>["events"], 2896=>["events"], 3102=>["events"], 3110=>["events"], 3111=>["events"], 3298=>["events"], 3407=>["events"], 2095=>["events", "export"], 2579=>["events", "export"], 2701=>["events", "export"], 2806=>["events", "export"], 1031=>["smart-groups"], 1032=>["smart-groups"], 1034=>["smart-groups"], 1036=>["smart-groups"], 1143=>["smart-groups"], 1148=>["smart-groups"], 1223=>["smart-groups"], 1232=>["smart-groups"], 1527=>["smart-groups"], 1629=>["smart-groups"], 1844=>["smart-groups"], 1861=>["smart-groups"], 1864=>["smart-groups"], 2212=>["smart-groups"], 2461=>["smart-groups"], 2495=>["smart-groups"], 2628=>["smart-groups"], 2638=>["smart-groups"], 2674=>["smart-groups"], 2712=>["smart-groups"], 2893=>["smart-groups"], 2944=>["smart-groups"], 3144=>["smart-groups"], 3158=>["smart-groups"], 3174=>["smart-groups"], 1347=>["admin"], 1500=>["admin"], 1950=>["admin"], 2164=>["admin"], 2365=>["admin"], 2511=>["admin"], 2543=>["admin"], 2590=>["admin"], 2740=>["admin"], 2923=>["admin"], 2945=>["admin"], 2973=>["admin"], 2994=>["admin"], 3002=>["admin"], 3062=>["admin"], 3217=>["admin"], 3287=>["admin"], 3289=>["admin"], 3316=>["admin"], 3318=>["admin"], 3319=>["admin"], 3374=>["admin"], 3382=>["admin"], 1171=>["church-directory"], 1173=>["church-directory"], 2398=>["church-directory"], 2400=>["church-directory"], 2401=>["church-directory"], 2406=>["church-directory"], 2407=>["church-directory"], 2422=>["church-directory"], 2690=>["church-directory"], 2925=>["church-directory"], 3005=>["church-directory"], 3030=>["church-directory"], 3192=>["church-directory"], 3271=>["church-directory"], 3294=>["church-directory"], 3393=>["church-directory"], 2534=>["pastoral-visits"], 2816=>["pastoral-visits"], 2935=>["pastoral-visits"], 3029=>["pastoral-visits"], 3070=>["pastoral-visits"], 3071=>["pastoral-visits"], 2629=>["anniversary-notifications"], 2630=>["anniversary-notifications"], 2631=>["anniversary-notifications"], 870=>["redesign"], 2249=>["redesign"], 2708=>["redesign"], 2798=>["redesign"], 3009=>["redesign"], 503=>["add-event"], 1802=>["permissions"], 2290=>["permissions"], 2920=>["permissions"], 2932=>["permissions"], 2975=>["permissions"], 2977=>["permissions"], 3031=>["permissions"], 3047=>["permissions"], 3052=>["permissions"], 3087=>["permissions"], 3286=>["permissions"], 1960=>["0"], 39=>["ux"], 313=>["ux"], 652=>["ux"], 683=>["ux"], 689=>["ux"], 712=>["ux"], 755=>["ux"], 833=>["ux"], 1017=>["ux"], 1019=>["ux"], 1492=>["ux"], 1506=>["ux"], 1642=>["ux"], 1664=>["ux"], 1676=>["ux"], 1736=>["ux"], 1834=>["ux"], 1859=>["ux"], 1879=>["ux"], 1914=>["ux"], 2064=>["ux"], 2174=>["ux"], 2175=>["ux"], 2192=>["ux"], 2266=>["ux"], 2284=>["ux"], 2322=>["ux"], 2323=>["ux"], 2333=>["ux"], 2380=>["ux"], 2436=>["ux"], 2444=>["ux"], 2488=>["ux"], 2490=>["ux"], 2578=>["ux"], 2626=>["ux"], 2735=>["ux"], 2736=>["ux"], 2898=>["ux"], 2961=>["ux"], 2997=>["ux"], 3035=>["ux"], 3094=>["ux"], 3117=>["ux"], 3250=>["ux"], 3272=>["ux"], 3273=>["ux"], 3292=>["ux"], 2112=>["integration"], 3239=>["integration"], 94=>["denominational-reports"], 1176=>["denominational-reports"], 1349=>["denominational-reports"], 1350=>["denominational-reports"], 2414=>["denominational-reports"], 2563=>["denominational-reports"], 2778=>["denominational-reports"], 3310=>["denominational-reports"], 3321=>["denominational-reports"],
    2507=>["reports"],
    2995=>["reports"],
    3081=>["reports"],
    2847=>["redesign"],
    3550=>["redesign"],
    1939=>["redesign"],
    2202=>["redesign"],
    2232=>["redesign"],
    2464=>["redesign"],
    2620=>["redesign"],
    2844=>["redesign"],
    2971=>["redesign"]
  }.freeze

end
