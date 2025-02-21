module ApplicationHelper
  def meta_title
    [@meta_title, 'Ecosyste.ms: Resolve'].compact.join(' | ')
  end

  def meta_description
    @meta_description || app_description
  end

  def app_name
    "Resolve"
  end

  def app_description
    'An open API service to resolve dependency trees of packages for many open source software ecosystems. '
  end
end
