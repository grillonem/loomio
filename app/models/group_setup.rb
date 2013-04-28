class GroupSetup < ActiveRecord::Base
  attr_accessible :group_name, :group_description, :viewable_by, :members_invitable_by,
                  :discussion_title, :discussion_description, :motion_title, :motion_description,
                  :close_at_date, :close_at_time, :close_at_time_zone, :admin_email, :members_list, :invite_subject, :invite_body

  after_initialize :set_default_close_at_date_and_time

  belongs_to :group

  def compose_group!
    self.group.update_attributes(name: group_name,
                                 description: group_description,
                                 viewable_by: viewable_by,
                                 members_invitable_by: members_invitable_by)
    self.group.save!
  end

  def compose_discussion!(author, group)
    discussion = Discussion.new(title: discussion_title,
                                description: discussion_description)
    discussion.author = author
    discussion.group = group
    discussion.save!
  end

  def compose_motion!(author, discussion)
    motion =  Motion.new( name: motion_title,
                          description: motion_description,
                          close_at_date: close_at_date,
                          close_at_time: close_at_time,
                          close_at_time_zone: close_at_time_zone
                          )
    motion.author = author
    motion.discussion = discussion
    motion.save!
  end

  def send_invitations
    invite_people = InvitePeople.new(params[:invite_people])
    num = CreateInvitation.to_people_and_email_them(invite_people, group: @group, inviter: current_user)
  end


  def finish!(author)
    return true if compose_group! &&
                   compose_discussion!(author, group) &&
                   compose_motion!(author, group.discussions.first)
    false
  end

  private
    def set_default_close_at_date_and_time
      self.close_at_date ||= 3.days.from_now.to_date
      self.close_at_time = Time.now.strftime("%H:00")
    end
end