Houston.config do

  # This is the name that will be shown in the banner
  title "Houston"

  # This is the host where Houston will be running
  host "houston.my-company.com"

  # This is the email address for emails send from Houston
  mailer_sender "houston@my-company.com"

  # This is the passphrase Houston will use to encrypt and decrypt sensitive data
  passphrase "Keep it secret! Keep it safe."

  # (Optional) These are the categories you can organize your projects by
  project_categories "Products", "Services", "Libraries", "Tools"

  # These are the colors available for projects
  project_colors(
    "teal"          => "39b3aa",
    "sky"           => "239ce7",
    "sea"           => "335996",
    "indigo"        => "7d63b8",
    "thistle"       => "b35ab8",
    "tomato"        => "e74c23",
    "bark"          => "756e54",
    "hazelnut"      => "a4703d",
    "burnt_sienna"  => "df8a3d",
    "orange"        => "e9b84e",
    "pea"           => "84bd37",
    "leaf"          => "409938",
    "spruce"        => "307355",
    "slate"         => "6c7a80",
    "silver"        => "a2a38b" )

  # These are the environments you deploy projects to
  environments "Production", "Staging"

  # These are the tags available for each change in Release Notes
  change_tags( {name: "New Feature", as: "feature", color: "8DB500"},
               {name: "Improvement", as: "improvement", color: "3383A8", aliases: %w{enhancement}},
               {name: "Bugfix", as: "fix", color: "C64537", aliases: %w{bugfix}},
               {name: "Refactor", as: "refactor", color: "909090"},
               {name: "Testfix", as: "testfix", color: "909090"},
               {name: "CI Fix", as: "ci", color: "909090", aliases: %w{cifix ciskip}} )

  # These are the types of tickets
  ticket_types({
    "Chore"       => "909090",
    "Feature"     => "8DB500",
    "Enhancement" => "3383A8",
    "Bug"         => "C64537"
  })



  # Modules
  # ---------------------------------------------------------------------------
  #
  # Modules provide a way to extend Houston.
  #
  # They are mountable Rails Engines whose routes are automatically
  # added to Houston's, prefixed with the name of the module.
  #
  # To create a new module for Houston, run:
  #
  #   gem install houston-cli
  #   houston_new_module <MODULE>
  #
  # Then add the module to this file with:
  #
  #   use :<MODULE>, github: "<USERNAME>/houston-<MODULE>", branch: "master"
  #
  # When developing a module, it can be helpful to tell Bundler
  # to refer to the local copy of your module's repo:
  #
  #   bundle config local.houston-<MODULE> ~/Projects/houston-<MODULE>
  #

  use :feedback, bundle: false



  # Roles
  # ---------------------------------------------------------------------------
  #
  # A user can have zero or one of these roles.
  # You can refer to these roles when you configure
  # abilities.
  #
  # To this list, Houston will add the role "Guest",
  # which is the default (null) role.
  #
  # Presently, Houston requires that "Tester" be
  # one of these roles.
  roles "Developer",
        "Tester"

  # Project Roles
  # ---------------------------------------------------------------------------
  #
  # Each of these roles is project-specific. A user
  # can have zero or many project roles. You can refer
  # to these roles when you configure abilities.
  #
  # Presently, Houston requires that "Maintainer" be
  # one of these roles.
  project_roles "Owner",
                "Maintainer"

  # Abilities
  # ---------------------------------------------------------------------------
  #
  # In this block, use the DSL defined by CanCan.
  # Learn more: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  abilities do |user|
    if user.nil?

      # Customers are allowed to see Release Notes of products, for production
      can :read, Release do |release|
        release.project.category == "Products" && (release.environment_name.blank? || release.environment_name == "Production")
      end

      # Customers are allowed to see Features, Improvements, and Bugfixes
      can :read, ReleaseChange, tag_slug: %w{feature improvement fix}

    else

      # Everyone can see Releases to staging
      can :read, Release

      # Everyone is allowed to see Features, Improvements, and Bugfixes
      can :read, ReleaseChange, tag_slug: %w{feature improvement fix}

      # Everyone can see Projects
      can :read, Project

      # Everyone can see and create Tickets
      can [:read, :create], Ticket

      # Everyone can see Milestones
      can :read, Milestone

      # Everyone can see Users and update themselves
      can :read, User
      can :update, user

      # Everyone can make themselves a "Follower"
      can :create, Role, name: "Follower"

      # Everyone can remove themselves from a role
      can :destroy, Role, user_id: user.id

      # Everyone can edit their own testing notes
      can [:update, :destroy], TestingNote, user_id: user.id

      # Everyone can see project quotas
      can :read, Houston::Scheduler::ProjectQuota

      # Developers see the other kinds of changes: Test Fixes and Refactors
      # as well as commit info
      can :read, [Commit, ReleaseChange] if user.developer?
      can :manage, Sprint if user.developer?

      # Testers and Developers can see and comment on all testing notes
      can [:create, :read], TestingNote if user.tester? or user.developer?
      can :manage, Houston::Alerts::Alert if user.developer? or user.tester?
      can :manage, Task if user.developer?

      # The following abilities are project-specific and depend on one's role
      roles = user.roles.participants
      if roles.any?

        # Everyone can see and comment on Testing Reports for projects they are involved in
        can [:create, :read], TestingNote, project_id: roles.pluck(:project_id)

        # Maintainers can manage Releases, close and estimate Tickets, and update Projects
        roles.maintainers.pluck(:project_id).tap do |project_ids|
          can :manage, Release, project_id: project_ids
          can :update, Project, id: project_ids
          can :close, Ticket, project_id: project_ids
          can :estimate, Project, id: project_ids # <-- !todo: remove
        end

        # Product Owners can prioritize tickets
        can :prioritize, Project, id: roles.owners.pluck(:project_id)
      end
    end
  end



end
