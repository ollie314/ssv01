module ApplicationHelper
  def user_signed_in?
    return false
  end

  def in_maintenance?
    return true
  end
end
