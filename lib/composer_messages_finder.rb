class ComposerMessagesFinder

  def initialize(user, details)
    @user = user
    @details = details
  end

  def find
    check_education_message ||
    check_avatar_notification
  end

  # Determines whether to show the user education text
  def check_education_message
    if creating_topic?
      count = @user.created_topic_count
      education_key = :education_new_topic
    else
      count = @user.topic_reply_count
      education_key = :education_new_reply
    end

    if count <= SiteSetting.educate_until_posts
      education_posts_text = I18n.t('education.until_posts', count: SiteSetting.educate_until_posts)
      return {templateName: 'composer/education',
              wait_for_typing: true,
              body: PrettyText.cook(SiteContent.content_for(education_key, education_posts_text: education_posts_text)) }
    end

    nil
  end

  # Should a user be contacted to update their avatar?
  def check_avatar_notification

    # A user has to be basic at least to be considered for an avatar notification
    return unless @user.has_trust_level?(:basic)

    # We don't notify users who have avatars or who have been notified already.
    return if @user.user_stat.has_custom_avatar? || UserHistory.exists_for_user?(@user, :notified_about_avatar)

    # Finally, we don't check users whose avatars haven't been examined
    return unless UserHistory.exists_for_user?(@user, :checked_for_custom_avatar)

    # If we got this far, log that we've nagged them about the avatar
    UserHistory.create!(action: UserHistory.actions[:notified_about_avatar], target_user_id: @user.id )

    # Return the message
    {templateName: 'composer/education', body: PrettyText.cook(I18n.t('education.avatar', profile_path: "/users/#{@user.username_lower}")) }
  end

  private

    def creating_topic?
      return @details[:composerAction] == "createTopic"
    end

    def replying?
      return @details[:composerAction] == "reply"
    end

end