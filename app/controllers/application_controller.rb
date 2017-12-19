class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true
  # protect_from_forgery with: :exception

  before_action :authorize_current_activity, :unless => :devise_controller?

  Warden::Manager.after_set_user do |user, auth, opts|
    session = auth.env["rack.session"]
    session["link_user_id"] = user.id
  end

  def authorize_current_activity
    # See if we're coming in from another customer
    current_customer_id = Customer.current&.id
    previous_customer_id = session["customer_id"].to_i
    if current_customer_id && previous_customer_id > 0 && (previous_customer_id != current_customer_id)
      previous_customer = Customer.find_by(id: previous_customer_id)
      if previous_customer
        # Allow transitivity by seeing if there is any possible sequence of
        # links we can navigate that allows us to get to this other customer.
        links = UserLink.find_by_sql(
"WITH RECURSIVE hops AS
  (SELECT id, user_id, customer_id, link_user_id, link_customer_id,
    ',' || CAST(link_customer_id AS VARCHAR) || ',' AS ids
    FROM public.user_links
    WHERE active = true AND link_customer_id = #{previous_customer.id} AND link_user_id = #{session["link_user_id"].to_i}
UNION ALL
  SELECT n.id, n.user_id, n.customer_id, n.link_user_id, n.link_customer_id,
    hops.ids || CAST(n.link_customer_id AS VARCHAR) || ','
    FROM public.user_links AS n
      INNER JOIN hops ON hops.ids NOT LIKE '%,' || n.customer_id || ',%' AND hops.user_id = n.link_user_id AND hops.customer_id = n.link_customer_id
    WHERE active = true)
SELECT * FROM hops;")
        # There may be multiple valid paths, but pick the first one that gets us there
        user_link = links.find{|link| link.customer_id == current_customer_id}
        # On any found user_link we can see the user_id for whom we should now be logged in

        # Re-do things so we're on as the right person
        sign_in(User.find(user_link.user_id), scope: :user) if user_link
      end
    end

    unless current_customer_id.nil?
      authenticate_user! unless (user_signed_in? || devise_controller?)
      # authorize_action_for current_activity unless (devise_controller? && !(self.is_a? Users::InvitationsController) || (self.is_a?(Users::InvitationsController) && current_user.nil? ))
      session["customer_id"] = current_customer_id
    end

  end
end
