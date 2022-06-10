# frozen_string_literal: true

namespace :decidim do
  namespace :activities do
    desc "Displays a set of stats of the organizations"
    task report: [:environment] do
      heading "Stats for #{Decidim::Organization.count} organization(s):"
      hr
      heading "Users"
      report "Users", Decidim::User.count
      report "Users with activity", users_with_activity

      heading "Comments"
      report "Comments", Decidim::Comments::Comment.count
      report "Comment votes", Decidim::Comments::CommentVote.count

      heading "Proposals"
      report "Proposals", Decidim::Proposals::Proposal.count
      report "Proposal votes", Decidim::Proposals::ProposalVote.count
      report "Proposal endorsements", Decidim::Endorsement.where(resource_type: "Decidim::Proposals::Proposal").count

      heading "Meetings"
      report "Meetings", Decidim::Meetings::Meeting.count
      report "Meeting registrations", Decidim::Meetings::Registration.count

      heading "Debates"
      report "Debates", Decidim::Debates::Debate.count
      report "Debates endorsements", Decidim::Endorsement.where(resource_type: "Decidim::Debates::Debate").count

      heading "Participatory Processes"
      report "Participatory Processes", Decidim::ParticipatoryProcess.count

      if model_present?("Decidim::Assembly")
        heading "Assemblies"
        report "Assemblies", Decidim::Assembly.count
        report "Assembly Members", Decidim::AssemblyMember.count
      end

      if model_present?("Decidim::Initiative")
        heading "Initiatives"
        report "Initiatives", Decidim::Initiative.count
        report "Initiatives votes", Decidim::InitiativesVote.count
      end
      hr
    end

    desc "Extracts decidim activities"
    task activities_csv: [:environment] do
      path = "/tmp/decidim_activities_report.csv"
      File.binwrite(path, Decidim::Exporters::CSV.new(activities_collection).export(",").read)
    end

    desc "Loads decidim activities on a previous interval if defined"
    task :load_activities, [:minutes_interval] => :environment do |_t, args|
      interval = args[:minutes_interval].present? ? args[:minutes_interval].to_i.minutes.ago : nil
      activities_collection(interval).each do |activity|
        next if Decidim::Activity.exists?(item_type: activity[:item_type], item_id: activity[:item_id])

        Decidim::Activity.create(activity.except(:item_title, :target_title, :participatory_space_title))
      end
    end

    TYPES_CONVERSIONS = {
      "Decidim::Comments::Comment" => "comment",
      "Decidim::Comments::CommentVote" => "comment_vote",
      "Decidim::Debates::Debate" => "debate",
      "Decidim::Endorsement" => "endorsement",
      "Decidim::Follow" => "following",
      "Decidim::Meetings::Meeting" => "meeting",
      "Decidim::Meetings::Registration" => "meeting_registration",
      "Decidim::ParticipatoryProcess" => "participatory_process",
      "Decidim::Proposals::Proposal" => "proposal",
      "Decidim::Proposals::ProposalVote" => "proposal_vote",
      "Decidim::Initiative" => "initiative",
      "Decidim::InitiativesVote" => "initiative_vote",
      "Decidim::Pages::Page" => "page",
      "Decidim::Budgets::Project" => "budget_project",
      "Decidim::UserBaseEntity" => "user",
      "Decidim::User" => "user",
      "Decidim::Assembly" => "assembly",
      "Decidim::AssemblyMember" => "assembly_member",
      "Decidim::Proposals::CollaborativeDraft" => "proposal_collaborative_draft",
      "Decidim::Accountability::Result" => "accountability_result",
      "Decidim::Blogs::Post" => "blog_post",
      "Decidim::Consultations::Question" => "consultation_question",
      "Decidim::Votings::Voting" => "voting",
      "Decidim::Conference" => "conference"
    }.freeze

    RESOURCES_WITHOUT_TITLE = [
      "Decidim::AssemblyMember",
      "Decidim::Comments::Comment",
      "Decidim::Endorsement",
      "Decidim::Follow",
      "Decidim::Meetings::Registration",
      "Decidim::Proposals::ProposalVote",
      "Decidim::Comments::CommentVote",
      "Decidim::InitiativesVote"
    ]


    RESOURCES_WITHOUT_URL = [
      "Decidim::AssemblyMember",
      "Decidim::Endorsement",
      "Decidim::Follow",
      "Decidim::Meetings::Registration",
      "Decidim::Proposals::ProposalVote",
      "Decidim::Comments::CommentVote",
      "Decidim::InitiativesVote"
    ]

    def activities_collection(time_interval = nil)
      [
        ["Decidim::User", :present_user],
        ["Decidim::Comments::Comment", :present_comment],
        ["Decidim::Comments::CommentVote", :present_comment_vote],
        ["Decidim::Proposals::Proposal", :present_proposal],
        ["Decidim::Proposals::CollaborativeDraft", :present_proposal],
        ["Decidim::Proposals::ProposalVote", :present_proposal_vote],
        ["Decidim::Endorsement", :present_endorsement],
        ["Decidim::Meetings::Meeting", :present_meeting],
        ["Decidim::Meetings::Registration", :present_meeting_registration],
        ["Decidim::Debates::Debate", :present_debate],
        ["Decidim::ParticipatoryProcess", :present_participatory_process],
        ["Decidim::Assembly", :present_assembly],
        ["Decidim::AssemblyMember", :present_assembly_member],
        ["Decidim::Initiative", :present_initiative],
        ["Decidim::InitiativesVote", :present_initiatives_vote],
        ["Decidim::Follow", :present_follow],
        ["Decidim::Blogs::Post", :present_post]
      ].map do |(model, presenter)|
        next [] unless model_present?(model)

        items = time_interval.present? ? model.constantize.where("created_at >= ?", time_interval) : model.constantize.all

        items.map do |item|
          transform_data(send(presenter, item))
        end
      end.compact.flatten
    end

    def transform_data(data)
      data[:timestamp] = data[:timestamp].strftime("%Y-%m-%d")
      data[:item_type] = type_map(data[:item_type])
      data[:target_type] = type_map(data[:target_type])
      data[:participatory_space_type] = type_map(data[:participatory_space_type])
      data
    end

    def type_map(type)
      return if type.blank?

      TYPES_CONVERSIONS[type].presence || "unknown: #{type}"
    end

    def present_user(item)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: nil,
        target_id: nil,
        decidim_user_id: nil,
        participatory_space_type: nil,
        participatory_space_id: nil,
        decidim_organization_id: item.decidim_organization_id,
        item_title: locator_title(item),
        item_url: user_url(item),
        target_title: nil,
        target_url: nil,
        participatory_space_title: nil,
        participatory_space_url: nil
      }
    end

    def present_comment(item)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: item.decidim_commentable_type,
        target_id: item.decidim_commentable_id,
        decidim_user_id: item.decidim_author_id,
        participatory_space_type: item.component&.participatory_space_type,
        participatory_space_id: item.component&.participatory_space_id,
        decidim_organization_id: item.commentable&.organization&.id,
        item_title: locator_title(item),
        item_url: comment_url(item),
        target_title: locator_title(item.commentable),
        target_url: locator_url(item.commentable),
        participatory_space_title: locator_title(item.component&.participatory_space),
        participatory_space_url: locator_url(item.component&.participatory_space)
      }
    end

    def present_comment_vote(item)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: "Decidim::Comments::Comment",
        target_id: item.decidim_comment_id,
        decidim_user_id: nil,
        participatory_space_type: item.comment&.component&.participatory_space_type,
        participatory_space_id: item.comment&.component&.participatory_space_id,
        decidim_organization_id: item.comment&.organization&.id,
        item_title: locator_title(item.comment),
        item_url: locator_url(item.comment),
        target_title: locator_title(item.comment.commentable),
        target_url: locator_url(item.comment.commentable),
        participatory_space_title: locator_title(item.comment.component&.participatory_space),
        participatory_space_url: locator_url(item.comment.component&.participatory_space)
      }
    end

    def present_proposal(item)
      space_title = locator_title(item.component&.participatory_space)
      space_url = locator_url(item.component&.participatory_space)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: item.component&.participatory_space_type,
        target_id: item.component&.participatory_space_id,
        decidim_user_id: item.coauthorships.first&.decidim_author_id,
        participatory_space_type: item.component&.participatory_space_type,
        participatory_space_id: item.component&.participatory_space_id,
        decidim_organization_id: item.organization&.id,
        item_title: locator_title(item),
        item_url: locator_url(item),
        target_title: space_title,
        target_url: space_url,
        participatory_space_title: space_title,
        participatory_space_url: space_url
      }
    end

    def present_proposal_vote(item)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: "Decidim::Proposals::Proposal",
        target_id: item.decidim_proposal_id,
        decidim_user_id: nil,
        participatory_space_type: item.proposal&.component&.participatory_space_type,
        participatory_space_id: item.proposal&.component&.participatory_space_id,
        decidim_organization_id: item.proposal&.organization&.id,
        item_title: locator_title(item),
        item_url: locator_url(item),
        target_title: locator_title(item.proposal),
        target_url: locator_url(item.proposal),
        participatory_space_title: locator_title(item.proposal&.component&.participatory_space),
        participatory_space_url: locator_url(item.proposal&.component&.participatory_space)
      }
    end

    def present_endorsement(item)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: item.resource_type,
        target_id: item.resource_id,
        decidim_user_id: item.decidim_author_id,
        participatory_space_type: item.resource&.try(:component)&.participatory_space_type,
        participatory_space_id: item.resource&.try(:component)&.participatory_space_id,
        decidim_organization_id: item.resource&.organization&.id,
        item_title: locator_title(item),
        item_url: locator_url(item),
        target_title: locator_title(item.resource),
        target_url: locator_url(item.resource),
        participatory_space_title: locator_title(item.resource&.try(:component)&.participatory_space),
        participatory_space_url: locator_url(item.resource&.try(:component)&.participatory_space)
      }
    end

    def present_meeting(item)
      space_title = locator_title(item.component&.participatory_space)
      space_url = locator_url(item.component&.participatory_space)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: item.component&.participatory_space_type,
        target_id: item.component&.participatory_space_id,
        decidim_user_id: item.decidim_author_id,
        participatory_space_type: item.component&.participatory_space_type,
        participatory_space_id: item.component&.participatory_space_id,
        decidim_organization_id: item.organization&.id,
        item_title: locator_title(item),
        item_url: locator_url(item),
        target_title: space_title,
        target_url: space_url,
        participatory_space_title: space_title,
        participatory_space_url: space_url
      }
    end

    def present_meeting_registration(item)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: "Decidim::Meetings::Meeting",
        target_id: item.decidim_meeting_id,
        decidim_user_id: item.decidim_user_id,
        participatory_space_type: item.meeting&.component&.participatory_space_type,
        participatory_space_id: item.meeting&.component&.participatory_space_id,
        decidim_organization_id: item.meeting&.organization&.id,
        item_title: locator_title(item),
        item_url: locator_url(item),
        target_title: locator_title(item.meeting),
        target_url: locator_url(item.meeting),
        participatory_space_title: locator_title(item.meeting&.component&.participatory_space),
        participatory_space_url: locator_url(item.meeting&.component&.participatory_space)
      }
    end

    def present_debate(item)
      space_title = locator_title(item.component&.participatory_space)
      space_url = locator_url(item.component&.participatory_space)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: item.component&.participatory_space_type,
        target_id: item.component&.participatory_space_id,
        decidim_user_id: item.decidim_author_id,
        participatory_space_type: item.component&.participatory_space_type,
        participatory_space_id: item.component&.participatory_space_id,
        decidim_organization_id: item.organization&.id,
        item_title: locator_title(item),
        item_url: locator_url(item),
        target_title: space_title,
        target_url: space_url,
        participatory_space_title: space_title,
        participatory_space_url: space_url
      }
    end

    def present_participatory_process(item)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: nil,
        target_id: nil,
        decidim_user_id: nil,
        participatory_space_type: "Decidim::ParticipatoryProcess",
        participatory_space_id: item.id,
        decidim_organization_id: item.decidim_organization_id,
        item_title: locator_title(item),
        item_url: locator_url(item),
        target_title: nil,
        target_url: nil,
        participatory_space_title: locator_title(item),
        participatory_space_url: locator_url(item)
      }
    end

    def present_assembly(item)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: nil,
        target_id: nil,
        decidim_user_id: nil,
        participatory_space_type: "Decidim::Assembly",
        participatory_space_id: item.id,
        decidim_organization_id: item.decidim_organization_id,
        item_title: locator_title(item),
        item_url: locator_url(item),
        target_title: nil,
        target_url: nil,
        participatory_space_title: locator_title(item),
        participatory_space_url: locator_url(item)
      }
    end

    def present_assembly_member(item)
      space_title = locator_title(item.assembly)
      space_url = locator_url(item.assembly)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: "Decidim::Assembly",
        target_id: item.decidim_assembly_id,
        decidim_user_id: item.decidim_user_id,
        participatory_space_type: "Decidim::Assembly",
        participatory_space_id: item.decidim_assembly_id,
        decidim_organization_id: item.organization&.id,
        item_title: locator_title(item),
        item_url: locator_url(item),
        target_title: space_title,
        target_url: space_url,
        participatory_space_title: space_title,
        participatory_space_url: space_url
      }
    end

    def present_initiative(item)
      space_title = locator_title(item)
      space_url = locator_url(item)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: nil,
        target_id: nil,
        decidim_user_id: item.decidim_author_id,
        participatory_space_type: "Decidim::Initiative",
        participatory_space_id: item.id,
        decidim_organization_id: item.decidim_organization_id,
        item_title: space_title,
        item_url: space_url,
        target_title: nil,
        target_url: nil,
        participatory_space_title: space_title,
        participatory_space_url: space_url
      }
    end

    def present_initiatives_vote(item)
      space_title = locator_title(item.initiative)
      space_url = locator_url(item.initiative)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: "Decidim::Initiative",
        target_id: item.decidim_initiative_id,
        decidim_user_id: nil,
        participatory_space_type: "Decidim::Initiative",
        participatory_space_id: item.decidim_initiative_id,
        decidim_organization_id: item.initiative&.decidim_organization_id,
        item_title: locator_title(item),
        item_url: locator_url(item),
        target_title: space_title,
        target_url: space_url,
        participatory_space_title: space_title,
        participatory_space_url: space_url
      }
    end

    def present_follow(item)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: item.decidim_followable_type,
        target_id: item.decidim_followable_id,
        decidim_user_id: item.decidim_user_id,
        participatory_space_type: item.followable&.try(:component)&.participatory_space_type,
        participatory_space_id: item.followable&.try(:component)&.participatory_space_id,
        decidim_organization_id: item.user&.organization&.id,
        item_title: locator_title(item),
        item_url: locator_url(item),
        target_title: locator_title(item.followable),
        target_url: locator_url(item.followable),
        participatory_space_title: locator_title(item.followable&.try(:component)&.participatory_space),
        participatory_space_url: locator_url(item.followable&.try(:component)&.participatory_space)
      }
    end

    def present_post(item)
      space_title = locator_title(item.component&.participatory_space)
      space_url = locator_url(item.component&.participatory_space)
      {
        timestamp: item.created_at,
        item_type: item.class.name,
        item_id: item.id,
        target_type: item.component&.participatory_space_type,
        target_id: item.component&.participatory_space_id,
        decidim_user_id: item.decidim_author_id,
        participatory_space_type: item.component&.participatory_space_type,
        participatory_space_id: item.component&.participatory_space_id,
        decidim_organization_id: item.organization&.id,
        item_title: locator_title(item),
        item_url: locator_url(item),
        target_title: space_title,
        target_url: space_url,
        participatory_space_title: space_title,
        participatory_space_url: space_url
      }
    end

    def locator_url(item)
      return if item.blank?
      return if RESOURCES_WITHOUT_URL.any? { |class_name| item.is_a?(class_name.constantize) rescue false }

      if item.is_a?(Decidim::Comments::Comment)
        comment_url(item)
      elsif item.is_a?(Decidim::Budgets::Project)
        item.polymorphic_resource_url({})
      elsif [Decidim::User, Decidim::UserGroup, Decidim::UserBaseEntity].any? { |klass| item.is_a?(klass) }
        user_url(item)
      else
        ::Decidim::ResourceLocatorPresenter.new(item).url
      end
    rescue => e
      "FAIL"
    end

    def locator_title(item)
      return if item.blank?
      return if RESOURCES_WITHOUT_TITLE.any? { |class_name| item.is_a?(class_name.constantize) rescue false }
      return user_title(item) if [Decidim::User, Decidim::UserGroup, Decidim::UserBaseEntity].any? { |klass| item.is_a?(klass) }

      item.try(:title) || item.try(:name) || item.try(:subject) || "#{resource.model_name.human} ##{resource.id}"
    rescue
      "0000_FAIL"
    end

    def user_title(item)
      item.nickname
    end

    def comment_url(item)
      item.reported_content_url
    rescue
      "FAIL"
    end

    def user_url(item)
      Decidim::UserPresenter.new(item).profile_url
    end

    def hr(extra = "\n")
      puts "===========================================#{extra}"
    end

    def report(title, value)
      puts "  * #{title}: #{value}"
    end

    def heading(title)
      puts "\n== #{title}"
    end

    def users_with_activity
      [
        ["Decidim::Comments::Comment", :decidim_author_id],
        ["Decidim::Comments::CommentVote", :decidim_author_id],
        ["Decidim::Coauthorship", :decidim_author_id],
        ["Decidim::Proposals::ProposalVote", :decidim_author_id],
        ["Decidim::Endorsement", :decidim_author_id],
        ["Decidim::Meetings::Meeting", :decidim_author_id],
        ["Decidim::Meetings::Registration", :decidim_user_id],
        ["Decidim::Debates::Debate", :decidim_author_id],
        ["Decidim::Initiative", :decidim_author_id],
        ["Decidim::InitiativesVote", :decidim_author_id],
        ["Decidim::Follow", :decidim_user_id]
      ].map do |(model, attribute)|
        next [] unless model_present?(model)

        model.constantize.select(attribute).distinct.pluck(attribute)
      end.compact.flatten.uniq.count
    end

    def model_present?(model_name)
      model_name.constantize.is_a? Class
    rescue NameError
      heading "#{model_name} not installed"
      false
    end
  end
end
